. "$(dirname "$0")/lib.sh"
export PATH=$HOME/lrz-demo/docker:$PATH DOCKER_HOST=unix:///run/user/1001/docker.sock
docker rmi -f $(docker images -q 'localhost:5000/hpc') >/dev/null 2>&1
cd $HOME/lrz-demo/envs/hpc
spack -e . mirror rm hpc-registry >/dev/null 2>&1
PROMPT_DIR="hpc-env"
say "a local registry for the demo; any OCI registry works (ghcr.io, GitLab, Harbor, ...)"
run "spack -e . mirror add --unsigned hpc-registry oci+http://localhost:5000/hpc"
say "push hdf5 and its runtime dependencies on top of ubuntu:26.04"
run "spack -e . buildcache push --without-build-dependencies --base-image ubuntu:26.04 --tag hdf5 hpc-registry hdf5"
pause 4
say "and run it like any other image"
run "docker run --rm localhost:5000/hpc:hdf5 h5dump --version"
say "the lstopo that failed on SLES 15 SP6 works here: the base image brings glibc 2.43"
run "docker run --rm localhost:5000/hpc:hdf5 lstopo --version"
end
