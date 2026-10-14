. "$(dirname "$0")/lib.sh"
rm -rf $HOME/lrz-demo/c $HOME/lrz-demo/machines/c; mkdir -p $HOME/lrz-demo/machines/c; cd $HOME/lrz-demo/machines/c
PROMPT_HOST="machine-c"; PROMPT_DIR=""
say "another machine, no Docker needed: the registry is just a build cache"
run "spack env create -d my-env ~/lrz-demo/envs/hpc/spack.lock"
run "spack -e my-env mirror add --unsigned hpc-registry oci+http://localhost:5000/hpc"
run "spack -e my-env config add config:install_tree:root:~/lrz-demo/c"
run "spack -e my-env install"
end
