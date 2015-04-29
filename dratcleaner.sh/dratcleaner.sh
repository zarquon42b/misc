#! /bin/bash

function usage {
    
    echo " "
    echo " Usage: dratcleaner.sh -d dratdir"
    echo "    -u dratdir         specify local drat repo to remove orphanaged tarballs"
    echo " "
    exit 1
}
while getopts ":d:" opt; do
    case "$opt" in
        d)  dratdir=$(realpath $OPTARG);;

	: ) echo "Missing option argument for -$OPTARG" >&2; exit 1
    esac
done
if [ -z $dratdir ];then
    usage
    echo "   ERROR: no drat dir selected"
    exit 1
fi
if [ ! -e $dratdir/src/contrib/PACKAGES ];then
    usage
    echo "   ERROR: this is not a drat dir"
    exit 1
fi


pckgname=($(grep ^Package: $dratdir/src/contrib/PACKAGES | awk 'BEGIN {FS=":"};{print $2}'))

pckversion=($(grep ^Version: $dratdir/src/contrib/PACKAGES | awk 'BEGIN {FS=":"};{print $2}'))

n=${#pckversion[@]} 

for (( i=0; i<n; i++ ))
do
    comb0=${pckgname[$i]}_${pckversion[$i]}".tar.gz"
    comb2="$comb2  $comb0"
    
done

tarballs=$(ls "$dratdir/src/contrib/" | grep tar.gz)

for i in $tarballs; do
    if [[ $comb2 =~ $i ]];then
	echo 'yes'
    else 
	rm $dratdir/src/contrib/$i
	echo "removed orphaned $i"
    fi 
done

