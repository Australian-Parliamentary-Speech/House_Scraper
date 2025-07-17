# Function references
## ParlinfoSpeechScraper
```@meta
CurrentModule = ParlinfoSpeechScraper
```

```@autodocs
Modules = [ParlinfoSpeechScraper]
```

## RunModule
```@meta
CurrentModule = ParlinfoSpeechScraper.RunModule
```

```@autodocs
Modules = [RunModule]
```

## XMLModule

```@meta
CurrentModule = ParlinfoSpeechScraper.RunModule.EditModule
```

```@autodocs
Modules = [EditModule]
```


## NodeModule
```@meta
CurrentModule = ParlinfoSpeechScraper.RunModule.NodeModule
```

```@docs
get_all_subtypes(type,st=())
```

```@docs
reverse_find_first_node_name(node_tree,names)
```

```@docs
reverse_find_first_node_not_name(node_tree,names)
```

```@docs
get_talker_from_parent(node::Node,parent_node::Node)
```

```@docs
detect_node_type(node,node_tree,date,soup,PhaseType)
```

```@docs
parse_node(node::Node,node_tree,io)
```

```@docs
process_node(node::Node,node_tree)
```

```@docs
is_nodetype(node,node_tree, nodetype::Type{<:AbstractNode}, phase::Type{<:AbstractPhase}, soup, args...; kwargs...)
```

```@docs
get_xpaths(::Type{<:N}) where {N <: AbstractNode}
```

```@docs
find_section_title(node_tree,soup,section_type)
```

```@docs
find_chamber(node,node_tree)
```

```@docs
define_flags(node::Node{<:AbstractNode{<:AbstractPhase}},parent_node,node_tree)
```

```@docs
write_test_xml(trigger_node, parent_node, edge_case)
```


