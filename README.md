# BigDataLab3 - Secret Management with HashiCorp Vault

This project extends BigDataLab2 by adding secret management using HashiCorp Vault. Instead of storing database credentials in environment variables or configuration files, they are now securely stored in Vault.

## Architecture

The project consists of three Docker containers:
1. **Vault**: HashiCorp Vault for secret management
2. **Postgres**: PostgreSQL database for storing predictions
3. **App**: The machine learning model API

## Secret Management

Database credentials are stored in Vault and retrieved by the application at runtime. This improves security by:
- Encrypting secrets at rest
- Providing access control to secrets
- Centralizing secret management
- Enabling secret rotation

## Setup and Running

1. Clone the repository
2. Run the application using the provided script with parameters:
   ```
   ./start.sh --db-user=postgres --db-password=your_password --db-name=reviewdb --db-port=5432
   ```

   Alternatively, you can use an environment file:
   ```
   ./start.sh --env-file=.env
   ```

The script will:
1. Start Vault with database credentials
2. Start PostgreSQL with initialization variables
3. Start the application without database credentials (it will retrieve them from Vault)

This approach ensures that database credentials are only passed to the services that need them, and the application retrieves credentials only from Vault.

### Command Line Options

```
Usage: ./start.sh [options]
Options:
  --db-user=USER         Database user (default: postgres)
  --db-password=PASSWORD Database password (default: postgres)
  --db-name=NAME         Database name (default: reviewdb)
  --db-port=PORT         Database port (default: 5432)
  --vault-addr=ADDR      Vault address (default: http://vault:8200)
  --env-file=FILE        Environment file to use
  --clean                Remove existing volumes before starting (use with caution!)
  --help                 Show this help message
```

> **Note**: If you encounter issues with PostgreSQL authentication or "role does not exist" errors, try using the `--clean` flag to remove existing volumes and start fresh. This is especially useful when changing database credentials.

## API Endpoints

- `/predict`: Make a prediction based on a review
- `/predictions`: Get the latest predictions from the database
- `/health`: Check the health of the API, including Vault connection status
- `/vault-status`: Check the status of the Vault connection

## Security Notes

- The `.env` file is only used for initial setup and should be removed in production
- In production, Vault should be properly configured with appropriate authentication methods and policies
- The Vault token used by the application should be rotated regularly
