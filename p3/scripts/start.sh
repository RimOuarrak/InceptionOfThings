#!/bin/bash
set -e

# Resolve the directory this script lives in so relative paths work from any CWD
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Colors
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
BLUE="\e[34m"
RESET="\e[0m"

echo -e "${BLUE}============================================${RESET}"
echo -e "${BLUE}   InceptionOfThings — Starting setup...    ${RESET}"
echo -e "${BLUE}============================================${RESET}"

echo -e "${YELLOW}>> Creating k3d cluster (may take a few moments)${RESET}"
k3d cluster create -p "8080:80@loadbalancer" -p 8888:30888@loadbalancer
echo -e "${GREEN}--> k3d cluster created${RESET}"

echo -e "${YELLOW}>> Creating argocd namespace${RESET}"
kubectl create namespace argocd
kubectl create namespace dev
echo -e "${GREEN}--> Namespace creation requested${RESET}"

echo -e "${YELLOW}>> Installing ArgoCD${RESET}"
kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml -n argocd
sleep 3
echo -e "${CYAN}Waiting for ArgoCD pods to become ready...${RESET}"
kubectl wait -n argocd --for=condition=Ready  pods --all
echo -e "${GREEN}--> ArgoCD pods ready${RESET}"

echo -e "${YELLOW}>> Configuring ArgoCD server for insecure access${RESET}"
kubectl patch configmap argocd-cmd-params-cm -n argocd \
  --type merge \
  -p '{"data":{"server.insecure":"true"}}'
kubectl rollout restart deployment argocd-server -n argocd
sleep 3
echo -e "${GREEN}--> ArgoCD server configured${RESET}"

echo -e "${CYAN}Waiting for ArgoCD to restart...${RESET}"
kubectl wait -n argocd --for=condition=Ready pods --all
echo -e "${GREEN}--> ArgoCD server configured${RESET}"

echo -e "${YELLOW}>> Applying ingress for ArgoCD${RESET}"
kubectl apply -f "$SCRIPT_DIR/../confs/ingress.yaml" -n argocd
sleep 3
echo -e "${GREEN}--> Ingress applied${RESET}"

echo -e "${YELLOW}>> Applying project manifest${RESET}"
kubectl apply -f "$SCRIPT_DIR/../confs/project.yaml" -n argocd
sleep 3
echo -e "${GREEN}--> Project applied${RESET}"

echo -e "${YELLOW}>> Applying application manifest${RESET}"
kubectl apply -f "$SCRIPT_DIR/../confs/application.yaml" -n argocd
sleep 3
echo -e "${GREEN}--> Application applied${RESET}"

echo -e "${YELLOW}>> Setting admin password to 'amineadmin'${RESET}"
kubectl -n argocd patch secret argocd-secret \
  -p '{"stringData": {
    "admin.password": "$2a$12$wcYL7VfnFuEyHUV0uDl2/u5GD33oheeS1Q6O.DWD.fpVsipBgxWAy"
  }}'
sleep 3
echo -e "${GREEN}--> Admin password set${RESET}"

echo -e "${BLUE}============================================${RESET}"
echo -e "${BLUE}   Setup complete.                         ${RESET}"
echo -e "${BLUE}   ArgoCD: http://localhost:8080           ${RESET}"
echo -e "${BLUE}   Playground: http://localhost:8888       ${RESET}"
echo -e "${BLUE}============================================${RESET}"