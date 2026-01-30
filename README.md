# pi-distribution

Home Manager module for [pi-coding-agent](https://shittycodingagent.ai/)

## Features

- **Skills**: Agent skills for specialized tasks (e.g., Conductor workflow management)
- **Extensions**: TypeScript extensions with tool access
- **Prompts**: Reusable prompt templates for common workflows

## Available Packages

### Skills
- `conductor-setup` - Initialize Conductor project structure
- `conductor-implement` - Execute track implementation tasks
- `conductor-new-track` - Create and plan new development tracks
- `conductor-status` - Display project progress
- `conductor-revert` - Revert previous work

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
      pkgs.piSkills.conductor.conductor-setup
      pkgs.piSkills.conductor.conductor-implement
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
# Build a skill
nix build .#conductor-setup

# Build an extension
nix build .#tools

# Build a prompt
nix build .#git-commit
```
