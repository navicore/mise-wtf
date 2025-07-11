# K8s Lab Architecture

## Overview

A distributed application demonstrating real-world patterns for local Kubernetes development.

**Focus**: Application development with realistic networking patterns. No service mesh, no TLS - just the core app and networking patterns that mirror production.

## Components

### 1. PostgreSQL Database
- Persistent storage for observations
- StatefulSet with PVC for data persistence
- Simple password auth

### 2. REST API Service
- CRUD operations for observations
- Database connection pooling
- Health/readiness endpoints
- Plain HTTP (no TLS)

### 3. SignalK Simulator
- Generates marine/IoT telemetry data
- Publishes to Apache Pulsar topics
- Configurable data generation rates

### 4. Aggregator Service
- Subscribes to Pulsar topics
- Computes rolling aggregates (min/max/avg)
- Updates database via REST API

### 5. Web Application
- Query interface for aggregated data
- Real-time dashboard
- Served via Ingress (HTTP only)

### 6. Apache Pulsar
- Message streaming platform
- Topic management for observations
- Persistent message storage
- Admin UI exposed via Ingress

## Network Architecture

```
Internet
    |
[Ingress Controller] (nginx, HTTP only)
    |
    ├── app.k8s.local → [Web App Service]
    ├── api.k8s.local → [REST API Service]
    └── pulsar.k8s.local → [Pulsar Admin UI]
                                |
                         [REST API Service]
                                |
                           [PostgreSQL]

[SignalK Simulator] → [Pulsar Broker] ← [Aggregator Service]
                                                |
                                                └→ [REST API]
```

## DNS Setup (dnsmasq)

- `*.k8s.local` → 127.0.0.1
- Ingress routes by hostname:
  - `app.k8s.local` → Web application
  - `api.k8s.local` → REST API
  - `pulsar.k8s.local` → Pulsar admin console

This pattern demonstrates how production apps expose multiple services through a single ingress, each with their own hostname.

## Data Flow

1. SignalK Simulator generates observations
2. Observations published to Pulsar topic
3. Aggregator consumes from Pulsar
4. Aggregator computes windowed aggregates
5. Aggregates posted to REST API
6. REST API stores in PostgreSQL
7. Web App queries REST API for display
8. Developers can monitor message flow via Pulsar Admin UI

## What We're NOT Doing (On Purpose)

- **No TLS**: Plain HTTP everywhere (this is dev, not prod)
- **No Service Mesh**: Direct service-to-service communication
- **No Authentication**: Focus on app logic, not security
- **No Multi-tenancy**: Single namespace, simple permissions
- **No High Availability**: Single replicas are fine for dev

## Why This Architecture?

This setup validates:
- Multi-service ingress routing (critical for microservices)
- Event-driven architecture with Pulsar
- Database-backed services
- Admin/monitoring interfaces alongside app interfaces
- Real DNS resolution (not just port-forwarding)

Perfect for testing how your app will actually behave in production networking.