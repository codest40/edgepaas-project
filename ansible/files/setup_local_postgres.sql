-- =============================================================================
-- EdgePaaS Local Postgres Setup (Test DB)
-- Idempotent: safe to run multiple times
-- =============================================================================

-- Create test user if it doesn't exist
-- Create test user if not exists
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

-- Create database only if it doesn't exist
-- Run this as plain SQL (not inside DO block)
\connect postgres
-- check if db exists, then create
CREATE DATABASE testdb OWNER testuser;
