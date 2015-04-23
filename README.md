misc
====

Just some stuff that oneday might be worth having.

 
 
#packageVersion.sh

bump the version of an R-package and optionally build tarball and add it to a drat repostiory

##Usage
```
Usage: packageVersion.sh -p package_dir [-dfsbrh] [-v new_version] [-u dratdir] [-m YYYY-MM-DD] 
    -p package_dir     select package directory
    -d                 bump version to daily
    -v new_version     specify new version number
    -f                 allow version number to be <= the old one
    -s                 simple roxygenisation off
    -b                 build package tarball
    -r                 do not (re)build package vignette
    -u dratdir         specify local drat repo: update drat repo
    -c                 commit changes in dratrepo (if it is a git repo)
    -o                 commit and push changes in datrepo (if it is a git repo)
    -m date            set custom release date (other than actual date) formatted as YYYY-MM-DD
    -h                 print this help
 
 Details: if -v and -d are not set, the tarball will be created and (if -u flag is set) added to the specified drat directory
 
``` 
 
#dratcleaner.sh

remove orphaned (not contained in PACKAGES file) tarballs from a drat repository
##Usage
```
Usage: dratcleaner.sh -d dratdir
    -u dratdir         specify local drat repo to remove orphanaged tarballs
 
```