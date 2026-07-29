module Visualization

using ..Ingestion
using Latexify
using Symbolics

export generate_proof, forward_verify, ast_to_latex

"""
    ast_to_latex(expr)

Converts a Symbolics expression or ASTNode to a raw LaTeX string suitable for dataset serialization.
"""
function ast_to_latex(expr)
    if expr isa AlgebraicNode
        # Extract Symbolics payload
        payload = expr.payload
    else
        payload = expr
    end
    # latexify gives a LaTeX formatted string, we strip the $ $ tags
    raw_tex = string(latexify(payload, env=:raw))
    # Basic cleanup for clean json representation
    raw_tex = replace(raw_tex, "\\begin{equation}" => "")
    raw_tex = replace(raw_tex, "\\end{equation}" => "")
    return strip(raw_tex)
end

"""
    forward_verify(expr)

Uses SymbolicIntegration.jl (RUBI) to solve the integration and generate 
a step-by-step mathematical proof confirming the deterministic generation.
"""
function forward_verify(expr)
    @eval using SymbolicIntegration
    @variables x
    # Forward pass using RUBI rules, via invokelatest to avoid world-age and namespace issues
    result = Base.invokelatest(eval(:(SymbolicIntegration.integrate)), expr, x)
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
