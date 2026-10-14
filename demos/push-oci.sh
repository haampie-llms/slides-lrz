. "$(dirname "$0")/lib.sh"
cd $HOME/lrz-demo/envs/hpc
spack -e . mirror rm hpc-registry >/dev/null 2>&1
PROMPT_DIR="hpc-env"
say "a local registry for the demo; any OCI registry works (ghcr.io, GitLab, Harbor, ...)"
run "spack -e . mirror add --unsigned hpc-registry oci+http://localhost:5000/hpc"
say "first an image with only hdf5 and its runtime dependencies"
run "spack -e . buildcache push --without-build-dependencies --base-image ubuntu:26.04 --tag hdf5 hpc-registry hdf5"
say "then the whole environment"
run "spack -e . buildcache push --without-build-dependencies --base-image ubuntu:26.04 --tag hpc-env hpc-registry"
end
