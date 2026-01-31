# pi-distribution

Home Manager module for [pi-coding-agent](https://shittycodingagent.ai/)

## Features

- **Skills**: Agent skills for specialized tasks (e.g., Conductor workflow management)
- **Extensions**: TypeScript extensions with tool access
- **Prompts**: Reusable prompt templates for common workflows

## Available Packages

### Skills

#### Conductor (Project Management)
- `conductor-setup` - Initialize Conductor project structure
- `conductor-implement` - Execute track implementation tasks
- `conductor-new-track` - Create and plan new development tracks
- `conductor-status` - Display project progress
- `conductor-revert` - Revert previous work

#### Browser Automation
- `browser-tools` - Interactive browser automation via Chrome DevTools Protocol

### Extensions
- `tools` - Additional tool integrations
- `plan-mode` - Planning and task management
- `sandbox` - Safe execution environment

### Prompts
- `git-commit` - Create intelligent conventional commits based on conversation context

## Usage with Home Manager

```nix
{
  programs.pi = {
    enable = true;

    skills = [
      # Conductor project management
      pkgs.piSkills.conductor.conductor-setup
      pkgs.piSkills.conductor.conductor-implement

      # Browser automation
      pkgs.piSkills.browser.browser-tools
    ];

    extensions = [
      pkgs.piExtensions.tools
      pkgs.piExtensions.plan-mode
    ];

    prompts = [
      pkgs.piPrompts.git-commit
    ];
  };
}
```

## Usage in a project flake

For a workspace that already defines a flake, `mkPiEnv` builds the entire
`.pi/agent/` tree as a single derivation. Symlink it into your working directory
instead of managing each entry by hand.

Add pi-distribution as a flake input and pull in the overlay:

```nix
{
  inputs.pi-distribution.url = "github:maxouverzou/pi-distribution";

  outputs = { self, nixpkgs, pi-distribution, ... }:
  let
    pkgs = import nixpkgs {
      system = "x86_64-linux";
      overlays = [ pi-distribution.overlays.default ];
    };
  in {
    # Expose the assembled env as a package so `nix build .#piEnv` works
    packages.x86_64-linux.piEnv = pkgs.mkPiEnv {
      skills = [
        pkgs.piSkills.conductor.conductor-setup
        pkgs.piSkills.browser.browser-tools
      ];
      prompts = [
        pkgs.piPrompts.git-commit
      ];
      extensions = [
        pkgs.piExtensions.tools
        pkgs.piExtensions.plan-mode
      ];

      # Optional: manage settings.json through Nix.
      # Omit (or set to null) to edit it manually.
      settings = {
        defaultProvider = "anthropic";
        defaultModel   = "claude-sonnet-4-20250514";
      };
    };

    devShells.x86_64-linux.default = pkgs.mkShellNoCC {
      # Creates .pi/agent/ as a real directory and symlinks each
      # top-level entry from the store into it.  When settings is null,
      # settings.json is absent from the store and can be managed manually.
      shellHook = ''
        mkdir -p .pi/agent
        for entry in ${self.packages.x86_64-linux.piEnv}/*; do
          ln -sf "$entry" .pi/agent/
        done
      '';
    };
  };
}
```

Add `.pi/agent` to `.gitignore` — it contains symlinks into the Nix store.
When `settings` is null and you manage `settings.json` manually, use a glob
rather than the directory so that git can re-include it:

```gitignore
.pi/agent/*
!.pi/agent/settings.json
```

## Building Packages

```bash
# Build skills
nix build .#conductor-setup
nix build .#browser-tools

# Build an extension
nix build .#tools

# Build a prompt
nix build .#git-commit
```

## Builders

This distribution provides several builders for creating pi-compatible packages:

- `mkSkill` - Build Agent Skills from Nix expressions
- `mkSkillFromGeminiCommand` - Convert Gemini CLI commands to Agent Skills
- `mkSkillWithDeps` - Build Agent Skills with npm dependencies (for skills like browser-tools)
- `mkPromptTemplate` - Create prompt templates
- `mkExtension` - Build TypeScript extensions
- `mkExtensionWithDeps` - Build extensions with npm dependencies
- `mkPiEnv` - Assemble a complete `.pi/agent/` directory from skills, prompts, extensions, and settings
