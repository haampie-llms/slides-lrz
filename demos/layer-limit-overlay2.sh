. "$(dirname "$0")/lib.sh"
export PATH=$HOME/lrz-demo/docker:$PATH DOCKER_HOST=unix:///run/user/1001/docker.sock
docker rmi -f $(docker images -q) >/dev/null 2>&1
cd $HOME/lrz-demo/work
say "synthetic images: ubuntu:26.04 (2 layers) + N tiny layers"
run "docker info --format '{{.Driver}}'"
run "skopeo inspect --tls-verify=false docker://localhost:5000/layers:126 | jq '.Layers|length'"
run "docker pull -q localhost:5000/layers:125 && docker run --rm localhost:5000/layers:125 echo ok"
run "docker pull -q localhost:5000/layers:126"
end
