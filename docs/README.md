# Peacebonds Documentation

Welcome to the Peacebonds documentation. This directory contains all the documentation for the Peacebonds framework.

## Overview

Peacebonds is a dashboard application for managing peace bonds and related frameworks.

## Getting Started

To get started with Peacebonds:

1. Clone the repository
2. Install dependencies: `npm install`
3. Start the development server: `npm start`

## Eternalization

The Peacebonds documentation is eternalized using IPFS and Pinata for permanent, decentralized storage.

### Using the Eternalization Script

1. Export your Pinata JWT token:
   ```bash
   export PINATA_JWT="your_pinata_jwt_token"
   ```

2. Run the eternalization script:
   ```bash
   ./eternalize.sh
   ```

The script will automatically:
- Install IPFS CLI if needed
- Initialize and start the IPFS daemon
- Add the docs/ directory to IPFS
- Pin the content to Pinata

### Script Features

The `eternalize.sh` script provides:

- **Automated Installation**: Downloads and installs IPFS CLI for Linux and macOS
- **Error Handling**: Clear error messages for missing prerequisites
- **Progress Feedback**: Color-coded status messages throughout execution
- **Security**: Stores daemon logs in secure location (~/.ipfs/daemon.log)
- **Flexibility**: Falls back to user-level installation if system-wide installation fails

### Output Files

After successful execution, the following files are generated:

- `.ipfs_cid` - Contains the Content Identifier (CID) for the uploaded documentation
- `.pinata_response.json` - Contains the full API response from Pinata

These files are automatically excluded from git via `.gitignore`.

## License

See the main repository for license information.

