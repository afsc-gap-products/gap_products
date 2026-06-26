create or replace PROCEDURE update_field_comments AS

PRAGMA AUTONOMOUS_TRANSACTION; -- Declare an autonomous transaction

CURSOR COLUMN_NAMES IS 
SELECT OWNER, TABLE_NAME, COLUMN_NAME 
FROM all_tab_cols 
WHERE OWNER = 'GAP_PRODUCTS'
AND TABLE_NAME NOT IN ('VOUCHERS');

v_field_description VARCHAR2(4000); 

BEGIN
DBMS_OUTPUT.PUT_LINE('Starting procedure execution at ' || SYSTIMESTAMP);
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
DBMS_OUTPUT.PUT_LINE('Procedure completed at ' || SYSTIMESTAMP);
COMMIT;
END;