#! /bin/bash
pckgname="nix"

function usage {
    echo " "
    echo " Usage: packageVersion.sh -p package_dir [-d ] [-v new_version][ -h] [-f ] [-s] [-b] [-r] [-u dratdir] [-h]"
    echo " "
    echo "    -p package_dir     select package directory"
    echo "    -d                 bump version to daily"
    echo "    -v new_version     specify new version number"
    echo "    -f                 allow version number to be <= the old one"
    echo "    -s                 simple roxygenisation off"
    echo "    -b                 build package tarball"
    echo "    -r                 do not (re)build package vignette"
    echo "    -u dratdir         specify local drat repo: update drat repo"
    echo "    -c                 commit changes in dratrepo (if it is a git repo)"
    echo "    -o                 commit and push changes in datrepo (if it is a git repo)"
    echo "    -h                 print this help"
    echo " "
    echo " Details: if -v and -d are not set, the tarball will be created and (if -u flag is set) added to the specified drat directory"
    echo " "
    
    exit
}

roxypox () {

    if [ -z $1 ];then
	type="fast"
    else
	type=$1
    fi

    if [ $type == "full" ]; then
	Rscript -e 'require(devtools);require(methods);document(".")'
    else
	Rscript -e 'require(roxygen2);require(methods);roxygenise(".")'
    fi

}
stripspace () {
    stripit=$(echo -e "${1}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    echo "$stripit"
}
vercomp () {
    if [[ $1 == $2 ]]
    then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            return 2
        fi
    done
    return 0
}

testvercomp () {
    vercomp $1 $2
    case $? in
        0) op='=';;
        1) op='>';;
        2) op='<';;
    esac
    
    if [[ $op != $3 ]]
    then
        echo "fail"
    else
        echo "pass"
    fi
}

daily=0
force=0
while getopts ":p:v:dhfsbru:co" opt; do
    case "$opt" in
        p)  packagedir=$OPTARG;;
        v)  newvn=$OPTARG ;;
	d)  daily=1;;
	h)  usage;;
	f)  force=1;;
	s)  simple="full";;
	b)  build=1
	    remove=0
	    ;;
	r)  Ropts="--no-build-vignettes ";;
	u)  dratdir=$OPTARG
	    build=2
	    ;;
	c) commit=1;;
	o) push=1
	    commit=1
	    ;;
	: ) echo "Missing option argument for -$OPTARG" >&2; exit 1
	    
    esac
done
roxymeth="full"

if [ -z $packagedir ];then
    echo "   ERROR: please select package directory"
    usage
    exit 1
fi
echo "   INFO: Selected directory is $packagedir"



origdir=$(pwd)
cd $packagedir
pckgname=$(grep ^Package: DESCRIPTION | awk 'BEGIN {FS=":"};{print $2}')
pckgname="$(echo -e "${pckgname}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
### select package to build
if [ ! -e "R/$pckgname-package.R" ];then
    noR=1
    echo "   INFO: No file named $pckgname-package.R found"
    #exit 1
    
fi

dat=$(date +%Y-%m-%d)
datstring=$(date +%y%m%d)


vn=$(grep Version: DESCRIPTION)
prev=${vn/Version: /}
prev=$(stripspace $prev)
origversion=$prev
### check for version number ###

if [ $daily == 1 ]; then
    
    laststring=${prev##*.}
    if [ ${#laststring} == 6 ]; then
	prev=${prev%.*}
    fi
    version="$prev.$datstring"
    
elif [ ! -z $newvn ];then
    version=$newvn
elif [ -z $build ];then

    echo "   ERROR: Please enter a version number!" 
    echo "   Current $vn" 
    usage
    exit 1
fi
if [ ! -z $version ];then
    echo "   INFO: Changing $pckgname to version $version"
    echo "   INFO: new version is $version"
    echo "   INFO: old version is $origversion"
    #echo $(testvercomp $version $origversion ">")
    if [ $(testvercomp $version $origversion ">") == "fail" ] && [ $force == 0 ]; then
	echo "   ERROR: New version not higher than old one"
	echo "   you can force a downgrade using the -f flag"
	
	exit 1
	
    fi
    if [ -e R/$pckgname-package.R ];then
	target="R/$pckgname-package.R"
	
	echo "   INFO: Found file $target. Update and roxygenize $pckgname"
	sed -i "s/Version: \\\tab *.*.*\\\cr/Version: \\\tab $version\\\cr/g" $target
	sed -i "s/Date: \\\tab *.*.*\\\cr/Date: \\\tab $dat\\\cr/g" $target
	roxypox  $simple 
	
    fi
    #fi

    sed -i "s/Version: *.*.*.*/Version: $version/g" DESCRIPTION
    sed -i "s/Date: *.*.*/Date: $dat/g" DESCRIPTION
else 
    echo "   INFO: No version bump requested"
fi

### build tarball
if [ ! -z $build ];then
    cd $origdir
    if [ ! -z $version ];then
	tarball=$(pwd)/$pckgname"_"$version".tar.gz"
    else
	tarball=$(pwd)/$pckgname"_"$origversion".tar.gz"
    fi
    echo " "
    echo "  INFO: Creating tarball $tarball"
    echo " "
    
    R CMD build $Ropts$packagedir 
fi

if [ ! -z $dratdir ];then
    if [ -d $dratdir/.git ]; then
	gitrepo=1
	echo " "
	echo "  INFO: Git repo found"
	cd $dratdir
	## check if a gh-pages branch exists
	curbranch=$(git rev-parse --abbrev-ref HEAD)
	ghp=$(git branch | cut -c 3- | grep gh-pages)
	if [ ! -z $ghp ];then
	    if  [ $ghp != $curbranch ];then
		echo "   INFO: checking out branch gh-pages"
		git checkout gh-pages
		ghchange=1
	    fi
	fi
    fi
    echo "  INFO: Updating drat repo at $dratdir"
    Rscript -e "drat::insertPackage('$tarball','$dratdir')"
    if [ -z $remove ];then
	echo "  INFO: removing $tarball as only a drat update is requested"
	rm $tarball
    fi
    if [ ! -z $commit ];then
	cd $dratdir
	git add src/contrib/$(basename $tarball)
	echo " "
	echo "  INFO: Commiting $(basename $tarball)"
	echo " "
	git commit -a -m "added version $version of $pckgname"
	if [ ! -z $push ];then
	    git push
	fi
    fi
    if [ ! -z $ghchange ];then
	echo " "
	if [ -z $commit ];then
	    echo "   INFO: Please commit your changes before changing back to branch $curbranch"
	else
	    echo "   INFO: Switching back to $curbranch"
	    git checkout $curbranch
	fi
    fi
fi
