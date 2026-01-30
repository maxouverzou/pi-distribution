{ pkgs, mkSkillWithDeps }:

let
  # Pinned to specific commit for reproducibility
  rev = "d0cf5255d51169f99113b65e611bc6449bf0e8ba";
  version = "unstable-2025-01-30";

  piSkillsSrc = pkgs.fetchFromGitHub {
    owner = "badlogic";
    repo = "pi-skills";
    inherit rev;
    sha256 = "sha256-aiWUEK90kQpRdcmME3ldsstvHgfDCpMVNWajgVESg5g=";
  };

in
{
  browser-tools = mkSkillWithDeps {
    src = "${piSkillsSrc}/browser-tools";
    npmDepsHash = "sha256-WxNI44ASObreDyy7myg1yoVJs0uUrR+YBMOlL8E8YI4=";
    inherit version;
    doCheck = true;

    # Puppeteer tries to download Chrome during install, but Nix builds don't have network access
    # The skill will use the system's Chrome/Chromium instead via CDP
    env = {
      PUPPETEER_SKIP_DOWNLOAD = "true";
    };

    # Post-process SKILL.md to fix paths and remove npm install instructions
    postInstall = ''
      # Replace {baseDir} with the actual nix store path
      substituteInPlace $out/SKILL.md \
        --replace-fail '{baseDir}' "$out"

      # Remove the "Setup" section that instructs users to run npm install
      # This removes from "## Setup" through the end of the code block
      sed -i '/^## Setup$/,/^```$/d' $out/SKILL.md
    '';
  };
}
