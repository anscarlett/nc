# Architecture Overview

## System Architecture

```mermaid
graph TB
    subgraph "Public Repository"
        F[flake.nix] --> O[outputs/]
        F --> M[modules/]
        F --> L[lib/]
        
        O --> NC[nixos-configurations.nix]
        O --> HC[home-configurations.nix]
        
        M --> MC[modules/core/]
        M --> MD[modules/desktop/]
        M --> MS[modules/server/]
        M --> MI[modules/installer/]
        
        L --> AU[auto-users.nix]
        L --> MK[mk-configs.nix]
        L --> GN[get-name-from-path.nix]
        L --> PW[passwords.nix]
        
        subgraph "Configuration Discovery"
            HOSTS[hosts/] --> AU
            HOMES[homes/] --> AU
            AU --> MK
            MK --> NC
            MK --> HC
        end
    end
    
    subgraph "Private Repository"
        PF[private-flake.nix] --> PO[Public Repo Outputs]
        PF --> PH[private-hosts/]
        PF --> PHM[private-homes/]
        PH --> PS[secrets.nix]
        PHM --> PHS[secrets.nix]
    end
    
    F --> PO
    
    style F fill:#e1f5fe
    style PF fill:#fff3e0
    style AU fill:#f3e5f5
```

## Module Dependency Graph

```mermaid
graph LR
    subgraph "Core Modules"
        CORE[core/default.nix] --> ZSH[zsh config]
        CORE --> YUBIKEY[yubikey support]
        CORE --> USERS[user management]
        CORE --> PACKAGES[unfree packages]
    end
    
    subgraph "Desktop Modules"
        DESKTOP[desktop/default.nix] --> HYPRLAND[hyprland/]
        DESKTOP --> GNOME[gnome/]
        DESKTOP --> KDE[kde/]
        DESKTOP --> DWM[dwm/]
    end
    
    subgraph "Server Modules"
        SERVER[server/default.nix] --> SSH[ssh config]
        SERVER --> FIREWALL[firewall]
        SERVER --> SERVICES[system services]
    end
    
    subgraph "Installer Module"
        INSTALLER[installer/default.nix] --> DISKO[disko presets]
        INSTALLER --> YUBIKEY_LUKS[yubikey luks]
    end
    
    CORE --> DESKTOP
    CORE --> SERVER
    CORE --> INSTALLER
    
    style CORE fill:#c8e6c9
    style DESKTOP fill:#e1f5fe
    style SERVER fill:#fff3e0
    style INSTALLER fill:#fce4ec
```

## Configuration Flow

```mermaid
sequenceDiagram
    participant User
    participant Flake
    participant AutoUsers
    participant MkConfigs
    participant GetName
    participant Outputs
    
    User->>Flake: nix build/switch
    Flake->>AutoUsers: discover configurations
    AutoUsers->>MkConfigs: found hosts/homes
    MkConfigs->>GetName: extract names from paths
    GetName->>MkConfigs: context-aware usernames
    MkConfigs->>Outputs: generated configs
    Outputs->>User: built system/home
    
    Note over AutoUsers,GetName: Supports flexible folder structures
    Note over GetName,MkConfigs: Handles username contexts (home/work)
```

## Secrets Management Architecture

```mermaid
graph TB
    subgraph "Agenix Integration"
        SECRETS[secrets/] --> AGE[age encryption]
        AGE --> KEYS[SSH/age keys]
        KEYS --> DECRYPT[runtime decryption]
    end
    
    subgraph "Co-located Secrets"
        HOST_CONFIG[host.nix] --> HOST_SECRETS[secrets.nix]
        HOME_CONFIG[home.nix] --> HOME_SECRETS[secrets.nix]
    end
    
    subgraph "Password Management"
        PASSWORDS[lib/passwords.nix] --> AGENIX_PWD[agenix passwords]
        PASSWORDS --> HASH[mkpasswd hashing]
        PASSWORDS --> YUBIKEY_PWD[yubikey passwords]
    end
    
    HOST_SECRETS --> AGENIX_PWD
    HOME_SECRETS --> AGENIX_PWD
    DECRYPT --> HOST_CONFIG
    DECRYPT --> HOME_CONFIG
    
    style SECRETS fill:#ffebee
    style PASSWORDS fill:#e8f5e8
    style DECRYPT fill:#fff3e0
```

## Build Optimization Flow

```mermaid
graph LR
    subgraph "Build Process"
        SOURCE[Source] --> EVAL[Evaluation]
        EVAL --> BUILD[Build]
        BUILD --> CACHE[Cache Store]
    end
    
    subgraph "Optimization"
        CACHE --> SUBSTITUTERS[Binary Cache]
        CACHE --> BUILDERS[Remote Builders]
        CACHE --> MONITORING[Build Monitoring]
    end
    
    subgraph "Performance"
        MONITORING --> METRICS[Performance Metrics]
        MONITORING --> CLEANUP[Garbage Collection]
        MONITORING --> HEALTH[Health Checks]
    end
    
    SUBSTITUTERS --> BUILD
    BUILDERS --> BUILD
    HEALTH --> SOURCE
    
    style CACHE fill:#e3f2fd
    style MONITORING fill:#f3e5f5
    style HEALTH fill:#e8f5e8
```

## Testing Architecture

```mermaid
graph TB
    subgraph "Test Suite"
        TEST_RUNNER[test-all.sh] --> SYNTAX[Syntax Tests]
        TEST_RUNNER --> BUILD_TESTS[Build Tests]
        TEST_RUNNER --> VM_TESTS[VM Tests]
        TEST_RUNNER --> HEALTH[Health Checks]
    end
    
    subgraph "Test Types"
        SYNTAX --> FLAKE_CHECK[nix flake check]
        BUILD_TESTS --> NIXOS_BUILD[NixOS Builds]
        BUILD_TESTS --> HOME_BUILD[Home Manager Builds]
        VM_TESTS --> VM_BUILD[VM Configuration]
        HEALTH --> DISK_CHECK[Disk Space]
        HEALTH --> STORE_CHECK[Nix Store Verify]
    end
    
    subgraph "Reporting"
        TEST_RUNNER --> RESULTS[Test Results]
        RESULTS --> LOGS[Detailed Logs]
        RESULTS --> BENCHMARK[Performance Data]
        RESULTS --> REPORT[Summary Report]
    end
    
    style TEST_RUNNER fill:#e1f5fe
    style RESULTS fill:#f3e5f5
    style HEALTH fill:#e8f5e8
```

## Private Repository Integration

```mermaid
graph TB
    subgraph "Setup Process"
        TEMPLATE[private-template/] --> COPY[Copy Template]
        COPY --> SETUP[setup.sh]
        SETUP --> FOLDERS[Create Folders]
        SETUP --> CONFIGS[Generate Configs]
    end
    
    subgraph "Template Structure"
        FOLDERS --> USERNAME_FOLDER[username/]
        FOLDERS --> HOSTNAME_FOLDER[hostname/]
        CONFIGS --> HOST_NIX[host.nix]
        CONFIGS --> HOME_NIX[home.nix]
        CONFIGS --> SECRETS_NIX[secrets.nix]
    end
    
    subgraph "Integration"
        HOST_NIX --> PUBLIC_IMPORT[Import Public Outputs]
        HOME_NIX --> PUBLIC_IMPORT
        PUBLIC_IMPORT --> DIRECT_USE[Direct Usage]
    end
    
    style TEMPLATE fill:#fff3e0
    style SETUP fill:#e8f5e8
    style PUBLIC_IMPORT fill:#e1f5fe
```
