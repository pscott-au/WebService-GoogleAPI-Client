# When hacking on this repo

There are some live tests in `xt/` which require real user credentials. All they
do is create a file in Google Drive, and then delete it, in order to make sure that 
things are ACTUALLY running.

# Bug Reporting and General Help Requests

- Use the [Github Issues Page](https://github.com/rabbiveesh/WebService-GoogleAPI-Client/issues) 

## Github Repo Management

- Aspiring to [Trunk Based Developent](https://paulhammant.com/2013/04/05/what-is-trunk-based-development/)
- Relase branches are created when package is published to CPAN ( starting V1.12 )


# CONTRIBUTING CODE

- There remain a few architectural bad smells from the original source code this was based on - don't assume that the class structure is sane
- Pull reqeusts preferred but whatever works for you I will try to work with

# HELP WANTED 

- Seek reviews from http://prepan.org/module.submit and similar
- refactor to improve test coverage
- clean up the test structure
- survey other Google Perl modules
- implement batch requests - really an interface question more than the
  technicalities
- API worked examples with help functions
- ability to examine CHI cache and introspect on Client instance metrics ( number of HTTP calls, cache size, TTL data sent/received etc )
- comparison with other language Client libraries
- The structure under the AuthStorage is ugly and needs some love


Github Repo: [https://github.com/pscott-au/WebService-GoogleAPI-Client]

## A few notes
`dzil cover -outputdir docs/cover/`
