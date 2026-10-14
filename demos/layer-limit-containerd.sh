. "$(dirname "$0")/lib.sh"
export PATH=$HOME/lrz-demo/docker:$PATH DOCKER_HOST=unix:///run/user/1001/docker.sock
docker rmi -f $(docker images -q) >/dev/null 2>&1
cd $HOME/lrz-demo/work
say "same synthetic images, Docker 29 default: containerd image store"
run "docker info --format '{{.Driver}} {{.DriverStatus}}'"
run "docker pull -q localhost:5000/layers:126 && docker run --rm localhost:5000/layers:126 echo ok"
run "docker pull -q localhost:5000/layers:499 && docker run --rm localhost:5000/layers:499 echo ok"
run "docker pull -q localhost:5000/layers:500 && docker run --rm localhost:5000/layers:500 echo ok 2>&1 | grep -o 'err: .*'"
end
