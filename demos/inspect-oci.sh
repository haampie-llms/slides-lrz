. "$(dirname "$0")/lib.sh"
cd $HOME/lrz-demo/work
PROMPT_DIR=""
say "the registry now has one tag per package, plus our two image tags"
run "skopeo list-tags --tls-verify=false docker://localhost:5000/hpc"
pause
say "the hpc-env image: base image layers + one layer per package"
run "skopeo inspect --tls-verify=false docker://localhost:5000/hpc:hpc-env | jq '.Layers | length'"
say "its config sets the environment, pointing into each package prefix (first entry shown)"
run "skopeo inspect --tls-verify=false --config docker://localhost:5000/hpc:hpc-env | jq -r '.config.Env[]' | cut -d: -f1"
pause
end
