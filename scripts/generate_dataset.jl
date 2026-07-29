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
    args = Dict("category" => "All", "count" => "1080", "output" => "dataset.jsonl")
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

const TECHNIQUES = Dict(
    "Integration" => ["Reverse_Risch", "Parametric_Integration", "Algebraic_Substitution"],
    "Differentiation" => ["Logarithmic_Tower", "Implicit_Chain_Rule", "Quotient_Rule_Cascade"],
    "Summation" => ["Gosper_Telescoping", "Arithmogeometric_Series", "Partial_Fraction_Collapse"],
    "Limit" => ["Taylor_Trap", "LHopital_Tower", "Algebraic_Conjugate"]
)

const DIFFICULTIES = [
    (name="Easy", depth=2, obf_passes=0),
    (name="Medium", depth=4, obf_passes=1),
    (name="Hard", depth=6, obf_passes=2)
]

function generate_category(category, count, io)
    println("Generating ~$count questions for $category...")
    
    techs = TECHNIQUES[category]
    num_buckets = length(techs) * length(DIFFICULTIES)
    
    # We round to ensure perfectly equal buckets
    count_per_bucket = max(1, count ÷ num_buckets)
    actual_total = count_per_bucket * num_buckets
    
    if actual_total != count
        println("  Note: Adjusting count from $count to $actual_total for perfectly equal divisions.")
    end
    
    global_idx = 1
    
    for tech in techs
        for diff in DIFFICULTIES
            for i in 1:count_per_bucket
                problem_node, solution_node, exploit_type = if category == "Integration"
                    generate_integration_problem(diff.depth, tech)
                elseif category == "Differentiation"
                    generate_differentiation_problem(diff.depth, tech)
                elseif category == "Summation"
                    generate_summation_problem(diff.depth, tech)
                elseif category == "Limit"
                    generate_limit_problem(diff.depth, tech)
                end
                
                # Obfuscation Passes tied to difficulty
                obfuscated_payload = equality_expansion(problem_node.payload, passes=diff.obf_passes)
                
                # Extract LaTeX
                prob_tex = ast_to_latex(obfuscated_payload)
                sol_tex = ast_to_latex(solution_node.payload)
                
                record = Dict(
                    "id" => string(uppercase(category[1:3]), "_", lpad(global_idx, 4, '0')),
                    "category" => category,
                    "exploit_type" => exploit_type,
                    "difficulty" => diff.name,
                    "problem_latex" => prob_tex,
                    "solution_latex" => sol_tex,
                    "proof_steps" => ["Generated via $exploit_type with depth $(diff.depth)", "Applied $(diff.obf_passes) MBA equality expansion passes."]
                )
                
                # Write streaming JSONL format
                println(io, JSON.json(record))
                
                if global_idx % 100 == 0
                    println("  ...generated $global_idx / $actual_total")
                end
                
                global_idx += 1
            end
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
