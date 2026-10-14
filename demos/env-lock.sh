. "$(dirname "$0")/lib.sh"
cd $HOME/lrz-demo/envs/hpc
spack -e . mirror rm hpc-registry >/dev/null 2>&1
cat > spack.yaml <<'YAML'
spack:
  specs:
  - hdf5+mpi
  - mpich
  - py-h5py
  view: false
  concretizer:
    unify: true
YAML
PROMPT_DIR="hpc-env"
say "spack.yaml: what we asked for"
run "cat spack.yaml"
say "spack.lock: what we got. It's just JSON"
run "jq .roots spack.lock"
say "two nodes in the lock file were not built by Spack"
run "spack -e . find --external --paths"
end
