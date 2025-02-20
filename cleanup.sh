#!/bin/bash

echo "checking for configs and secrets. . "

# Function to check if a config is used by any service
check_config_usage() {
    for service in $(docker service ls -q); do
        if docker service inspect "$service" --format '{{ .Spec.TaskTemplate.ContainerSpec.Configs }}' | grep -q "$1"; then
            return 0
        fi
    done
    return 1
}

# Function to check if a secret is used by any service
check_secret_usage() {
    for service in $(docker service ls -q); do
        if docker service inspect "$service" --format '{{ range .Spec.TaskTemplate.ContainerSpec.Secrets }}{{ .SecretName }} {{end}}' | grep -wq "$1"; then
            return 0
        fi
    done
    return 1
}

# Clean up unused configs
for config in $(docker config ls -q); do
    if ! check_config_usage "$config"; then
        config_name=$(docker config inspect "$config" --format '{{ .Spec.Name }}')
        echo "Unused config found: $config_name, removing config file"
        docker config rm "$config"
    fi
done

# Clean up unused secrets
for secret in $(docker secret ls -q); do
    if ! check_secret_usage "$secret"; then
        secret_name=$(docker secret inspect "$secret" --format '{{ .Spec.Name }}')
        echo "Unused secret: $secret_name, removing now"
        docker secret rm "$secret"
    fi
done

echo "Prune unused Docker objects"
docker system prune -f
