-- Merge SIZECOMP table updates
BEGIN
    -- Merge records based on operation type
    MERGE INTO SIZECOMP target
    USING STAGE_SIZECOMP source
    ON (target.SURVEY_DEFINITION_ID = source.SURVEY_DEFINITION_ID AND 
        target.YEAR                 = source.YEAR AND
        target.AREA_ID              = source.AREA_ID AND
        target.SPECIES_CODE         = source.SPECIES_CODE AND
        target.SEX                  = source.SEX AND
        target.LENGTH_MM            = source.LENGTH_MM)
  
    -- Combined UPDATE and DELETE block
    WHEN MATCHED THEN 
        UPDATE SET              
            target.POPULATION_COUNT = source.POPULATION_COUNT
        DELETE WHERE source.OPERATION = 'DELETE'
        
    WHEN NOT MATCHED THEN 
        INSERT (SURVEY_DEFINITION_ID, YEAR,
                SPECIES_CODE, AREA_ID, 
                LENGTH_MM, SEX, POPULATION_COUNT)
        VALUES (source.SURVEY_DEFINITION_ID, source.YEAR, 
                source.SPECIES_CODE, source.AREA_ID, 
                source.LENGTH_MM, source.SEX, 
                source.POPULATION_COUNT)
        WHERE source.OPERATION = 'INSERT';

    -- Commit the merge changes explicitly before DDL execution
    COMMIT;

    -- 2. Truncate the stage table
    EXECUTE IMMEDIATE 'TRUNCATE TABLE STAGE_SIZECOMP';
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
