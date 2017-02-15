#!/usr/bin/env bash

ZABBIX_VERSION="3.2"
ZABBIX_URL="https://github.com/zabbix/zabbix-docker.git"
ZABBIX_TYPE="server"
ZABBIX_DB_TYPE="mysql"

DOCKER_IMAGE=turgon37/armhf-zabbix-${ZABBIX_TYPE}-${ZABBIX_DB_TYPE}
BUILD_TIME=$(date --rfc-2822)

echo "[[ Build ${DOCKER_IMAGE} docker image ]]"
echo '...Downloading Official x86 project'
git clone --branch "${ZABBIX_VERSION}" --single-branch "${ZABBIX_URL}" zabbix-docker

echo '...prepare the build'
for f in `ls -1 zabbix-docker/${ZABBIX_TYPE}-${ZABBIX_DB_TYPE}/alpine`; do
  ignore=false
  case $f in
    README*|LICENCE|build.sh|Dockerfile_armhf)
      ignore=true
      ;;
  esac
  if [ "$ignore" == 'false' ]; then
    cp --recursive zabbix-docker/${ZABBIX_TYPE}-${ZABBIX_DB_TYPE}/alpine/$f ./
    #echo zabbix-docker/${ZABBIX_TYPE}-${ZABBIX_DB_TYPE}/alpine/$f
  fi
done
# remove base image
sed -i -e 's|^FROM\s*.*$||g' Dockerfile
# remove declared maintainer
sed -i -e 's|^MAINTAINER\s*.*$||g' Dockerfile
# remove too more volume declarations
sed -i -e 's|^VOLUME\s*.*$||g' Dockerfile

# create fina ldockerfile
cat Dockerfile_armhf > Dockerfile_tmp

# add volume to the official dockerfile
volumes=`grep '^VOLUME' Dockerfile_armhf`
sed -i -e "s|\(ENTRYPOINT.*$\)|$volumes\n\1|" Dockerfile

# remove volume from custom dockerfile
sed -i -e 's|^VOLUME\s*.*$||g' Dockerfile_tmp

# append official dockerfile to the custom
cat Dockerfile >> Dockerfile_tmp

echo '...Build the images'
docker build --build-arg ZABBIX_VERSION="$ZABBIX_VERSION" \
             --build-arg BUILD_TIME="$BUILD_TIME" \
             --tag ${DOCKER_IMAGE}:${ZABBIX_VERSION} \
             --tag ${DOCKER_IMAGE}:latest \
             --file Dockerfile_tmp \
             .

docker push ${DOCKER_IMAGE}:latest

echo '...Clean the directory'
for f in `ls`; do
  remove=true
  case $f in
    README*|LICENCE|build.sh|Dockerfile_armhf)
      remove=false
      ;;
  esac
  if [ "$remove" == 'true' ]; then
    cp --recursive --preserve-root "./$f"
    #echo zabbix-docker/${ZABBIX_TYPE}-${ZABBIX_DB_TYPE}/alpine/$f
  fi
done
