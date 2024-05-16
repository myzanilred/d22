## D22 Build Utility
The d22 utility is a build automation tool written in POSIX shell script, and designed to provide a flexible, yet powerful environment for building software.

It is easy to pick up for anyone with shell scripting experience, as all build configurations are created as shell scripts. This also gives a developer a large amount of freedom in the behaviour of their build configurations, as any valid shell commands can be used.

### Early Development Disclaimer
d22 is still in its early stages of development. While it's expected to be usable, it should not be considered stable, or complete.

*Use caution if you choose to use this utility for your own projects.*  
(And please report any issues if you do.)

## Instalation
The included **install.sh** script makes d22 easy to install.

Run:

	# ./install.sh

If run as root, the installer will install d22 globally, installing the d22 script at the location specified by the **TDIR** shell variable (/usr/bin, by default). It will also install the man page, and create the **/etc/d22rc** configuration file.

If run as a user, the install script will attempt to install the utility, and its supporting files, locally for the current user. The script will be installed in the location specified by the **TDIR** variable ($HOME/.local/bin, by default), and will install the man page in $HOME/share/man, as well as a user configuration file at **$HOME/.d22rc**. Some variables, like the user's **PATH**, may need to be updated to achive the correct behaviour for this type of installation.

### Removal
The **install.sh** script can be used to remove d22 after installation as well. Just run:

	# ./install.sh -r

If $TDIR was set manually during installation, it will need to be set for uninstallation as well. The same rules apply for global and local removal, as with the installation process.

## Configuration
d22 relies on the existence of at least one of two possible files for configuration. If no configuration is present, d22 will likely fail.

The global config, located at **/etc/d22rc**, if present, is always sourced first, allowing a system to provide a general configuration for all users.

The user configuration, located at **$HOME/.d22rc**, is sourced last, allowing a user to override any global configuration options.

### Configuration Options
As of the release of the current alpha, there are a few options directly used by d22:

* **CC=<Compiler\>**  
Sets the compiler. This will *force* the use of a specific compiler.  
CAUTION: If this option is set in the configuration, specifying $CC on the command line will be ignored, as the configuration will take precedence! It is better to use $CC\_PREF instead.

* **CC_PREF=<Compiler\>**  
Sets the *prefered* compiler. If d22 finds that $CC is not set at runtime, it will set it based on this value.
It is recommended to use this option over $CC.

* **OPTS="<Compiler options\>"**  
Sets the default options to be passed to the compiler when compiling a source using **build_stack**.

* **LINKER=<Linker\>**  
Sets the default linker to use when linking an object file with **link_stack**.  
NOTE: This option defaults to the same value as $CC. There is normally no reason to set this, but it may be useful in some cases, such as when linking a static library with *ar*.

* **JOB_MAX=<Max compile jobs\>**  
Sets the maximum number of concurrent compile jobs that d22 may start at once.  
NOTE: If a dependency for a target calls **build_stack** it will start its own build session. A build session is limited by the number of sources included by the target, and its dependencies. In other words, if a dependency for a target has only one or two sources and calls **build_stack**, the number of jobs will be limited to the two or three sources of the dependency, even if the originating target has many more sources, and regardless of the value of $JOB\_MAX.

* **SILENT=<Any non-empty value\>**  
If this value is set, d22 will suppress non-fatal messages.  
NOTE: Later versions of d22 should provide a flag to set this automatically.

While users are free to add whatever options they want to the config, beware that they could cause conflicts in later releases.

## Setup/Usage
When run, d22 will search the current directory for a file with the name **build22**. If it exists, it sources it, and executes the selected target, or, if no target was given, the default target.

The build22 file for a project should contain, either directly, or by sourcing another file, all build targets expected for the project, and may contain any valid shell commands, or scripts. Targets are declared by creating a shell function with the name **target_<Target Name\>**. For example, the default target would be declared as:

**target_default**() {  
    ...  
}

Build targets may accept arguments. Currently this functionality is not used, however, later versions may take advantage of this.

### D22 Special Functions and Values
Currently d22 provides the following functions for managing sources, targets, and the build process:

* **add_source <Source\> <Object\>**

* **add_source (-o|-O) "<Args\>" <Source\> <Objects\>**  
This function adds a source to the current target's source dependency list. The *Object* argument should be the name of the object produced by the compilation of *Source*.  
If **add_source** is called with either *\-o* or *\-O* then the optional argument *Args* will be passed to the compiler when compiling *Source*. The *\-o* option will append *Args* to $OPTS, while *\-O* will override $OPTS with the value of *Args*.

* **add_object_dependency <Object\> <Dependency\>**  
This function adds the file *Dependency* as a dependency for an object file, *Object*. Before d22 goes to compile *Object*, it will check all dependencies for changes before determining whether an object should be recompiled.

* **wants_target <Target\>**

* **requires_target <Target\>**  
These functions append a target to the current target's dependency list. If a target is added using **wants_target** the target will be considered non\-critical. If a non\-critical target fails to build, d22 will output an error and continue, omitting the target from the final build. If a dependency added using **requires_target** fails to build, d22 will abort the build process.

* **build_stack**  
This function recursively builds all sources and targets on the stack for the current target, and prepares the final objects for linking.

* **link_stack <Object\> "[Args]"**  
This function links all the objects on the current stack into the final output file *Object* using $LINKER, and optionally passes *Args* to the linker.  
NOTE: This function has no effect if a target was called for cleanup (See below).

* **clean_objects**  
This function will call the dependencies for the current target in cleanup mode. This will remove all object file associated with any dependencies.  
CAUTION: The **build_stack** and **link_stack** functions clear the dependency and source lists for a target. Calls to **clean_objects** should be made from a seperate cleaup target which includes all targets to be cleaned as dependencies. Care should also be taken that any code executed by any targets called by **clean_objects** does not interfere with the cleanup process. This can be done by testing if a target was called in cleanup mode by using the **in_cleanup** alias (See below).

Because POSIX doesn't specify a standard for arrays in the shell d22 provides its own. These arrays, as well as d22's stacks, use newlines as the delimiter between elements. The following functions provide the interface for using d22's arrays:

* **array_index <Name\> <Index\> [Value]**

* **array_put <Name\> <Index\> <Value\>**  
These functions are the main way of accessing an array element by its index, starting from zero. The **array_index** function will print the element located at *Name[Index]*, it optionally accepts the argument, *Value*, which will replace the current element's value after it is printed. The **array_put** function is much the same as **array_index**, but requires the *Value* argument to be set, and doesn't print the existing value of the element to be replaced.  
NOTE: Placing a value at any index greater then the index of the last element will cause the element to be appended to the end of the array.

* **array_drop <Name\> <Index\>**  
This function drops the element *Name[Index]* from an array.  
NOTE: This differs from clearing a value, as the element is removed from the array, and the remaining elements are shifted to fill the gap.

* **array_count <Name\>**  
Prints the number of elements in the array *Name*.

* **stack_push <Name\> <Value\>**  
Pushes *Value* onto the top of the stack or array *Name*.

* **stack_pop <Name\>**

* **stack_get <Name\>**  
These functions will print the item at the top of the stack or array *Name*. The **stack_pop** function pops the top item off of the stack after printing it.

Currently d22 provides the following miscellaneous functions for use in constructing build scripts:

* **is_function <Command name\>**  
This function tests to see if a command is a shell function. If it is the function returns true, otherwise it returns false.  
NOTE: The use of this function is rather limited, but it is provided for your convenience.

* **emit  ...**

* **emit_warning ...**

* **emit_error ...**  
These functions should be used in place of echo. They allow you to produce output at notable points while allowing d22 to suppress non-critical messages while set to silent.  
The **emit_warning** and **emit_error** varients output to stderr.  
The **emit_warning** function will be suppressed by $SILENT, while **emit_error** may be used to emit a critical error, even when $SILENT is set.

The following are special non-function aliases and values that may be used in build scripts:

* **in_cleanup**  
This alias is the only correct way to test if a target was called by **clean_objects**. It can be used to safely exclude code during cleanup. It may be tested directly using a shell *if* statement.

* **which**  
The **which** command is a common utility to identify which version of a utility will be executed in Linux environments. If d22 is executed in an environment which doesn't provide the **which** utility, it will provide similar functionality through an alias. This is for the convenience of those who are accustomed to Linux environments.

* **CURRENT_TARGET**  
Expands to the name of the current target.

### Options
Currently d22 does not accept any arguments besides the build target. Later versions will provide additional command line options to set/unset various options.
