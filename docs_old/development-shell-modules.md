# modules/home-manager/development/default.nix

```nix
{ config, lib, ... }:
{
  imports = [
    ./languages
    ./tools
  ];
  
  options.myHome.development = {
    enable = lib.mkEnableOption "development environment";
  };
}
```

# modules/home-manager/development/languages/default.nix

```nix
{
  imports = [
    ./python
    ./rust
    ./javascript
  ];
}
```

# modules/home-manager/development/languages/python/default.nix

```nix
{ config, lib, pkgs, ... }:
{
  imports = [
    ./packages.nix
    ./tools.nix
  ];
  
  options.myHome.development.python = {
    enable = lib.mkEnableOption "Python development environment";
    
    version = lib.mkOption {
      type = lib.types.enum [ "python39" "python310" "python311" "python312" ];
      default = "python311";
      description = "Python version to use";
    };
    
    packages = {
      enable = lib.mkEnableOption "common Python packages" // { default = true; };
      
      extraPackages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [];
        description = "Additional Python packages to install";
      };
    };
    
    tools.enable = lib.mkEnableOption "Python development tools" // { default = true; };
    
    virtualenvs = {
      enable = lib.mkEnableOption "virtual environment support" // { default = true; };
      
      defaultPackages = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "pip" "setuptools" "wheel" ];
        description = "Packages to install in new virtual environments";
      };
    };
  };
  
  config = lib.mkIf config.myHome.development.python.enable {
    home.packages = with pkgs; [
      # Python interpreter
      (builtins.getAttr config.myHome.development.python.version pkgs)
      
      # Virtual environment tools
    ] ++ lib.optionals config.myHome.development.python.virtualenvs.enable [
      python3Packages.virtualenv
      python3Packages.pipenv
      poetry
    ];
    
    # Python environment variables
    home.sessionVariables = {
      PYTHONPATH = "$HOME/.local/lib/python${lib.substring 6 9 config.myHome.development.python.version}/site-packages:$PYTHONPATH";
      PIP_USER = "1";
      PYTHONDONTWRITEBYTECODE = "1";
      PYTHONUNBUFFERED = "1";
    };
    
    # Python shell aliases
    home.shellAliases = {
      py = "python3";
      pip = "python3 -m pip";
      venv = "python3 -m venv";
      activate = "source venv/bin/activate";
    };
  };
}
```

# modules/home-manager/development/languages/python/packages.nix

```nix
{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.myHome.development.python.packages.enable {
    home.packages = with pkgs.python3Packages; [
      # Core packages
      pip
      setuptools
      wheel
      virtualenv
      
      # Development tools
      black
      isort
      flake8
      pylint
      mypy
      autopep8
      
      # Testing
      pytest
      pytest-cov
      pytest-mock
      tox
      
      # Documentation
      sphinx
      mkdocs
      
      # Jupyter
      jupyter
      jupyterlab
      ipython
      
      # Data science (optional)
      numpy
      pandas
      matplotlib
      seaborn
      scipy
      scikit-learn
      
      # Web development
      requests
      flask
      fastapi
      django
      
      # Database
      sqlalchemy
      psycopg2
      
      # Utilities
      click
      pyyaml
      python-dotenv
      rich
      typer
    ] ++ config.myHome.development.python.packages.extraPackages;
  };
}
```

# modules/home-manager/development/languages/python/tools.nix

```nix
{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.myHome.development.python.tools.enable {
    home.packages = with pkgs; [
      # Python version management
      pyenv
      
      # Package management
      poetry
      pipenv
      
      # Code formatting and linting
      ruff  # Fast Python linter
      
      # Type checking
      pyright
      
      # Debugging
      python3Packages.pdb-clone
      python3Packages.ipdb
      
      # Performance profiling
      python3Packages.line-profiler
      python3Packages.memory-profiler
      
      # Documentation
      python3Packages.sphinx
      python3Packages.sphinx-rtd-theme
      
      # Notebook tools
      python3Packages.nbconvert
      python3Packages.nbformat
    ];
    
    # Configure development tools
    home.file = {
      # Flake8 configuration
      ".config/flake8".text = ''
        [flake8]
        max-line-length = 88
        extend-ignore = E203, W503, E501
        exclude = .git,__pycache__,docs/source/conf.py,old,build,dist
        max-complexity = 10
      '';
      
      # Black configuration
      ".config/black".text = ''
        [tool.black]
        line-length = 88
        target-version = ['py311']
        include = '\.pyi?$'
        skip-string-normalization = true
      '';
      
      # isort configuration
      ".config/isort.cfg".text = ''
        [settings]
        profile = black
        multi_line_output = 3
        line_length = 88
        known_first_party = myproject
        skip = migrations
      '';
      
      # Pylint configuration
      ".config/pylintrc".text = ''
        [MASTER]
        load-plugins = pylint.extensions.docparams
        
        [MESSAGES CONTROL]
        disable = missing-docstring,
                  invalid-name,
                  too-few-public-methods,
                  too-many-arguments,
                  too-many-locals,
                  too-many-branches,
                  too-many-statements
        
        [FORMAT]
        max-line-length = 88
      '';
    };
  };
}
```

# modules/home-manager/development/languages/rust/default.nix

```nix
{ config, lib, pkgs, ... }:
{
  imports = [
    ./cargo.nix
    ./tools.nix
  ];
  
  options.myHome.development.rust = {
    enable = lib.mkEnableOption "Rust development environment";
    
    channel = lib.mkOption {
      type = lib.types.enum [ "stable" "beta" "nightly" ];
      default = "stable";
      description = "Rust toolchain channel";
    };
    
    targets = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Additional Rust targets to install";
    };
    
    components = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "rustfmt" "clippy" "rust-src" ];
      description = "Rust components to install";
    };
    
    cargo.enable = lib.mkEnableOption "Cargo configuration" // { default = true; };
    tools.enable = lib.mkEnableOption "Rust development tools" // { default = true; };
  };
  
  config = lib.mkIf config.myHome.development.rust.enable {
    home.packages = with pkgs; [
      # Rust toolchain
      rustc
      cargo
      rustfmt
      clippy
      rust-analyzer
      
      # Build tools
      pkg-config
      openssl
      
      # Additional tools based on channel
    ] ++ lib.optionals (config.myHome.development.rust.channel == "nightly") [
      pkgs.rust-bin.nightly.latest.default
    ];
    
    # Rust environment variables
    home.sessionVariables = {
      RUST_BACKTRACE = "1";
      CARGO_HOME = "$HOME/.cargo";
      RUSTUP_HOME = "$HOME/.rustup";
    };
    
    # Add cargo bin to PATH
    home.sessionPath = [
      "$HOME/.cargo/bin"
    ];
    
    # Rust shell aliases
    home.shellAliases = {
      c = "cargo";
      cb = "cargo build";
      cr = "cargo run";
      ct = "cargo test";
      cc = "cargo check";
      cf = "cargo fmt";
      ccl = "cargo clippy";
      cu = "cargo update";
      cn = "cargo new";
      ci = "cargo install";
    };
  };
}
```

# modules/home-manager/development/languages/rust/cargo.nix

```nix
{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.myHome.development.rust.cargo.enable {
    # Cargo configuration
    home.file.".cargo/config.toml".text = ''
      [build]
      # Use all available CPU cores for compilation
      jobs = ${toString (pkgs.lib.max 1 (pkgs.lib.div pkgs.stdenv.hostPlatform.parsed.cpu.bits 2))}
      
      [cargo-new]
      # Default template for new projects
      vcs = "git"
      
      [registries.crates-io]
      protocol = "sparse"
      
      [profile.dev]
      # Faster compilation for development
      opt-level = 0
      debug = true
      debug-assertions = true
      overflow-checks = true
      lto = false
      panic = 'unwind'
      incremental = true
      codegen-units = 256
      rpath = false
      
      [profile.release]
      # Optimized for production
      opt-level = 3
      debug = false
      debug-assertions = false
      overflow-checks = false
      lto = true
      panic = 'abort'
      incremental = false
      codegen-units = 1
      rpath = false
      
      [target.x86_64-unknown-linux-gnu]
      linker = "${pkgs.clang}/bin/clang"
      rustflags = ["-C", "link-arg=-fuse-ld=${pkgs.mold}/bin/mold"]
      
      [net]
      retry = 2
      git-fetch-with-cli = true
      
      [term]
      color = 'auto'
      
      [alias]
      # Useful cargo aliases
      b = "build"
      c = "check"
      t = "test"
      r = "run"
      br = "run --bin"
      ex = "run --example"
      rr = "run --release"
      tr = "test --release"
      br = "build --release"
      wr = "watch -x run"
      wt = "watch -x test"
      wb = "watch -x build"
      
      # Clippy with common flags
      cl = "clippy -- -D warnings"
      
      # Clean and build
      cb = ["clean", "build"]
      
      # Install with locked dependencies  
      il = "install --locked"
    '';
  };
}
```

# modules/home-manager/development/languages/rust/tools.nix

```nix
{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.myHome.development.rust.tools.enable {
    home.packages = with pkgs; [
      # Core Rust tools
      rust-analyzer
      rustfmt
      clippy
      
      # Cargo extensions
      cargo-edit          # cargo add, cargo rm, cargo upgrade
      cargo-watch         # cargo watch
      cargo-expand        # cargo expand (show macro expansions)
      cargo-outdated      # cargo outdated
      cargo-audit         # cargo audit (security vulnerabilities)
      cargo-tree          # cargo tree (dependency tree)
      cargo-bloat         # cargo bloat (find what takes space)
      cargo-udeps         # cargo +nightly udeps (unused dependencies)
      cargo-deny          # cargo deny (license/security checks)
      cargo-flamegraph    # cargo flamegraph (profiling)
      cargo-nextest       # cargo nextest (better test runner)
      
      # Development tools
      bacon               # Background code checker
      mold                # Fast linker
      sccache             # Compilation cache
      
      # Cross-compilation
      cross               # Cross-compilation tool
      
      # Documentation
      mdbook              # Rust documentation book generator
      
      # Web assembly
      wasm-pack           # WebAssembly package builder
      wasmtime            # WebAssembly runtime
      
      # Benchmarking
      hyperfine           # Command-line benchmarking tool
      
      # Database tools (Rust-based)
      diesel-cli          # Diesel ORM CLI
      sqlx-cli           # SQLx CLI
    ];
    
    # Rust development configuration files
    home.file = {
      # Rustfmt configuration
      ".rustfmt.toml".text = ''
        edition = "2021"
        max_width = 100
        hard_tabs = false
        tab_spaces = 4
        newline_style = "Unix"
        use_small_heuristics = "Default"
        reorder_imports = true
        reorder_modules = true
        remove_nested_parens = true
        merge_derives = true
        use_try_shorthand = false
        use_field_init_shorthand = false
        force_explicit_abi = true
        empty_item_single_line = true
        struct_lit_single_line = true
        fn_single_line = false
        where_single_line = false
        imports_layout = "Mixed"
        merge_imports = false
        group_imports = "StdExternalCrate"
      '';
      
      # Clippy configuration
      ".clippy.toml".text = ''
        # Clippy configuration
        cognitive-complexity-threshold = 30
        type-complexity-threshold = 60
        too-many-arguments-threshold = 7
        too-many-lines-threshold = 100
        large-type-threshold = 200
        trivial-copy-size-limit = 128
        pass-by-value-size-limit = 256
        too-many-arguments-threshold = 7
        type-complexity-threshold = 250
        single-char-binding-names-threshold = 4
        literal-representation-threshold = 10
      '';
    };
  };
}
```

# modules/home-manager/development/languages/javascript/default.nix

```nix
{ config, lib, pkgs, ... }:
{
  imports = [
    ./node.nix
    ./frameworks.nix
  ];
  
  options.myHome.development.javascript = {
    enable = lib.mkEnableOption "JavaScript/TypeScript development environment";
    
    runtime = lib.mkOption {
      type = lib.types.enum [ "nodejs" "bun" "deno" ];
      default = "nodejs";
      description = "JavaScript runtime to use";
    };
    
    packageManager = lib.mkOption {
      type = lib.types.enum [ "npm" "yarn" "pnpm" ];
      default = "npm";
      description = "Package manager to use";
    };
    
    typescript.enable = lib.mkEnableOption "TypeScript support" // { default = true; };
    frameworks.enable = lib.mkEnableOption "JavaScript frameworks" // { default = true; };
  };
  
  config = lib.mkIf config.myHome.development.javascript.enable {
    home.packages = with pkgs; [
      # JavaScript runtime
      nodejs
      
      # Package managers
    ] ++ lib.optionals (config.myHome.development.javascript.packageManager == "yarn") [
      yarn
    ] ++ lib.optionals (config.myHome.development.javascript.packageManager == "pnpm") [
      nodePackages.pnpm
    ] ++ lib.optionals config.myHome.development.javascript.typescript.enable [
      # TypeScript
      typescript
      nodePackages.ts-node
      nodePackages.tsx
    ] ++ [
      # Development tools
      nodePackages.eslint
      nodePackages.prettier
      nodePackages.nodemon
      nodePackages.live-server
      
      # Build tools
      nodePackages.webpack
      nodePackages.webpack-cli
      nodePackages.vite
      
      # Testing
      nodePackages.jest
      nodePackages.mocha
      nodePackages.cypress
    ];
    
    # Node.js environment variables
    home.sessionVariables = {
      NODE_ENV = "development";
      NPM_CONFIG_PREFIX = "$HOME/.npm-global";
    };
    
    # Add npm global bin to PATH
    home.sessionPath = [
      "$HOME/.npm-global/bin"
      "$HOME/node_modules/.bin"
    ];
    
    # JavaScript aliases
    home.shellAliases = {
      # Node.js
      node = "node";
      npm = "npm";
      npx = "npx";
      
      # Package management shortcuts
      ni = "npm install";
      nid = "npm install --save-dev";
      nig = "npm install --global";
      nr = "npm run";
      ns = "npm start";
      nt = "npm test";
      nb = "npm run build";
      nd = "npm run dev";
      
      # TypeScript
      tsc = "npx tsc";
      tsn = "npx ts-node";
      
      # Development servers
      serve = "npx live-server";
      
      # Linting and formatting
      lint = "npx eslint";
      format = "npx prettier --write";
    } // lib.optionalAttrs (config.myHome.development.javascript.packageManager == "yarn") {
      # Yarn shortcuts
      yi = "yarn install";
      ya = "yarn add";
      yad = "yarn add --dev";
      yr = "yarn run";
      ys = "yarn start";
      yt = "yarn test";
      yb = "yarn build";
      yd = "yarn dev";
    } // lib.optionalAttrs (config.myHome.development.javascript.packageManager == "pnpm") {
      # pnpm shortcuts
      pi = "pnpm install";
      pa = "pnpm add";
      pad = "pnpm add --save-dev";
      pr = "pnpm run";
      ps = "pnpm start";
      pt = "pnpm test";
      pb = "pnpm build";
      pd = "pnpm dev";
    };
  };
}
```

# modules/home-manager/development/tools/default.nix

```nix
{
  imports = [
    ./git
    ./docker
  ];
}
```

# modules/home-manager/development/tools/git/default.nix

```nix
{ config, lib, pkgs, ... }:
{
  imports = [
    ./aliases.nix
    ./hooks.nix
  ];
  
  options.myHome.development.git = {
    enable = lib.mkEnableOption "Git configuration";
    
    user = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Git user name";
      };
      
      email = lib.mkOption {
        type = lib.types.str;
        description = "Git user email";
      };
      
      signingKey = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "GPG signing key ID";
      };
    };
    
    aliases.enable = lib.mkEnableOption "Git aliases" // { default = true; };
    hooks.enable = lib.mkEnableOption "Git hooks" // { default = true; };
    
    extraConfig = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Additional Git configuration";
    };
  };
  
  config = lib.mkIf config.myHome.development.git.enable {
    programs.git = {
      enable = true;
      
      userName = config.myHome.development.git.user.name;
      userEmail = config.myHome.development.git.user.email;
      
      # GPG signing
      signing = lib.mkIf (config.myHome.development.git.user.signingKey != null) {
        key = config.myHome.development.git.user.signingKey;
        signByDefault = true;
      };
      
      # Core configuration
      extraConfig = {
        init.defaultBranch = "main";
        
        # Core settings
        core = {
          editor = "vim";
          autocrlf = "input";
          safecrlf = true;
          filemode = true;
          precomposeunicode = true;
        };
        
        # Push/Pull behavior
        push = {
          default = "simple";
          autoSetupRemote = true;
        };
        pull = {
          rebase = false;
          ff = "only";
        };
        
        # Merge settings
        merge = {
          tool = "vimdiff";
          conflictstyle = "diff3";
        };
        
        # Rebase settings
        rebase = {
          autoStash = true;
          autoSquash = true;
        };
        
        # Diff settings
        diff = {
          colorMoved = "default";
          algorithm = "patience";
        };
        
        # Status settings
        status = {
          showUntrackedFiles = "all";
          submoduleSummary = true;
        };
        
        # Color settings
        color = {
          ui = "auto";
          branch = "auto";
          diff = "auto";
          status = "auto";
        };
        
        # URL rewrites for HTTPS
        url = {
          "https://github.com/".insteadOf = "git@github.com:";
          "https://gitlab.com/".insteadOf = "git@gitlab.com:";
        };
        
        # Security
        transfer.fsckObjects = true;
        receive.fsckObjects = true;
        fetch.fsckObjects = true;
        
        # Performance
        feature.manyFiles = true;
        index.threads = true;
        
        # Submodules
        submodule.recurse = true;
        
        # Maintenance
        maintenance.auto = false;
        gc.auto = 0;
      } // config.myHome.development.git.extraConfig;
    };
    
    # Git-related tools
    home.packages = with pkgs; [
      # Git utilities
      git-crypt
      git-lfs
      git-filter-repo
      git-absorb
      git-branchless
      
      # GitHub CLI
      gh
      
      # GitLab CLI
      glab
      
      # Git UI tools
      gitui
      lazygit
      tig
      
      # Diff tools
      delta
      difftastic
      
      # Git statistics
      git-quick-stats
      onefetch
    ];
    
    # Configure delta as the default pager
    programs.git.extraConfig.core.pager = "${pkgs.delta}/bin/delta";
    programs.git.extraConfig.interactive.diffFilter = "${pkgs.delta}/bin/delta --color-only";
    programs.git.extraConfig.delta = {
      navigate = true;
      light = false;
      line-numbers = true;
      side-by-side = false;
      syntax-theme = "Dracula";
    };
  };
}
```

# modules/home-manager/development/tools/git/aliases.nix

```nix
{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.myHome.development.git.aliases.enable {
    programs.git.aliases = {
      # Basic shortcuts
      a = "add";
      aa = "add --all";
      ap = "add --patch";
      b = "branch";
      ba = "branch --all";
      bd = "branch --delete";
      c = "commit";
      ca = "commit --amend";
      cm = "commit --message";
      co = "checkout";
      cob = "checkout -b";
      d = "diff";
      dc = "diff --cached";
      f = "fetch";
      fa = "fetch --all";
      m = "merge";
      p = "push";
      pf = "push --force-with-lease";
      pl = "pull";
      r = "rebase";
      ri = "rebase --interactive";
      s = "status";
      ss = "status --short";
      
      # Log aliases
      l = "log --oneline";
      lg = "log --graph --oneline --decorate --all";
      ll = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
      lol = "log --graph --decorate --pretty=oneline --abbrev-commit";
      lola = "log --graph --decorate --pretty=oneline --abbrev-commit --all";
      
      # Stash shortcuts
      sl = "stash list";
      sa = "stash apply";
      ss = "stash save";
      sp = "stash pop";
      sd = "stash drop";
      
      # Remote shortcuts
      rv = "remote -v";
      ra = "remote add";
      rr = "remote remove";
      
      # Reset shortcuts
      unstage = "reset HEAD --";
      discard = "checkout --";
      uncommit = "reset --soft HEAD~1";
      
      # Advanced workflows
      wip = "commit -am 'WIP'";
      unwip = "reset HEAD~1";
      assume = "update-index --assume-unchanged";
      unassume = "update-index --no-assume-unchanged";
      assumed = "!git ls-files -v | grep ^h | cut -c 3-";
      
      # Find and cleanup
      find-merge = "!sh -c 'commit=$0 && branch=${1:-HEAD} && (git rev-list $commit..$branch --ancestry-path | cat -n; git rev-list $commit..$branch --first-parent | cat -n) | sort -k2 -s | uniq -f1 -d | sort -n | tail -1 | cut -f2'";
      show-merge = "!sh -c 'merge=$(git find-merge $0 $1) && [ -n \"$merge\" ] && git show $merge'";
      cleanup = "!git branch --merged | grep -v '\\*\\|main\\|master\\|develop' | xargs -n 1 git branch -d";
      
      # Undo shortcuts
      undo = "reset HEAD~1 --mixed";
      redo = "reset 'HEAD@{1}'";
      
      # Show what changed
      what = "show --name-only";
      who = "shortlog -s --";
      
      # Aliases for common typos
      ad = "add";
      stats = "diff --stat";
      pom = "push origin main";
      recent = "branch --sort=-committerdate";
    };
  };
}
```

# modules/home-manager/shell/default.nix

```nix
{
  imports = [
    ./zsh
    ./bash
    ./fish
  ];
  
  options.myHome.shell = {
    enable = lib.mkEnableOption "shell configuration";
    
    default = lib.mkOption {
      type = lib.types.enum [ "zsh" "bash" "fish" ];
      default = "zsh";
      description = "Default shell to use";
    };
  };
  
  config = lib.mkIf config.myHome.shell.enable {
    # Auto-enable the default shell
    myHome.shell.zsh.enable = lib.mkIf (config.myHome.shell.default == "zsh") true;
    myHome.shell.bash.enable = lib.mkIf (config.myHome.shell.default == "bash") true;
    myHome.shell.fish.enable = lib.mkIf (config.myHome.shell.default == "fish") true;
  };
}
```

# modules/home-manager/shell/zsh/default.nix

```nix
{ config, lib, pkgs, ... }:
{
  imports = [
    ./oh-my-zsh.nix
    ./plugins.nix
    ./aliases.nix
  ];
  
  options.myHome.shell.zsh = {
    enable = lib.mkEnableOption "Zsh shell";
    
    ohMyZsh.enable = lib.mkEnableOption "Oh My Zsh" // { default = true; };
    plugins.enable = lib.mkEnableOption "Zsh plugins" // { default = true; };
    aliases.enable = lib.mkEnableOption "shell aliases" // { default = true; };
    
    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Additional Zsh configuration";
    };
    
    history = {
      size = lib.mkOption {
        type = lib.types.int;
        default = 10000;
        description = "History size";
      };
      
      save = lib.mkOption {
        type = lib.types.int;
        default = 10000;
        description = "Number of history entries to save";
      };
      
      share = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Share history between sessions";
      };
    };
  };
  
  config = lib.mkIf config.myHome.shell.zsh.enable {
    programs.zsh = {
      enable = true;
      
      # History configuration
      history = {
        size = config.myHome.shell.zsh.history.size;
        save = config.myHome.shell.zsh.history.save;
        share = config.myHome.shell.zsh.history.share;
        extended = true;
        ignoreDups = true;
        ignoreSpace = true;
      };
      
      # Auto-completion
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      
      # Environment variables
      sessionVariables = {
        EDITOR = "vim";
        BROWSER = "firefox";
        TERM = "xterm-256color";
      };
      
      # Shell options
      initExtra = ''
        # Zsh options
        setopt AUTO_CD              # Change directory without cd command
        setopt AUTO_PUSHD           # Push directories to stack automatically
        setopt PUSHD_IGNORE_DUPS    # Don't duplicate directories in stack
        setopt GLOB_DOTS            # Include dotfiles in globbing
        setopt EXTENDED_GLOB        # Enable extended globbing
        setopt NOMATCH              # Print error if glob doesn't match
        setopt NOTIFY               # Report job status immediately
        setopt HASH_LIST_ALL        # Hash entire command path first
        setopt COMPLETEINWORD       # Complete from both ends of word
        setopt NOHUP                # Don't kill jobs on shell exit
        setopt AUTO_MENU            # Show completion menu on tab
        setopt COMPLETE_IN_WORD     # Complete from cursor position
        setopt NO_MENU_COMPLETE     # Don't autoselect first completion
        setopt FLOW_CONTROL         # Enable flow control
        setopt INTERACTIVE_COMMENTS # Allow comments in interactive shell
        
        # Key bindings
        bindkey '^[[A' history-substring-search-up
        bindkey '^[[B' history-substring-search-down
        bindkey '^[[1;5C' forward-word
        bindkey '^[[1;5D' backward-word
        bindkey '^[[3~' delete-char
        bindkey '^[[H' beginning-of-line
        bindkey '^[[F' end-of-line
        
        # Custom functions
        function mkcd() {
          mkdir -p "$1" && cd "$1"
        }
        
        function extract() {
          if [ -f $1 ] ; then
            case $1 in
              *.tar.bz2)   tar xjf $1     ;;
              *.tar.gz)    tar xzf $1     ;;
              *.bz2)       bunzip2 $1     ;;
              *.rar)       unrar x $1     ;;
              *.gz)        gunzip $1      ;;
              *.tar)       tar xf $1      ;;
              *.tbz2)      tar xjf $1     ;;
              *.tgz)       tar xzf $1     ;;
              *.zip)       unzip $1       ;;
              *.Z)         uncompress $1  ;;
              *.7z)        7z x $1        ;;
              *)           echo "'$1' cannot be extracted via extract()" ;;
            esac
          else
            echo "'$1' is not a valid file"
          fi
        }
        
        # Additional configuration
        ${config.myHome.shell.zsh.extraConfig}
      '';
    };
    
    # Shell utilities
    home.packages = with pkgs; [
      # Modern CLI tools
      exa          # Better ls
      bat          # Better cat
      fd           # Better find
      ripgrep      # Better grep
      fzf          # Fuzzy finder
      zoxide       # Better cd
      direnv       # Environment management
      
      # System monitoring
      htop
      btop
      neofetch
      
      # Network tools
      curl
      wget
      httpie
      
      # Archive tools
      unzip
      p7zip
      
      # JSON/YAML tools
      jq
      yq
    ];
    
    # Configure modern CLI tools
    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
      defaultCommand = "${pkgs.fd}/bin/fd --type f --hidden --follow --exclude .git";
      defaultOptions = [
        "--height 40%"
        "--layout=reverse"
        "--border"
        "--inline-info"
      ];
    };
    
    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
    
    programs.direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };
    
    programs.eza = {
      enable = true;
      enableZshIntegration = true;
      extraOptions = [
        "--group-directories-first"
        "--header"
      ];
    };
  };
}
      