#!/usr/bin/perl

###########################################################################
## Perl Template
################################
#
# Template
# 
# Author: Loic Grondin, France
#
# Version: 1.0
# Last update: 02/2015
#
# Using Perl 5.18.2
# And differents modules 
#
###########################################################################

###################################################################
## Description
#############
##
##
##
#############
## Description
#################################################################

use strict;
use warnings;

########################################
# Don't forget to specify the absolute path
use lib '/path/to/Modules/';
########################################

#################################################################
## Use
#########

# Command Line Parameter
use Getopt::Long;
# version: 2.43

# Logger
use Log::Log4perl;
########################################
# Don't forget to specify the absolute path
Log::Log4perl::init('/path/to/Log/log4perl.conf');
########################################
# version 1.46

# Parrallel works
# 	local installation
require Proc::ParallelLoop;
#version 0.5

# Execute Extern Program
# 	local installation
require Proc::Reliable;
#version 1.16

# Print a structure easily
#	used to develop
#	can be deleted in production
#	print Dumper \%hash
use Data::Dumper qw(Dumper);
# version 2.154

# Use color to print 
use Term::ANSIColor;
# version 4.03

# Benchmark the script
# Use like this:
#	$t0 = Benchmark->new;
# 	... your code here ...
#	$t1 = Benchmark->new;
#	$td = timediff($t1, $t0);
#	print "the code took:",timestr($td),"\n";
use Benchmark;
# version 1.18

# High resolution alarm, sleep, gettimeofday, interval timers
use Time::HiRes;
# version 1.9726

# Run a process in background while continuing the Script
#	local installation
use Proc::Simple;
# version 1.21

#########
## Require
##################################################################


#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#\\\\\\\\\\\\\\\\\\\\\\\ Use of Getopt::Long
#
# To use options
#
#	--verbose
#	To print information on the console
#
#
#
#\\\\\\\\\\\\\\\\\\\\\\\
#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\


##################################################################
## Global variables
###################


# ------------ Options
my $verb = '';
# ---------------------------------------

# ------------ Log
my $log = Log::Log4perl->get_logger();
# ---------------------------------------

#------------ External Process
my $myproc = Proc::Reliable->new();


# -------------------------------------


###################
## Global variables
##################################################################


##################################################################
## First Step
#### Take informations from the user
## And check it

GetOptions (

	"verbose" => \$verb

);


##
#### User informations
## First Step
##################################################################





##################################################################
## Subfunctions
###############

# Function used to return the load average of the computer on one second
#
#	It uses /proc/stat
#	param[out]	loadAverage

sub load_average {

	my $loadAverage;
	my $loadAverageAc;
	my $loadAverageAl;
	my $loadInstantAc1;
	my $loadInstantAc2;
	my $loadInstantAl1;
	my $loadInstantAl2;
	my $nbCPU;
	my $askCPU = "grep '^processor' /proc/cpuinfo | wc -l";
	my @out;

	@out = &launch_program($askCPU);
	$nbCPU = $out[0];

	($loadInstantAc1,$loadInstantAl1) = &load_instant();
	sleep(1.0);
	($loadInstantAc2,$loadInstantAl2) = &load_instant();

	$loadAverageAc = ($loadInstantAc2 - $loadInstantAc1);
	$loadAverageAl = ($loadInstantAl2 - $loadInstantAl1);
	$loadAverage = (($loadAverageAc / $loadAverageAl) / $nbCPU) * 100;
	
	return $loadAverage;


}


# Function used to return the load of the computer on one instant
#
#	It uses /proc/stat
#	param[out]	loadActive
#	param[out]	loadAll

sub load_instant {

	my $loadActive;
	my $loadAll;
	my $readCPU = "grep '^cpu ' /proc/stat";
	my @out;

	@out = &launch_program($readCPU);
	$out[0] =~ /^(cpu)(\s+)(\d+)(\s+)(\d+)(\s+)(\d+)(\s+)(\d+)(\s+)(\d+)(\s+)(\d+)(\s+)(\d+)/;
	$loadActive = $3 + $5 + $7;
	$loadAll = $loadActive + $9 + $11 + $13 + $15;

	return ($loadActive,$loadAll);


}

# Function used to return the load of a program on one instant
#
#	It uses /proc/pid/stat
#	param[in]	pid of the program
#	param[out]	load

sub load_instant_pid {

	# variables
	my $pid = $_[0];
	my $load;
	my $readCPU = "cat /proc/$pid/stat";
	my $readUptime = "cat /proc/uptime";
	my @out;
	my @sp;
	my $uptime;
	my $utime;
	my $stime;
	my $cutime;
	my $cstime;
	my $starttime;
	my $clockPerTicks;
	my $totaltime;
	my $seconds;


	# check if the process still exist
	if (-e "/proc/$pid/stat") {

		# get informations
		@out = &launch_program($readUptime);
		$out[0] =~ /^(\d+\.\d+)(\s+)(\d+\.\d+)/;
		$uptime = $1;

		@out = &launch_program($readCPU);
		@sp = split(' ',$out[0]);
		$utime = $sp[13];
		$stime = $sp[14];
		$cutime = $sp[15];
		$cstime = $sp[16];
		$starttime = $sp[21];

		$clockPerTicks = sysconf( _SC_CLK_TCK );

		# process
		$totaltime = $utime + $stime + $cstime + $cutime;
		$seconds = $uptime - ($starttime / $clockPerTicks);

		$load = (($totaltime / $clockPerTicks) / $seconds) * 100;

	} else {
		&verbose("error","The process PID=".$pid." doen't exist any more... Exiting !");
	}
	

	return $load;
	
}


# Function used to return the the CPU time execution of a program 
#	It works only for running program
#	It is the time used by the cpu to work on the program
#
#	It uses /proc/pid/stat
#	param[in]	pid of the program
#	param[out]	time in second

sub time_pid {

	# variables
	my $pid = $_[0];
	my $time;
	my $readCPU = "cat /proc/$pid/stat";
	my @out;
	my @sp;
	my $utime;
	my $stime;
	my $cutime;
	my $cstime;
	my $clockPerTicks;
	my $totaltime;

	# check if the process still exist
	if (-e "/proc/$pid/stat") {

		# get informations
		@out = &launch_program($readCPU);
		@sp = split(' ',$out[0]);
		$utime = $sp[13];
		$stime = $sp[14];
		$cutime = $sp[15];
		$cstime = $sp[16];


		$clockPerTicks = sysconf( _SC_CLK_TCK );

		# process
		$totaltime = $utime + $stime + $cstime + $cutime;
		$time = ($totaltime / $clockPerTicks);
		print $time;

	} else {
		&verbose("error","The process PID=".$pid." doen't exist any more... Exiting !");
	}


	
	return $time;


}


# Function used to take the exit status of the program running in background
#
#	param[in] 	text
#	param[out]	exit status

sub exitStatus_PIB {

	my $pib = $_[0];

	return $pib->exit_status();

}

# Function used to take the pid of the program running in background
#
#	param[in] 	text
#	param[out]	pid

sub pidOf_PIB {

	my $pib = $_[0];

	return $pib->pid;

}


# Function used to see if the programm in background is finished
#
#	param[in] 	text
#	param[out]	1 if alive, 0 if finished

sub isAlive_PIB {

	my $pib = $_[0];

	return $pib->poll();

}

# Function used to wait the programm in background to finish
#
#	param[in] 	text

sub wait_PIB {

	my $pib = $_[0];

	&verbose("info","The program can now be interupted by ctrl+c ");

	while (&isAlive_PIB($pib) == 1) {
		sleep 1;

		$SIG{INT} = sub {

			&verbose("warn","The program have been interupted !");
			&stop_PIB($pib)

		};
	}

}

# Function used to stop the programm in background
#
#	param[in] 	text

sub stop_PIB {

	my $pib = $_[0];

	$pib->kill();

}


# Function used to launch the program in background
#
#	param[in] 	text
#	param[out] 	instance of program running in background

sub launch_PIB {

	my $command = $_[0];
	my $pib;

	$pib = Proc::Simple->new(); 
	$pib->redirect_output("/dev/null","/dev/null");
	$pib->start($command);

	return $pib;

}

# Function used to launch the programm 
#
#	param[in] 	text
#	param[out]	stdout,stderr

sub launch_program {

	my $command = $_[0];
	my $stdout;
	my $stderr;
	my $status;
	my $msg;

	($stdout, $stderr, $status, $msg) = $myproc->run($command);

	if ($status != 0) {

		&verbose("error","Problem occurs during the execution");
		&verbose("console","\n##############################\n");
		&verbose("info","STDOUT of the program:");
		&verbose("info",$stdout);
		&verbose("error","STDERR of the program:");
		&verbose("error",$stderr);
		&verbose("console","\n##############################\n");
		return ($stdout,$stderr);
		&verbose("fatal","The Script can't continue... Exiting !");
		
	} else {
		
		&verbose("info","The program works very well !");

		&verbose("console","\n##############################\n");
		&verbose("info","STDOUT of the program:");
		&verbose("info",$stdout);
		&verbose("console","\n##############################\n");
		return ($stdout,undef);

	}

}




# Function used to print a text only if verbose is set
#	log the text in the other case 
#
#	param[in] 	type
#	param[in] 	text,{text}n

sub verbose {

	my $nb;
	my $type = $_[0];
	$nb = $#_ ;

	if ($type ne "debug" && $type ne "error" && $type ne "info" && $type ne "fatal" && $type ne "warn" && $type ne "trace" && $type ne "console") {
		print ("Wrong type used in verbose function... Exiting !\n");
		&quit();
	}

	if ($nb == 0) {
		print ("No text used in verbose function... Exiting !\n");
		&quit();
	}

	if ($type eq "trace") {
		for (my $i = 1; $i <= $nb ; $i++) {
			$log->trace($_[$i]);
		}
	} 

	if ($type eq "info") {
		for (my $i = 1; $i <= $nb ; $i++) {
			$log->info($_[$i]);
		}
	} 

	if ($type eq "warn") {
		for (my $i = 1; $i <= $nb ; $i++) {
			$log->warn($_[$i]);
		}
	} 

	if ($type eq "debug") {
		for (my $i = 1; $i <= $nb ; $i++) {
			$log->debug($_[$i]);
		}
	}  

	if ($type eq "error") {
		for (my $i = 1; $i <= $nb ; $i++) {
			$log->error($_[$i]);
		}
	} 

	if ($type eq "fatal") {
		for (my $i = 1; $i <= $nb ; $i++) {
			$log->fatal($_[$i]);
		}
	} 


	if ($verb) {

		if ($type eq "console") {
			print color('green');
		} 

		if ($type eq "trace") {
			print color('white');
		} 

		if ($type eq "info") {
			print color('white');
		} 

		if ($type eq "warn") {
			print color('yellow');
		} 

		if ($type eq "debug") {
			print color('bold blue');
		}  

		if ($type eq "error") {
			print color('red');
		} 

		if ($type eq "fatal") {
			print color('bold red');
		} 

		if ($type eq "fatal" || $type eq "error") {
			for (my $i = 1; $i <= $nb ; $i++) {
				print STDERR $_[$i]."\n";
			}
		} else {
			for (my $i = 1; $i <= $nb ; $i++) {
				print STDOUT $_[$i]."\n";
			}
		}

		print color('reset');
	
	}


	if ($type eq "fatal") {
		&quit();
	}


}

# Function used to print a structure
#	like table, hash or object
#	used only to develop
#
#	Exemple:
#	my %hash;
#	&dumping(\%hash);
#
#	param[in] 	ref to a structure

sub dumping {

	print color('red');
	print Dumper $_[0];
	print color('reset');

}


# Function used to quit properly

sub quit {

	exit;

}



##############
## Subfunctions
###################################################################