using Pkg
Pkg.activate(".")
using ACES
using ACES.GeneratorBase
using ACES.Obfuscation
using ACES.Visualization
using Symbolics

println("=== Testing Generative Matrix ===")
# Generate depth 2 tower
integrand_node, exact_node = generate_liouvillian_extension(2)

println("1. Generated Exact Solution:")
println(exact_node.payload)

println("\n2. Base Generated Integrand (Reverse Risch):")
println(integrand_node.payload)

println("\n3. Applying MBA Obfuscation...")
obfuscated = apply_mba_obfuscation(integrand_node.payload)
println(obfuscated)

println("\n4. Forward Verification with RUBI...")
try
    # Note: RUBI integration can take time. We test it here.
    verified = forward_verify(obfuscated)
    println("Verified Integral: ", verified)
catch e
    println("Verification failed or timed out: ", e)
end

println("\n5. Generating LaTeX Proof Sequence...")
proof = generate_proof([exact_node, AlgebraicNode{Any}(obfuscated)])
println(proof)
