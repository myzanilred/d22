#! /bin/sh

if [ "$1" = "-r" ]
then
    if [ "$(id -u)" = 0 ]
    then
        if [ -z $TDIR ]
        then
            TDIR="/usr/bin"
        fi

        echo "Removing D22..."
        rm -f "$TDIR/d22" 2&> /dev/null
        rm -f "/usr/share/man/man1/d22.1" 2&> /dev/null
        rm -f "/etc/d22rc" 2&> /dev/null
        echo "Done."
        exit 0
    else
        if [ -z $TDIR ]
        then
            TDIR="$HOME/.local/bin"
        fi

        echo "Removing local D22 installation..."
        rm -f "$TDIR/d22" 2&> /dev/null
        rm -f "$HOME/share/man/man1/d22.1" 2&> /dev/null
        rm -f "$HOME/.d22rc" 2&> /dev/null
        echo "Done."
        exit 0
    fi
fi

if [ "$(id -u)" = 0 ]
then
    if [ -z $TDIR ]
    then
        TDIR="/usr/bin"
    fi

    echo "Installing d22 in \"$TDIR\""
    if install -m 755 ./d22 "$TDIR/d22" &&
       install -m 644 ./doc/d22.1 /usr/share/man/man1/d22.1 &&
       install -m 644 /dev/null /etc/d22rc
    then
        echo "CC_PREF=gcc" > /etc/d22rc
        echo "Done."
        exit 0
    else
        1>&2 echo 'Failed!'
        exit 1
    fi
else
    if [ -z $TDIR ]
    then
       TDIR="$HOME/.local/bin"
    fi

    echo "Not running as super user!"
    echo "D22 will be installed for this user in \"$TDIR\""
    echo "Is this okay (Y/n)?"
    read prompt
    case $prompt in
       yes|Yes|y|Y)
           echo "Installing localy..."
           ;;
       *)
           exit 0
           ;;
    esac

    if install -D -m 750 ./d22 "$TDIR/d22" &&
       install -D -m 640 ./doc/d22.1 "$HOME/.local/share/man/man1" &&
       install -m 640 /dev/null "$HOME/.d22rc"
    then
        echo "CC_PREF=gcc" > "$HOME/.d22rc"
        echo "Done."
        exit 0
    else
        1>&2 echo 'Failed!'
        exit 1
    fi
fi
