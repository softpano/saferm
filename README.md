# saferm
Perl wrapper for rm command that helps to prevent accidental deletion of vital files

Currently installation consists of copying the  script into one of the directories on your path an creation of the alias to this place. For example

<code>alias rm='/usr/bin/saferm'</code>

The program uses two blacklists (system-wide and user-specific), each of which consists of set of "typed" (see acceptable types below) Perl regular expressions.

Defaults are /etc/saferm.conf and ~/Saferm/saferm.conf . They can be overwritten via env. variables saferm_global_conf and saferm_private_conf, correspondingly. 

# System configuration file

The first is so called system-wide blacklist which is located in /etc/saferm.conf. If it does not exist on the first invocation and the script is run as root, it will be created from the default blacklist stored in the script. 

After that you can edit it to adapt it to your system (default system blacklist is Red Hat oriented)

# User (or private)  configuration file

The second is user blacklist lives in ~/Saferm/saferm.conf  and can add to system blacklist directories and files that are important for you. 

It can be multiple such files tuned to different tasks/projects with differents sets of protection regex. The one that is used can be symlinked to the ~/Saferm/saferm.conf

For the documentation see http://www.softpanorama.org/Utilities/Saferm/index.shtml

For the set of ideas behind the utility see http://www.softpanorama.org/Admin/Horror_stories/creative_uses_of_rm.shtml

For installation (which is trivial) see README file. there is also a simple installation script called saferm_install.sh 
