using ParlinfoSpeechScraper
using EzXML
using InteractiveUtils
using Test
using CSV, DataFrames
using Glob
using BetterInputFiles
include(joinpath(@__DIR__, "utils.jl"))

const RunModule = ParlinfoSpeechScraper.RunModule
using ParlinfoSpeechScraper.RunModule.EditModule

function setup()
    tomlpath = "../Inputs/hansard/hansard.toml"
    toml = setup_input(tomlpath,false)
    global_options = toml["GLOBAL"]
    outputpath = global_options["OUTPUT_PATH"]
    xml_path_toml = toml["XML_DIR"][1]
    xml_path = xml_path_toml["PATH"]
    inputpath = joinpath(dirname(tomlpath),xml_path)
    return inputpath,outputpath
end

function get_sample_csvs(outputpath,gold_standard_csvs,sample_dir)
    for gs_csv in gold_standard_csvs
        gs_name = basename(gs_csv)
        year = split(gs_name,"-")[1]
        sample_file_name = joinpath([outputpath, year, gs_name])
        dir_file_name = joinpath(sample_dir, gs_name)
        cp(sample_file_name, dir_file_name,force=true)
    end
end



function similarity_ratio(gold_standard_csvs,sample_csv_path, testpath)
    fn = joinpath(testpath,"similarity_test.csv")
    open(fn,"w") do io
        for gs_csv in gold_standard_csvs
            gs_name = basename(gs_csv)

            sample_csv = joinpath(sample_csv_path,gs_name)
            ratio = similarity_csv(gs_csv,sample_csv)
            @show ratio
            println(io,"\"$gs_name\",ratio")
        end
    end
end


function compare_outputs(gold_standard_csvs,sample_csv_path,testpath)
    fn = joinpath(testpath,"compatibility_test.csv")
    open(fn,"w") do io
        for gs_csv in gold_standard_csvs
            gs_name = basename(gs_csv)
            sample_csv = joinpath(sample_csv_path,gs_name)
            mismatched = compare_csv(gs_csv,sample_csv)
            println(io,"\"$gs_name\","*mismatched)
        end
    end
end

function compare_gold_standard(outputpath, testpath,which_test)
    gold_standard_path = joinpath(testpath,"gold_standard")
    sample_csv_path = joinpath(testpath,"sample_csv")
    create_dir(sample_csv_path)
    gold_standard_csvs = get_all_csvnames(gold_standard_path)
    get_sample_csvs(outputpath,gold_standard_csvs,sample_csv_path)
    if which_test == :debug
        compare_outputs(gold_standard_csvs, sample_csv_path,testpath)
    elseif which_test == :ratio
        similarity_ratio(gold_standard_csvs,sample_csv_path, testpath) 
    end
end


function get_all_csv_dates(outputpath,testpath)
    function find_all_csv_dates(all_csv_names)
        simple_list = []
        for name in all_csv_names
            date_match = match(r"\d+-\d+-\d+",name)
            date = date_match.match
            push!(simple_list,date) 
        end
        return unique(simple_list)
    end
    all_csv_names = get_all_csv_subdir(outputpath)
    all_csv_dates = find_all_csv_dates(all_csv_names)
    years = [split(date,"-")[1] for date in all_csv_dates]
    open("all_csv_dates.csv", "w") do io
        for (x,y) in zip(years, all_csv_dates)
            println(io, "$x,$y")
        end
    end
end

function get_all_xml_dates(inputpath,testpath)
    function find_all_xml_dates(all_xml_names)
        simple_list = []
        for name in all_xml_names
            date_match = match(r"\d+_\d+_\d+",name)
            date = date_match.match
            date = replace(date, "_" => "-")
            push!(simple_list,date) 
        end
        return unique(simple_list)
    end
    all_xml_names = get_all_xml_subdir(inputpath)
    all_xml_dates = find_all_xml_dates(all_xml_names)
    years = [split(date,"-")[1] for date in all_xml_dates]
    open("all_xml_dates.csv", "w") do io
        for (x,y) in zip(years, all_xml_dates)
            println(io, "$x,$y")
        end
    end
end



@testset verbose = true "Test set" begin
    inputpath, outputpath = setup()
    @test begin
        compare_gold_standard(outputpath, @__DIR__,[:debug,:ratio][2])
        true
    end

#    @test begin
#        get_all_csv_dates(outputpath,@__DIR__)
#        get_all_xml_dates(inputpath,@__DIR__)
#
#        xml = CSV.read("all_xml_dates.csv", DataFrame)
#        csv = CSV.read("all_csv_dates.csv", DataFrame)
#
#        xmls = xml[:, 2]
#        csvs = csv[:, 2]
#        only_in_xml = setdiff(xmls, csvs)
#        only_in_csv = setdiff(csvs, xmls)
#        @show only_in_xml
#        @show only_in_csv
#        true
#    end
end
 


