{
  lib,
  python3Packages,
  fetchFromGitHub,
}:

python3Packages.buildPythonApplication rec {
  pname = "skills-ref";
  version = "0.1.0";
  pyproject = true;

  # Pinned: 2025-01-28
  src = fetchFromGitHub {
    owner = "agentskills";
    repo = "agentskills";
    rev = "c9e5df0a28386e0797f46cbf8d147ce612d94f65";
    hash = "sha256-PHOAIeLUlmZCnDO9PXtKioUa4JD64TwAbdwOSMV3bwI=";
  };

  sourceRoot = "${src.name}/skills-ref";

  build-system = [ python3Packages.hatchling ];

  dependencies = with python3Packages; [
    click
    strictyaml
  ];

  # No tests in the package
  doCheck = false;

  meta = {
    description = "Reference library for Agent Skills";
    homepage = "https://github.com/agentskills/agentskills";
    license = lib.licenses.asl20;
    maintainers = [ ];
    mainProgram = "skills-ref";
  };
}
