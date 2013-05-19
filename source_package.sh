package=$1
branch=$2
org=`dirname $package`
basename=`basename $package`
basetgz=`echo $branch | sed 's/\//./g'`.tgz

basedir=`pwd`
if [ ! -f $basetgz ] ; then
    pbuilder --create --basetgz hp.grizzly.2013.1.1.tgz \
        --othermirror "deb http://repo.mnorp.com $branch main
deb http://archive.ubuntu.com/ubuntu precise-updates main universe
deb http://archive.ubuntu.com/ubuntu precise main universe" --override-config
fi

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
rm -rf dist/*tar.gz
python setup.py sdist
version=`python setup.py --version`
safe_version=`echo $version | sed 's/\.[A-Za-z]/~/'`
short_version=`echo $safe_version | sed 's/~.*//'`
distro=`echo $branch | sed 's/\//-/g'`
cd dist
mv *tar.gz ${basename}_$safe_version.orig.tar.gz

if [ ! -d grizzly ] ; then
    bzr branch lp:~openstack-ubuntu-testing/$basename/grizzly
fi
rm -rf build-area
cd grizzly
bzr pull --overwrite

echo yes | DEBEMAIL=review@mnorp.com DEBFULLNAME='mnorp CI' dch -b -D $distro -v "1:$safe_version-0hp1" "Build of $safe_version"
debcommit
bzr bd --builder='debuild -S -uc -us'
cd ../build-area
python /root/binary_package.py *dsc
