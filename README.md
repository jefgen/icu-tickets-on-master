# ICU Tickets on master

## Description:

This script generates a list of JIRA tickets made on the ICU '`master`' branch since
the last maintenance release (tagged with '`latest`').

It should be run on an up-to-date clone of the ICU repository (or fork) with the 'master' branch checked-out and up-to-date (ex: git pull).

Example Usage: `perl list-tickets.pl -query`

```
Options for output:
   -query   Outputs a JIRA Query JQL for copy/pasting into the 'Advanced' query box.
   -link    Outputs a link to a JIRA Query for copy/pasting into a web-browser.
   -list    Outputs a flat list of tickets, one per line.
```

### LICENSE

- Copyright (C) 2018 and later: Unicode, Inc. and others.
- License & terms of use: http://www.unicode.org/copyright.html
- see [LICENSE](LICENSE.txt)
