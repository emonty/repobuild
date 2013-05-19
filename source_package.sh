package=$1
branch=$2
targetdist=${3:-precise}
company=${4:-hp}
org=`dirname $package`
basename=`basename $package`
basedir=`pwd`

if [ ! -d $org ] ; then
    mkdir $org
fi
cd $org
if [ ! -d $basename ] ; then
    git clone https://review.mnorp.com/p/$package
else
    git remote update
fi

cd $basename
git reset --hard origin/$branch
version=`python setup.py --version`
safe_version=`echo $version | sed 's/\.[A-Za-z]/~/'`
short_version=`echo $safe_version | sed 's/~.*//'`
version_suffix="0${company}1$targetdist"
distro=`echo $branch | sed 's/\//-/g'`

rm -rf dist/*tar.gz
python setup.py sdist
cd dist
mv *tar.gz ${basename}_$safe_version.orig.tar.gz

if [ ! -d grizzly ] ; then
    bzr branch lp:~openstack-ubuntu-testing/$basename/grizzly
fi
rm -rf build-area
cd grizzly
bzr pull --overwrite

echo yes | DEBEMAIL=review@mnorp.com DEBFULLNAME='mnorp CI' dch -b -D $distro -v "1:$safe_version-$version_suffix" "Build of $safe_version"
debcommit
bzr bd --builder='debuild -S -uc -us'
cd ../build-area
python $basedir/binary_package.py *dsc
