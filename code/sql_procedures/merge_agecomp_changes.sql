BEGIN
    -- Merge records based on operation type
    MERGE INTO AGECOMP target
    USING STAGE_AGECOMP source
    ON (target.SURVEY_DEFINITION_ID = source.SURVEY_DEFINITION_ID AND 
        target.AREA_ID_FOOTPRINT    = source.AREA_ID_FOOTPRINT AND
        target.YEAR                 = source.YEAR AND
        target.AREA_ID              = source.AREA_ID AND
        target.SPECIES_CODE         = source.SPECIES_CODE AND
        target.SEX                  = source.SEX AND
        target.AGE                  = source.AGE)
  
    -- Combine UPDATE and DELETE into a single MATCHED block
    WHEN MATCHED THEN 
        UPDATE SET          
            target.POPULATION_COUNT = source.POPULATION_COUNT,
            target.LENGTH_MM_MEAN   = source.LENGTH_MM_MEAN,
            target.LENGTH_MM_SD     = source.LENGTH_MM_SD
        DELETE WHERE source.OPERATION = 'DELETE'
        
    WHEN NOT MATCHED THEN 
        INSERT (SURVEY_DEFINITION_ID, AREA_ID_FOOTPRINT, 
                YEAR, SPECIES_CODE, AREA_ID, 
                SEX, AGE, POPULATION_COUNT, 
                LENGTH_MM_MEAN, LENGTH_MM_SD)
        VALUES (source.SURVEY_DEFINITION_ID, source.AREA_ID_FOOTPRINT, 
                source.YEAR, source.SPECIES_CODE, source.AREA_ID, 
                source.SEX, source.AGE, source.POPULATION_COUNT, 
                source.LENGTH_MM_MEAN, source.LENGTH_MM_SD)
        WHERE source.OPERATION = 'INSERT';

    -- Commit the merge changes explicitly before DDL execution
    COMMIT;

    -- 2. Truncate the stage table
    EXECUTE IMMEDIATE 'TRUNCATE TABLE STAGE_AGECOMP';
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
