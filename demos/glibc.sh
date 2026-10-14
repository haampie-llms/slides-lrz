. "$(dirname "$0")/lib.sh"
export PATH=$HOME/lrz-demo/docker:$PATH DOCKER_HOST=unix:///run/user/1001/docker.sock
cd $HOME/lrz-demo/envs/hpc
PROMPT_DIR="hpc-env"
say "lstopo from hwloc, built with Spack on this laptop"
run "ldd --version | head -1"
run "lstopo=\$(spack -e . location -i hwloc)/bin/lstopo"
run "\$lstopo --version"
say "the very same file on SLES 15 SP6 (mounted at the same path)"
run "docker run --rm -v ~/lrz-demo:\$HOME/lrz-demo registry.suse.com/bci/bci-base:15.6 ldd --version | head -1"
run "docker run --rm -v ~/lrz-demo:\$HOME/lrz-demo registry.suse.com/bci/bci-base:15.6 \$lstopo --version"
pause
end
