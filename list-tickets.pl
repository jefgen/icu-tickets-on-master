#!/usr/bin/perl
# Copyright (C) 2018 and later: Unicode, Inc. and others.
# License & terms of use: http://www.unicode.org/copyright.html 
#
# Author: jefgen
#
# Description:
#  This script is used to collect a list of JIRA tickets made on the ICU 'master' branch since
#  the last "maintenance" release (tagged with 'latest').
#
#  It should be run on an up-to-date clone of the ICU repository (or fork) with the 'master' branch
#  checked-out and up-to-date (git pull). 
#
use strict;
use warnings;
use utf8;

# Globals
my %tickets;
# Output settings.
my $outputJiraQuery = 0;
my $outputJiraLink = 0;
my $outputJiraListing = 0;

sub printUsage
{
    print "This script generates a list of JIRA tickets made on the ICU 'master' branch since \n";
    print "the last maintenance release (tagged with 'latest').  It should be run on an up-to-date\n";
    print "clone of the ICU repository (or fork) with the 'master' branch checked-out and up-to-date.\n\n";
    print "Example Usage: perl list-tickets.pl -query\n\n";
    print "Options for output:\n";
    print "   -query   Outputs a JIRA Query JQL for copy/pasting into the 'Advanced' query box.\n";
    print "   -link    Outputs a JIRA Query JQL for copy/pasting into the 'Advanced' query box.\n";
    print "   -list    Outputs a flat list of tickets, one per line.\n";
    print "\n";
}

sub parseArgs
{
    foreach my $arg (@ARGV)
    {
        if ($arg =~ /-query/i)
        {
            $outputJiraQuery = 1;
        }
        if ($arg =~ /-link/i)
        {
            $outputJiraLink = 1;
        }
        if ($arg =~ /-list/i)
        {
            $outputJiraListing = 1;
        }
    }
    if (!($outputJiraQuery || $outputJiraLink || $outputJiraListing))
    {
        printUsage();
        exit;
    }
}

sub uri_encode
{
    my $string = shift;
    $string =~ s/([^^A-Za-z0-9\-_.!~*'()])/ sprintf "%%%02x", ord $1 /eg;
    return $string;
}

# Simple helper to remove both leading and trailing white-space.
sub trim
{
    my $string = shift;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}

# Look for ticket numbers (ICU-1234) at the beginning of a string, and ignore any
# ticket numbers that occur later on in the string.
# The reason for this is that people will sometimes mention and/or refer to other
# tickets in the commit body text and we don't want to pick-up on those tickets as
# they might be older tickets, committed long ago.
#
# Input: string of text
# Return: array of tickets, if no tickets are found returns an empty array.
sub findTickets
{
    my $text = shift;
    my @tickets;
    
    if ($text eq '')
    {
        return @tickets;
    }
    
    $text = trim($text);
    my @parts = split(/\s+/, $text);
    
    if (scalar(@parts))
    {
        foreach (@parts)
        {
            if ($_ =~ /ICU-([0-9]+)/)
            {
                #print ' Found ticket '. $1 ."\n";
                push @tickets, $1;
            }
            else
            {
                # Stop once we hit something other than ticket numbers in the text.
                last;
            }
        }
    }
    
    return @tickets;
}

# Have git output all of the commits on the 'master' branch from the tag 'latest'.
#
# Notes:
#  - The tag 'latest' refers to the most recent maintenance commit on the 'maint/maint-*' branch. 
#  About the arguments to git:
#  - "no-decorate"      Don't show refs or local branches in the output, we just want the commit titles.
#  - "oneline"          Output oneline per commit.
#  - "no-abbrev-commit" Show the full SHA1 hash, don't abbreviate it.
#
# The output will look like this:
#   aa9e98758b447c32731906acfb6fcf137dfa7b98 ICU-13645 Add C++11 move constructor and assign operator to Locale.
#   30f737b09d5e9a2940545ac9efb7acce09cd5e3f ICU-20043 ICU-13214 ICU-13764 MSVC W3 and W4 warning cleanup (#53)
#   ...
sub parseGitLogOutput
{
    my $output = `git log --oneline --no-decorate --no-abbrev-commit latest..master`;

    foreach my $line (split(/\n/, $output))
    {
        my ($sha1, $title) = ($line =~ /^([a-f0-9]{40}) (.+)$/);
        $title = trim($title);
        
        if ($title eq '')
        {
            print 'Error: No commit title for: \''. $sha1 ."'\n";
            continue;
        }
        
        my @tickets = findTickets($title);
        
        # Check if no tickets found in the title.
        if (scalar(@tickets) == 0)
        {
            # If we could not find any ticket numbers in the title, try looking at the full commit
            # body message, but only if the commit was a merge commit.
            # We want to look at merge commits as sometimes people make a merge commit that has
            # the ticket number in the message, but the auto-generated title does not.
            
            if ($title =~ /^Merge pull request/i)
            {
                my $cmd = 'git show -s --format=%b '. $sha1;
                my $commitMessage = `$cmd`;
                @tickets = findTickets($commitMessage);
                
                if (scalar(@tickets) == 0)
                {
                    print 'Warning: Could not find a ticket number in the title or commit body message! \''. $line ."'\n";
                }
                else
                {
                    # print 'Found ticket number(s) in the commit body message. \''. $line ."'\n";
                }
            }
            else
            {
                print 'Warning: Could not find any tickets for commit: \''. $line ."'\n";
            }
        }
        
        # print 'Found '. scalar(@tickets) .' ticket(s)'."\n";
        
        foreach my $ticketNumber (@tickets)
        {
            $tickets{'ICU-'.$ticketNumber} = $sha1;
        }
    }
}

sub outputJiraQuery
{
    # JIRA Query syntax looks like this:
    #  ' project = ICU AND issuekey IN ("ICU-7270", "ICU-8151", "ICU-8966") '
    
    my $jiraQuery = 'project = ICU AND issuekey IN ("'. join('", "', (keys %tickets)) . '")';
    print "\n";
    print "JIRA Query for pasting into the 'Advanced' search box: \n\n";
    print ' '. $jiraQuery." \n\n";
}

sub outputJiraLink
{
    my $jiraQuery = ' = ICU AND issuekey IN ("'. join('", "', (keys %tickets)) . '")';
    my $link = 'https://unicode-org.atlassian.net/issues/?jql=project'. uri_encode($jiraQuery);
    print "\n";
    print "JIRA Link to advanced query with the tickets:\n";
    print ' '. $link ."\n\n";
}

sub outputJiraListing
{
    print "\n";
    print join("\n", (keys %tickets));
    print "\n";
}

sub outputResults
{
    if ($outputJiraQuery)
    {
        outputJiraQuery();
    }
    if ($outputJiraLink)
    {
        outputJiraLink();
    }
    if ($outputJiraListing)
    {
        outputJiraListing();
    }
}

print "\n";

parseArgs();
parseGitLogOutput();
outputResults();
