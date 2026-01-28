# Extensions from pi-mono repository
{
  pkgs,
  mkExtension,
  mkExtensionWithDeps,
}:

let
  # Fetch the pi-mono repository
  # Pinned: 2025-01-28
  piMonoSrc = pkgs.fetchFromGitHub {
    owner = "badlogic";
    repo = "pi-mono";
    rev = "df667b510a301f7ad4b7dc42991999601bd24ad3";
    sha256 = "sha256-2upWf769kTm+R3filF9EJVxBfh591IdAIqvkTUbyKqo=";
  };

  extensionsPath = "${piMonoSrc}/packages/coding-agent/examples/extensions";

in
{
  # Tools extension - single file
  tools = mkExtension {
    name = "tools";
    src = "${extensionsPath}/tools.ts";
  };

  # Plan mode extension - directory with index.ts and utils.ts
  plan-mode = mkExtension {
    name = "plan-mode";
    src = "${extensionsPath}/plan-mode";
  };

  # Sandbox extension - OS-level sandboxing for bash commands
  # Requires @anthropic-ai/sandbox-runtime npm package
  sandbox = mkExtensionWithDeps {
    name = "sandbox";
    src = "${extensionsPath}/sandbox";
    npmDepsHash = "sha256-eJbT63DS557JrRE/dLLVITtZIHYsCxlowRJHIkSGKTc=";
  };
}
