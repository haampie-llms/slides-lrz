. "$(dirname "$0")/lib.sh"
export PATH=$HOME/lrz-demo/docker:$PATH DOCKER_HOST=unix:///run/user/1001/docker.sock
cd $HOME/lrz-demo/envs/hpc; rm -f load.sh
PROMPT_DIR="hpc-env"
say "built on this laptop:"
run "ldd --version | head -1"
say "newest glibc symbol version each binary needs:"
run "objdump -T \$(spack -e . location -i python)/bin/python3 | grep -o 'GLIBC_[0-9.]*' | sort -uV | tail -1"
run "objdump -T \$(spack -e . location -i openblas)/lib/libopenblas.so | grep -o 'GLIBC_[0-9.]*' | sort -uV | tail -1"
say "run the very same files on SLES 15 SP6 (glibc 2.38) and Ubuntu 26.04 (2.43)"
run "spack -e . load --sh py-numpy > load.sh"
run "mount=\"-v \$HOME/lrz-demo:\$HOME/lrz-demo:ro -w \$PWD\""
run "docker run --rm \$mount registry.suse.com/bci/bci-base:15.6 bash -c '. ./load.sh; python3 --version; python3 -c \"import numpy\" 2>&1 | grep -o \"version .GLIBC_.*\" | head -1'"
run "docker run --rm \$mount ubuntu:26.04 bash -c '. ./load.sh; python3 -c \"import numpy; print(numpy.__version__)\"'"
rm -f load.sh
end
