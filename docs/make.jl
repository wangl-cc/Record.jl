using Documenter
using RecordedArrays

makedocs(;
    sitename="RecordedArrays.jl",
    pages=["index.md", "manual.md", "example.md", "references.md"],
)

deploydocs(; repo="github.com/wangl-cc/RecordedArrays.jl.git", push_preview=true)
