# gui-scale

gui-scale is a simple tool that scales GTK or Qt applications easily. It uses
the native scaling variables provided by the GTK and Qt frameworks.

The tool simply checks for the right one being used, so you don't have to
remember or know which one uses what GUI framework.

# Global Installation Instructions

A global installation makes sure your DE can also run the tool easily, or any
other user logged into the system for that matter.

I recommend having a bin directory in your home folder. Following command
checks for it existence and if not, it creates it.

```bash
cd $HOME/bin || mkdir $HOME/bin
```

Now it is time to get scale and symbolically link it to your
```/usr/local/bin``` directory, so users as well as the DE can run it easily.

```bash
git clone https://github.com/dhhdev/gui-scale $HOME/bin

sudo ln -s $HOME/bin/gui-scale/gui-scale.sh /usr/local/bin/gui-scale
```

Now, to make sure we can run it, we change the mode of the file we have
symbolically linked.

```bash
chmod 755 $HOME/bin/scale/scale.sh
```

To make the tool visible to the terminal, you'll have to restart it. If you
want the tool to be picked up by the DE itself - for example using Custom
Shortcuts on a KDE system. You'll have to reboot, restart your DM or log out
and in to the system again.
