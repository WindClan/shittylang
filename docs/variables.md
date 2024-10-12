# shittylang docs - WIP docs for shittylang
## Variables

### Variable definition
shittylang has three operations that use the "variable definition" parser: `setvar`, `setglobal`, and `addarg`. These are the only way to add new data as you need to use variables for most operations.

`setvar` sets a variable

`setglobal` sets a Lua global (in `_G`) 

`addarg` is a way to parse arguments to a function ran with `runlua` (doesn't take the variable name argument like the others!!)

#### How it works

First you pass a variable name: `setvar myVariable`

Then you choose the type of variable: `setvar myVariable string`

Then you input the data you want: `setvar myVariable string Hello, world!`

#### List of variable types
`string`/`str`, `number`/`num`, `obj`/`object`, `varobj`, `variable`/`var`, `func`/`function`, `true` & `false`, `nil`/`none`/`null`, `table`/`tab`