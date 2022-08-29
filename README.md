# Purpleconf

System configuration management, as simple as can be.

Purpleconf is a tool enabling remote machine configuration as code as simply as possible.
It is based on simple principles and requires very little dependencies.

## Design goals
- Easy to modify
- Simple mapping to regular shell commands

## Requirements

Infratools requires [yq](https://github.com/mikefarah/yq) (ideally version 4+) and [jq](https://github.com/stedolan/jq) during "compilation" for `machines.yaml` parsing.

Running tests requires [bats-core](https://github.com/bats-core/bats-core/).

## Usage

Compiling for a specific machine:

    ./compile.sh machines.yaml machine.example.com
        
Deploying:

    ./deploy.sh machines.yaml machine.example.com

## Exit codes

Deploying might exit with specific exit codes. Please refer to the following table for the list of possible codes:

| Code     | Description                                        |
|----------|----------------------------------------------------|
| 0        | No error.                                          |
| 1        | Unspecified error.                                 |
| 101      | Human intervention required. Process halted.       |
