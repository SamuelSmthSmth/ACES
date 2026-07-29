using JSON

const TECH_WEIGHTS = Dict(
    # Advanced / High (Weight = 3.0)
    "Reverse_Risch" => 3.0,
    "Gosper_Telescoping" => 3.0,
    "Taylor_Trap" => 3.0,
    
    # Medium - High (Weight = 2.0)
    "Parametric_Integration" => 2.0,
    "Logarithmic_Tower" => 2.0,
    "Arithmogeometric_Series" => 2.0,
    "LHopital_Tower" => 2.0,
    
    # Moderate (Weight = 1.0)
    "Algebraic_Substitution" => 1.0,
    "Implicit_Chain_Rule" => 1.0,
    "Quotient_Rule_Cascade" => 1.0,
    "Partial_Fraction_Collapse" => 1.0,
    "Algebraic_Conjugate" => 1.0
)

const TIER_WEIGHTS = Dict(
    "Hard" => 3.0,
    "Medium" => 2.0,
    "Easy" => 1.0
)

function compute_score(item)
    tech_score = get(TECH_WEIGHTS, item["exploit_type"], 1.0)
    tier_score = get(TIER_WEIGHTS, item["difficulty"], 1.0)
    
    # Secondary score based on LaTeX expression complexity (length)
    tex_length = length(get(item, "problem_latex", "")) + length(get(item, "solution_latex", ""))
    
    # Primary sorting key combines technique (weight 100) and tier (weight 30)
    # Secondary sorting key is LaTeX length (weight 0.001)
    score = (tech_score * 100.0) + (tier_score * 30.0) + (tex_length * 0.001)
    return score
end

function rank_dataset(input_path, output_path)
    println("Reading $input_path...")
    records = []
    open(input_path, "r") do io
        for line in eachline(io)
            if !isempty(strip(line))
                push!(records, JSON.parse(line))
            end
        end
    end
    
    println("Read $(length(records)) questions. Computing composite difficulty scores...")
    
    # Pair each record with its score
    scored_records = [(record=r, score=compute_score(r)) for r in records]
    
    # Sort descending by score (Hardest first)
    sort!(scored_records, by = x -> x.score, rev = true)
    
    println("Assigning ranks from 1 (Hardest) to $(length(scored_records)) (Easiest)...")
    
    open(output_path, "w") do io
        for (rank, pair) in enumerate(scored_records)
            r = pair.record
            r["difficulty_rank"] = rank
            println(io, JSON.json(r))
        end
    end
    
    println("Ranking complete! Saved to $output_path")
end

input_file = length(ARGS) >= 1 ? ARGS[1] : "balanced_dataset.jsonl"
output_file = length(ARGS) >= 2 ? ARGS[2] : "ranked_dataset.jsonl"

rank_dataset(input_file, output_file)
