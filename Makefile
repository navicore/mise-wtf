.PHONY: help setup cluster ingress dns validate clean test-dns test-ingress

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

setup: ## Run initial setup (mise and brew tools)
	./setup.sh

env: ## Source the project environment
	@echo "Run: source .env"

cluster: ## Create kind cluster with podman
	./scripts/cluster-create.sh

ingress: ## Install nginx ingress controller
	./scripts/ingress-setup.sh

dns: ## Configure DNS for *.k8s.local
	./scripts/dns-setup.sh

validate: ## Validate entire setup
	./scripts/validate.sh

all: cluster registry ingress dns validate ## Full setup: cluster, registry, ingress, DNS

registry: ## Set up local Docker registry
	./scripts/registry-setup.sh

clean-cluster: ## Delete kind cluster
	kind delete cluster --name k8s-lab

clean-dns: ## Remove DNS configuration
	@echo "Removing DNS configuration..."
	@sudo rm -f /etc/resolver/k8s.local
	@echo "DNS resolver removed. You may want to manually clean dnsmasq.conf"

clean: clean-cluster ## Clean everything (cluster)

test-dns: ## Test DNS resolution
	@echo "Testing DNS resolution..."
	@dig +short test.k8s.local
	@echo "If you see 127.0.0.1, DNS is working!"

test-ingress: ## Test ingress with curl
	@echo "Testing ingress..."
	curl -H 'Host: hello.k8s.local' http://localhost || echo "Direct test failed"
	@echo ""
	curl http://hello.k8s.local || echo "DNS test failed"

podman-start: ## Start podman machine
	podman machine start

podman-stop: ## Stop podman machine
	podman machine stop

podman-reset: ## Reset podman completely
	@echo "This will destroy all podman data. Continue? [y/N]"
	@read ans && [ $${ans:-N} = y ] && (podman machine stop; podman machine rm -f; podman system reset -f)

postgres: ## Deploy PostgreSQL database
	./scripts/postgres-setup.sh

postgres-connect: ## Connect to PostgreSQL CLI
	./scripts/postgres-connect.sh

postgres-seed: ## Seed test data into PostgreSQL
	./scripts/postgres-seed-data.sh

postgres-port-forward: ## Port forward PostgreSQL to localhost:5432
	kubectl port-forward svc/postgres 5432:5432

rest-api: ## Build and deploy REST API
	./scripts/rest-api-setup.sh

rest-api-test: ## Test REST API endpoints
	./scripts/rest-api-test.sh

rest-api-logs: ## Show REST API logs
	kubectl logs -l app=rest-api --tail=50 -f

pulsar: ## Deploy Apache Pulsar
	./scripts/pulsar-setup.sh

pulsar-create-topics: ## Create Pulsar topics
	./scripts/pulsar-create-topics.sh

pulsar-test: ## Test Pulsar messaging
	./scripts/pulsar-test.sh

pulsar-logs: ## Show Pulsar logs
	kubectl logs deployment/pulsar --tail=50 -f

pulsar-admin: ## Open Pulsar admin CLI
	kubectl exec -it deployment/pulsar -- bin/pulsar-admin

status: ## Show current status
	@echo "=== Tool Versions ==="
	@mise list 2>/dev/null || echo "mise not activated"
	@echo ""
	@echo "=== Podman Status ==="
	@podman machine list || echo "podman not available"
	@echo ""
	@echo "=== Kind Clusters ==="
	@kind get clusters 2>/dev/null || echo "No kind clusters"
	@echo ""
	@echo "=== Ingresses ==="
	@kubectl get ingress 2>/dev/null || echo "No ingresses or cluster not accessible"
	@echo ""
	@echo "=== Services ==="
	@kubectl get svc 2>/dev/null || echo "No services"
	@echo ""
	@echo "=== Pods ==="
	@kubectl get pods 2>/dev/null || echo "No pods"