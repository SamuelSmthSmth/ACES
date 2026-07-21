using Pkg
Pkg.activate(".")
Pkg.add("PackageCompiler")
using PackageCompiler

println("Starting PackageCompiler Sysimage Build for ACES...")
println("This will bake ACES and all 3,400+ SymbolicIntegration rules into a fast binary.")

# We use test_exhaustive.jl as the precompile execution script. 
# It will run the exhaustive test suite to trace all compiled methods 
# so they are aggressively baked into the sysimage.
create_sysimage(["ACES", "Symbolics", "SymbolicUtils", "SymbolicIntegration", "Latexify"];
    sysimage_path="aces_sysimage.so",
    precompile_execution_file="test_exhaustive.jl",
    # Increase optimization level for the generated binary
    cpu_target="generic;sandybridge,-xsaveopt,clone_all;haswell,-rdrnd,base(1)"
)

println("\nBuild complete! You can now launch Julia with:")
println("  julia -J aces_sysimage.so")
