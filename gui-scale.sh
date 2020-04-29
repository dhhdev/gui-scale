#!/usr/bin/env bash

# License: MIT
_author_name="Daniel Hyldebrandt Hemmingsen"
_author_mail="daniel@dhhit.dk"

# Make sure users settings doesn't interferre with the script, when doing
# calculations with bc or casting to float with printf.
LC_NUMERIC="C"

# Display messages
_print()
{
	if [ $# -ne 2 ];
	then
		_type=D
		_message="_print function has $# arguments, should have 2 in total."
	else
		_type=$1
		_message=$2
	fi
	_prefix="" # empty by default
	_colour="0m" # default colour

	# Danger
	[[ $_type = D ]] && _colour="91m" && _prefix="[DANGER]: "

	# Success
	[[ $_type = S ]] && _colour="92m" && _prefix="[SUCCESS]: "

	# Warning
	[[ $_type = W ]] && _colour="93m" && _prefix="[WARNING]: "

	# Info
	[[ $_type = I ]] && _colour="96m" && _prefix="[INFO]: "

	# Set colours
	_sc="\e[$_colour"
	_ec="\e[0m"

	# Print message
	printf "$_sc%s%s$_ec\n" "$_prefix" "$_message"
}

# Check for dependencies
_script_dependencies=(which basename realpath dirname bc ldd)

for _dependency in ${_script_dependencies[*]}
do
	if [ ! $(which $_dependency) ];
	then
		_print D "You don't seem to have $_dependency installed."
		exit 1
	fi
done

_script_name=$(basename -- $0)
_script_version="0.0.1"
_github_link="https://github.com/dhhdev/gui-scale"
_github_issues="$_github_link/issues"
_github_license="$_github_link/LICENSE.md"

# Hard min/max values for scaling
_min_scale=1.00
_max_scale=5.00

# Helpers
_redirect=/dev/null

_project_info()
{
cat <<EOF
Project information:
	Version: $_script_version
	 Author: $_author_name <$_author_email>
	 GitHub: <$_github_link>
	 Issues: <$_github_issues>
	License: <$_github_license>
EOF
}

_usage()
{
cat <<EOF
Usage: $_script_name [OPTIONS] [scale_factor] [program_to_run]
Scale GTK and Qt applications.

You can specify the scale_factor as either digits, or as a decimal numbers
within the range of $_min_scale - $_max_scale.

program_to_run can be with arguments, see examples.

Options:
	-h	display usage information
	-i	display $_script_name project information
	-v	display version

	-V	be extra verbose aka. show all errors for debugging

NOTE:
	$_script_name is still experimental in many ways. I am trying to make this
	as polished as possible, but some edge cases might result in weird
	behaviour.

	Flatpak or Snap packages are not supported at this time, and I am not sure
	if they will ever be because of their sandbox nature.

	Please report bugs at <$_github_issues>

Examples:
	$_script_name 1.5 konsole --full-screen

	Will scale konsole in full screne mode (Qt application) up by 50%.

	$_script_name

Bugs can be reported at: <$_github_issues>
License can be viewed at: <$_github_license> (MIT)
EOF
}

_check_scaling()
{
	# Use two point precision
	_scale_factor=$(printf %.2f $1)

	if [ $? -ne 0 ];
	then
		_print W "scale_factor: Has to be a whole or decimal number."
		return 1
	fi

	# Check float range
	_bc_output=$(bc -l <<-EOM
		$_scale_factor >= $_min_scale && $_scale_factor <= $_max_scale
	EOM
	)

	if [ $_bc_output -ne 1 ];
	then
		_print W "scale_factor: Has to be a value between $_min_scale and $_max_scale."

		return 1
	fi

	return 0
}

_check_library()
{
	[[ -z $1 ]] && _print W "program_to_run wasn't set." && return 1

	_program_path=$(which $1)

	if [ $? -eq 0 ]
	then
		_ldd_output=$(ldd $_program_path)
	fi

	echo $_ldd_output | grep 'gtk' &>$_redirect
	[ $? -eq 0 ] && _library=GTK && return 0
	echo $_ldd_output | grep 'libQt'&>$_redirect
	[ $? -eq 0 ] && _library=QT && return 0

	_print W "program_to_run wasn't a GTK or Qt application."

	return 1
}

# Main script

# getopts, handle specified arguments from user (if any)
while getopts 'hivV' c
do
	case $c in
		h)
			_usage
			exit 0
			;;
		i)
			_project_info
			exit 0
			;;
		v)
			echo $_script_version
			exit 0
			;;
		V)
			_verbose=true
			;;
		*)
			_usage
			exit 1
			;;
	esac
done

# Unset GTK and Qt env variables
unset GDK_DPI_SCALE QT_SCALE_FACTOR

# Get me the anything but the getopts
shift $((OPTIND-1))

# Save arguments to variables
_scale_factor=$1
_program_to_run=${@:2}

# Be loud af? (as fun?)
if [[ $_verbose == true ]];
then
	_print I "Verbose mode is active."

	# Set stderror redirection to /dev/tty
	REDIRECTION=/dev/tty

	# Display scaling_factor and program_to_run
	_print I "scale_factor set to: $_scale_factor"
	_print I "program_to_run set to: $_program_to_run"
fi

# scale_factor handling
_check_scaling $_scale_factor

if [ $? -ne 0 ];
then
	_print D "Aborting..."
	exit 1
fi

# Check which library the program_to_run uses
_check_library ${_program_to_run%% *}

if [ $? -ne 0 ];
then
	_print D "Aborting..."
	exit 1
fi

# run command with desired scale factor
case $_library in
	GTK)
		GDK_DPI_SCALE=$_scale_factor ${_program_to_run} &>/dev/null &
		;;
	QT)
		QT_SCALE_FACTOR=$_scale_factor ${_program_to_run} &>/dev/null &
		;;
esac

disown

exit 0
