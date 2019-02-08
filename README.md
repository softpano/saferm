# saferm
Wrapper for rm that helps to prevent accidental deletion of vital files

Perl wrapper for rm which prevents accidental deletions using a set of regular expressions. Initially was based on safe-rm - https://launchpad.net/safe-rm
Currently installation consists of copying the  script into one of the directories on your path an creation of the alias to this place. For example
alias rm='/usr/bin/saferm'
The program uses two blacklists (system-wide and user-specific), each of which consists of set of "typed" (see acceptable types below) Perl regular expressions.
Defaults are /etc/saferm.conf and ~/.saferm.conf . They can be overwritten via env. variables saferm_conf and saferm_private_conf, correspondingly. 
System configuration file
The first is so called system-wide blacklist which is located in /etc/saferm.conf. If it does not exist on the first invocation it will be created from the default backlist in the script. 
#
# ====================== TYPES OF CHECKS ================================
# === IMPLEMENTED ===
# a -- absolute protection using supplied prefix; type of object does not matter (for example, it can be iether link or directory)
# d -- Protected only if match is a directory.
# l -- protected only if the match is a link
# f -- protected only if the match is a file
# === UNDER CONSIDERATION ===
# t -- TAG for the object (for example root:sys is detected then the whole tree is protected. any deletion of subdirectories is not allowed, type of object does not matter
# 9 -- No more then N files in the directory. Directories is extracted from full path and the counter for directory hash increases. If counter exceeds specified limit the operation if blocked (1 to 9). Should be the first and only symbol.
# b -- delete and create the copy in the backup directory
#
# 1: All level 2 directories
^/\w+$ d
# 2: All files in /boot are protected
^/boot($|/) a
# 3: All files in /dev are protected
^/dev($|/) a
# 4: /root/bin and root/.ssh directorories
^/root($|/bin$|.ssh$)' d
# 5: dot files in root
^/root/\.bash f
# 6: Files directly in /etc, not in subdirectories
^/etc/([-\w]+($|\.conf)) f
# 7: Subdirectories of /etc including .d .daily directories such as profile.d yum.d
^/etc/[-\w]+($|.\w+$)' d
# 8: Home directories (diectories only, not the content; they should be removed with userdel not rm
^/home/\w+/$ d
# 9: Dot files and files in .ssh directory
^/home/\w+/(\.ssh|\.bash) f
# 10: Proc directory
^/proc($|/) a
# 11: Links introduced in RHEL7
^/bin$|^/sbin$|^/lib$|^lib64$ l
# 12: /sys
^/sys$' a
# 13: Subdirectories in /usr are protected
^/usr($|\w+) d
# 14: subdirectories of /var
^/var($|\w+) d
# 15: log file
^/var/log/messages f
#
# Site customarization
#
# 16: subdirectories in Apps
^/Apps($|\w+/$) d
# 17: Subdiretories in Scratch
^/Scratch($|/\w+/$)' d
# 18: .ssh directories on any level of nesting
^.*/.ssh$ d
After that you can edit it to adapt to your system (default system blacklist is Red Hat oriented)
User (or private)  configuration file
The second is user blacklist lives in ~/.saferm  and can add to system blacklist directories and files that are important for you. 
In the future this script might also allow to use a certain combination of owner and group (for example root:sys) as a poor man system attribute (Unix does not have system attribute for files and directories). We need to see if this feature is useful.  
There are three tags under  consideration as for their usefulness: 
# === UNDER CONSIDERATION ===
# t -- aTtr of the object (for example root:sys type of object does not matter)
# 9 -- No more then N files in the directory. Directories is extracted from full path and the counter for directory hash increases. If counter exceeds specified limit the operation if blocked (1 to 9). Should be the first and only symbol.
# b -- delete and create the copy in the backup directory

