#!/bin/sh

set -euo pipefail

# If the first argument starts with '-' (indicating it's a flag) or ends with '.conf' (indicating it's a config file),
# prepend 'redis-server' to the arguments to ensure that Redis runs with the appropriate command.
if [ "${1#-}" != "$1" ] || [ "${1%.conf}" != "$1" ]; then
    # Set the command to run 'redis-server' with the provided arguments
    set -- redis-server "$@"
fi

# If the command is 'redis-server' and the script is running as root (UID 0), then:
# - Change ownership of all files in the current directory to the 'redis' user.
# - Use 'su-exec' to drop privileges and run Redis as the 'redis' user.
if [ "$1" = 'redis-server' -a "$(id -u)" = '0' ]; then
    # Change the ownership of all files in the current directory to the 'redis' user
    find . \! -user redis -exec chown redis '{}' +
    # Replace the current process with 'su-exec', running Redis as the 'redis' user
    exec su-exec redis "$0" "$@"
fi

# Store the current umask (file creation mode mask) in the variable 'um'
um="$(umask)"

# If the umask is the default value '0022' (which gives more permissive permissions),
# change it to '0077' to ensure that any newly created files are only accessible by the owner.
if [ "$um" = '0022' ]; then
    # Set a more restrictive umask '0077', which ensures files are only readable/writable by the owner
    umask 0077
fi

# Finally, execute the command passed to the script (either 'redis-server' or another command).
exec "$@"
