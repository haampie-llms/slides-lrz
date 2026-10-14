. "$(dirname "$0")/lib.sh"
export PATH=$HOME/lrz-demo/docker:$PATH DOCKER_HOST=unix:///run/user/1001/docker.sock
cd $HOME/lrz-demo/envs/hpc
PROMPT_DIR="hpc-env"
say "now the whole environment: hdf5 and its dependencies are already in the registry"
run "spack -e . buildcache push --without-build-dependencies --base-image ubuntu:26.04 --tag hpc-env hpc-registry"
pause 4
run "docker pull -q localhost:5000/hpc:hpc-env"
run "docker run --rm localhost:5000/hpc:hpc-env python3 -c 'import h5py; print(h5py.version.info)'"
run "docker run --rm localhost:5000/hpc:hpc-env mpiexec -n 4 python3 -c 'from mpi4py import MPI; print(\"rank\", MPI.COMM_WORLD.rank)'"
end
