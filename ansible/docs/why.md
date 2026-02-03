# Specific Reasons for Certain Choices We Made

```
## 1. PostgreSQL User and Database Creation (Common Role)

In the Common role, we intentionally create the PostgreSQL user and database using `sudo -u postgres psql` rather than Ansible’s `community.postgresql` modules.

### Why this decision was necessary

Amazon Linux 2023 has a known incompatibility with Ansible’s privilege escalation mechanism when using:
```

```yaml
become: yes
become_user: postgres
```

When Ansible becomes an unprivileged user (such as `postgres`), it attempts to manage temporary files using POSIX ACLs. Internally, Ansible issues `chmod` commands with ACL-style syntax (for example: `A+user:postgres:rx:allow`).

On Amazon Linux 2023, the underlying filesystem and ACL tooling do **not** support this syntax. As a result, tasks that rely on `become_user: postgres` fail with errors similar to:

```
chmod: invalid mode: ‘A+user:postgres:rx:allow’
```

This failure occurs **before** the PostgreSQL module logic is executed, meaning it is not a database configuration issue, a permissions misconfiguration, or a missing dependency—it is a platform-level incompatibility between Ansible and Amazon Linux 2023.

### Why Ansible PostgreSQL modules were avoided

The following modules are affected by this issue on Amazon Linux 2023:

* `community.postgresql.postgresql_db`
* `community.postgresql.postgresql_user`
* Any module requiring `become_user: postgres`

Because this behavior is inconsistent and environment-specific, relying on these modules would introduce fragility into the provisioning process.

### Why `sudo -u postgres psql` is the safer alternative

Using:

```bash
sudo -u postgres psql
```

allows the operating system’s `sudo` mechanism to handle user switching directly, bypassing Ansible’s ACL-based temporary file handling entirely. This approach:

* Avoids Ansible’s Filesystem Access Control List (ACL) and temp-file permission issues
* Works reliably on Amazon Linux 2023
* Preserves least-privilege execution (commands still run as `postgres`)
* Allows explicit, controlled SQL execution

### Idempotency and safety

Idempotency is preserved by embedding explicit existence checks inside SQL (for example, checking system catalogs before creating users or databases). This ensures:

* Tasks can be safely re-run
* No duplicate users or databases are created
* Playbooks remain predictable and repeatable

### Summary

This choice was made to favor **platform stability, predictability, and operational reliability** over strict adherence to Ansible modules. While Ansible’s PostgreSQL modules are generally preferred, using `sudo -u postgres psql` is the most robust and production-safe approach on Amazon Linux 2023 until the underlying ACL incompatibi




2. 
