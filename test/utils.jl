using CSV

function get_row(row)
    row_ = @. collect(row)
    row = row_[1]
    return row 
end

function collect_row(row)
    row_ = @. collect(row)
    row = row_[1]
    return row
end
 
function compare_csv(csv1,csv2)
    csvfile1 = CSV.File(csv1)
    csvfile2 = CSV.File(csv2)
    rows1 = eachrow(csvfile1)
    rows2 = eachrow(csvfile2)
    if length(rows1) == length(rows2)
        rows_mismatched = ""
        for i in 1:length(rows1)
            crow1 = collect_row(rows1[i])
            crow2 = collect_row(rows2[i])
            if crow1 != crow2
                rows_mismatched = rows_mismatched * "\"$(i+1)\","
            end
        end
    else
        rows_mismatched = "length not equal"
    end
    return rows_mismatched
end


function edit_set_up(headers)
    return Dict(zip(headers,collect(1:length(headers)))) 
end

function compare_row(sample_rows, gs_row, num, header_to_num)
    function equiv(row,gs_row)
        @show row
        @show gs_row
        return row == gs_row
    end
    content = gs_row[header_to_num[:content]]
    for i in num:length(sample_rows)
        row = get_row(sample_rows[i])
        sample_content = row[header_to_num[:content]]
        if content == sample_content
            return equiv(row,gs_row),i
        end
    end
    return "N/A", num
end


function similarity_csv(gs_csv,sample_csv)
    sample_csvfile = CSV.File(sample_csv)
    gs_rows = eachrow(CSV.File(gs_csv))
    headers = copy(propertynames(sample_csvfile)) 
    sample_rows = eachrow(sample_csvfile)
    header_to_num = edit_set_up(headers)
    num = 1
    success = 0
    for gs_row in gs_rows
        gs_row = get_row(gs_row)
        equiv, i = compare_row(sample_rows,gs_row,num,header_to_num) 
        @show equiv
        if equiv == true
            success += 1
        end
    end
    return success/length(gs_rows)
end


function create_dir(directory_path::String)
    if !isdir(directory_path)
        mkpath(directory_path)
    end
end

function check_csv(curr,correct)
    file_curr = open(curr, "r") do f
        readlines(f)
    end

    file_correct = open(correct, "r") do f
        readlines(f)
    end

    return file_curr == file_correct
end

function get_all_csvnames(path)
    all = readdir(glob"*.csv", path)
    return all
end

function get_all_csv_subdir(path)
    all = readdir(glob"*/*.csv", path)
    return all
end

function get_all_xml_subdir(path)
    all = readdir(glob"*/*.xml", path)
    return all
end
