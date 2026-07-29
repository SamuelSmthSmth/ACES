using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

using JSON
using ACES
using ACES.GeneratorBase
using ACES.Obfuscation
using ACES.Visualization

function print_usage()
    println("Usage: julia generate_dataset.jl --category <Integration|Differentiation|Summation|Limit|All> --count <N> --output <dataset.jsonl>")
end

function parse_args()
    args = Dict("category" => "All", "count" => "10", "output" => "dataset.jsonl")
    i = 1
    while i <= length(ARGS)
        if ARGS[i] == "--category" && i+1 <= length(ARGS)
            args["category"] = ARGS[i+1]
            i += 2
        elseif ARGS[i] == "--count" && i+1 <= length(ARGS)
            args["count"] = ARGS[i+1]
            i += 2
        elseif ARGS[i] == "--output" && i+1 <= length(ARGS)
            args["output"] = ARGS[i+1]
            i += 2
        else
            println("Unknown argument: ", ARGS[i])
            print_usage()
            exit(1)
        end
    end
    return args
end

function generate_category(category, count, io)
    println("Generating $count questions for $category...")
    for i in 1:count
        # Depth ranges from 2 to 5 for variety
        depth = rand(2:5)
        
        problem_node, solution_node, exploit_type = if category == "Integration"
            generate_integration_problem(depth)
        elseif category == "Differentiation"
            generate_differentiation_problem(depth)
        elseif category == "Summation"
            generate_summation_problem(depth)
        elseif category == "Limit"
            generate_limit_problem(depth)
        end
        
        # Obfuscation Passes
        obf_passes = rand(0:2)
        obfuscated_payload = equality_expansion(problem_node.payload, passes=obf_passes)
        
        # Extract LaTeX
        prob_tex = ast_to_latex(obfuscated_payload)
        sol_tex = ast_to_latex(solution_node.payload)
        
        record = Dict(
            "id" => string(uppercase(category[1:3]), "_", lpad(i, 4, '0')),
            "category" => category,
            "exploit_type" => exploit_type,
            "difficulty" => (obf_passes == 0 ? "Easy" : (obf_passes == 1 ? "Medium" : "Hard")),
            "problem_latex" => prob_tex,
            "solution_latex" => sol_tex,
            "proof_steps" => ["Generated via $exploit_type with depth $depth", "Applied $obf_passes MBA equality expansion passes."]
        )
        
        # Write streaming JSONL format
        println(io, JSON.json(record))
        if i % 100 == 0
            println("  ...generated $i / $count")
        end
    end
end

function main()
    args = parse_args()
    
    count = parse(Int, args["count"])
    out_file = args["output"]
    categories = args["category"] == "All" ? ["Integration", "Differentiation", "Summation", "Limit"] : [args["category"]]
    
    open(out_file, "w") do io
        for cat in categories
            generate_category(cat, count, io)
        end
    end
    
    println("\nDataset generation complete! Saved to $out_file")
end

main()
