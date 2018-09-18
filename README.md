# ICU Tickets on master

## Description:

This script generates a list of JIRA tickets made on the ICU 'master' branch since
the last maintenance release (tagged with 'latest').  It should be run on an up-to-date
clone of the ICU repository (or fork) with the 'master' branch checked-out and up-to-date.

Example Usage: perl list-tickets.pl -query

Options for output:
   -query   Outputs a JIRA Query JQL for copy/pasting into the 'Advanced' query box.
   -link    Outputs a JIRA Query JQL for copy/pasting into the 'Advanced' query box.
   -list    Outputs a flat list of tickets, one per line.