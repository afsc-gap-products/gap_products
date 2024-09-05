-- Set up the Procedure to loop through every column in GAP_PRODUCTS and 
-- update the column comment with what is in GAP_PRODUCTS.METADATA_COLUMN

CREATE OR REPLACE PROCEDURE update_field_comments AS
    
    PRAGMA AUTONOMOUS_TRANSACTION; -- Declare an autonomous transaction

    -- Query all column names from every table in GAP_PRODUCTS EXCEPT VOUCHERS
    CURSOR COLUMN_NAMES IS 
        SELECT OWNER, TABLE_NAME, COLUMN_NAME 
        FROM all_tab_cols 
        WHERE OWNER = 'GAP_PRODUCTS'
        AND TABLE_NAME NOT IN ('VOUCHERS');

    v_field_description VARCHAR2(4000); -- temporary string variable
    
BEGIN
    DBMS_OUTPUT.PUT_LINE('Updating Field Comments');
    FOR rec IN COLUMN_NAMES LOOP
        BEGIN
            -- Attempt to find the field description from GAP_PRODUCTS.METADATA_COLUMN
            SELECT METADATA_COLNAME_DESC
            INTO v_field_description
            FROM GAP_PRODUCTS.METADATA_COLUMN
            WHERE METADATA_COLNAME = rec.COLUMN_NAME
            AND ROWNUM = 1;  -- Ensure we only get one record

            -- Update the comment on the column if a description is found
            IF v_field_description IS NOT NULL THEN
                EXECUTE IMMEDIATE 'COMMENT ON COLUMN ' || rec.OWNER || '.' || rec.TABLE_NAME || '.' || rec.COLUMN_NAME || ' IS ''' || v_field_description || '''';
            END IF;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                -- No matching metadata column, continue to the next
                NULL;
            WHEN OTHERS THEN
                -- Log unexpected errors and continue
                DBMS_OUTPUT.PUT_LINE('An error occurred for column ' || rec.COLUMN_NAME || ': ' || SQLERRM);
        END;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('Finished Updating Field Comments');
END;

-- Set up the Trigger
CREATE OR REPLACE TRIGGER trg_update_field_comments
AFTER INSERT OR UPDATE OR DELETE ON GAP_PRODUCTS.METADATA_COLUMN
BEGIN
    -- Call procedure to update field comments across all GAP_PRODUCTS tables
    update_field_comments;
END;