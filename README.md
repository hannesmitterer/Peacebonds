# Peacebonds

A dashboard application for managing peace bonds and related frameworks.

## Documentation Eternalization

This repository includes an automated script to eternalize documentation using IPFS and Pinata.

### Prerequisites

- Pinata account with JWT token
- Documentation files in the `docs/` directory

### Usage

1. Export your Pinata JWT token:
   ```bash
   export PINATA_JWT="your_pinata_jwt_token"
   ```

2. Ensure your documentation is in the `docs/` directory.

3. Run the eternalization script:
   ```bash
   ./eternalize.sh
   ```

### What the Script Does

The `eternalize.sh` script automates the complete workflow for eternalizing frameworks:

1. **IPFS CLI Installation**: Automatically downloads and installs the IPFS CLI if not already installed
2. **Daemon Initialization**: Initializes the IPFS repository and starts the daemon
3. **Add Documentation**: Recursively adds all files in the `docs/` directory to IPFS
4. **Pin to Pinata**: Automatically pins the resulting CID to Pinata using your JWT token
5. **User Feedback**: Provides clear status messages for each step

### Output

Upon successful completion, the script will:
- Save the IPFS CID to `.ipfs_cid` file
- Save the Pinata API response to `.pinata_response.json` file
- Display the IPFS and Pinata gateway URLs for accessing your content

## Development

### Install Dependencies
```bash
npm install
```

### Start Development Server
```bash
npm start
```

### Build for Production
```bash
npm run build
```
