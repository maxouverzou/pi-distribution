# Conductor skills - converted from Gemini CLI extension commands
#
# Source: https://github.com/gemini-cli-extensions/conductor
# These TOML command files are converted to Agent Skills format
{ pkgs, mkSkillFromGeminiCommand }:

let
  # Fetch the conductor repository
  conductorSrc = pkgs.fetchFromGitHub {
    owner = "gemini-cli-extensions";
    repo = "conductor";
    rev = "conductor-v0.2.0";
    sha256 = "sha256-e4jMBtI4OA83VmHAwsmGTqD0hDHzuBPVLRZi4x3ty1w=";
  };

  commandsPath = "${conductorSrc}/commands/conductor";
  templatesPath = "${conductorSrc}/templates";

  # Common metadata for all conductor skills
  commonMetadata = {
    source = "gemini-cli-extensions/conductor";
    original-format = "gemini-cli-command";
  };

  # Path replacement: Gemini CLI extension path -> absolute Nix store path
  # The original commands reference ~/.gemini/extensions/conductor/templates/
  # We replace this with the absolute path so it works regardless of working directory
  templatePathReplacements = {
    "~/.gemini/extensions/conductor/templates/" = "${templatesPath}/";
  };

in
{
  # Setup - scaffolds the project and sets up the Conductor environment
  # Templates are referenced via absolute Nix store paths in the instructions
  conductor-setup = mkSkillFromGeminiCommand {
    name = "conductor-setup";
    src = "${commandsPath}/setup.toml";
    metadata = commonMetadata;
    replacements = templatePathReplacements;
  };

  # Implement - executes the tasks defined in the specified track's plan
  conductor-implement = mkSkillFromGeminiCommand {
    name = "conductor-implement";
    src = "${commandsPath}/implement.toml";
    metadata = commonMetadata;
  };

  # New Track - plans a track and generates track-specific spec documents
  conductor-new-track = mkSkillFromGeminiCommand {
    name = "conductor-new-track";
    src = "${commandsPath}/newTrack.toml";
    metadata = commonMetadata;
  };

  # Status - displays the current progress of the project
  conductor-status = mkSkillFromGeminiCommand {
    name = "conductor-status";
    src = "${commandsPath}/status.toml";
    metadata = commonMetadata;
  };

  # Revert - reverts previous work
  conductor-revert = mkSkillFromGeminiCommand {
    name = "conductor-revert";
    src = "${commandsPath}/revert.toml";
    metadata = commonMetadata;
  };
}
