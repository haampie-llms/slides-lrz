. "$(dirname "$0")/lib.sh"
cd $HOME/lrz-demo/envs/hpc
PROMPT_DIR="hpc-env"
say "spack.yaml: what we asked for"
run "cat spack.yaml"
say "spack.lock: what we got"
run "jq '.concrete_specs | length' spack.lock"
run "spack -e . spec -l | cut -c 1-100 | head -13"
say "externals: nodes Spack did not build, with a prefix on *this* machine"
run "jq -c '.concrete_specs[] | select(.external) | {name, version, prefix: .external.path}' spack.lock"
end
