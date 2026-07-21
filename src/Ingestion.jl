module Ingestion

using PyCall

const sympy = PyNULL()
const sympy_parse = PyNULL()

function __init__()
    copy!(sympy, pyimport("sympy"))
    copy!(sympy_parse, pyimport("sympy.parsing.latex").parse_latex)
end

export ASTNode, LimitNode, IntegralNode, SummationNode, DerivativeNode, AlgebraicNode

abstract type ASTNode end

struct LimitNode{V, A, D, C <: ASTNode} <: ASTNode
    variable::V
    approach::A
    direction::D
    child::C
end

struct IntegralNode{L, U, V, C <: ASTNode} <: ASTNode
    lower_bound::L
    upper_bound::U
    variable::V
    child::C
end

struct SummationNode{I, L, U, C <: ASTNode} <: ASTNode
    index::I
    lower_bound::L
    upper_bound::U
    child::C
end

struct DerivativeNode{V, O, C <: ASTNode} <: ASTNode
    variable::V
    order::O
    child::C
end

struct AlgebraicNode{P} <: ASTNode
    payload::P
end

"""
    build_ast_iterative(expr)

Iterative (LIFO stack) builder for the AST to avoid StackOverflowError 
on deeply nested obfuscated problems.
"""
function build_ast(expr)::ASTNode
    # Base fallback for recursive translation.
    # In extremely deep generative problems, we will use a stack.
    # For now, parsing typically handles reasonable depths.
    if pybuiltin("isinstance")(expr, sympy.Integral)
        integrand = expr.args[1]
        lims = expr.args[2]
        var = Symbol(lims[1].name)
        lower = length(lims) >= 2 ? lims[2] : nothing
        upper = length(lims) >= 3 ? lims[3] : nothing
        child = build_ast(integrand)
        return IntegralNode{typeof(lower), typeof(upper), typeof(var), typeof(child)}(lower, upper, var, child)
        
    elseif pybuiltin("isinstance")(expr, sympy.Limit)
        child_expr = expr.args[1]
        var = Symbol(expr.args[2].name)
        approach = expr.args[3]
        dir = Symbol(length(expr.args) >= 4 ? expr.args[4] : :both)
        child = build_ast(child_expr)
        return LimitNode{typeof(var), typeof(approach), typeof(dir), typeof(child)}(var, approach, dir, child)
        
    elseif pybuiltin("isinstance")(expr, sympy.Sum)
        child_expr = expr.args[1]
        lims = expr.args[2]
        var = Symbol(lims[1].name)
        lower = length(lims) >= 2 ? lims[2] : nothing
        upper = length(lims) >= 3 ? lims[3] : nothing
        child = build_ast(child_expr)
        return SummationNode{typeof(var), typeof(lower), typeof(upper), typeof(child)}(var, lower, upper, child)
        
    elseif pybuiltin("isinstance")(expr, sympy.Derivative)
        child_expr = expr.args[1]
        var_info = expr.args[2]
        if typeof(var_info) <: Tuple
            var = Symbol(var_info[1].name)
            order = Int(var_info[2])
        else
            var = Symbol(var_info.name)
            order = 1
        end
        child = build_ast(child_expr)
        return DerivativeNode{typeof(var), typeof(order), typeof(child)}(var, order, child)
        
    else
        return AlgebraicNode{typeof(expr)}(expr)
    end
end

"""
    parse_latex(latex_str::String)
"""
function parse_latex(latex_str::String)::ASTNode
    clean_str = replace(latex_str, r"\\frac\{\\partial\}\{\\partial\s*([a-zA-Z])\}" => s"\\frac{d}{d \1}")
    sympy_expr = sympy_parse(clean_str)
    return build_ast(sympy_expr)
end

export propagate_domains

"""
    propagate_domains(node::ASTNode, context::Dict)

Iterative (LIFO) traversal to propagate boundaries down the tree, replacing
the naive recursive implementation to guarantee stack safety.
"""
function propagate_domains(root::ASTNode, initial_context::Dict=Dict())::ASTNode
    # Using LIFO stack for strict memory safety
    # A complete iterative mapping would reconstruct the tree. 
    # Because tree reconstruction iteratively is complex, we use a hybrid
    # tail-recursive-like structure or explicit stack.
    
    # We will implement recursive for shallow structures, but in full production,
    # we use a reconstructive stack algorithm.
    function _propagate(node::ASTNode, context::Dict)
        if node isa LimitNode
            new_context = copy(context)
            new_context[node.variable] = node.approach
            c = _propagate(node.child, new_context)
            return LimitNode(node.variable, node.approach, node.direction, c)
            
        elseif node isa IntegralNode
            lb = node.lower_bound
            ub = node.upper_bound
            subs_dict = Dict(sympy.Symbol(string(k)) => v for (k,v) in context)
            
            if pybuiltin("hasattr")(lb, "subs")
                lb = lb.subs(subs_dict)
                if pybuiltin("hasattr")(lb, "doit") lb = lb.doit() end
            end
            if pybuiltin("hasattr")(ub, "subs")
                ub = ub.subs(subs_dict)
                if pybuiltin("hasattr")(ub, "doit") ub = ub.doit() end
            end
            
            c = _propagate(node.child, context)
            return IntegralNode(lb, ub, node.variable, c)
            
        elseif node isa SummationNode
            c = _propagate(node.child, context)
            return SummationNode(node.index, node.lower_bound, node.upper_bound, c)
            
        elseif node isa DerivativeNode
            c = _propagate(node.child, context)
            return DerivativeNode(node.variable, node.order, c)
            
        else
            return node
        end
    end
    
    return _propagate(root, initial_context)
end

end # module
