module Verification

using ..Ingestion
using SymbolicUtils

export verify_exploits

function verify_exploits(node::ASTNode, exploits::Vector)
    # TODO: Use localized E-Graph rulesets to verify prerequisites of exploits
    return exploits
end

end # module
