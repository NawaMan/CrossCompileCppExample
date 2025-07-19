#!/bin/bash
set -e

# Get the UID/GID from environment or use defaults
USER_ID=${HOST_UID:-1000}
GROUP_ID=${HOST_GID:-1000}

echo "Starting with UID: $USER_ID, GID: $GROUP_ID"

# Make sure the app directory has the right permissions
chown -R $USER_ID:$GROUP_ID /app 2>/dev/null || true

# Execute the command directly with the right user ID
exec "$@"
