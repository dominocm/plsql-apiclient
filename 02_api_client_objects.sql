--
-- Create table for storing information about services settings.
--
CREATE TABLE API_USER.SERVICE_PARAMS
(
  ID                           INTEGER             NOT NULL,  -- uniq identificator (primary key)
  NAME                         VARCHAR2(128 BYTE)  NOT NULL,  -- uniq description of service
  HOST_NAME                    VARCHAR2(64 BYTE),             -- name of service's host
  HOST_IP                      VARCHAR2(64 BYTE),             -- ip-address of service's host
  HOST_PORT                    INTEGER,                       -- service's port
  HOST_URL                     VARCHAR2(256 BYTE),            -- service's uri
  HOST_PROTOCOL                VARCHAR2(16 BYTE),             -- version of http protocol (HTTP 1.0, HTTP 1.1)
  ACCESS_KEY                   VARCHAR2(128 BYTE),            -- access key value (for BEARER auth)
  ACCESS_TOKEN                 VARCHAR2(128 BYTE),            -- access token value (for BEARER auth)
  USE_SSL                      INTEGER             DEFAULT 0, -- 0 - connect without ssl, 1 - connect with ssl
  AUTH_TYPE                    VARCHAR2(16 BYTE),             -- autentification type (BEARER, KEYSTONE, BASIC, TOKEN)
  AUTH_SERVICE_ID              INTEGER,                       -- id of another service from this table to use it for autentification          
  UTC_OFFSET                   INTEGER             DEFAULT 0, -- UTC offset on service
  TX_TIMEOUT                   INTEGER             DEFAULT 0, -- default tcp connection timeout
  IN_BUFFER_SIZE               INTEGER,                       -- tcp connection input buffer size
  OUT_BUFFER_SIZE              INTEGER,                       -- tcp connection outer buffer size
  WALLET_NAME                  VARCHAR2(128 BYTE),            -- wallet name for using with ssl
  WALLET_PWD                   VARCHAR2(128 BYTE),            -- wallet password for using with ssl
  CHARSET_NAME                 VARCHAR2(16 BYTE)              -- default charset
)
TABLESPACE DF_USERS;
/

CREATE UNIQUE INDEX API_USER.SERVICE_PARAMS_PK ON API_USER.SERVICE_PARAMS
(ID)
TABLESPACE DF_USERS;
/

ALTER TABLE API_USER.SERVICE_PARAMS ADD (
  CONSTRAINT SERVICE_PARAMS_PK
  PRIMARY KEY
  (ID)
  USING INDEX API_USER.SERVICE_PARAMS_PK
  ENABLE VALIDATE);
/

CREATE UNIQUE INDEX API_USER.SERVICE_PARAMS_NAME ON API_USER.SERVICE_PARAMS
(NAME)
TABLESPACE DF_USERS;
/

--
-- Create sequence for managing service's identifiers.
--
CREATE SEQUENCE API_USER.SQ_SERVICE_ID
  START WITH 1
  MAXVALUE 999999999999999999999999999
  MINVALUE 1
  NOCYCLE
  NOCACHE
  NOORDER;
/

CREATE TABLE API_USER.TOKEN_STORAGE
(
  SERVICE_ID   INTEGER NOT NULL,
  TOKEN             VARCHAR2(256 BYTE) NOT NULL,
  EXPIRATION_DATE   DATE
)
TABLESPACE DF_USERS;
/

CREATE UNIQUE INDEX API_USER.TOKEN_STORAGE_PK ON API_USER.TOKEN_STORAGE
(SERVICE_ID)
TABLESPACE DF_USERS;
/

ALTER TABLE API_USER.TOKEN_STORAGE ADD (
  CONSTRAINT TOKEN_STORAGE_PK
  PRIMARY KEY
  (SERVICE_ID)
  USING INDEX API_USER.TOKEN_STORAGE_PK
  ENABLE VALIDATE);
/

CREATE INDEX API_USER.TOKEN_STORAGE_IDX_EXP_DATE ON API_USER.TOKEN_STORAGE
(EXPIRATION_DATE)
TABLESPACE DF_USERS;
/

