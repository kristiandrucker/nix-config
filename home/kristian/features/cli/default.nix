{
  pkgs,
  ...
}: {
  imports = [
    ./zsh.nix
    ./ssh.nix
  ];

  # Install useful CLI tools
  home.packages = with pkgs; [
    # System utilities
    htop
    btop
    neofetch
    duf
    ncdu
    ripgrep
    fd
    jq
    yq
    fzf
    
    # Network utilities
    curl
    wget
    httpie
    iperf
    dnsutils
    
    # File management
    bat
    eza
    zip
    unzip
    
    # Git utilities
    git-lfs
    lazygit
    
    # DevOps tools
    kubectl
    kubectx
    helmfile
    # terraform
    
    # Helpful utilities
    direnv
    tmux
  ];

  # Enable direnv with nix integration
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Git configuration
  programs.git = {
    enable = true;
    userName = "Kristian"; # Update with your name
    userEmail = "kristian@example.com"; # Update with your email
    
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      rebase.autoStash = true;
      push.autoSetupRemote = true;
    };
    
    ignores = [
      ".direnv"
      ".envrc"
      "result"
      "result-*"
    ];
  };

  # Tmux configuration
  programs.tmux = {
    enable = true;
    clock24 = true;
    keyMode = "vi";
    terminal = "screen-256color";
    historyLimit = 10000;
    
    extraConfig = ''
      # Set prefix to Ctrl-a
      unbind C-b
      set -g prefix C-a
      bind C-a send-prefix
      
      # Enable mouse support
      set -g mouse on
      
      # Start window and pane indices at 1
      set -g base-index 1
      set -g pane-base-index 1
      
      # Status bar styling
      set -g status-style fg=white,bg=black
      set -g window-status-current-style fg=black,bg=white,bold
      
      # Automatically rename windows based on the program within
      setw -g automatic-rename on
      
      # Bind key for reloading config
      bind r source-file ~/.config/tmux/tmux.conf \; display-message "Config reloaded!"
      
      # Split panes using | and -
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      unbind '"'
      unbind %
      
      # Switch panes using Alt-arrow without prefix
      bind -n M-Left select-pane -L
      bind -n M-Right select-pane -R
      bind -n M-Up select-pane -U
      bind -n M-Down select-pane -D
    '';
  };
}