-- =============================================================================
-- EdgePaaS Local Postgres Setup (Test DB)
-- Idempotent: safe to run multiple times
-- =============================================================================

-- Create test user if it doesn't exist
DO
$$
BEGIN
   IF NOT EXISTS (
       SELECT FROM pg_catalog.pg_user WHERE usename = 'testuser'
   ) THEN
       CREATE USER testuser WITH PASSWORD 'testpass';
   END IF;
END
$$;

-- Create test database if it doesn't exist
DO
$$
BEGIN
   IF NOT EXISTS (
       SELECT FROM pg_database WHERE datname = 'testdb'
   ) THEN
       CREATE DATABASE testdb OWNER testuser;
   END IF;
END
$$;

-- Grant all privileges on testdb to testuser
GRANT ALL PRIVILEGES ON DATABASE testdb TO testuser;
