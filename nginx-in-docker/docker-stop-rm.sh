#/bin/sh
set -e
containers_to_rm_list=$(docker ps -a -q --filter ancestor="$1" --format="{{.ID}}")
if [[ -n "$containers_to_rm_list" ]]; then
  echo $containers_to_rm_list | xargs -L1 docker stop
  echo $containers_to_rm_list | xargs -L1 docker rm 
fi

