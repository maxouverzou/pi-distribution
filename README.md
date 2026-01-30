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
