println("Locating SymbolicIntegration.jl...")

pkg_path = Base.find_package("SymbolicIntegration")

if pkg_path === nothing
    println("ERROR: SymbolicIntegration is not installed!")
    exit(1)
end

println("Found SymbolicIntegration at: ", pkg_path)

content = read(pkg_path, String)

if occursin("__precompile__(false)", content)
    println("SymbolicIntegration is already patched!")
else
    # Insert __precompile__(false) right after the module declaration
    patched_content = replace(content, "module SymbolicIntegration\n" => "module SymbolicIntegration\n\n__precompile__(false)\n\n")
    
    if patched_content == content
        println("Warning: Could not find exactly 'module SymbolicIntegration\\n' to patch. Trying alternate...")
        patched_content = replace(content, "module SymbolicIntegration" => "module SymbolicIntegration\n__precompile__(false)")
    end
    
    write(pkg_path, patched_content)
    println("Successfully patched SymbolicIntegration to bypass the upstream precompilation crash!")
end
