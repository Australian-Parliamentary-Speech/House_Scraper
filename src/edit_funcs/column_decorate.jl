function column_decorate(input_fn, output_fn, ::Type{<:AbstractEditPhase})
    csvfile= CSV.File(input_fn)
    headers_ = copy(propertynames(csvfile))
    header_to_num = edit_set_up(headers_)
    num_to_header = reverse_dict(header_to_num)

    rows = eachrow(csvfile)
    row_index = 1

    new_header_to_num, new_headers = add_header(num_to_header)
    speaker_num = 1

    open(output_fn,"w") do io
        write_row_to_io(io,string.(new_headers))
        for row in rows
            if row_index > 1
                row_dict,speaker_num = input_speaker_number(rows,row_dict, row_index,speaker_num,header_to_num)
            else
                row_dict[:speaker_no] = speaker_num 
            end

            row_dict = Dict()
            if is_stage_direction(row,header_to_num)

                row_dict[:stage_direction_flag] = 1
            else
                row_dict[:stage_direction_flag] = 0
                speaker_num += 1
            end
            row_ = @. collect(row)
            row = row_[1]
            #fill row_dict with previous values
            for header in headers_ 
                row_dict[header] = row[header_to_num[header]]
            end
            new_row = fill_row(new_headers, row_dict)
            write_row_to_io(io,new_row)
            row_index += 1
        end
    end
end

function input_speaker_number(rows,row_dict,row_index, speaker_num,header_to_num)
    current_row = get_row(rows,row_index)
    prev_row = get_row(rows,row_index-1)
    if same_speaker(current_row,prev_row,header_to_num)
        row_dict[:speaker_no] = speaker_num
        return row_dict, speaker_num
    else
        row_dict[:speaker_no] = speaker_num + 1
        return row_dict, speaker_num + 1
    end
end

function same_speaker(current_row,prev_row,header_to_num)
   current_speaker = current_row[header_to_num[:name]]
    if current_speaker == "N/A"
        return false
    else
        prev_debate, prev_subdebate = prev_row[header_to_num[:debateinfo]],prev_row[header_to_num[:subdebateinfo]]
        current_debate, current_subdebate = current_row[header_to_num[:debateinfo]],current_row[header_to_num[:subdebateinfo]] 
        prev_speaker = prev_row[header_to_num[:name]]
        return current_speaker == prev_speaker && current_debate == prev_debate && current_subdebate == prev_subdebate
    end
end

function add_header(num_to_header)
    flag_max = last(sort([k for k in keys(num_to_header) if occursin("flag", string(num_to_header[k]))]))
    additions = [(flag_max+1,:stage_direction_flag),(flag_max+2,:speaker_no)]

    new_num_to_header = add_header_to_num(num_to_header,additions)
    new_headers = [new_num_to_header[i] for i in 1:length(new_num_to_header)]
    return reverse_dict(new_num_to_header),new_headers
end


