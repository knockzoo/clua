# clua
A library designed to replace the functionality of certain Lua functions with a custom, pure-Lua implementation. These implementations are not fast or efficient, and really serve no purpose outside of possible security applications.

# Usage
clua will attempt to replace the environment with a metatable which should return the custom implementations as well as original functions from the environment which were not changed.
This means to continue use in Lua 5.1 environments you don't need to change *anything*, and in other environments you may need to index `_ENV`.
