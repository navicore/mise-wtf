# Implementation Plan

## Phase 1: Foundation (Week 1)

### Checklist
- [ ] Set up Kind cluster with podman
- [ ] Configure dnsmasq for *.k8s.local
- [ ] Install nginx ingress controller
- [ ] Verify ingress routing with hello-world apps
- [ ] Document podman + kind gotchas on macOS

### Deliverables
- `scripts/cluster-create.sh` - Creates kind cluster with podman
- `scripts/dns-setup.sh` - Configures dnsmasq
- `k8s/ingress/nginx-controller.yaml`
- `docs/podman-kind-setup.md`

## Phase 2: Core Services (Week 2)

### Checklist
- [ ] Deploy PostgreSQL with persistent storage
- [ ] Create REST API service (Node.js/Go)
- [ ] Deploy Pulsar (standalone mode initially)
- [ ] Configure Pulsar admin ingress
- [ ] Test basic CRUD operations

### Deliverables
- `k8s/postgres/` - StatefulSet, Service, PVC
- `services/rest-api/` - API code and Dockerfile
- `k8s/pulsar/` - Pulsar deployment
- `k8s/ingress/services.yaml` - Ingress rules

## Phase 3: Data Pipeline (Week 3)

### Checklist
- [ ] Build SignalK simulator service
- [ ] Create Pulsar topics for observations
- [ ] Build aggregator service
- [ ] Wire up data flow end-to-end
- [ ] Add monitoring/logging

### Deliverables
- `services/signalk-simulator/` - Simulator code
- `services/aggregator/` - Aggregation logic
- `scripts/create-topics.sh` - Pulsar topic setup
- `docs/data-flow.md` - Detailed data flow docs

## Phase 4: Web Interface (Week 4)

### Checklist
- [ ] Create web dashboard (React/Vue)
- [ ] Implement API client
- [ ] Add real-time updates
- [ ] Configure web app ingress
- [ ] End-to-end testing

### Deliverables
- `services/web-app/` - Frontend application
- `k8s/web-app/` - Deployment configs
- `tests/e2e/` - End-to-end test suite

## Phase 5: Developer Experience (Week 5)

### Checklist
- [ ] Create Makefile for common tasks
- [ ] Add hot-reload for local development
- [ ] Create seed data scripts
- [ ] Write developer documentation
- [ ] Create troubleshooting guide

### Deliverables
- `Makefile` - Common development tasks
- `scripts/seed-data.sh` - Test data generation
- `docs/developer-guide.md`
- `docs/troubleshooting.md`

## Phase 6: Helm Charts (Week 6)

### Checklist
- [ ] Create Helm chart structure
- [ ] Parameterize all services
- [ ] Add values files for different environments
- [ ] Test chart installation
- [ ] Document chart usage

### Deliverables
- `charts/k8s-lab/` - Umbrella chart
- `charts/*/` - Individual service charts
- `docs/helm-usage.md`

## Phase 7: GitOps with Flux (Week 7)

### Checklist
- [ ] Install Flux in cluster
- [ ] Set up Git repository structure
- [ ] Create Flux manifests
- [ ] Configure automatic deployments
- [ ] Add Flux monitoring

### Deliverables
- `flux/` - Flux configurations
- `docs/gitops-workflow.md`
- `.github/workflows/` - CI/CD pipelines

## Success Criteria

1. **Networking**: Can access all services via real DNS names
2. **Data Flow**: Observations flow from simulator → Pulsar → aggregator → database
3. **Developer Experience**: New developer can be up and running in < 30 minutes
4. **Reliability**: Cluster survives pod restarts and redeploys
5. **Documentation**: Every component has clear documentation

## Risk Mitigation

1. **Podman + Kind Issues**: Document workarounds, have Docker Desktop fallback
2. **Resource Constraints**: Monitor memory/CPU, add resource limits
3. **Complexity Creep**: Stay focused on dev experience, not production features
4. **Platform Differences**: Test on both Intel and Apple Silicon Macs