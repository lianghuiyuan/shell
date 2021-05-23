#!/bin/bash
URL="https://harbor.xxxx.com"
USER="admin"
PASS="Harbor12345"
PRO="library"
HARBOR_PAHT="/iba/harbor"

# 查询有哪些project(project_id)
# curl -vvv -u "user:password" -X GET -H "Content-Type: application/json" "https://harbor.xxxx.com/api/projects" | grep "project_id" | awk -F '[:, ]' '{print $7}'

# 通过 projects_id 获取 repositories
# curl -vvv -u "user:password" -X GET -H "Content-Type: application/json" "https://harbor.xxxx.com/api/repositories?project_id=2" | grep "name" | awk -F '"' '{print $4}'



# 软删除 harbor tags
del_tags()
{
    echo "软删除 ${rp}/${t}"
    curl -X DELETE -H 'Accept: text/plain' -u ${USER}:${PASS} "${URL}/api/repositories/${rp}/tags/${t}"

}

# 硬删除 harbor tags
har_del_tags()
{
   cd ${HARBOR_PAHT}
   docker-compose -f docker-compose.yml -f docker-compose.clair.yml stop
   docker run -it --name gc --rm --volumes-from registry vmware/registry:2.6.2-photon garbage-collect /etc/registry/config.yml
   docker-compose -f docker-compose.yml -f docker-compose.clair.yml start
}


# 获取 project id
PID=$(curl -s -X GET --header 'Accept: application/json' "${URL}/api/projects"|grep -w -B 2 "${PRO}" |grep "project_id"|awk -F '[:, ]' '{print $7}')
#echo ${PID}

# 拿获取到的 projects_id 获取 repositories
REPOS=$(curl -s -X GET --header 'Accept: application/json' "${URL}/api/repositories?project_id=${PID}"|grep "name"|awk -F '"' '{print $4}')
for rp in ${REPOS}
do
    echo ${rp}

    TAGS=$(curl -s -X GET --header 'Accept: application/json' "${URL}/api/repositories/${rp}/tags"|grep \"name\"|awk -F '"' '{print $4}'|sort -r |awk 'NR > 9 {print $1}')

    for t in ${TAGS}
    do
        echo ${t}
        del_tags
    done

    echo "===================="
done

har_del_tags