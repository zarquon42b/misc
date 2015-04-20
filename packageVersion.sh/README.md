#packageVersion.sh

bump the version of an R-package and optionally build tarball and add it to a drat repostiory

##Usage
```

 Usage: packageVersion.sh -p package_dir [-d ] [-v new_version][ -h] [-f ] [-s] [-b] [-r] [-u dratdir] [-h]
 
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
    -h                 print this help

 
 Details: if -v and -d are not set, the tarball will be created and (if -u flag is set) added to the specified drat directory

 ```
