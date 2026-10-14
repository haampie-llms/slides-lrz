. "$(dirname "$0")/lib.sh"
export PATH=$HOME/lrz-demo/docker:$PATH DOCKER_HOST=unix:///run/user/1001/docker.sock
docker rmi -f $(docker images -q 'localhost:5000/hpc') >/dev/null 2>&1
cd $HOME/lrz-demo/work
PROMPT_DIR=""
run "time docker pull -q localhost:5000/hpc:hpc-env"
run "docker run --rm localhost:5000/hpc:hpc-env python3 -c 'import h5py; print(h5py.version.info)'"
run "docker run --rm localhost:5000/hpc:hpc-env mpiexec -n 4 python3 -c 'from mpi4py import MPI; print(\"rank\", MPI.COMM_WORLD.rank)'"
say "the hdf5 image only has layers that are already here"
run "time docker pull -q localhost:5000/hpc:hdf5"
end
