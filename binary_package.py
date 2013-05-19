import datetime
import os
import shlex
import subprocess
import sys

from debian import deb822

extra_repos = """deb http://repo.mnorp.com %s main
deb http://archive.ubuntu.com/ubuntu precise-updates main universe
deb http://archive.ubuntu.com/ubuntu precise main universe"""

def run_command_status(*argv, **env):
    print datetime.datetime.now(), "Running:", " ".join(argv)
    if len(argv) == 1:
        argv = shlex.split(str(argv[0]))
    newenv = os.environ
    newenv.update(env)
    p = subprocess.Popen(argv,
                         stderr=subprocess.STDOUT, env=newenv)
    (out, nothing) = p.communicate()
    return (p.returncode, out)


def main():
    global extra_repos
    dsc_file = sys.argv[1]
    changes_file = dsc_file.replace('.dsc', '_source.changes')
    changes = deb822.Changes(open(changes_file, 'r'))
    distro = changes.get('Distribution')
    repo = distro.replace('-', '/')
    basetgz = "/root/%s.tgz" % distro

    if not os.path.exists(basetgz):
        run_command_status(
            "pbuilder", "--create", "--basetgz", basetgz,
            "--othermirror",
            extra_repos % repo,
            "--override-config")

    os.mkdir('output')

    run_command_status(
        "pbuilder", "--build", "--allow-untrusted",
        "--buildresult", os.path.abspath('output'),
        "--basetgz", basetgz, dsc_file,
        DEB_BUILD_OPTIONS='nocheck')

    #reprepro --ignore=wrongdistribution -Vb /var/www include $branch output/*changes

if __name__ == '__main__':
    main()
