--
-- Create database user (schema) for storing settings and package.
--
CREATE USER API_USER
  IDENTIFIED BY API_USER
  DEFAULT TABLESPACE USERS
  TEMPORARY TABLESPACE TEMP
  PROFILE DEFAULT
  ACCOUNT UNLOCK;
/

--
-- Grant connect role.
--
GRANT CONNECT TO API_USER;
/

--
-- Grant resource role.
--
GRANT RESOURCE TO API_USER;
/

--
-- Set default role.
--
ALTER USER API_USER DEFAULT ROLE ALL;
/

--
-- Grant using of unlimited tablespace.
--
GRANT UNLIMITED TABLESPACE TO API_USER;
/

--
-- Set unlimited quota.
--
ALTER USER API_USER QUOTA UNLIMITED ON USERS;
/

--
-- Grant using UTL_TCP package.
--
GRANT EXECUTE ON UTL_TCP TO API_USER;
/

--
-- Grant using DBMS_NETWORK_ACL_ADMIN package.
--
GRANT EXECUTE ON DBMS_NETWORK_ACL_ADMIN TO API_USER;
/
