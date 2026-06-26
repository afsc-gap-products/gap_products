create or replace PROCEDURE UPDATE_TABLE_COMMENTS AS

  CURSOR GP_TABLES IS 
    SELECT MVIEW_NAME AS TABLE_NAME, 'MATERIALIZED VIEW' TABLE_TYPE 
    FROM USER_MVIEW_COMMENTS
    
        UNION
    
    SELECT TABLE_NAME, TABLE_TYPE 
    FROM ALL_TAB_COMMENTS 
    WHERE OWNER = 'GAP_PRODUCTS' AND TABLE_TYPE = 'TABLE' AND TABLE_NAME != 'VOUCHERS';

  v_comment_text VARCHAR2(4000);  -- Variable to store the concatenated string
  v_noaa_text VARCHAR2(4000);  -- Variable to store the concatenated string
  v_last_ddl_time VARCHAR2(100);  -- Variable to store the last DDL time
  v_description_name VARCHAR2(255);  -- Variable to store the concatenated name for metadata
BEGIN
  FOR REC IN GP_TABLES LOOP
    BEGIN
      -- Step 1: Generate the concatenated string
      v_description_name := LOWER(REC.TABLE_NAME) || '_description';

      -- Step 2: Get the last DDL time of the table
      SELECT TO_CHAR(LAST_DDL_TIME, 'DD Month YYYY')
      INTO v_last_ddl_time
      FROM USER_OBJECTS
      WHERE OBJECT_NAME = REC.TABLE_NAME
      AND OBJECT_TYPE = 'TABLE';

      SELECT metadata_sentence
      INTO v_comment_text
      FROM METADATA_TABLE
      WHERE metadata_sentence_name = v_description_name;

      -- Step 3: Concatenate the metadata_sentence values
       SELECT LISTAGG(metadata_sentence, ' ') WITHIN GROUP (
        ORDER BY
          CASE metadata_sentence_name
            WHEN 'survey_institution' THEN 1
            WHEN 'github' THEN 2
            WHEN 'legal_restrict_none' THEN 3
            ELSE 5  -- For any unexpected values, ensure they are sorted last
          END
      ) INTO v_noaa_text
      FROM METADATA_TABLE
      WHERE metadata_sentence_name IN (
        'survey_institution',
        'github',
        'legal_restrict_none'
      );

      -- Step 4: Append the last DDL time to the concatenated string
      v_noaa_text := 'This table was created ' || v_noaa_text || ' Last updated on ' || v_last_ddl_time || '.';

      -- Debug output to verify comment text
      DBMS_OUTPUT.PUT_LINE('COMMENT ON ' || REC.TABLE_TYPE || ' GAP_PRODUCTS.' || REC.TABLE_NAME || ' IS ''' || v_comment_text || ' ' || v_noaa_text || '''');

      -- Step 5: Use the concatenated string with last DDL time as a comment for a table
      EXECUTE IMMEDIATE 'COMMENT ON ' || REC.TABLE_TYPE || ' GAP_PRODUCTS.' || REC.TABLE_NAME || ' IS ''' || v_comment_text || ' ' || v_noaa_text || '''';

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No data found for table ' || REC.TABLE_NAME);
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error for table ' || REC.TABLE_NAME || ': ' || SQLERRM);
    END;
  END LOOP;
END;