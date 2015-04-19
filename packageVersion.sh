#! /bin/bash
pckgname="nix"

function usage {
    echo " "
    echo "usage: changeGen -p package_dir [-d ] [-v ][ -h] [-f ] [-s] [-b] [-h]"
    echo " "
    echo "    -p package_dir     select package directory"
    echo "    -d                 bump version to daily"
    echo "    -f                 allow version number to be <= the old one"
    echo "    -s                 simple roxygenisation off"
    echo "    -b                 build package tarball"
    echo "    -u dratdir         specify local drat repo: update drat repo"
    echo "    -h                 print this help"
    echo " "
    
    exit
}

roxypox () {

if [ -z $1 ];then
    type="fast"
else
    type=$2
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
while getopts "p:v:dhfsbu:" opt; do
    case "$opt" in
        p)
            packagedir=$OPTARG
	    VPNNAME=$(nmcli -t -f NAME,uuid c| grep "$VPNNAME" |cut -d ":" -f1 | head -1)

            ;;
        v)  newvn=$OPTARG
            ;;
	d) daily=1
	    ;;
	h)
	    usage
	    ;;
	f)
	    force=1
	   ;;
	s)
	    simple="full"
	    ;;
	b)
	    build=1
	    ;;
	u)
	    dratdir=$OPTARG
	    
    esac
done
roxymeth="full"

if [ -z $packagedir ];then
    echo "  please select package directory"
    usage
    exit 1
fi
echo "  Selected directory is $packagedir"



origdir=$(pwd)
cd $packagedir
pckgname=$(grep Package: DESCRIPTION | awk 'BEGIN {FS=":"};{print $2}')
pckgname="$(echo -e "${pckgname}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
### select package to build
if [ ! -e "R/$pckgname-package.R" ];then
    noR=1
    echo "  No file named $pckgname-package.R found"
    #exit 1
    
fi
echo "Updating $pckgname"
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
else

    echo " Please enter a version number!" 
    echo " Current $vn" 
    usage
    exit 1
fi

echo "  new version is $version"
echo "  old version is $origversion"
echo $(testvercomp $version $origversion ">")
if [ $(testvercomp $version $origversion ">") == "fail" ] && [ $force == 0 ]; then
    echo "  New version not higher than old one"
    echo "  you can force a downgrade using the -f flag"
    
    exit 1
    
fi
if [ -e R/$pckgname-package.R ];then
    target="R/$pckgname-package.R"
    
    echo "   * doing stuff using roxygen2"
    sed -i "s/Version: \\\tab *.*.*\\\cr/Version: \\\tab $version\\\cr/g" $target
    sed -i "s/Date: \\\tab *.*.*\\\cr/Date: \\\tab $dat\\\cr/g" $target
    roxypox  $simple
fi
#fi

sed -i "s/Version: *.*.*.*/Version: $version/g" DESCRIPTION
sed -i "s/Date: *.*.*/Date: $dat/g" DESCRIPTION

### build tarball
if [ ! -z $build ];then
    cd $origdir
    tarball=$(pwd)/$pckgname"_"$version".tar.gz"
    echo "  Creating tarball $pckgname _$version.tar.gz"
    R CMD build $packagedir
fi

if [ ! -z $dratdir ];then
    echo "  * Updating drat repo at $dratdir"
    Rscript -e "drat::insertPackage('$tarball','$dratdir')"
    
fi
