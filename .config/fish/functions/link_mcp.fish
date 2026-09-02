function link_mcp
    # Define the source file path
    set SOURCE_FILE "$HOME/mcp.json"

    # Define the destination symlink name in the current directory
    set SYMLINK_NAME "./mcp.json"

    # Check if the source file exists
    if test -f "$SOURCE_FILE"
        # Check if a file with the same name already exists
        if test -e "$SYMLINK_NAME"
            echo "Error: A file named 'mcp.json' already exists in this directory."
            return 1
        end

        # Create the symlink
        ln -s "$SOURCE_FILE" "$SYMLINK_NAME"
        echo "Symlink 'mcp.json' created for '$SOURCE_FILE'."
    else
        echo "Error: Source file '$SOURCE_FILE' does not exist."
        return 1
    end
end
