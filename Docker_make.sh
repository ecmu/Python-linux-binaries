#!/usr/bin/env bash
#set -x #echo on
#set -e #Exists on errors

#region === Parse script arguments

DOCKER_IMAGE_NAME=python
GITHUB_REF_NAME=3.13.5
DOCKER_RESET=0

usage()
{
  cat << EOF
  Usage: 
    $0 [--DockerImageName=newName] [--GithubRefName=value] [--DockerReset=value] [--help|-h]

    --DockerImageName=newName  Nouveau nom pour l'image docker. Default = ${DOCKER_IMAGE_NAME}.
    --GithubRefName=value      Version python à compiler, définit la variable d'environnement GITHUB_REF_NAME? Défaut = $GITHUB_REF_NAME.
    --DockerReset=value        Faut-il réinitialiser l'image Docker (1 = Oui / Toute autre valeur = Non) ? Défaut = $DOCKER_RESET.
    --help|-h                  print this help and quit.
EOF
}

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --DockerImageName=*)  DOCKER_IMAGE_NAME="${1#*=}" ;;
    --DockerReset=*)      DOCKER_RESET="${1#*=}" ;;
    --help|-h)            usage && exit 0 ;;
    #*) usage ;;
  esac
  shift
done

#Mandatory arguments
#if [ "$TARGET" == "" ]; then
#  echo "Missing mandatory argument(s)..."
#  usage
#fi

echo "Version python compilée = $GITHUB_REF_NAME"
export GITHUB_REF_NAME

#endregion

SCRIPTPATH=$(cd $(dirname "$BASH_SOURCE") && pwd)
pushd "$SCRIPTPATH"

if [ "$DOCKER_RESET" == "1" ] || [ "$(docker image ls ${DOCKER_IMAGE_NAME} | grep ${DOCKER_IMAGE_NAME})" == "" ]
then
  echo "Deleting existing container '${DOCKER_IMAGE_NAME}'..."
  docker stop ${DOCKER_IMAGE_NAME}
  docker rm ${DOCKER_IMAGE_NAME}

  echo "Deleting existing image '${DOCKER_IMAGE_NAME}'..."
  docker image rm ${DOCKER_IMAGE_NAME}
  
  echo "Building image '${DOCKER_IMAGE_NAME}'..."
  docker build --tag ${DOCKER_IMAGE_NAME} .

  echo "Running '${DOCKER_IMAGE_NAME}' image into '${DOCKER_IMAGE_NAME}' container..."
  docker run --interactive --tty \
  --volume /etc/timezone:/etc/timezone --volume /etc/localtime:/etc/localtime --volume ${SCRIPTPATH}:/${DOCKER_IMAGE_NAME} \
  --env LANG=fr_FR.UTF-8 --env LC_ALL=fr_FR.UTF-8 --env GITHUB_REF_NAME=$GITHUB_REF_NAME \
  --name ${DOCKER_IMAGE_NAME} ${DOCKER_IMAGE_NAME} \
  /usr/bin/bash /${DOCKER_IMAGE_NAME}/make_binaries.sh
else
  echo "Running existing ${DOCKER_IMAGE_NAME} container..."
  docker start --attach ${DOCKER_IMAGE_NAME}
fi

popd
