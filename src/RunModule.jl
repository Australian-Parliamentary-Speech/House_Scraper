module RunModule
using InteractiveUtils
using Reexport
using OrderedCollections
using CSV

export run_ParlinfoSpeechScraper
export get_year

include("Utils.jl")
using .Utils

include("XMLModule.jl")
using .XMLModule

include("NodeModule.jl")
@reexport using .NodeModule

include("EditModule.jl")
@reexport using .EditModule



"""
    get_date(fn)

Get the date from the xml file

Inputs:
- `fn`: the file directory for the xml file
"""
function get_date(fn)
    function process_fn(fn)
        return replace(basename(fn),".xml"=>"")
    end
    year,month,day,time = begin
        try
            xdoc = readxml(fn)
            soup = root(xdoc)
            time_node = findfirst("//session.header/date",soup)
            time = time_node.content
            year,month,day = split(time,"-")
            Base.GC.gc()
            year,month,day,time
        catch
            fn = process_fn(fn)
            year,month,day = split(fn,"_")
            time = replace(fn, "_" => "-")
            year,month,day,time
        end
    end
    #turns dates into a float for comparison
    return date_to_float(parse(Int,year),parse(Int,month),parse(Int,day)),time
end

"""
run_ParlinfoSpeechScraper(toml::Dict{String, Any})

This function processes XML files for parliamentary speeches according to the configuration specified in the provided TOML dictionary. It reads XML file paths, processes each XML file, and outputs the results to a specified directory.

Inputs:
- `toml`: A dictionary containing configuration options for the scraper.

"""
function run_ParlinfoSpeechScraper(toml::Dict{String, Any})
    global_options = toml["GLOBAL"]
    general_options = toml["GENERAL_OPTIONS"]

    input_path = global_options["INPUT_PATH"]
    output_path = global_options["OUTPUT_PATH"] 
    year_range = general_options["YEAR"]
    which_house = general_options["WHICH_HOUSE"]
    csv_exist = general_options["CSV_EXIST"]
    edit_funcs = general_options["EDIT"]
    over_write = general_options["OVERWRITE"]
    sample_write = general_options["SAMPLE"]

    xml_paths = [] 

    # Get single xml path
    single_xmls = get(toml, "XML", [])
    for single_xml in single_xmls
        filename = single_xml["FILENAME"]
        if ! isabspath(filename)
            filename = joinpath(input_path, filename)
        end
        year = match(r"/(\d{4})/", filename).captures[1]
        push!(xml_paths,(year, filename))
    end

    # Get all xml paths in a directory with years being the subdirectory
    xml_dirs = get(toml,"XML_DIR",[])
    for xml_dir in xml_dirs
        path = xml_dir["PATH"]
        if ! isabspath(path)
            path = joinpath(input_path,path)
        end
        for year in readdir(path)
            if year_range[1] <= parse(Int,year) <= year_range[2]
                for filename in readdir(joinpath(path,year))
                    push!(xml_paths,(year,joinpath(joinpath(path,year),filename)))
                end
            end
        end
    end
    Threads.@threads for (year,fn) in xml_paths
        output_path_ = joinpath(output_path,"$year")
        date_float,date = get_date(fn)
        outputcsv = joinpath(output_path_,"$date.csv")
        if !(isfile(outputcsv))
            create_dir(output_path_)
            run_xml(fn,output_path_,csv_exist,edit_funcs,which_house)
        else
            if over_write
                run_xml(fn,output_path_,csv_exist,edit_funcs,which_house)
            end 
        end
   end
   if sample_write
        copy_sample_file(output_path,length(edit_funcs))
   end
end

function copy_sample_file(output_path,num)
    function skip(num,fn)
        for i in 2:num-1
            if occursin("step$(i)",fn)
                return false
            end
        end
        return true
    end
    sample_dir = joinpath(dirname(output_path),"upload")
    create_dir(sample_dir)
    dirs = filter(isdir,readdir(output_path,join=true))   
    for dir in dirs
        if occursin("1977",dir)
            run(`cp $(joinpath(dir,"1977-08-23_edit_step$(num).csv")) $sample_dir`)
#            run(`cp $(joinpath(dir,"1977-08-23_edit_step1.csv")) $sample_dir`)
 
        end
        ran = 15
        i = 0
        for fn in readdir(dir,join=true)
            if i > ran
                if occursin("step$(num)",fn)  
                    command = `cp $fn $sample_dir`
                    run(command)
                    break
                end
            else
                if skip(num,fn)
                    i += 1
                end
            end
        end
    end
end



"""
    run_xml(fn, output_path, csv_exist, edit_funcs)

Process and save XML data to CSV

This function processes an XML file, extracts relevant data, and saves it to a CSV file. If specified, it also edits the CSV file after creation.

Inputs:
- `fn`: The file path for the XML file.
- `output_path`: The directory where the processed CSV file will be saved.
- `csv_exist`: Boolean flag indicating if a CSV file already exists.
- `edit_funcs`: list of edit functions
"""
function run_xml(fn,output_path,csv_exist,edit_funcs,which_house)
    error_files = []
    xdoc = nothing
    try
        xdoc = readxml(fn)
    catch e
        push!(error_files,fn)
        Base.GC.gc()
        return
    end
    soup = root(xdoc)
    date_float,date = get_date(fn)
    @show date
    PhaseType = detect_phase(date_float,which_house)
    outputcsv = joinpath(output_path,"$date.csv")
    if !(csv_exist) 
        open(outputcsv, "w") do io
            headers_dict = define_headers(PhaseType)
            @debug methods(define_headers)
            write_row_to_io(io,collect(keys(headers_dict)))
            recurse(soup,date_float,PhaseType,soup,io,headers_dict)
        end
    end
    ###Edit
    edit_phase = detect_edit_phase(date)
    editor = Editor(edit_funcs,edit_phase)    
    edit_main(outputcsv,editor)
    open("$(output_path)/log_failed_files.txt", "w") do file
        println(file, error_files)
    end
    Base.GC.gc()
    return date
end


"""
recurse(soup, date, PhaseType, xml_node, io, index=1, depth=0, max_depth=0, node_tree=Vector{Node}())

Recursively process XML nodes and write data to output

This function recursively processes XML nodes, extracts relevant data, and writes it to an output stream. It handles node types, depth limitations, and maintains a tree of processed nodes.

Inputs:
- `soup`: The parsed XML document.
- `date`: The date associated with the XML document.
- `PhaseType`: The phase type determined from the date.
- `xml_node`: The current XML node being processed.
- `io`: The output stream where data is written.
- `index` (optional): The index of the current node (default is 1).
- `depth` (optional): The current depth of recursion (default is 0).
- `max_depth` (optional): The maximum depth for recursion (default is 0, meaning no limit).
- `node_tree` (optional): A vector maintaining the tree of nodes (default is an empty vector).
"""
function recurse(soup, date, PhaseType, xml_node, io, headers_dict, index=1,depth=0, max_depth=0, node_tree=Vector{Node}())
    # If max_depth is defined, and depth has surpassed, don't do anything
    if (max_depth > 0) && (depth > max_depth)
        return nothing
    end

    # Debug statements indented by depth
    ins = ' '^depth
    @debug "$(ins)depth: $depth"
    @debug "$(ins)max_depth: $max_depth"
    @debug "$(ins)node_tree has $(length(node_tree)) elements"
    # First parse the current node, if it is parsable

    # First get nodetype of this node
    NodeType = detect_node_type(xml_node, node_tree, date,soup,PhaseType)

   # If NodeType is not nothing, then we can parse this node
    if !isnothing(NodeType)
        node = Node{NodeType{PhaseType}}(xml_node,index,date,soup,headers_dict)
        @debug "NodeType: $(typeof(node))"
        parse_node(node, node_tree, io)

    else
        @debug "$(ins)NodeType: GenericNode"
        node = Node{GenericNode{GenericPhase}}(xml_node,index,date,soup,headers_dict)
    end

    # Next, recurse into any subnodes
    subnodes = elements(xml_node)
    @debug"$(ins)num_subnodes: $(length(subnodes))"
    #       @show node_tree
    if length(subnodes) > 0
        # Add node to subnode tree
        subnode_tree = copy(node_tree)
        #subnode_tree = node_tree
        #subnode_tree = (node_tree..., node)
        if !(node isa Node{<:GenericNode})
            push!(subnode_tree, node)
        end
        for (i,subnode) in enumerate(subnodes)
            recurse(soup,date,PhaseType,subnode,io,headers_dict,i,depth+1,max_depth,subnode_tree)
        end
    end
end
end
