# Source this file for setting up the development environment.


# Add cc65 (which I cloned in this directory on my system)
# to the search path.
export PATH="$PATH:$(pwd)/cc65/bin"

# Extra lazy.
alias b='just build'
alias w='just build && just write'
