. "$(dirname "$0")/lib.sh"
rm -rf $HOME/lrz-demo/cache $HOME/lrz-demo/b $HOME/lrz-demo/machines/b; mkdir -p $HOME/lrz-demo/machines/b
cd $HOME/lrz-demo/envs/hpc
PROMPT_DIR="hpc-env"
say "push the installed environment to a build cache on a shared file system"
run "spack -e . buildcache push --unsigned --without-build-dependencies ~/lrz-demo/cache"
pause
cd $HOME/lrz-demo/machines/b
PROMPT_HOST="machine-b"; PROMPT_DIR=""
say "another machine: just the lock file + access to the build cache"
run "spack env create -d my-env ~/lrz-demo/envs/hpc/spack.lock"
run "spack -e my-env mirror add --unsigned cache ~/lrz-demo/cache"
run "spack -e my-env config add config:install_tree:root:~/lrz-demo/b"
run "spack -e my-env install"
pause
end
