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
  version = "0.57.1";

  src = fetchurl {
    url = "https://registry.npmjs.org/@mariozechner/pi-coding-agent/-/pi-coding-agent-${version}.tgz";
    hash = "sha256-hkjnHVVTOI7XEPHvQWXZ8JDheD5EZilBDFRYdaxWS28=";
  };

  sourceRoot = "package";

  # Use the package-lock.json we generated
  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-swe+Calzn4MNnv6kJsbIoyiQyb0p2rtF7XS8eZlq9X0=";

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
