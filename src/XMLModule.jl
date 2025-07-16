module XMLModule
using Reexport
using AndExport
@reexport using EzXML

using ..Utils

@xport function findall_in_subsoup(path,xpath,soup)
    return findall("$(path)$xpath",soup)
end

@xport function findfirst_in_subsoup(path,xpath,soup)
    return findfirst("$(path)$xpath",soup)
end

@xport function filter_node_content_by_paths(node,paths)
    content = ""
    path = node.path
    for child in nodes(node)
        if !(any(x -> x == child.path, paths))
            content *= child.content
        end
    end
    return clean_text(content)
end


function pair_quotes(s)
#    s = replace(s, "'" => '\"')
#    single_quote_count = count(c -> c == '\'', s)
#    double_quote_count = count(c -> c == '"', s)
#    s = replace(s, '\'' => "")
#    s = replace(s, '"' => "")
    return s
end

@xport function clean_text(str::AbstractString)
    # Replace newline characters with an empty string
    filtered_str = replace(str, "\n" => "")
#    filtered_str = replace.(str, r"^[ \.]?-+" => "")
    # Replace multiple spaces with a single space, excluding spaces between words
    filtered_str = pair_quotes(replace(filtered_str, r"\s+" => " "))
    if all(isspace, filtered_str)
        return "N/A"
    else
        return strip(lstrip(filtered_str))
    end
end


end
