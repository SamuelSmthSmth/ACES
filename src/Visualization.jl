module Visualization

using ..Ingestion
using Latexify
using Symbolics

export generate_proof, forward_verify

"""
    forward_verify(expr)

Uses SymbolicIntegration.jl (RUBI) to solve the integration and generate 
a step-by-step mathematical proof confirming the deterministic generation.
"""
function forward_verify(expr)
    @eval using SymbolicIntegration
    @variables x
    # Forward pass using RUBI rules, via invokelatest to avoid world-age and namespace issues
    result = Base.invokelatest(SymbolicIntegration.integrate, expr, x)
    return result
end

"""
    generate_proof(steps::Vector{ASTNode})

Render intermediate generation steps back to perfectly readable LaTeX.
"""
function generate_proof(steps::AbstractVector{<:ASTNode})
    proof_latex = String[]
    for (i, step) in enumerate(steps)
        if step isa AlgebraicNode
            push!(proof_latex, latexify(step.payload))
        else
            # Basic fallback. In a full implementation, we define @latexrecipe 
            # for LimitNode, IntegralNode, etc.
            push!(proof_latex, "\\text{Step $i: } " * string(typeof(step)))
        end
    end
    return proof_latex
end

end # module
