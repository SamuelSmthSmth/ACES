module AlgorithmicCalculus

__precompile__(false)

using Symbolics
using SymbolicUtils
using JSON
using AbstractTrees

export parse_latex, detect_exploits, verify_exploits, generate_problem, generate_proof

# Include submodules
include("Ingestion.jl")
include("Exploits.jl")
include("Verification.jl")
include("GeneratorBase.jl")
include("Obfuscation.jl")
include("Visualization.jl")

using .Ingestion
using .Exploits
using .Verification
using .GeneratorBase
using .Obfuscation
using .Visualization

end # module
