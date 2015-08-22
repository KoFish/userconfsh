userconfsh
==========

This tool is created to making it easier to manage and use git repositories that
contains "dot files" such as `.xinit`, `.bashrc`, `.nvimrc` and so on. By using
userconfsh you can choose which files to install and apply diffs to each file as
you install them.

To be more technical this is a collection of shell scripts that takes a "repo
configuration file", which contains a git-url to a repo with a `install.conf`
file. Based on that install-file it then puts the files in the repo at specified
places from the users root catalogue. If the file it tries to install already
exists the user can choose to generate a set of diffs that will be applied in
the future when trying to install that particular file (when the repo has been
updated for example.

Usage
-----

    sh setup.sh [-h] [-d] [-c] [-r "repo.conf"] [-b "/home/user/confrepos"] [-f]

repo.conf
---------

Command line arguments:
 - `-r` (default: `repo.conf`) - Gives the name of the file.
 - `-b` (default: `/userconfsh-dir/repos`) - Gives the absolute path to the
   place where the repos are too be stored, this is also where the repo.conf
   file that is used needs to be located.

The syntax of the `repo.conf` file is simply the name of the repo followed by
the url to the repo, for example:

    kofish git@github.com:KoFish/dotkofish.git

Here the name that will be used is `kofish`. If the file contains anything more
or less it will not be accepted.

install.conf
------------

In the cloned repo there needs to be a file at the root named `install.conf`,
the syntax of this file is slightly more complicated.

### Comments

Anywhere in the file a comment can be included by starting a line, no leading
whitespaces, with a `#`. This is the only types of comments allowed.

### Configuration

Before the first install directives in the file some options can be changed.
Currently these are limited to setting the directory for diffs and backups (both
relative to the root of the repository). This is done by including the lines

    DIFF=diffs

For setting the directory for diffs to `diffs`, and

    BACKUP=backup

For setting the directory for backups to `backup`.

### Install directives

These starts with a line that isn't indented and ends with a colon, it says
where the following files are to be installed. After that a set of indented
lines can be followed that says which files, relative to the repository root,
that should be installed here.

For example:

    ~/:
    	confs/.bashrc

This will install the file `confs/.bashrc` to `~/.bashrc`.

If the file to be installed is a directory (ending with a `/`) the files on each
row following this that is indented an extra step will be installed. If there
are no such files all files in that directory will be assumed. This means that
the following example has the exact same effect as the previous:

    ~/:
    	confs/
    		.bashrc

As you might have noticed the first component of the files does not affect where
the files are to be installed and all indentation needs to be tabs, one level of
indentation is one tab character followed by a non-tab character. It's also
worth noticing that the only form of tilde-expansion that is being done is
expanding `~` in the beginning of a path to the content of `$HOME`.
