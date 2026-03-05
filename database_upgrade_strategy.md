# Database Upgrade Strategy for Sunbit POS API

In the context of the Sunbit POS API architecture—specifically because it utilizes **Argo Rollouts** for Progressive Delivery (Canary deployments)—upgrading the database requires a careful and orchestrated strategy. 

Because a Canary rollout runs **both the old version (v1) and the new version (v2) of your API simultaneously**, any database schema changes must be **backward-compatible** so that the v1 pods don't crash while v2 is being tested.

Here is the industry-standard way to handle database changes in this scenario, known as the **Expand and Contract Pattern** (or Parallel Change).

---

## The Expand and Contract Pattern

### 1. The "Expand" Phase (Backward-Compatible DB Migration)
Before or during the deployment, you run a database migration (using a tool like Alembic for Python/FastAPI, Flyway, or Liquibase). 
- **Rule:** You can only **add** new tables, columns, or non-restrictive constraints.
- **Do Not:** Rename columns, delete columns, or add `NOT NULL` constraints without default values.
- **Execution:** You can run this migration via a Kubernetes `Job` triggered via your CI/CD pipeline (e.g., GitHub Actions), or as a `PrePromotion` hook within Argo Rollouts.
- **Result:** Both v1 (old pods) and v2 (new Canary pods) can safely read and write to the database. The v1 pods simply ignore the new schema elements.

### 2. The Application Rollout (Canary)
Now you trigger your Argo Rollout for the `pos-api` which deploys the new application code.
- **Canary (20%):** 20% of traffic routes to v2. v2 is aware of the new DB columns and utilizes them.
- **Stable (80%):** 80% of traffic routes to v1. v1 completely ignores the new columns.
- *Optional Data Sync:* If data consistency between old and new formats is needed (e.g., you are moving a column), v2 can be configured in code to "dual-write" to both the old and new columns.

### 3. The Monitor & Promote Phase
Argo Rollouts pauses the rollout automatically (as defined by the `pause` steps in `argo-rollout.yaml`). 
- You monitor APM (Datadog) metrics to ensure v2 isn't throwing 500 errors, experiencing latency bottlenecks, or failing database inserts.
- If successful, you promote the rollout to 100%. All traffic is now handled by v2, and the v1 pods are terminated.

### 4. The "Contract" Phase (Cleanup)
Once the rollout is 100% complete and you are absolutely certain a rollback to v1 is no longer needed, you can schedule a future, separate database migration to clean up.
- This migration drops the old, unused columns or tables.
- Because v1 is completely gone from the cluster, dropping the old columns is now safe and will not cause outages.

---

## Alternative: Destructive / Non-Compatible Changes
If a schema change is so fundamental or destructive that it **cannot** be made backward-compatible (e.g., massive table refactoring that cannot be temporarily dual-written):

1. **Clone:** Clone the database (e.g., using AWS Aurora Fast Database Cloning or restoring a snapshot).
2. **Migrate:** Apply the destructive migrations to the cloned, isolated database.
3. **Deploy:** Deploy the v2 application pointing entirely to the cloned database.
4. **Switch:** Route 100% of traffic to v2 simultaneously. This often requires a short maintenance window or complex event streaming (via Amazon MSK/Kafka) to synchronize the delta state between the old and new database during the switch.

**Note:** For the high-availability BNPL architecture defined in this project, the **Expand and Contract (Backward-Compatible)** approach is heavily preferred to maintain the true zero-downtime, continuous delivery lifecycle.
