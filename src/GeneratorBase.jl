module GeneratorBase

using ..Ingestion
using Symbolics
using SymbolicUtils

export generate_integration_problem, generate_differentiation_problem, generate_summation_problem, generate_limit_problem

"""
    generate_integration_problem(depth::Int)

Generates an indefinite integral problem using the Reverse Risch methodology.
Returns the ASTNode for the integrand and the ASTNode for the known antiderivative.
"""
function generate_integration_problem(depth::Int)
    @variables x
    
    # Base expression
    expr = sin(x) * exp(x)
    
    for i in 1:depth
        # Random extensions
        r = rand(1:3)
        if r == 1
            expr = log(expr^2 + rand(1:5))
        elseif r == 2
            expr = exp(sin(expr))
        else
            expr = sqrt(expr^2 + x^2 + rand(1:5))
        end
    end
    
    integrand = Symbolics.derivative(expr, x)
    integrand = Symbolics.expand_derivatives(integrand)
    
    return AlgebraicNode{typeof(integrand)}(integrand), AlgebraicNode{typeof(expr)}(expr), "Reverse_Risch"
end

"""
    generate_differentiation_problem(depth::Int)

Generates a nested differentiation problem using logarithmic power towers.
"""
function generate_differentiation_problem(depth::Int)
    @variables x
    
    expr = x + rand(1:5)
    
    for i in 1:depth
        r = rand(1:3)
        if r == 1
            expr = expr^(sin(x) + rand(1:3))
        elseif r == 2
            expr = exp(expr * x)
        else
            expr = log(expr^2 + x^2 + 1)
        end
    end
    
    derivative = Symbolics.derivative(expr, x)
    derivative = Symbolics.expand_derivatives(derivative)
    
    return AlgebraicNode{typeof(expr)}(expr), AlgebraicNode{typeof(derivative)}(derivative), "Logarithmic_Tower"
end

"""
    generate_summation_problem(depth::Int)

Reverse-engineers a telescoping sum structure.
"""
function generate_summation_problem(depth::Int)
    @variables k
    
    t_k = 1 / (k^2 + rand(1:5))
    
    for i in 1:depth
        t_k = t_k + sin(k * rand(1:3)) / (k + rand(1:5))
    end
    
    t_k_plus_1 = substitute(t_k, Dict(k => k + 1))
    a_k = t_k_plus_1 - t_k
    
    return AlgebraicNode{typeof(a_k)}(a_k), AlgebraicNode{typeof(t_k)}(t_k), "Gosper_Telescoping"
end

"""
    generate_limit_problem(depth::Int)

Generates an indeterminate limit trap (L'Hopital trap).
"""
function generate_limit_problem(depth::Int)
    @variables x
    
    # Target answer is 1
    target = x^2 + 1
    
    numerator = sin(x)^2 + cos(x)^2 - 1 + target * x^depth
    denominator = x^depth
    
    problem = numerator / denominator
    
    return AlgebraicNode{typeof(problem)}(problem), AlgebraicNode{typeof(target)}(target), "Taylor_Trap"
end

end # module
