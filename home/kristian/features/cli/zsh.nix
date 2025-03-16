{
  pkgs,
  config,
  ...
}: {
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    autocd = true;
    dotDir = ".config/zsh";

    history = {
      save = 10000;
      size = 10000;
      path = "${config.xdg.dataHome}/zsh/history";
      ignoreDups = true;
      share = true;
    };

    shellAliases = {
      ls = "ls --color=auto";
      ll = "ls -la";
      ".." = "cd ..";
      "..." = "cd ../..";
      "....." = "cd ../../..";
      cat = "${pkgs.bat}/bin/bat";
      g = "git";
      vim = "nvim";
      vi = "nvim";
    };

    initExtra = ''
      # Completion styling
      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
      
      # Keep 1000 lines of history within the shell and save it to ~/.zsh_history:
      HISTSIZE=1000
      SAVEHIST=1000
      
      # Useful Functions
      mkcd() {
        mkdir -p "$@" && cd "$_";
      }
      
      # FZF integration
      if command -v fzf-share >/dev/null; then
        source "$(fzf-share)/key-bindings.zsh"
        source "$(fzf-share)/completion.zsh"
      fi
    '';

    # Enable oh-my-zsh with plugins
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "terraform"
        "docker"
        "docker-compose"
        "sudo"
        "command-not-found"
      ];
    };
    
    plugins = [
      {
        name = "zsh-nix-shell";
        file = "nix-shell.plugin.zsh";
        src = pkgs.fetchFromGitHub {
          owner = "chisui";
          repo = "zsh-nix-shell";
          rev = "v0.8.0";
          sha256 = "sha256-Z6EYQdasvpl1P78poj9efnnLj7QQg13Me8x1Ryyw+dM=";
        };
      }
    ];
  };

  # Add starship prompt
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    
    settings = {
      add_newline = false;
      
      format = "$all";
      
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[✗](bold red)";
      };
      
      directory = {
        truncation_length = 3;
        truncate_to_repo = true;
      };
      
      git_branch = {
        symbol = "🌱 ";
        truncation_length = 20;
      };
      
      nix_shell = {
        symbol = "❄️ ";
        format = "[$symbol$state]($style) ";
      };
      
      hostname = {
        ssh_only = false;
        format = "[$hostname]($style) ";
        style = "bold green";
      };
      
      username = {
        format = "[$user]($style) at ";
        show_always = true;
      };
    };
  };
  
  # Set some environment variables for ZSH
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    PAGER = "less";
    LESS = "-R";
  };
}