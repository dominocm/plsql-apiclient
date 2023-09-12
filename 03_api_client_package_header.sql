CREATE OR REPLACE PACKAGE API_USER.api_client AS
--
--
-- Package for work with http/https via tcp connection.
--
--
-- Block with constants.
--
    C_HTTP_0        CONSTANT VARCHAR2(10)   DEFAULT 'HTTP/1.0';
    C_HTTP_1        CONSTANT VARCHAR2(10)   DEFAULT 'HTTP/1.1';
    C_POST          CONSTANT VARCHAR2(4)    DEFAULT 'POST';
    C_GET           CONSTANT VARCHAR2(3)    DEFAULT 'GET';
    C_HEAD          CONSTANT VARCHAR2(4)    DEFAULT 'HEAD';
    C_DELETE        CONSTANT VARCHAR2(6)    DEFAULT 'DELETE';
    C_PUT           CONSTANT VARCHAR2(3)    DEFAULT 'PUT';
    C_PATCH         CONSTANT VARCHAR2(5)    DEFAULT 'PATCH';
    C_AUTH_BEARER   CONSTANT VARCHAR2(6)    DEFAULT 'BEARER';
    C_AUTH_KEYSTONE CONSTANT VARCHAR2(8)    DEFAULT 'KEYSTONE';
    C_AUTH_BASIC    CONSTANT VARCHAR2(5)    DEFAULT 'BASIC';
    C_AUTH_TOKEN    CONSTANT VARCHAR2(5)    DEFAULT 'TOKEN';
    C_ACL_NAME      CONSTANT VARCHAR2(23)   DEFAULT 'api_client.xml';
--
--
-- Type for service params. Reflection of SERVICE_PARAMS table.
--
    TYPE service_params IS RECORD (
        f_service_id         INTEGER,
        f_host_ip           VARCHAR2(128),
        f_host_protocol     VARCHAR2(16),
        f_host_name         VARCHAR2(128),
        f_host_port         INTEGER,
        f_host_url          VARCHAR2(256),
        f_url               VARCHAR2(512),
        f_use_ssl           INTEGER,
        f_tx_timeout        INTEGER,
        f_in_buffer_size    INTEGER,
        f_out_buffer_size   INTEGER,
        f_wallet_name       VARCHAR2(128),
        f_wallet_pwd        VARCHAR2(128),
        f_auth_header       VARCHAR2(4000),
        f_expiration_date   DATE,
        f_charset           VARCHAR2(16)
    );
--
--
-- Type for client request.
--
    TYPE request IS RECORD (
        f_header       VARCHAR2(2000),
        f_content_type VARCHAR2(50), 
        f_data         BLOB,
        f_text         CLOB
    );
--
--
-- Type for service response.
--
    TYPE response IS RECORD (
        f_header       VARCHAR2(2000),
        f_content_type VARCHAR2(50), 
        f_data         BLOB,
        f_text         CLOB,
        f_is_file      BOOLEAN,
        f_code         INTEGER
    );
--
--
-- Refresh accesses in C_ACL_NAME ACL.
--      p_err_code   - if 0 - operation successful, 
--                     if <0 - sqlcode of error
--
    PROCEDURE refresh_acl(
                p_err_code OUT INTEGER);
--
--
-- Add service to SERVICE_PARAMS table.
--      p_service_id   - if 0 - identifier of service from table SERVICE_PARAMS, 
--                       if <0 - sqlcode of error
--
    PROCEDURE add_service(
                p_service_id         OUT INTEGER,
                p_name            IN     VARCHAR2,
                p_host_name       IN     VARCHAR2,
                p_host_ip         IN     VARCHAR2,
                p_host_port       IN     INTEGER,
                p_host_url        IN     VARCHAR2,
                p_host_protocol   IN     VARCHAR2,
                p_charset_name    IN     VARCHAR2 DEFAULT NULL,
                p_auth_type       IN     VARCHAR2 DEFAULT NULL,
                p_access_key      IN     VARCHAR2 DEFAULT NULL, 
                p_access_token    IN     VARCHAR2 DEFAULT NULL,
                p_auth_service_id IN     INTEGER  DEFAULT NULL,          
                p_in_buffer_size  IN     INTEGER  DEFAULT NULL,
                p_out_buffer_size IN     INTEGER  DEFAULT NULL,
                p_tx_timeout      IN     INTEGER  DEFAULT 0,
                p_utc_offset      IN     INTEGER  DEFAULT 0,
                p_use_ssl         IN     INTEGER  DEFAULT 0,
                p_wallet_name     IN     VARCHAR2 DEFAULT NULL,
                p_wallet_pwd      IN     VARCHAR2 DEFAULT NULL);
--
--
-- Delete service from SERVICE_PARAMS table.
--      p_service_id - identifier of service from table SERVICE_PARAMS
--      p_err_code   - if 0 - operation successful, 
--                     if <0 - sqlcode of error
--
    PROCEDURE rem_service(
                p_service_id IN     INTEGER,
                p_err_code      OUT INTEGER);
--
--
-- Delete service from SERVICE_PARAMS table.
--      p_service_name - name of service from table SERVICE_PARAMS
--      p_err_code     - if 0 - operation successful, 
--                       if <0 - sqlcode of error
--
    PROCEDURE rem_service(
                p_service_name IN     VARCHAR2,
                p_err_code        OUT INTEGER);
--
--
-- Loading service params from SERVICE_PARAMS table into service_params record.
--      p_param      - service_params record
--      p_service_id - identifier of service from table SERVICE_PARAMS
--      p_err_code   - if 0 - operation successful, 
--                     if <0 - sqlcode of error
--
    PROCEDURE init_service_params(
                p_param       IN OUT NOCOPY service_params,
                p_service_id  IN            INTEGER,
                p_err_code       OUT        INTEGER);
--
--
-- Init client request.
--      p_request      - request record 
--      p_header       - request header
--      p_content_type - request content type 
--      p_data         - binary body
--      p_text         - text body
--      p_err_code     - if 0 - operation successful, 
--                       if <0 - sqlcode of error
--
    PROCEDURE init_request(
                p_request      IN OUT NOCOPY request,
                p_header       IN            VARCHAR2,
                p_content_type IN            VARCHAR2, 
                p_data         IN            BLOB,
                p_text         IN            CLOB,
                p_err_code        OUT        INTEGER);
--
--
-- Init service response.
--      p_response     - response record
--      p_content_type - request content type 
--      p_is_file      - if true - read as file, if false - read as text
--      p_err_code     - if 0 - operation successful, 
--                       if <0 - sqlcode of error
--
    PROCEDURE init_response(
                p_response     IN OUT NOCOPY response,
                p_content_type IN            VARCHAR2, 
                p_is_file      IN            BOOLEAN,
                p_err_code        OUT        INTEGER);
--
--
-- Checking of service accessibility.
--      p_service_id - identifier of service from table SERVICE_PARAMS
--      p_err_code   - if 0 - operation successful, 
--                     if <0 - sqlcode of error
--
    PROCEDURE check_connection(
                p_service_id  IN     INTEGER, 
                p_err_code       OUT INTEGER);
--
--
-- Open tcp connection with service_params.
--      p_c          - tcp connection
--      p_param      - record with service params
--      p_err_code   - if 0 - operation successful, 
--                     if <0 - sqlcode of error
--      
    PROCEDURE open_connection(
                p_c            OUT NOCOPY utl_tcp.connection, 
                p_param     IN            service_params, 
                p_err_code     OUT        INTEGER);
--
--
-- Loading service_params and open tcp connection for service.
--      p_service_id - identifier of service from table SERVICE_PARAMS
--      p_c          - tcp connection
--      p_param      - record with service params
--      p_err_code   - if 0 - operation successful, 
--                     if <0 - sqlcode of error
--
    PROCEDURE open_connection(
                p_service_id IN            INTEGER, 
                p_c             OUT NOCOPY utl_tcp.connection, 
                p_param         OUT NOCOPY service_params, 
                p_err_code      OUT        INTEGER);
--
--
-- Reopen tcp connection for service.
--      p_c          - tcp connection
--      p_param      - record with service params
--      p_err_code   - if 0 - operation successful, 
--                     if <0 - sqlcode of error
--
    PROCEDURE reopen_connection(
                p_c        IN OUT NOCOPY utl_tcp.connection, 
                p_param    IN            service_params, 
                p_err_code    OUT        INTEGER);
--
--
-- Close tcp connection.
--      p_c          - tcp connection
--
    PROCEDURE close_connection(
                p_c IN OUT NOCOPY utl_tcp.connection);
--
--
-- Parse http code from response.
--      p_text       - string with http result text
--      result       - if NULL then client don't get any response from service
--                     if >0 code from http response (200,201,500,503 etc)
--                     if <0 sqlcode of error   
--
    FUNCTION get_http_result(
                p_text  IN  VARCHAR2)
                RETURN      INTEGER;
--
--
-- Retrieve new token for service.
--      p_service_id      - identifier of service from table SERVICE_PARAMS
--      p_auth_type       - authorization type (KEYSTONE, BEARER, BASIC, TOKEN)
--      p_token           - actual token
--      p_expiration_date - token expiration date
--
    PROCEDURE get_token(
                p_service_id      IN     INTEGER, 
                p_auth_type       IN     VARCHAR2, 
                p_token              OUT VARCHAR2, 
                p_expiration_date    OUT DATE);
--
--
-- Get authorization information for header 
-- from service params and actual token.
--      p_service_id      - identifier of service from table SERVICE_PARAMS
--      p_auth_str        - string for Authorization header
--      p_expiration_date - token expiration date
-- 
    PROCEDURE get_auth_header(
                p_service_id      IN     INTEGER, 
                p_auth_str           OUT VARCHAR2, 
                p_expiration_date    OUT DATE);
--
--
-- Send binary data into connection.
--      p_c          - tcp connection
--      p_data       - binary data
--
    PROCEDURE write_data(
                p_c    IN OUT NOCOPY utl_tcp.connection, 
                p_data IN            BLOB);
--
--
-- Send text data into connection.
--      p_c          - tcp connection
--      p_text       - text data
--
    PROCEDURE write_text(
                p_c    IN OUT NOCOPY utl_tcp.connection, 
                p_text IN            CLOB);
--
--
-- Set request headers and properties.
--      p_c          - tcp connection
--      p_param      - record with service params
--      p_method     - request method (POST, GET, HEAD, PUT, PATCH, DELETE)
--      p_function   - endpoint function
--      p_query      - function params
--
    PROCEDURE set_request(
                p_c        IN OUT NOCOPY utl_tcp.connection, 
                p_param    IN OUT NOCOPY service_params,
                p_method   IN            VARCHAR2, 
                p_function IN            VARCHAR2, 
                p_query    IN            VARCHAR2);
--
--
-- Set request body.
--      p_c            - tcp connection
--      p_request      - request record
-- 
    PROCEDURE set_body(
                p_c            IN OUT NOCOPY utl_tcp.connection,
                p_request      IN            request);
--
--
-- Send request to service.
--      p_c            - tcp connection
--      p_param        - record with service params
--      p_method       - request method (POST, GET, HEAD, PUT, PATCH, DELETE)
--      p_function     - endpoint function
--      p_query        - function params
--      p_request      - request record
--      p_err_code     - if 0 - operation successful, 
--                       if <0 - sqlcode of error
--
    PROCEDURE send_request(
                p_c            IN OUT NOCOPY utl_tcp.connection, 
                p_param        IN OUT NOCOPY service_params, 
                p_method       IN            VARCHAR2, 
                p_function     IN            VARCHAR2, 
                p_query        IN            VARCHAR2,
                p_request      IN            request, 
                p_err_code        OUT        INTEGER);
--
--
-- Read chunk of binary data from connection.
--      p_c            - tcp connection
--      p_data         - binary data (loaded chunk have been attached to it)
--      p_chunk_size   - size of chunk for reading 
--      p_chunk        - loaded chunk
--
    PROCEDURE read_data_chunk(
                p_c          IN OUT NOCOPY utl_tcp.connection,
                p_data       IN OUT NOCOPY BLOB,
                p_chunk_size IN            INTEGER,
                p_chunk         OUT        RAW);
--
--
-- Read chunk of text data from connection.
--      p_c            - tcp connection
--      p_text         - text data (loaded chunk have been attached to it)
--      p_chunk_size   - size of chunk for reading 
--      p_chunk        - loaded chunk
--
    PROCEDURE read_text_chunk(
                p_c          IN OUT NOCOPY utl_tcp.connection,
                p_text       IN OUT NOCOPY CLOB,
                p_chunk_size IN            INTEGER,
                p_chunk      OUT           VARCHAR2);
--
--
-- Read binary file from connection.
--      p_c            - tcp connection
--      p_data         - binary data (file)
--      p_header       - http header 
--
    PROCEDURE read_data_file(
                p_c      IN OUT NOCOPY utl_tcp.connection, 
                p_data      OUT        BLOB, 
                p_header    OUT        VARCHAR2);
--
--
-- Read text file from connection.
--      p_c            - tcp connection
--      p_text         - text data (file)
--      p_header       - http header 
--
    PROCEDURE read_text_file(
                p_c      IN OUT NOCOPY utl_tcp.connection, 
                p_text      OUT        CLOB, 
                p_header    OUT        VARCHAR2);
--
--
-- Read binary data from connection.
--      p_c            - tcp connection
--      p_data         - binary data
--      p_header       - http header 
--
    PROCEDURE read_data(
                p_c       IN OUT NOCOPY utl_tcp.connection, 
                p_data       OUT        BLOB, 
                p_header     OUT        VARCHAR2);
--
--
-- Read text data from connection.
--      p_c            - tcp connection
--      p_text         - text data
--      p_header       - http header 
--
    PROCEDURE read_text(
                p_c       IN OUT NOCOPY utl_tcp.connection, 
                p_text       OUT        CLOB, 
                p_header     OUT        VARCHAR2);
--
--
-- Read json data from connection.
--      p_c            - tcp connection
--      p_json         - text data
--      p_header       - http header 
--
    PROCEDURE read_json(
                p_c       IN OUT NOCOPY utl_tcp.connection, 
                p_json       OUT        CLOB, 
                p_header     OUT        VARCHAR2);
--
--
-- Get response from connection.
--      p_c            - tcp connection
--      p_response     - response record
--
    PROCEDURE get_response(
                p_c        IN OUT NOCOPY utl_tcp.connection, 
                p_response IN OUT NOCOPY response);
--
--
-- Receive response from service.
--      p_c            - tcp connection
--      p_response     - response record
--      p_err_code     - if 0 - operation successful, 
--                       if <0 - sqlcode of error
--
    PROCEDURE receive_response(
                p_c        IN OUT NOCOPY utl_tcp.connection, 
                p_response IN OUT NOCOPY response, 
                p_err_code    OUT        INTEGER);
--
--
-- Send request and receive response.
--      p_c            - tcp connection
--      p_param        - record with service params
--      p_method       - request method (POST, GET, HEAD, PUT, PATCH, DELETE)
--      p_function     - endpoint function
--      p_query        - function params
--      p_request      - request record
--      p_response     - response record
--      p_err_code     - if 0 - operation successful, 
--                       if <0 - sqlcode of error
--
    PROCEDURE call_http(
                p_c            IN OUT NOCOPY utl_tcp.connection, 
                p_param        IN OUT NOCOPY service_params, 
                p_method       IN            VARCHAR2, 
                p_function     IN            VARCHAR2, 
                p_query        IN            VARCHAR2, 
                p_request      IN            request, 
                p_response     IN OUT        response, 
                p_err_code        OUT        INTEGER);
--
--
-- Call service and receive response.
--      p_service_id   - identifier of service from table SERVICE_PARAMS
--      p_method       - request method (POST, GET, HEAD, PUT, PATCH, DELETE)
--      p_function     - endpoint function
--      p_query        - function params
--      p_request      - request record
--      p_response     - response record
--      p_err_code     - if 0 - operation successful, 
--                       if <0 - sqlcode of error
--
    PROCEDURE call_http(
                p_service_id   IN     INTEGER, 
                p_method       IN     VARCHAR2, 
                p_function     IN     VARCHAR2, 
                p_query        IN     VARCHAR2, 
                p_request      IN     request, 
                p_response     IN OUT response, 
                p_err_code        OUT INTEGER);
--
--
-- Send SOAP request and receive response.
--      p_c            - tcp connection
--      p_param        - record with service params
--      p_function     - endpoint function
--      p_body         - xml body
--      p_result       - xml response data
--      p_err_code     - if 0 - operation successful, 
--                       if <0 - sqlcode of error
--
    PROCEDURE call_soap(
                p_c        IN OUT NOCOPY utl_tcp.connection, 
                p_param    IN OUT NOCOPY service_params, 
                p_function IN            VARCHAR2, 
                p_body     IN            CLOB, 
                p_result      OUT        CLOB, 
                p_err_code    OUT        INTEGER);
--
--
-- Send SOAP request and receive response.
--      p_c            - tcp connection
--      p_param        - record with service params
--      p_body         - xml body
--      p_result       - xml response data
--      p_err_code     - if 0 - operation successful, 
--                       if <0 - sqlcode of error
--
    PROCEDURE call_soap(
                p_c        IN OUT NOCOPY utl_tcp.connection, 
                p_param    IN OUT NOCOPY service_params, 
                p_body     IN            CLOB, 
                p_result      OUT        CLOB, 
                p_err_code    OUT        INTEGER);
--
--
-- Send SOAP request and receive response.
--      p_service_id   - identifier of service from table SERVICE_PARAMS
--      p_function     - endpoint function
--      p_body         - xml body
--      p_result       - xml response data
--      p_err_code     - if 0 - operation successful, 
--                       if <0 - sqlcode of error
--
    PROCEDURE call_soap(
                p_service_id IN     INTEGER, 
                p_function   IN     VARCHAR2, 
                p_body       IN     CLOB, 
                p_result        OUT CLOB, 
                p_err_code      OUT INTEGER);
--
--
-- Send SOAP request and receive response.
--      p_service_id   - identifier of service from table SERVICE_PARAMS
--      p_body         - xml body
--      p_result       - xml response data
--      p_err_code     - if 0 - operation successful, 
--                       if <0 - sqlcode of error
--
    PROCEDURE call_soap(
                p_service_id IN     INTEGER, 
                p_body       IN     CLOB, 
                p_result        OUT CLOB, 
                p_err_code      OUT INTEGER);
END api_client;
/