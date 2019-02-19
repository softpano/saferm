# saferm
Wrapper for rm that helps to prevent accidental deletion of vital files

Perl wrapper for rm which prevents accidental deletions using a set of regular expressions. Initially was based on safe-rm - https://launchpad.net/safe-rm

Currently installation consists of copying the  script into one of the directories on your path an creation of the alias to this place. For example

<code>alias rm='/usr/bin/saferm'</code>

The program uses two blacklists (system-wide and user-specific), each of which consists of set of "typed" (see acceptable types below) Perl regular expressions.

Defaults are /etc/saferm.conf and ~/.saferm.conf . They can be overwritten via env. variables saferm_conf and saferm_private_conf, correspondingly. 

#System configuration file

The first is so called system-wide blacklist which is located in /etc/saferm.conf. If it does not exist on the first invocation it will be created from the default backlist in the script. 

After that you can edit it to adapt to your system (default system blacklist is Red Hat oriented)

#User (or private)  configuration file

The second is user blacklist lives in ~/.saferm  and can add to system blacklist directories and files that are important for you. 
In the future this script might also allow to use a certain combination of owner and group (for example root:sys) as a poor man system attribute (Unix does not have system attribute for files and directories). We need to see if this feature is useful.  
