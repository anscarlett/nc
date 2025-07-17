# Personal home configuration for Adrian
inputs: { pkgs, ... }: {
  home = {
    username = "adrian";
    homeDirectory = "/home/adrian";
    stateVersion = (import ../../../lib/constants.nix).nixVersion;
  };

  # Let home-manager manage itself
  programs.home-manager.enable = true;

  # Personal configurations
  programs.git = {
    enable = true;
    userName = "Adrian Scarlett";
    userEmail = "personal@email.com";
  };

  # Zsh configuration
  programs.zsh = {
    enable = true;
    dotDir = ".config/zsh";
    
    history = {
      size = 10000;
      path = "$HOME/.config/zsh/history";
    };
    
    shellAliases = {
      ll = "ls -l";
      la = "ls -la";
      l = "ls -CF";
      ".." = "cd ..";
      "..." = "cd ../..";
      grep = "grep --color=auto";
      fgrep = "fgrep --color=auto";
      egrep = "egrep --color=auto";
      
      # Git aliases
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git log --oneline";
      gd = "git diff";
      
      # System aliases
      reload = "source ~/.config/zsh/.zshrc";
      edit-zsh = "nano ~/.config/zsh/.zshrc";
    };
    
    initContent = ''
      # Set a nice prompt
      autoload -U colors && colors
      setopt PROMPT_SUBST
      
      # Git prompt function
      git_branch() {
        git branch 2>/dev/null | sed -n 's/^\* //p'
      }
      
      git_status() {
        if git rev-parse --git-dir > /dev/null 2>&1; then
          local branch=$(git_branch)
          if [[ -n $branch ]]; then
            local status=""
            if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
              status=" %{$fg[red]%}✗%{$reset_color%}"
            else
              status=" %{$fg[green]%}✓%{$reset_color%}"
            fi
            echo " %{$fg[blue]%}($branch$status%{$fg[blue]%})%{$reset_color%}"
          fi
        fi
      }
      
      # Set the prompt
      PROMPT='%{$fg[green]%}%n@%m%{$reset_color%} %{$fg[blue]%}%~%{$reset_color%}$(git_status) %# '
      
      # Right prompt with time
      RPROMPT='%{$fg[yellow]%}%T%{$reset_color%}'
      
      # Zsh options
      setopt AUTO_CD              # cd by typing directory name if it's not a command
      setopt HIST_VERIFY          # show command with history expansion to user before running it
      setopt SHARE_HISTORY        # share command history data
      setopt EXTENDED_HISTORY     # record timestamp of command in HISTFILE
      setopt HIST_EXPIRE_DUPS_FIRST # delete duplicates first when HISTFILE size exceeds HISTSIZE
      setopt HIST_IGNORE_DUPS     # ignore duplicated commands history list
      setopt HIST_IGNORE_SPACE    # ignore commands that start with space
      setopt HIST_FIND_NO_DUPS    # ignore duplicates when searching
      setopt INC_APPEND_HISTORY   # add commands to HISTFILE in order of execution
      
      # Auto completion
      autoload -U compinit
      compinit
      
      # Case insensitive completion
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
      
      # Menu selection for completion
      zstyle ':completion:*' menu select
      
      # Colors for completion
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
      
      # Welcome message
      echo "Welcome to NixOS VM with Hyprland!"
      echo "Keyboard shortcuts (VM-friendly Alt bindings):"
      echo "  Alt + R: Application launcher"
      echo "  Alt + T: Terminal"
      echo "  Alt + Return: Terminal (alternative)"
      echo "  Alt + E: File manager"
      echo "  Alt + C: Close window"
      echo "  Alt + M: Exit Hyprland"
      echo "  Alt + 1-9: Switch workspaces"
      echo "  Ctrl + Alt + T: Terminal (familiar shortcut)"
      echo "  Ctrl + Alt + Del: Exit Hyprland"
      echo ""
      echo "To setup Hyprland config, run: setup-hypr-config"
      echo "To test key detection, run: test-keys"
      echo ""
      
      # Load custom functions
      if [ -f ~/.config/zsh/functions ]; then
        source ~/.config/zsh/functions
      fi
    '';
  };

  # Additional zsh configuration files
  xdg.configFile."zsh/functions".text = ''
    # Custom zsh functions
    
    # Quick directory navigation
    mkcd() {
      mkdir -p "$1" && cd "$1"
    }
    
    # Extract various archive formats
    extract() {
      if [ -f $1 ] ; then
        case $1 in
          *.tar.bz2)   tar xjf $1     ;;
          *.tar.gz)    tar xzf $1     ;;
          *.bz2)       bunzip2 $1     ;;
          *.rar)       unrar e $1     ;;
          *.gz)        gunzip $1      ;;
          *.tar)       tar xf $1      ;;
          *.tbz2)      tar xjf $1     ;;
          *.tgz)       tar xzf $1     ;;
          *.zip)       unzip $1       ;;
          *.Z)         uncompress $1  ;;
          *.7z)        7z x $1        ;;
          *)     echo "'$1' cannot be extracted via extract()" ;;
        esac
      else
        echo "'$1' is not a valid file"
      fi
    }
    
    # Quick find function
    ff() {
      find . -name "*$1*" 2>/dev/null
    }
    
    # Process search
    psg() {
      ps aux | grep -v grep | grep "$1"
    }
    
    # Quick nix commands
    nix-shell-run() {
      nix-shell -p "$1" --run "$1"
    }
    
    # VM shortcuts
    hypr-reload() {
      setup-hypr-config && echo "Hyprland config reloaded!"
    }
    
    # Show keyboard shortcuts
    shortcuts() {
      echo "Hyprland keyboard shortcuts:"
      echo "  Alt + R: Application launcher"
      echo "  Alt + T: Terminal"
      echo "  Alt + E: File manager"
      echo "  Alt + C: Close window"
      echo "  Alt + M: Exit Hyprland"
      echo "  Alt + 1-9: Switch workspaces"
      echo "  Alt + Shift + 1-9: Move window to workspace"
      echo "  Alt + Arrow keys: Move focus between windows"
      echo "  Ctrl + Alt + T: Terminal (familiar shortcut)"
      echo "  Ctrl + Alt + Del: Exit Hyprland"
    }
  '';
  
  # Source functions in zsh
  # (Already included in programs.zsh.initExtra above)
  
  # Ensure the directory exists
  xdg.configFile."hypr/.keep".text = "";
}
