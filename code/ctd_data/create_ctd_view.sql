CREATE OR REPLACE PROCEDURE update_ctd_view_structure AS
    v_sql        CLOB;
    v_pivot_cols CLOB;
BEGIN
    -- 1. Gather the current variables
    SELECT LISTAGG('''' || VAR_NAME || ''' AS "' || VAR_NAME || '"', ', ') 
           WITHIN GROUP (ORDER BY VAR_NAME)
    INTO v_pivot_cols
    FROM (SELECT DISTINCT VAR_NAME 
          FROM CTD_VARIABLE_CODES
          WHERE VARIABLE IN (SELECT DISTINCT VARIABLE FROM CTD_DATA WHERE DIRECTION = 0));

    -- 2. Build the CREATE OR REPLACE VIEW statement
    v_sql := 'CREATE OR REPLACE VIEW CTD_SUMMARY_V AS 
        SELECT * FROM (
            SELECT 
                d.hauljoin, 
                d.depth_m, 
                c.var_name,
                d.value
            FROM CTD_DATA d
            JOIN CTD_VARIABLE_CODES c ON d.variable = c.variable
            WHERE d.direction = 0
        )
        PIVOT (
            MAX(value) 
            FOR var_name IN (' || v_pivot_cols || ')
        )';

    -- 3. Execute the DDL to create/update the view
    EXECUTE IMMEDIATE v_sql;
END;
/

EXEC update_ctd_view_structure;