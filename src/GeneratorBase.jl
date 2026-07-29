module GeneratorBase

using ..Ingestion
using Symbolics
using SymbolicUtils

export generate_integration_problem, generate_differentiation_problem, generate_summation_problem, generate_limit_problem

# --- INTEGRATION GENERATORS ---

function generate_integration_problem(depth::Int, technique::String="Reverse_Risch")
    @variables x
    
    if technique == "Reverse_Risch"
        expr = sin(x) * exp(x)
        for i in 1:depth
            r = rand(1:3)
            if r == 1; expr = log(expr^2 + rand(1:5))
            elseif r == 2; expr = exp(sin(expr))
            else; expr = sqrt(expr^2 + x^2 + rand(1:5))
            end
        end
        integrand = Symbolics.expand_derivatives(Symbolics.derivative(expr, x))
        return AlgebraicNode{typeof(integrand)}(integrand), AlgebraicNode{typeof(expr)}(expr), technique
        
    elseif technique == "Parametric_Integration"
        # Feynman's trick structure: generate parameterized integral
        expr = (exp(x * rand(1:3)) - exp(x * rand(4:6))) / x
        for i in 1:(depth-1)
            expr = expr * sin(x * rand(1:5))
        end
        # Differentiate it to guarantee a solvable integrand
        integrand = Symbolics.expand_derivatives(Symbolics.derivative(expr, x))
        return AlgebraicNode{typeof(integrand)}(integrand), AlgebraicNode{typeof(expr)}(expr), technique
        
    elseif technique == "Algebraic_Substitution"
        # Weierstrass / U-sub trap
        u = x^2 + rand(1:5)
        for i in 1:(depth-1)
            u = u^3 + sin(u)
        end
        expr = sqrt(u)
        integrand = Symbolics.expand_derivatives(Symbolics.derivative(expr, x))
        return AlgebraicNode{typeof(integrand)}(integrand), AlgebraicNode{typeof(expr)}(expr), technique
    end
end

# --- DIFFERENTIATION GENERATORS ---

function generate_differentiation_problem(depth::Int, technique::String="Logarithmic_Tower")
    @variables x
    
    if technique == "Logarithmic_Tower"
        expr = x + rand(1:5)
        for i in 1:depth
            r = rand(1:3)
            if r == 1; expr = expr^(sin(x) + rand(1:3))
            elseif r == 2; expr = exp(expr * x)
            else; expr = log(expr^2 + x^2 + 1)
            end
        end
        derivative = Symbolics.expand_derivatives(Symbolics.derivative(expr, x))
        return AlgebraicNode{typeof(expr)}(expr), AlgebraicNode{typeof(derivative)}(derivative), technique
        
    elseif technique == "Implicit_Chain_Rule"
        # Heavily nested chain rule resembling implicit diff expansion
        expr = sin(cos(exp(x)))
        for i in 1:depth
            expr = sqrt(expr^2 + x^2 + rand(1:5))
        end
        derivative = Symbolics.expand_derivatives(Symbolics.derivative(expr, x))
        return AlgebraicNode{typeof(expr)}(expr), AlgebraicNode{typeof(derivative)}(derivative), technique
        
    elseif technique == "Quotient_Rule_Cascade"
        # Nested fractions forcing catastrophic quotient rule expansion
        expr = x / (x^2 + 1)
        for i in 1:depth
            expr = (expr + sin(x)) / (expr^2 + cos(x) + 2)
        end
        derivative = Symbolics.expand_derivatives(Symbolics.derivative(expr, x))
        return AlgebraicNode{typeof(expr)}(expr), AlgebraicNode{typeof(derivative)}(derivative), technique
    end
end

# --- SUMMATION GENERATORS ---

function generate_summation_problem(depth::Int, technique::String="Gosper_Telescoping")
    @variables k
    
    if technique == "Gosper_Telescoping"
        t_k = 1 / (k^2 + rand(1:5))
        for i in 1:depth
            t_k = t_k + sin(k * rand(1:3)) / (k + rand(1:5))
        end
        t_k_plus_1 = substitute(t_k, Dict(k => k + 1))
        a_k = t_k_plus_1 - t_k
        return AlgebraicNode{typeof(a_k)}(a_k), AlgebraicNode{typeof(t_k)}(t_k), technique
        
    elseif technique == "Arithmogeometric_Series"
        t_k = k * (rand(1:3) / rand(4:7))^k
        for i in 1:(depth-1)
            t_k = t_k + k^2 * (1 / rand(2:5))^k
        end
        t_k_plus_1 = substitute(t_k, Dict(k => k + 1))
        a_k = t_k_plus_1 - t_k
        return AlgebraicNode{typeof(a_k)}(a_k), AlgebraicNode{typeof(t_k)}(t_k), technique
        
    elseif technique == "Partial_Fraction_Collapse"
        # Classic partial fraction telescoping
        t_k = 1 / (k * (k + rand(1:3)))
        for i in 1:(depth-1)
            t_k = t_k + 1 / ((k + rand(1:3)) * (k + rand(4:6)))
        end
        t_k_plus_1 = substitute(t_k, Dict(k => k + 1))
        a_k = t_k_plus_1 - t_k
        return AlgebraicNode{typeof(a_k)}(a_k), AlgebraicNode{typeof(t_k)}(t_k), technique
    end
end

# --- LIMIT GENERATORS ---

function generate_limit_problem(depth::Int, technique::String="Taylor_Trap")
    @variables x
    
    if technique == "Taylor_Trap"
        target = x^2 + 1
        numerator = sin(x)^2 + cos(x)^2 - 1 + target * x^depth
        denominator = x^depth
        problem = numerator / denominator
        return AlgebraicNode{typeof(problem)}(problem), AlgebraicNode{typeof(target)}(target), technique
        
    elseif technique == "LHopital_Tower"
        target = exp(x)
        numerator = exp(x) - 1 - x - (x^2)/2 + target * x^(depth+2)
        denominator = x^(depth+2)
        problem = numerator / denominator
        return AlgebraicNode{typeof(problem)}(problem), AlgebraicNode{typeof(target)}(target), technique
        
    elseif technique == "Algebraic_Conjugate"
        target = sqrt(x^2 + 1)
        numerator = sqrt(x^(2*depth) + 1) - 1 + target * x^(2*depth)
        denominator = x^(2*depth)
        problem = numerator / denominator
        return AlgebraicNode{typeof(problem)}(problem), AlgebraicNode{typeof(target)}(target), technique
    end
end

end # module
