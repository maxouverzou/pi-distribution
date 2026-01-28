# mkScript - Low-level script builder
#
# Creates executable scripts using various backends.
# Returns a derivation with the executable at $out/bin/${name}
{
  lib,
  pkgs,
}:

{
  # Script filename (e.g., "fetch.sh", "process.py")
  name,
  # One of: "python", "shell", "package", "raw", "derivation"
  type,

  # For type = "python"
  source ? null, # String (inline code) or path to .py file
  deps ? (_: [ ]), # Function: pythonPackages -> [ packages ]
  flakeIgnore ? [
    "E501" # line too long
    "E302" # expected 2 blank lines
    "E305" # expected 2 blank lines after class or function definition
    "E402" # module level import not at top of file
    "W503" # line break before binary operator
    "W292" # no newline at end of file
    "F401" # imported but unused (common in scripts that import for side effects)
  ], # Flake8 rules to ignore
  python ? pkgs.python3, # Python interpreter to use

  # For type = "shell"
  # source - same as above
  runtimeInputs ? [ ], # List of packages to include in PATH

  # For type = "package"
  package ? null, # Package derivation
  executable ? null, # Executable name (defaults to meta.mainProgram or pname)

  # For type = "raw"
  # source - required
  isExecutable ? false, # Whether to make the file executable

  # For type = "derivation"
  drv ? null, # Pre-built derivation
  # executable - same as above, defaults to name
}:

let
  # Helper to read source content whether it's a string or path
  sourceContent =
    if builtins.isString source then
      source
    else if builtins.isPath source || lib.isStorePath source then
      builtins.readFile source
    else
      throw "source must be a string or path, got: ${builtins.typeOf source}";

  # Strip .py extension for writePython3Bin (it adds .py back)
  pythonScriptName = lib.removeSuffix ".py" name;

  # Determine executable name for package/derivation types
  getExecutable =
    pkg:
    if executable != null then
      executable
    else if pkg ? meta && pkg.meta ? mainProgram then
      pkg.meta.mainProgram
    else if pkg ? pname then
      pkg.pname
    else
      name;

in
if type == "python" then
  pkgs.writers.writePython3Bin pythonScriptName {
    libraries = deps python.pkgs;
    inherit flakeIgnore;
  } sourceContent

else if type == "shell" then
  pkgs.writeShellApplication {
    inherit name runtimeInputs;
    text = sourceContent;
  }

else if type == "package" then
  let
    execName = getExecutable package;
    execPath = "${package}/bin/${execName}";
  in
  pkgs.runCommand name { } ''
    mkdir -p $out/bin
    ln -s ${execPath} $out/bin/${name}
  ''

else if type == "raw" then
  pkgs.runCommand name { } ''
    mkdir -p $out/bin
    ${
      if builtins.isPath source || lib.isStorePath source then
        ''
          cp ${source} $out/bin/${name}
        ''
      else
        ''
            cat > $out/bin/${name} << 'NIXEOF'
          ${source}
          NIXEOF
        ''
    }
    ${lib.optionalString isExecutable "chmod +x $out/bin/${name}"}
  ''

else if type == "derivation" then
  let
    execName = if executable != null then executable else name;
    execPath = "${drv}/bin/${execName}";
  in
  pkgs.runCommand name { } ''
    mkdir -p $out/bin
    ln -s ${execPath} $out/bin/${name}
  ''

else
  throw "Unknown script type: ${type}. Must be one of: python, shell, package, raw, derivation"
