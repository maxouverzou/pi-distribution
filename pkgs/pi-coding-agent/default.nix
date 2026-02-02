# Pi coding agent - built using buildNpmPackage
#
# Fetches the pre-built package from npm and installs dependencies
{
  lib,
  buildNpmPackage,
  fetchurl,
}:

buildNpmPackage rec {
  pname = "pi-coding-agent";
  version = "0.51.0";

  src = fetchurl {
    url = "https://registry.npmjs.org/@mariozechner/pi-coding-agent/-/pi-coding-agent-${version}.tgz";
    hash = "sha256-XEgxOvOhvzBMq2mVjcgBP3FNmSM0YHpn5ubvUiXdcVY=";
  };

  sourceRoot = "package";

  # Use the package-lock.json we generated
  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-LfPwE7eA1bs7sfsoP7P206SRaKvBtdxRH3S4fw81vmg=";

  # The package is pre-built, no build step needed
  dontNpmBuild = true;

  meta = {
    description = "Coding agent CLI with read, bash, edit, write tools and session management";
    homepage = "https://github.com/badlogic/pi-mono";
    license = lib.licenses.mit;
    maintainers = [ ];
    mainProgram = "pi";
  };
}
