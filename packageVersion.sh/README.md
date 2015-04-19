#packageVersion.sh

bump the version of an R-package and optionally build tarball and add it to a drat repostiory

##Usage
```
packageVersion.sh -p package_dir [-d ] [-v new_version][ -h] [-f ] [-s] [-b] [-u dratdir] [-h]
 
    -p package_dir     select package directory
    -d                 bump version to daily
    -v new_version     specify new version number
    -f                 allow version number to be <= the old one
    -s                 simple roxygenisation off
    -b                 build package tarball
    -u dratdir         specify local drat repo: update drat repo
    -h                 print this help
```
