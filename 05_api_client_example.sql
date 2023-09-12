--
--
-- Example of using package
-- Procedures: rem_service
--             add_service
--             refresh_acl
--             init_request
--             init_response
--             call_http
DECLARE
    v_service_id INTEGER;
    v_service_name VARCHAR2(32) := 'ipwhois';
    v_service_host_name VARCHAR2(32) := 'ipwho.is';
    v_service_host_ip VARCHAR2(32) := 'ipwho.is';
    v_ip_address VARCHAR2(15) := '8.8.8.8';
    v_request API_USER.API_CLIENT.request;
    v_response API_USER.API_CLIENT.response;
    v_err_code INTEGER;
BEGIN
    API_USER.API_CLIENT.rem_service('ipwhois',
                                    v_err_code);
    API_USER.API_CLIENT.add_service(p_service_id    => v_service_id, 
                                    p_name          => v_service_name, 
                                    p_host_name     => v_service_host_name, 
                                    p_host_ip       => v_service_host_ip,
                                    p_host_port     => 80,
                                    p_host_url      => '/',
                                    p_host_protocol => API_USER.API_CLIENT.C_HTTP_1,
                                    p_tx_timeout    => 3);
    API_USER.API_CLIENT.refresh_acl(v_err_code); 
    IF (v_service_id > 0 AND v_err_code = 0) THEN
        API_USER.API_CLIENT.init_request(p_request      => v_request,
                                         p_header       => NULL,
                                         p_content_type => NULL,
                                         p_data         => NULL,
                                         p_text         => NULL,
                                         p_err_code     => v_err_code);
        IF (v_err_code = 0) THEN
            API_USER.API_CLIENT.init_response(v_response, 
                                              'application/json', 
                                              FALSE, 
                                              v_err_code);
            IF (v_err_code = 0) THEN
                API_USER.API_CLIENT.call_http(v_service_id,
                                              API_USER.API_CLIENT.C_GET,
                                              v_ip_address,
                                              NULL,
                                              v_request,
                                              v_response,
                                              v_err_code);
                IF (v_err_code = 0) THEN
                    dbms_output.put_line(dbms_lob.substr(v_response.f_text,4000));
                END IF;                             
            END IF;
        END IF;
    END IF;
    IF (v_err_code < 0) THEN
        dbms_output.put_line('error code SQL'||v_err_code);
    END IF;
END;