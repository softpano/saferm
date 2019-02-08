#!/usr/bin/perl
#:: saferm -- Safer deletion using set of protection regex (perl regular expresions) and addtional safety check if -r is given
#:: by Nikolai Bezroukov
#:: Released under Perl Artisitic License
#:: 
#:: Options:
#::   --help -- this help
#:: Configuration file
#::     system /etc/saferm
#::     private ~/saferm.conf or any file provided by the valus of environment variable saferm_conf   
#::
#:: This utility tries generate rm commad from given argument and to use provided regex to lock deletion of files and directories that match them 
#:: If recursive key is given one one argument is accepted for dafety reasons. 
#:: if Tree contains sirecotries sybmolic links a warning provided 
#:: one filesystem and -v are added to rm if not given; then can be edited out if not nessesary. .
#::
#--- Development History
#
#++ Ver   Date         Who       Modification
#++ ===   ==========   ========  =========================
#++ 1.0   2018/04/21   BEZROUN   Initial implementation
#++ 2.0   2019/01/17   BEZROUN   Rewrite for genomic files

# ------------------------------------------ START --------------------------------------------

use v5.10;
use feature 'state';
use warnings;
use strict 'subs';
use Cwd 'realpath';
use Getopt::Std;

our $VERSION = '1.00';
   $debug=0;
   $major_version=1; $minor_version='0';
   $SCRIPT_NAME='saferm';
   $msglevel1=5; # level of messages in print
   $msglevel2=3; # level of message in log
   $top_severity=0;
   
   $HOME=$ENV{HOME};
   chomp($HOSTNAME=`hostname -s`);
   $LOG_DIR="$HOME/Logs"; # used for opening SYSLOG 
   mkdirs($LOG_DIR);
   banner();


prolog();  
my $HOME= $ENV{'HOME'};
#
# Config_name should be: iether file or directory, d - directory  f -- file 
#  

if(  -f $SYS_CONFIG ){ 
   slurp_config($SYS_CONFIG);
} else {
   logme(__LINE__,'W', "$SCRIPT_NAME No system configratin file found");  
}

# setting in env has highest priority
my $SYS_CONFIG = '/etc/saferm.conf';
if( -f $ENV{'saferm_conf'} ){
   # take config from envinment.
   $SYS_CONFIG=$ENV{'saferm_conf'};
} 
#
# If privite config exists it is added
#   
if(  -f "$HOME/.Config/saferm.conf" ){
   # take config from home directory
    $PRIVATE_CONFIG="$HOME/.Config/saferm.conf"
} 

# Private config, if it exists, adds entries to system config, overiting duplicates 
my %protection_regex = ();
my $protected_ownership='root:root';
slurp_config($SYS_CONFIG);
if(  -f $PRIVATE_CONFIG ){ 
   slurp_config($PRIVATE_CONFIG);
} 

#
# Check what we have now
#
if(  0 == scalar keys %protection_regex  ){
    %protection_regex = %default_protection_regex;
    logme(__LINE__,'S', "$SCRIPT_NAME Creating $SYS_CONFIG from default entries. You can edits it later to suit your system");
    open(SYSOUT,'<',$SYS_CONFIG);
    foreach $f ( keys(%protection_regex)  ){
       print SYSOUT "$f %protection_regex{$f}\n"
    }
    close SYSOUT;
}    

my @allowed_args = ();

my ($optno,$argno,@opt_list,@arg_list);
my $recursive_mode=0;
#
# Loop for processing options. Detect if we are used -r -R ot -f. GETOPTS change $ARGV
# 
for ($i=0; $i<@ARGV; $i++ ){
     $_=$ARGV[$i];   
     if( substr($_,0,1) eq '-' ){
       # short option or list of options
       $opt_list[$optno++]=$_;
       if( substr($_,0,2) eq '--' ){ 
          if( $_ eq '--recursive' ){
              $recursive_mode=1;
          }elsif( $_ eq '--help' ){
              help();
              exit;
          }    
       } else {          
         if( index($_,'r') > -1 ){
           $recursive_mode=1;
           $summary=1;
           $generate_only=1;
         }  
         # forced option		 
		 if( index($_,'f') > -1 ){
           $forced_mode=1;
           $summary=1;
           $generate_only=1;
         } 
         		 
      }  
	  next;        
    }
    $arg_list[$argno++]=$_;
}
if( $recursive_mode==1 && $forced_mode==0 && scalar(@arg_list)>1 ){
    logme(__LINE__,'S', "More then one argument with regursive option specified. That's a dangerious command");
    abend(__LINE__,"Can't continue");	
}
@master_list=();
for($i=0; $i<@arg_list; $i++ ){  
    $arg=$arg_list[$i];
	if(  -e $arg ){
	   logme(__LINE__,'S', "$dir does not exists");
       exit;
    }
	 
    if(  -d $arg  ){
       @flist=`tree -afi $arg`; # get list of files and idrectories to be deleted
       $totals=scalar(@flist);  
       logme(__LINE__,'W',"We will be deleting $totals files in the directory $dir");  
       push(@master_list,@flist);	   
   } else {
      push(@master_list,$arg)
   }  
}
   $limit=(scalar(@master_list)>10)? 10 : scalar(@master_list);
 for ($i=0;$i<$limit;$i++ ){
        print $master_list[$i];
   }
   if( $limit>12 ){
          print "... ... ...\n";
          print $master_list[-3];
          print $master_list[-2];
          print $master_list[-1];
   } 
  
   my ($pathname,$normalized_pathname);
   foreach $name (@master_list ){ 
      chomp($name); 
      if(  -l $name  ){
         logme(__LINE__,'S',"Directory $name  is a symbolic link.");
         $debug=1;
      }
      if(  -f $name  ){
         # this is a file
         $is_dir=0;
         $normalized_fname=realpath($name);
         $normalized_path = substr($normalized_fname,0,rindex($name,'/'));
         if(  -l $normalized_path  ){
            logme(__LINE__,'S',"Directory $normalized_path is a symbolic link. Exiting");
            $debug=1
         }                 
      } elsif(  -d $name  ){
         if(  -l $name && $recursive_mode==1 ){
            logme(__LINE__,'S',"Directory $name is a symbolic link. Recursive mode was specified. Exiting");
             exit;
         }
         # Convert to an absolute path (e.g. remove "..")  
         $is_dir=1;
         $normalized_path = realpath($name); # for firectory it retrun path to the directory, not full path
         if( $name=m{\.\.?/(.*)/?$} ){
             $normalized_path.=$1; # concatenate the directory to the path
         }else{
             $normalized_path.=$name;
         }             
      } 
     
     
      # Check against the blacklist using types
	  
      foreach $f ( keys(%protection_regex)  ){
	     next unless $normalized_path=~/$f/;
		 if( $protection_regex{$f} eq 'a' ){
		    logme(__LINE__,'S',"Attempt to remove protected file or directory $normalized_path covered by regex $f");
            next;  
         } 
         if(  -d $normalized_path  && $protection_regex{$f} eq 'd' ){
            logme(__LINE__,'S',"Attempt to remove protected directory $normalized_path covered by regex $f");
            next;  
         }
		 if(  -d $normalized_path  && $protection_regex{$f} eq 'f' ){
            logme(__LINE__,'S',"Attempt to remove protected file $normalized_path covered by regex $f");
            next;  
         }
		 if(  -d $normalized_path  && $protection_regex{$f} eq 'l' ){
            logme(__LINE__,'S',"Attempt to remove protected link $normalized_path covered by regex $f");
            next;  
         }
      } # for 
            
       
   }
   $severe_errors=summary();
   if( $severe_errors>0 ){
      $generate_only=1;
	  if( scalar(@master_list<100) ){
	     for( $i=0; $i<@master_list; $i++ ){
		    say @master_list
	     }
      } else {
      }
      exit 1
   } 
   # Prepare for actually deleting the file
   my $RM = '/bin/rm';
   if( $debug>2 ){
      $RM = '/bin/ls';  
   }
   #$command= $RM.' -v -I --one-file-system '.join(' ',@opt_list).' '.join(' ',@arg_list);
   print "\n\nGENERATED COMMAND:\n\t $command\n";
 
   $rc=system($command);
   if( $rc>0 ){
      logme(__LINE__,'S',"/bin/rm returned rc=$rc");
   }    
   exit $rc;
     
            
sub prolog
{
# TYPES OF CHEXKS
#this string is checked against the type the onject in the main loop. 

# a - absolute protecion using supplied prefix; type off object does not matter (for example can be iether link or directory)
# t TAG if the object (for example __no_delete__ is detected the whole tree is protected. any deletion of subdirectories is not allowed, type of object does not matter 
# d Protected only if match is a directory.
# 9 Directories is extracted from full path and the counter for directory hash increases. If counter exceeds specoified limit the operation if blocked (1 to 9). Should be the first and only symbol. 
# l protected only if the match is a link
# f protected only if the match is a file 
# m delete only if /BACKUP contains this file

# POSSIBLE ACTIONS after the detection
# X abort 
# C continue
# ! ask

#
# This is global var, not local
#
%default_protection_regex = (
    '^/bin($|/)'           => 'd', # files can be deleted but the directory itslef or subdirectories can't 
    '^/boot($|/)'          => 'a',
    '^/dev($|/)'           => 'a',
    '^/root($|/bin$|.ssh$)' => 'd', 
	'^/root/\.bash/'       => 'f',
    '^/etc$'               => 'd', # /etc
    '^/etc/(\w+($|\.d|\.conf)' => 'a', # files or directories without suffixes
	'^/etc/\w+.d$'         => '',  # profile.d yum.d -- directory and thier content
	'^/etc/\w+.conf'       => 'f',  # protected conf files
    '^/home/\w+/$'         => 'd', #  Home directories (diectories only, not the content; they should be removed with userdel) 
    '^/home/\w+/\.$'       => 'a', # dot files and directory at home
    '^/lib|^lib64'         => 'a',
    '^/proc($|/)'          => 'a',
    '^/sbin$'              => 'a',
    '^/sys$'               => 'a',
    '^/usr($|\w+)'         => 'd', # level 3 subdirectories in /usr are protected
    '^/var($|\w+)'         => 'd',
    '^/Apps($|\w+/$)'      => 'd',  # level two directory and level 3 subdirectories
    '/Scratch($|\w+/$)'    => 'd', # level two directory and level 3 subdirectories
    '^.*/.ssh$'            => 'd',  # .ssh directories on any level of nesting and all files in the them are protected
);

$FIND='/bin/find';

}
sub slurp_config {
    my $filename = shift;
    my ($file,$type);
    if(  -e $filename  ){
        if(  open my $SYSIN, '<', $filename  ){
            while (<$SYSIN> ){
                chomp;
                ($file,$type)=split;
                unless($type =~/[adflt\d]/ && length($type)==1  ){
                  logme(__LINE__,'S', "Can't detect valid file type in the line $_ . Should be a,d,f,l, or t (all, file or directory)");
                  exit;  
                }                   
                $protection_regex{$file} = $type;                
            }
            close $SYSIN;    # deliberatly ignore errors
        }else{
           print {*STDERR} "Could not open configuration file: $filename\n";
        }
    }

    return;
}
   
#================================================================
# Standard subroutines -- version 3.00 (Dec 11, 2014)
#================================================================ 

#
# Read script and extract help from comments starting with #::
#
sub helpme
{
   open(SYSHELP,"<$0");
   while($line=<SYSHELP> ){
      if(  substr($line,0,3) eq "#::"  ){
         print substr($line,3);
      }
   } # for
   close SYSHELP;
   exit;
}

sub abend
{
my $lineno=$_[0];
my $message=$_[1];
      
  if( -f "$LOG_FILE" ){
     logme($lineno,'T',$message);
     close SYSLOG;
     `cat $LOG_FILE | mail -s "$HOSTNAME ABEND $message" "$owner_addr"`;
     die("Abend at $lineno. $message");
     system(qq(cat $LOG_FILE | $MAIL -r "$owner_addr"  -s "$SCRIPT_NAME: Abend at $lineno - $message" "$owner_addr"));
  } else {
     system(qq(cat "$message" | $MAIL -r "$owner_addr"  -s "$SCRIPT_NAME: Abend at $lineno - $message" "$owner_addr"));
  }  
  `echo $lineno "$message"> $LOG_FILE.abend`; # replicate abend message
  die("Abend at $lineno. $message");
} # abend
#
# Banner perform thrre fucntions
# 1. Cleans LOG_DIR
# 2. opens SYSLOG
# 3. print the banner message
#
sub banner {
my $timestamp=`date "+%y/%m/%d %H:%M"`;
my $title="$SCRIPT_NAME: $major_version.$minor_version. DEBUG=$debug Date $timestamp\n";
my $LOG_RETENTION_PERIOD=$_[0];
my $subtitle=$_[1];
   $day=`date '+%d%m'`; chomp $day;
   $day=substr($day,0,2);
   $log_stamp=`date "+%y%m%d_%H%M"`;
   if( $day==1 ){
     #Note: in debugging script home dir is your home dir and the last thing you want is to clean it ;-)
      `$FIND $LOG_DIR -name "*.log" -type f -mtime +$LOG_RETENTION_PERIOD -delete`; # monthly cleanup
   }

   $LOG_FILE="$LOG_DIR/$SCRIPT_NAME\_$log_stamp.log";
   if( $debug>0 ){
      open(SYSLOG, ">$LOG_FILE") || abenp d(__LINE__,"Fatal error: unable to open $LOG_FILE");
   }  else {
      open(SYSLOG, ">$LOG_FILE") || abend(__LINE__,"Fatal error: unable to open $LOG_FILE");
   }
      chomp $timestamp;
      if( $msglevel1==0  ){
         # do not write bannet with msglevel1==0
         return unless ( -z $LOG_FILE); # Write banner only at the beginning ofthe log
      }   
      logme(0,' ',$title);
      $subtitle='Logs are at $LOG_FILE. Type --help for help.\n';
      logme(0,' ',"$subtitle\n");
      logme(0,' ',"============\n");
}
#
# Message generator: Record message in log and STDIN (controlled by msglevel1 and msglevel2)
# lineno, severity, message
# NOTE: $top_severity, $msglevel1, $msflevel2 are global variables. Should be initialized elsewhere 
## ARG1 lineno
# Arg2 Error code (only first letter is used, subsequnt letter can contin assitional info)
# Arg3 Test of the message
sub logme
{
#our $top_severity; -- should be defined globally   
my $lineno=$_[0];
my $error_code=substr($_[1],0,1);
my $message=$_[2];
my $timestamp=`date "+%y/%m/%d %H:%M"`;
      chomp($timestamp);
#
# Two special cases -- lineno==0 and lineno is negative
#
   if( $lineno < 0  ){
      #interpreted as skip no;
      print SYSLOG "\n\n";
      return;
   } elsif( $lineno==0 ){
      # special message - no timestamp. Used for banner and options printing
      ($debug>0 || $msglevel1>0 ) && print "$message";
      print SYSLOG "$message";
      return;
   }                        
   my $severity=index("DIWEST",$error_code);
                        
   return if(  $severity == 0 && $debug==0 ); # no need to process debug messages if $debug==0
   $ercounter[$severity]++;
   $message="\[$error_code$major_version$minor_version.$lineno\] $timestamp: $message";     

#----------------- Error history -------------------------
   if(  $severity > $top_severity ){
      $top_severity=$severity;
      $top_message = $message;
   }
#--------- Message printing and logging --------------
   return if( $severity==0 && $debug==0); # do not print testing messages
   if( $severity > 3-$msglevel2  ){
      # msglevel2 defines writing to SYSLOG. 3 means Errors (Severe and terminal messages always whould be printed)
      print SYSLOG "$message\n";
   }
   if( $severity > 3-$msglevel1 ){
      # msglevel2 defines writing to STDIN. 3 means Errors (Severe and terminal messages always whould be printed)
      print "$message\n";
   }                           
} #logme
#
# Summary od diagnostic messages like in IBM compilers
# Uses globals @ercounter, $top_severity and $top_message;
#
sub summary {
   my $i;
   return if( $top_severity<2); # if no warning -- no summary
   logme(0,' ', "Messages summary:\n");
   for ( $i=length('DIWEST'); $i>0; $i--  ){
      next if( $ercounter[$i] == 0 );
      logme(0,' ',"\t\t".substr('DIWEST',$i,1).": ".$ercounter[$i]."\n");
   }
   logme(0,' ',"The most severe error: $top_message\n");
   return ($ercounter[-2]); # return severe errors
   
} # summary
#
# Make directories for the package
#
sub mkdirs
{
   foreach (@_ ){
      next if(  -e $_);
      `mkdir -p $_`;
   }
}