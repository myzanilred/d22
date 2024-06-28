## D22 Module System
Starting with version alpha 0.2.0, d22 will begin to provide the ability to load modules which add aditional functionality, such as detecting changes to files that a project's source files depend on. Modules are located in either **/etc/d22/modules/**, or **$HOME/.d22/modules**. Local user modules will take presedence over global modules, allowing users to override globally installed modules.

There are two types of modules:

* Language Modules  
These modules provide functionality specific to a given programming language, and are given the naming convention *lang_<name\>*, where **name** is the name of the target language. These modules are selected by a project's build script by setting the **$LANG_MOD** variable to the desired module name.

* Shell Modules  
Shell modules are used to replace or expand d22's default POSIX shell functions with versions which take advantage of the functionality provided by more feature-rich shells, such as ksh, bash, or zsh.

## Language Module Definitions
Language modules should be written with the same expectations as the base script. They should rely only on shell features defined by POSIX, or on the functions provided by d22 itself.

Language modules are currently expected to provide the following functionality:

* **\_\_auto\_dependency <Source\> <Object\>**  
This function is called before a source is compiled. It will be passed the arguments **Source** and **Object**, which will be the paths of the source to be compiled, and the output object file, respectively. Its job is to analyze the contents of **Source** and determine if any aditional files should be checked for changes, and add them to the file dependency list of **Object** using add_object_dependency.

## Shell Module Definitions
Shell module support will be added in a future version of d22.
