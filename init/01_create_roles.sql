-- Group roles: no direct login
CREATE ROLE app_owner NOLOGIN;
CREATE ROLE reporting NOLOGIN;

-- Individual login users
CREATE ROLE etl_user LOGIN PASSWORD 'etl_password';
CREATE ROLE analyst_user LOGIN PASSWORD 'analyst_password';

-- Group membership
GRANT app_owner to etl_user;
GRANT reporting TO analyst_user;
