SET DEFINE OFF;
CREATE OR REPLACE PACKAGE BODY API_USER.api_client AS
--
--
-- Package for work with http/https via tcp connection.
--
--
--
-- Refresh accesses in C_ACL_NAME ACL.
--      p_err_code   - if 0 - operation successful, 
--                     if <0 - sqlcode of error
--
    PROCEDURE refresh_acl(
                p_err_code OUT INTEGER)
    AS
        PRAGMA AUTONOMOUS_TRANSACTION;
        CURSOR c_services IS
            SELECT ROWNUM AS RN, HOST_ADDRESS, HOST_PORT FROM (
                SELECT DISTINCT NVL(HOST_IP, HOST_NAME) as HOST_ADDRESS, HOST_PORT
                FROM SERVICE_PARAMS
                WHERE NVL(HOST_IP, HOST_NAME) IS NOT NULL AND HOST_PORT IS NOT NULL);
        v_service c_services%ROWTYPE;
    BEGIN
        BEGIN
            DBMS_NETWORK_ACL_ADMIN.DROP_ACL(
                acl => C_ACL_NAME);
        EXCEPTION
            WHEN OTHERS THEN
                 NULL;
        END;
        OPEN c_services;
        LOOP
            FETCH c_services INTO v_service;
            EXIT WHEN c_services%NOTFOUND;
            IF (v_service.rn = 1) THEN
                DBMS_NETWORK_ACL_ADMIN.CREATE_ACL(
                    acl         => C_ACL_NAME,
                    description => C_ACL_NAME,
                    principal   => 'API_USER',
                    is_grant    => true,
                    privilege   => 'connect',
                    start_date  => NULL,
                    end_date    => NULL);
                DBMS_NETWORK_ACL_ADMIN.ADD_PRIVILEGE(
                    acl        =>  C_ACL_NAME,
                    principal  => 'API_USER',
                    is_grant   => true,
                    privilege  => 'connect',
                    start_date => NULL,
                    end_date   => NULL);
            END IF;
            DBMS_NETWORK_ACL_ADMIN.ASSIGN_ACL(
                acl        => C_ACL_NAME,
                host       => v_service.host_address,
                lower_port => v_service.host_port,
                upper_port => v_service.host_port);
        END LOOP;
        CLOSE c_services;
        commit;
        p_err_code := 0;
    EXCEPTION
        WHEN OTHERS THEN
             rollback;
             IF c_services%ISOPEN THEN
                CLOSE c_services;
             END IF;
             p_err_code := SQLCODE;
    END refresh_acl;
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
                p_wallet_pwd      IN     VARCHAR2 DEFAULT NULL)
    AS
    BEGIN
        p_service_id := SQ_SERVICE_ID.NextVal;
        INSERT INTO SERVICE_PARAMS(ID, NAME, 
               HOST_NAME, HOST_IP, HOST_PORT, HOST_URL, HOST_PROTOCOL,
               CHARSET_NAME, ACCESS_KEY, ACCESS_TOKEN, AUTH_SERVICE_ID, 
               IN_BUFFER_SIZE, OUT_BUFFER_SIZE, 
               TX_TIMEOUT, UTC_OFFSET, 
               USE_SSL, WALLET_NAME, WALLET_PWD)
        values(p_service_id, p_name, 
               p_host_name, p_host_ip, p_host_port, p_host_url, p_host_protocol,
               p_charset_name, p_access_key, p_access_token, p_auth_service_id, 
               p_in_buffer_size, p_out_buffer_size, 
               NVL(p_tx_timeout,0), NVL(p_utc_offset,0), 
               NVL(p_use_ssl,0), p_wallet_name, p_wallet_pwd);
        commit;
    EXCEPTION
        WHEN OTHERS THEN
            p_service_id := SQLCODE;
    END add_service;
--
--
-- Delete service from SERVICE_PARAMS table.
--      p_service_id - identifier of service from table SERVICE_PARAMS
--      p_err_code   - if 0 - service accessible, 
--                     if <0 - sqlcode of error
--
    PROCEDURE rem_service(
                p_service_id IN     INTEGER,
                p_err_code      OUT INTEGER)
    AS
    BEGIN
        DELETE FROM SERVICE_PARAMS
        WHERE ID = p_service_id;
        commit;
        p_err_code := 0;
    EXCEPTION
        WHEN OTHERS THEN
            p_err_code := SQLCODE;
    END rem_service;
--
--
-- Delete service from SERVICE_PARAMS table.
--      p_service_name - name of service from table SERVICE_PARAMS
--      p_err_code     - if 0 - operation successful, 
--                       if <0 - sqlcode of error
--
    PROCEDURE rem_service(
                p_service_name IN     VARCHAR2,
                p_err_code        OUT INTEGER)
    AS
    BEGIN
        DELETE FROM SERVICE_PARAMS
        WHERE NAME = p_service_name;
        commit;
        p_err_code := 0;
    EXCEPTION
        WHEN OTHERS THEN
            p_err_code := SQLCODE;
    END rem_service;
--
--
-- Loading service params from table SERVICE_PARAMS into service_params record.
--      p_param      - record with loaded params
--      p_service_id - identifier of service from table SERVICE_PARAMS
--      p_err_code   - if 0 - operation successful, 
--                     if <0 - sqlcode of error
--
    PROCEDURE init_service_params(
                p_param       IN OUT NOCOPY service_params,
                p_service_id  IN            INTEGER,
                p_err_code       OUT        INTEGER)
    AS
    BEGIN
        p_param.f_service_id := p_service_id;
        SELECT host_ip, host_name, host_port, 
            host_url, use_ssl, host_protocol, 
            tx_timeout, in_buffer_size, out_buffer_size, 
            wallet_name, wallet_pwd, charset_name
        INTO p_param.f_host_ip, p_param.f_host_name, p_param.f_host_port, 
            p_param.f_host_url, p_param.f_use_ssl, p_param.f_host_protocol, 
            p_param.f_tx_timeout, p_param.f_in_buffer_size, p_param.f_out_buffer_size, 
            p_param.f_wallet_name, p_param.f_wallet_pwd, p_param.f_charset
        FROM SERVICE_PARAMS 
        WHERE id = p_service_id;
        IF (p_param.f_charset IS NULL) THEN
            p_param.f_charset := 'AL32UTF8';
        END IF;
        IF (p_param.f_host_protocol = C_HTTP_1) THEN
            p_param.f_url := p_param.f_host_url;
        ELSE
            IF (p_param.f_use_ssl = 1) THEN
                p_param.f_url := 'https://'||p_param.f_host_name||p_param.f_host_url;
            ELSE
                p_param.f_url := 'http://'||p_param.f_host_name||p_param.f_host_url;
            END IF;
        END IF;
        p_err_code := 0;
    EXCEPTION
        WHEN OTHERS THEN
             p_err_code := SQLCODE;
    END init_service_params;
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
                p_err_code        OUT        INTEGER)
    AS
    BEGIN
        IF (p_data IS NOT NULL and p_text IS NOT NULL) THEN
            p_err_code := -1422;
        ELSE
            p_request.f_header       := p_header;
            p_request.f_content_type := p_content_type;
            p_request.f_data         := p_data;
            p_request.f_text         := p_text;
            IF (p_request.f_content_type IS NULL) THEN
                IF (p_request.f_data IS NOT NULL) THEN
                    p_request.f_content_type := 'application/octet-stream';
                ELSIF (p_request.f_text IS NOT NULL) THEN
                    p_request.f_content_type := 'application/json';
                END IF;
            END IF;
            p_err_code := 0;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
             p_err_code := SQLCODE;
    END init_request;
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
                p_err_code        OUT        INTEGER)
    AS
    BEGIN
        p_response.f_header       := NULL;
        p_response.f_content_type := p_content_type;
        p_response.f_data         := NULL;
        p_response.f_text         := NULL;
        p_response.f_is_file      := p_is_file;
        p_response.f_code         := NULL;
        p_err_code := 0;
    EXCEPTION
        WHEN OTHERS THEN
             p_err_code := SQLCODE;
    END init_response;
--
--
-- Checking of service accessibility.
--      p_service_id - identifier of service from table SERVICE_PARAMS
--      p_err_code   - if 0 - operation successful, 
--                     if <0 - sqlcode of error
--
    PROCEDURE check_connection(
                p_service_id  IN     INTEGER, 
                p_err_code       OUT INTEGER)
    AS
        v_c      utl_tcp.connection;
        v_param  service_params;
    BEGIN
        open_connection(p_service_id, v_c, v_param, p_err_code);
        close_connection(v_c);
    EXCEPTION
        WHEN OTHERS THEN
             p_err_code := SQLCODE;
    END check_connection;
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
                p_err_code     OUT        INTEGER)
    AS
    BEGIN
        IF (p_param.f_use_ssl = 1) THEN
            IF (p_param.f_wallet_name IS NOT NULL) THEN
                p_c := utl_tcp.open_connection(
                        remote_host     => p_param.f_host_ip, 
                        remote_port     => p_param.f_host_port, 
                        charset         => p_param.f_charset, 
                        tx_timeout      => p_param.f_tx_timeout,
                        in_buffer_size  => p_param.f_in_buffer_size, 
                        out_buffer_size => p_param.f_out_buffer_size,
                        wallet_path     => p_param.f_wallet_name, 
                        wallet_password => p_param.f_wallet_pwd);
                utl_tcp.secure_connection(p_c);
                p_err_code := 0;
            ELSE
                p_err_code := -28353;
            END IF;
        ELSE
            p_c := utl_tcp.open_connection(
                    remote_host     => p_param.f_host_ip, 
                    remote_port     => p_param.f_host_port, 
                    charset         => p_param.f_charset, 
                    tx_timeout      => p_param.f_tx_timeout,
                    in_buffer_size  => p_param.f_in_buffer_size, 
                    out_buffer_size => p_param.f_out_buffer_size);
            p_err_code := 0;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
             p_err_code := SQLCODE;
    END open_connection;
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
                p_err_code      OUT        INTEGER)
    AS
    BEGIN
        init_service_params(p_param, p_service_id, p_err_code);
        IF (p_err_code = 0) THEN
            get_auth_header(p_service_id, p_param.f_auth_header, 
                p_param.f_expiration_date);
            open_connection(p_c, p_param, p_err_code);
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
             p_err_code := SQLCODE;
    END open_connection;
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
                p_err_code    OUT        INTEGER)
    AS
    BEGIN
        close_connection(p_c);
        open_connection(p_c, p_param, p_err_code);
    EXCEPTION
        WHEN OTHERS THEN
             p_err_code := SQLCODE;
    END reopen_connection;
--
--
-- Close tcp connection.
--      p_c          - tcp connection
--
    PROCEDURE close_connection(
                p_c IN OUT NOCOPY utl_tcp.connection)
    AS
    BEGIN
        utl_tcp.close_connection(p_c);
    EXCEPTION
        WHEN OTHERS THEN
             NULL;
    END close_connection;
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
                RETURN      INTEGER
    AS
        p_code INTEGER;
    BEGIN  
        IF (p_text IS NULL) THEN
            p_code := NULL;
        ELSE
            p_code := to_number(substr(p_text,10,3));
        END IF;
        RETURN (p_code);
    EXCEPTION
        WHEN OTHERS THEN
             RETURN (SQLCODE);
    END get_http_result;
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
                p_expiration_date    OUT DATE) 
    AS
        v_expiredate          VARCHAR2(32);
        v_tmp_str             VARCHAR2(4000);
        v_tmp_tok             VARCHAR2(4000);
        v_c                   utl_tcp.connection;
        v_param               service_params;
        i                     INTEGER;
        v_utc_offset          INTEGER := 0;
        v_check_exp_date      DATE;
        v_exp_date_correction NUMBER;
        v_err_code            INTEGER;
        v_client_id           VARCHAR2(128);
        v_secret_id           VARCHAR2(128);
        v_auth_service_id     INTEGER;
        v_request             request;
        v_response            response;
    BEGIN
        p_token           := NULL;
        p_expiration_date := NULL;
        v_expiredate      := NULL;
        IF (p_service_id IS NOT NULL) THEN
            SELECT nvl(utc_offset,0) 
            INTO v_utc_offset 
            FROM SERVICE_PARAMS 
            WHERE id = p_service_id;
            v_exp_date_correction := 
                (1/60/24)+(v_utc_offset/24);
            v_check_exp_date := sysdate;
            BEGIN
                SELECT token, expiration_date 
                INTO p_token, p_expiration_date 
                FROM TOKEN_STORAGE 
                WHERE service_id = p_service_id AND rownum = 1;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                     p_token := NULL;
            END;
            IF (p_token IS NULL) THEN
                SELECT access_key, access_token, auth_service_id 
                INTO v_client_id, v_secret_id, v_auth_service_id 
                FROM SERVICE_PARAMS 
                WHERE id = p_service_id;
                IF (v_auth_service_id IS NULL) THEN
                    v_auth_service_id := p_service_id;
                END IF;
                open_connection(v_auth_service_id, v_c, v_param, v_err_code);
                IF (v_err_code = 0) THEN
                    CASE upper(p_auth_type)
                    WHEN C_AUTH_BEARER THEN
                        init_request(v_request, NULL, 'application/x-www-form-urlencoded', NULL, 
                            'grant_type=client_credentials&client_id=' || v_client_id ||
                            '&client_secret=' || v_secret_id, v_err_code);
                        IF (v_err_code = 0) THEN
                            init_response(v_response, 'application/json', false, v_err_code);
                        END IF;
                        IF (v_err_code = 0) THEN
                            call_http(v_c, v_param, C_POST, NULL, NULL, 
                                      v_request, v_response, v_err_code);
                        END IF;
                        IF (v_err_code = 0 AND v_response.f_text IS NOT NULL AND dbms_lob.getlength(v_response.f_text) > 0) THEN
                            v_tmp_str := regexp_substr(v_response.f_text, '{.*}', 1, 1);
                            IF (v_tmp_str IS NOT NULL) THEN
                                i := 1;
                                LOOP
                                    v_tmp_tok := regexp_substr(v_tmp_str, '[^,]+', 1, i);
                                    EXIT WHEN (v_tmp_tok IS NULL OR (p_token IS NOT NULL AND v_expiredate IS NOT NULL));
                                    IF (instr(v_tmp_tok, '"access_token":"') > 0) THEN
                                        p_token := substr(v_tmp_tok, 
                                                        instr(v_tmp_tok, '"access_token":"')+length('"access_token":"'), 
                                                        86);
                                    ELSIF instr(v_tmp_tok, '"expires_in":') > 0 THEN
                                        v_expiredate := substr(v_tmp_tok, 
                                                            instr(v_tmp_tok, '"expires_in":')+length('"expires_in":'), 
                                                            length(v_tmp_tok));
                                    END IF;
                                    i := i + 1;
                                END LOOP;
                                IF (p_token IS NOT NULL AND v_expiredate IS NOT NULL) THEN
                                    p_expiration_date := sysdate + to_number(v_expiredate)/60/60/24;
                                    p_expiration_date := p_expiration_date - v_exp_date_correction;
                                END IF;
                            END IF;
                        END IF;
                    WHEN C_AUTH_KEYSTONE THEN
                        init_request(v_request, NULL, 'application/json', NULL, 
                            '{"auth" : {"identity" : {"methods" : ["password"], "password" : {"user" : {"name" : "'||
                            v_client_id||'", "domain" : {"id" : "default"}, "password" : "'||
                            v_secret_id||'"}}}}}', v_err_code);
                        IF (v_err_code = 0) THEN
                            init_response(v_response, 'application/json', false, v_err_code);
                        END IF;
                        IF (v_err_code = 0) THEN
                            call_http(v_c, v_param, C_POST, NULL, NULL, 
                                      v_request, v_response, v_err_code);
                        END IF;
                        IF (v_err_code = 0 AND v_response.f_text IS NOT NULL AND dbms_lob.getlength(v_response.f_text) > 0) THEN
                            v_tmp_tok := regexp_substr(v_response.f_text, 'X-Subject-Token:(.*)', 1, 1);
                            IF (instr(v_tmp_tok, 'X-Subject-Token: ') > 0) THEN
                                p_token := substr(v_tmp_tok, 
                                                instr(v_tmp_tok, 'X-Subject-Token: ')+length('X-Subject-Token: '), 
                                                length(v_tmp_tok));
                            END IF;
                            v_tmp_str := regexp_substr(v_response.f_text, '{.*}', 1, 1);
                            IF (v_tmp_str IS NOT NULL) THEN
                                i := 1;
                                LOOP
                                    v_tmp_tok := regexp_substr(v_tmp_str, '[^,]+', 1, i);
                                    EXIT WHEN (v_tmp_tok IS NULL OR (p_token IS NOT NULL AND v_expiredate IS NOT NULL));
                                    IF (instr(v_tmp_tok, '"expires_at": "') > 0) THEN
                                        v_expiredate := replace(substr(v_tmp_tok, 
                                                                    instr(v_tmp_tok, '"expires_at": "')+length('"expires_at": "'), 
                                                                    19),
                                                                'T',' ');
                                    END IF;
                                    i := i + 1;
                                END LOOP;
                                IF (p_token IS NOT NULL AND v_expiredate IS NOT NULL) THEN
                                    p_expiration_date := to_date(v_expiredate,'YYYY-MM-DD hh24:mi:ss');
                                    p_expiration_date := p_expiration_date - v_exp_date_correction;
                                END IF;
                            END IF;
                        END IF;
                    END CASE;
                    IF (v_err_code = 0) THEN
                        DELETE FROM TOKEN_STORAGE 
                        WHERE service_id = p_service_id 
                        AND expiration_date < v_check_exp_date;
                        IF (p_token IS NOT NULL) THEN
                            INSERT INTO TOKEN_STORAGE(service_id, token, expiration_date)
                            VALUES(p_service_id, p_token, p_expiration_date);
                        END IF;
                        COMMIT;
                    END IF;
                END IF;
                close_connection(v_c);
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
             p_token := NULL;
             p_expiration_date := NULL;
    END get_token;
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
                p_expiration_date    OUT DATE)
    AS
        v_cnt       INTEGER;
        v_auth_type VARCHAR2(16);
        v_token     VARCHAR2(256);
        v_idaccess  VARCHAR2(128);
        v_pwaccess  VARCHAR2(128);
    BEGIN
        p_auth_str := NULL;
        p_expiration_date := NULL;
        IF (p_service_id IS NOT NULL) THEN
            SELECT auth_type, access_key, access_token 
            INTO v_auth_type, v_idaccess, v_pwaccess 
            FROM SERVICE_PARAMS 
            WHERE id = p_service_id;
            CASE upper(v_auth_type)
            WHEN C_AUTH_BEARER THEN
                get_token(p_service_id, v_auth_type, v_token, p_expiration_date);
                p_auth_str := 'Authorization: Bearer '||v_token;
            WHEN C_AUTH_BASIC THEN
                IF (v_idaccess IS NOT NULL) THEN
                    p_auth_str := 'Authorization: Basic '||v_idaccess||':'||v_pwaccess;
                ELSE
                    p_auth_str := 'Authorization: Basic '||v_pwaccess;
                END IF;
            WHEN C_AUTH_TOKEN THEN
                IF (v_idaccess IS NOT NULL) THEN
                    p_auth_str := 'token: Basic '||v_idaccess||':'||v_pwaccess;
                ELSE
                    p_auth_str := 'token: Basic '||v_pwaccess;
                END IF;
            WHEN C_AUTH_KEYSTONE THEN
                get_token(p_service_id, v_auth_type, v_token, p_expiration_date);
                p_auth_str := 'X-Auth-Token: '||v_token;
            END CASE;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
             p_auth_str := NULL;
             p_expiration_date := NULL;
    END get_auth_header; 
--
--
-- Send binary data into connection.
--      p_c          - tcp connection
--      p_data       - binary data
--
    PROCEDURE write_data(
                p_c    IN OUT NOCOPY utl_tcp.connection, 
                p_data IN            BLOB)
    AS
        v_ret    PLS_INTEGER;
        v_size   PLS_INTEGER := 4080;
        v_buffer RAW(4080);
        v_offset PLS_INTEGER;
        v_len    PLS_INTEGER;
    BEGIN
        IF (p_data IS NOT NULL) THEN
            v_offset := 1;
            v_len    := dbms_lob.getlength(p_data);
            LOOP
                v_buffer := dbms_lob.substr(p_data, v_size, v_offset);
                v_offset := v_offset + v_size;
                v_ret    := utl_tcp.write_raw(p_c, v_buffer);
                EXIT WHEN ((utl_raw.length(v_buffer) < v_size) or (v_offset >= v_len));
            END LOOP;  
        END IF;    
    END write_data;
--
--
-- Send text data into connection.
--      p_c          - tcp connection
--      p_text       - text data
--
    PROCEDURE write_text(
                p_c    IN OUT NOCOPY utl_tcp.connection, 
                p_text IN            CLOB)
    AS
        v_ret    PLS_INTEGER;
        v_size   PLS_INTEGER := 4080;
        v_buffer RAW(4080);
        v_offset PLS_INTEGER;
        v_len    PLS_INTEGER;
    BEGIN
        IF (p_text IS NOT NULL) THEN
            v_offset := 1;
            v_len    := dbms_lob.getlength(p_text);
            LOOP
                v_buffer := utl_raw.cast_to_raw(dbms_lob.substr(p_text, v_size, v_offset));
                v_offset := v_offset + v_size;
                v_ret    := utl_tcp.write_raw(p_c, v_buffer);
                EXIT WHEN ((utl_raw.length(v_buffer) < v_size) or (v_offset >= v_len));
            END LOOP;
        END IF;
    END write_text;
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
                p_query    IN            VARCHAR2)
    AS
        v_ret PLS_INTEGER;
        v_url VARCHAR2(512);
    BEGIN
        v_url := p_param.f_url||p_function;
        IF (p_query IS NOT NULL) THEN
            v_url := v_url||'?'||p_query;
        END IF;
        IF (p_param.f_expiration_date IS NOT NULL AND p_param.f_expiration_date <= sysdate) THEN
            get_auth_header(p_param.f_service_id, p_param.f_auth_header, p_param.f_expiration_date);
        END IF;
        IF (p_param.f_host_protocol = C_HTTP_1) THEN
            v_ret := utl_tcp.write_line(p_c, p_method||' '||v_url||' '||C_HTTP_1);
            v_ret := utl_tcp.write_line(p_c, 'Host: '||p_param.f_host_name);
        ELSE
            v_ret := utl_tcp.write_line(p_c, p_method||' '||v_url||' '||C_HTTP_0);
        END IF;
        IF (p_param.f_auth_header IS NOT NULL) THEN
            v_ret := utl_tcp.write_line(p_c, p_param.f_auth_header);
        END IF;
        v_ret := utl_tcp.write_line(p_c, 'Cache-Control: no-cache');
    END set_request;
--
--
-- Set request body.
--      p_c            - tcp connection
--      p_request      - request record
-- 
    PROCEDURE set_body(
                p_c            IN OUT NOCOPY utl_tcp.connection,
                p_request      IN            request)
    AS
        v_ret               PLS_INTEGER;
        v_boundary          VARCHAR2(128);
        v_body_length       INTEGER;
        v_part_content_type VARCHAR2(50);
    BEGIN
        IF (p_request.f_data IS NOT NULL) THEN
            v_body_length := dbms_lob.getlength(p_request.f_data);
        ELSIF (p_request.f_text IS NOT NULL) THEN    
            v_body_length := dbms_lob.getlength(p_request.f_text);
        ELSE
            v_body_length := 0;
        END IF;
        IF (p_request.f_content_type = 'multipart/form-data') THEN
            v_boundary := sys_guid();
            IF (v_body_length > 0) THEN
                IF (p_request.f_data IS NOT NULL) THEN
                    v_part_content_type := 'application/octet-stream';
                ELSE
                    v_part_content_type := 'text/plain';
                END IF;
                v_body_length := v_body_length + length('Content-Type: ' || v_part_content_type) + 
                                                 length(p_request.f_header) + 
                                                 length(v_boundary)*2 + 6 + 10;
                v_ret := utl_tcp.write_line(p_c, 'Content-Type: ' || p_request.f_content_type || '; boundary="' || v_boundary || '"');
                v_ret := utl_tcp.write_line(p_c, 'Content-Length: ' || to_char(v_body_length));
                v_ret := utl_tcp.write_line(p_c);
                v_ret := utl_tcp.write_line(p_c, '--' || v_boundary);
                v_ret := utl_tcp.write_line(p_c, p_request.f_header);
                v_ret := utl_tcp.write_line(p_c, 'Content-Type: ' || v_part_content_type);
                v_ret := utl_tcp.write_line(p_c);
                IF (p_request.f_data IS NOT NULL) THEN
                    write_data(p_c, p_request.f_data);
                ELSE
                    write_text(p_c, p_request.f_text);
                END IF;              
                v_ret := utl_tcp.write_line(p_c);
                v_ret := utl_tcp.write_line(p_c, '--' || v_boundary || '--');
            ELSE
                IF (p_request.f_header IS NOT NULL) THEN
                    v_ret := utl_tcp.write_line(p_c, p_request.f_header);
                END IF;
                v_ret := utl_tcp.write_line(p_c);
            END IF;
        ELSE
            IF (v_body_length > 0) THEN
                v_ret := utl_tcp.write_line(p_c, 'Content-Type: ' || p_request.f_content_type || ';');
                v_ret := utl_tcp.write_line(p_c, 'Content-Length: ' || to_char(v_body_length));
            END IF; 
            IF (p_request.f_header IS NOT NULL) THEN
                v_ret := utl_tcp.write_line(p_c, p_request.f_header);
            END IF;
            v_ret := utl_tcp.write_line(p_c);
            IF (v_body_length > 0) THEN
                IF (p_request.f_data IS NOT NULL) THEN
                    write_data(p_c, p_request.f_data);
                ELSE
                    write_text(p_c, p_request.f_text);
                END IF;              
            END IF;
        END IF;
    END set_body;
--
--
-- Send request with binary body to service.
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
                p_err_code        OUT        INTEGER)
    AS
    BEGIN
        set_request(p_c, p_param, p_method, p_function, p_query);
        set_body(p_c, p_request);
        IF (p_param.f_out_buffer_size > 0) THEN
            utl_tcp.flush(p_c);
        END IF;      
        p_err_code := 0;
    EXCEPTION
        WHEN OTHERS THEN
             p_err_code := SQLCODE;
    END send_request;
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
                p_chunk         OUT        RAW)
    AS
        v_ret PLS_INTEGER;
    BEGIN
        v_ret := utl_tcp.read_raw(p_c, p_chunk, p_chunk_size);
        dbms_lob.writeappend(p_data, utl_raw.length(p_chunk), p_chunk);    
    END read_data_chunk;
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
                p_chunk      OUT           VARCHAR2)
    AS
        v_ret PLS_INTEGER;
    BEGIN
        v_ret := utl_tcp.read_text(p_c, p_chunk, p_chunk_size);
        dbms_lob.writeappend(p_text, length(p_chunk), p_chunk);
    END read_text_chunk;
--
--
-- Read data file from connection.
--      p_c            - tcp connection
--      p_data         - binary data (file)
--      p_header       - http header 
--
    PROCEDURE read_data_file(
                p_c      IN OUT NOCOPY utl_tcp.connection, 
                p_data      OUT        BLOB, 
                p_header    OUT        VARCHAR2)
    AS
        v_raw        RAW(32767);
        v_file_beg   BOOLEAN;
        v_buff_max   INTEGER := 32767;
        v_line       VARCHAR2(32767);
        v_is_chunked BOOLEAN;
        v_chunk_size INTEGER;
        v_buff_size  INTEGER;
    BEGIN
        p_header     := NULL;
        v_file_beg   := false;
        v_is_chunked := false;
        v_chunk_size := 0;
        dbms_lob.createtemporary(p_data, false);
        LOOP
            IF (v_file_beg) THEN
                IF (v_is_chunked AND v_chunk_size = 0) THEN 
                    v_line := utl_tcp.get_line(p_c, true, false);
                    BEGIN
                        v_chunk_size := to_number(trim(v_line),trim(rpad(' ',length(v_line)+1,'x')));
                    EXCEPTION
                        WHEN OTHERS THEN
                             v_chunk_size := 0;
                    END;
                    EXIT WHEN (v_chunk_size <= 0);
                    IF (v_chunk_size > 0) THEN
                        IF v_chunk_size <= v_buff_max THEN
                            v_buff_size := v_chunk_size;
                        ELSE
                            v_buff_size := v_buff_max;
                        END IF;
                        LOOP 
                            read_data_chunk(p_c, p_data, v_buff_size, v_raw);
                            v_chunk_size := v_chunk_size - v_buff_size;
                            EXIT WHEN (v_chunk_size <= 0);
                            IF (v_chunk_size <= v_buff_max) THEN
                                v_buff_size := v_chunk_size;
                            ELSE
                                v_buff_size := v_buff_max;
                            END IF;
                        END LOOP;
                        v_chunk_size := 0;
                        v_line := utl_tcp.get_line(p_c, true, false);
                    END IF;
                ELSIF (NOT v_is_chunked) THEN
                    v_buff_size := v_buff_max;
                    read_data_chunk(p_c, p_data, v_buff_size, v_raw);
                END IF;
            ELSE
                v_line := utl_tcp.get_line(p_c, true, false);
                IF (p_header IS NULL) THEN
                    p_header := substr(v_line,1,4000);
                END IF;
                IF (v_line IS NULL) THEN
                    v_file_beg := true;
                ELSE
                    IF (NOT v_is_chunked AND instr(upper(v_line),upper('Transfer-Encoding: chunked')) > 0) THEN
                        v_is_chunked := true;
                    END IF;
                END IF;
            END IF;
        END LOOP;
    EXCEPTION
        WHEN utl_tcp.end_of_input THEN
             NULL;
        WHEN OTHERS THEN
             NULL;
    END read_data_file;
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
                p_header    OUT        VARCHAR2)
    AS
        v_text       VARCHAR2(32767);
        v_file_beg   BOOLEAN;
        v_buff_max   INTEGER := 32767;
        v_line       VARCHAR2(32767);
        v_is_chunked BOOLEAN;
        v_chunk_size INTEGER;
        v_buff_size  INTEGER;
    BEGIN
        p_header     := NULL;
        v_file_beg   := false;
        v_is_chunked := false;
        v_chunk_size := 0;
        dbms_lob.createtemporary(p_text, false);
        LOOP
            IF (v_file_beg) THEN
                IF (v_is_chunked AND v_chunk_size = 0) THEN 
                    v_line := utl_tcp.get_line(p_c, true, false);
                    BEGIN
                        v_chunk_size := to_number(trim(v_line),trim(rpad(' ',length(v_line)+1,'x')));
                    EXCEPTION
                        WHEN OTHERS THEN
                             v_chunk_size := 0;
                    END;
                    EXIT WHEN (v_chunk_size <= 0);
                    IF (v_chunk_size > 0) THEN
                        IF (v_chunk_size <= v_buff_max) THEN
                            v_buff_size := v_chunk_size;
                        ELSE
                            v_buff_size := v_buff_max;
                        END IF;
                        LOOP 
                            read_text_chunk(p_c, p_text, v_buff_size, v_text);
                            v_chunk_size := v_chunk_size - v_buff_size;
                            EXIT WHEN (v_chunk_size <= 0);
                            IF (v_chunk_size <= v_buff_max) THEN
                                v_buff_size := v_chunk_size;
                            ELSE
                                v_buff_size := v_buff_max;
                            END IF;
                        END LOOP;
                        v_chunk_size := 0;
                        v_line := utl_tcp.get_line(p_c, true, false);
                    END IF;
                ELSIF (NOT v_is_chunked) THEN
                    v_buff_size := v_buff_max;
                    read_text_chunk(p_c, p_text, v_buff_size, v_text);
                END IF;
            ELSE
                v_line := utl_tcp.get_line(p_c, true, false);
                IF (p_header IS NULL) THEN
                    p_header := substr(v_line,1,4000);
                END IF;
                IF (v_line IS NULL) THEN
                    v_file_beg := true;
                ELSE
                    IF (NOT v_is_chunked AND instr(upper(v_line),upper('Transfer-Encoding: chunked')) > 0) THEN
                        v_is_chunked := true;
                    END IF;
                END IF;
            END IF;
        END LOOP;
    EXCEPTION
        WHEN utl_tcp.end_of_input THEN
             NULL;
        WHEN OTHERS THEN
             NULL;
    END read_text_file;
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
                p_header     OUT        VARCHAR2)
    AS
        v_raw       RAW(32767);
        v_buff_size INTEGER := 32767;
    BEGIN
        p_header := NULL;
        dbms_lob.createtemporary(p_data, false);
        LOOP
            read_data_chunk(p_c, p_data, v_buff_size, v_raw);
            IF (p_header IS NULL) THEN
                p_header := substr(utl_raw.cast_to_varchar2(v_raw),1,4000);
            END IF;
        END LOOP;
    EXCEPTION
        WHEN utl_tcp.end_of_input THEN
             NULL;
        WHEN OTHERS THEN
             NULL;
    END read_data;
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
                p_header     OUT        VARCHAR2)
    AS
        v_text      VARCHAR2(32767);
        v_buff_size INTEGER := 32767;
    BEGIN
        p_header := NULL;
        dbms_lob.createtemporary(p_text, false);
        LOOP
            read_text_chunk(p_c, p_text, v_buff_size, v_text);
            IF (p_header IS NULL) THEN
                p_header := substr(v_text,1,4000);
            END IF;
        END LOOP;
    EXCEPTION
        WHEN utl_tcp.end_of_input THEN
             NULL;
        WHEN OTHERS THEN
             NULL;
    END read_text;
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
                p_header     OUT        VARCHAR2)
    AS
    BEGIN
        read_text(p_c, p_json, p_header);
        IF (p_json IS NOT NULL) THEN
            p_json := regexp_substr(p_json, '{.*}', 1, 1);
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
             NULL;
    END read_json;
--
--
-- Get response from connection.
--      p_c            - tcp connection
--      p_response     - response record
--
    PROCEDURE get_response(
                p_c        IN OUT NOCOPY utl_tcp.connection, 
                p_response IN OUT NOCOPY response)
    AS  
    BEGIN
        CASE lower(p_response.f_content_type)
        WHEN 'application/octet-stream' THEN
            IF (p_response.f_is_file) THEN
                read_data_file(p_c, p_response.f_data, p_response.f_header);
            ELSE
                read_data(p_c, p_response.f_data, p_response.f_header);
            END IF;
        WHEN 'application/json' THEN
            IF (p_response.f_is_file) THEN
                read_text_file(p_c, p_response.f_text, p_response.f_header);
            ELSE
                read_json(p_c, p_response.f_text, p_response.f_header);
            END IF;
        ELSE
            p_response.f_data := NULL;
            p_response.f_text := NULL;
            p_response.f_header := NULL;
        END CASE;
    EXCEPTION
        WHEN OTHERS THEN
             p_response.f_data := NULL;
             p_response.f_text := NULL;
             p_response.f_header := NULL;
    END get_response;
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
                p_err_code    OUT        INTEGER)
    AS
    BEGIN
        get_response(p_c, p_response);
        p_response.f_code := get_http_result(p_response.f_header);
        IF (p_response.f_code in (200,201)) THEN
            p_err_code := 0;
        ELSE
            IF (p_response.f_code < 0) THEN
                p_err_code := p_response.f_code;
            ELSE
                p_err_code := -29269;
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
             p_err_code := SQLCODE;
    END receive_response;
--
--
-- Send request and receive response.
--      p_c            - tcp connection
--      p_param        - record with service params
--      p_method       - request method (POST, GET, HEAD, PUT, PATCH, DELETE)
--      p_function     - endpoint function
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
                p_err_code        OUT        INTEGER)
    AS
    BEGIN       
        send_request(p_c, p_param, p_method, p_function, p_query, p_request, p_err_code);
        IF (p_err_code = 0) then
            receive_response(p_c, p_response, p_err_code);
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
             p_err_code := SQLCODE;
    END call_http;
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
                p_err_code        OUT INTEGER)    
    AS
        v_c     utl_tcp.connection;
        v_param service_params;
    BEGIN
        open_connection(p_service_id, v_c, v_param, p_err_code);
        IF (p_err_code = 0) THEN
            call_http(v_c, v_param, p_method, p_function, p_query, 
                      p_request, p_response, p_err_code);
        END IF;
        close_connection(v_c);
    EXCEPTION
        WHEN OTHERS THEN
             p_err_code := SQLCODE;
    END call_http;    
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
                p_err_code    OUT        INTEGER)
    AS
        v_request  request;
        v_response response;
    BEGIN
        p_result := NULL;
        init_request(v_request, 'SOAPAction: "'||p_function||'"', 'text/xml', NULL, p_body, p_err_code);
        IF (p_err_code = 0) THEN
            init_response(v_response, 'text/xml', true, p_err_code);
        END IF;
        IF (p_err_code = 0) THEN
            call_http(p_c, p_param, 'POST', NULL, NULL, 
                      v_request, v_response, p_err_code);
            IF (p_err_code = 0) THEN
                p_result := v_response.f_text;
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
             p_err_code := SQLCODE;
             p_result   := NULL;
    END call_soap;
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
                p_err_code    OUT        INTEGER)
    AS
        v_request  request;
        v_response response;
    BEGIN
        p_result := NULL;
        init_request(v_request, NULL, 'application/soap+xml', NULL, p_body, p_err_code);
        IF (p_err_code = 0) THEN
            init_response(v_response, 'application/soap+xml', true, p_err_code);
        END IF;
        IF (p_err_code = 0) THEN
            call_http(p_c, p_param, 'POST', NULL, NULL, 
                      v_request, v_response, p_err_code);
            IF (p_err_code = 0) THEN
                p_result := v_response.f_text;
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
             p_err_code := SQLCODE;
             p_result   := NULL;
    END call_soap;    
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
                p_err_code      OUT INTEGER)
    AS
        v_c     utl_tcp.connection;
        v_param service_params;
    BEGIN
        open_connection(p_service_id, v_c, v_param, p_err_code);
        IF (p_err_code = 0) THEN
            call_soap(v_c, v_param, p_function, p_body, p_result, p_err_code);
        ELSE
            p_result := NULL;
        END IF;
        close_connection(v_c);
    EXCEPTION
        WHEN OTHERS THEN
             p_err_code := SQLCODE;
             p_result   := NULL;
    END call_soap;
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
                p_err_code      OUT INTEGER)
    AS
        v_c     utl_tcp.connection;
        v_param service_params;
    BEGIN
        open_connection(p_service_id, v_c, v_param, p_err_code);
        IF (p_err_code = 0) THEN
            call_soap(v_c, v_param, p_body, p_result, p_err_code);
        ELSE
            p_result := NULL;
        END IF;
        close_connection(v_c);
    EXCEPTION
        WHEN OTHERS THEN
             p_err_code := SQLCODE;
             p_result   := NULL;
    END call_soap;
END api_client;
/

