-- Merge BIOMASS table updates
BEGIN
    -- Merge records based on operation type
    MERGE INTO BIOMASS target
    USING STAGE_BIOMASS source
    ON (target.SURVEY_DEFINITION_ID = source.SURVEY_DEFINITION_ID AND 
        target.YEAR                 = source.YEAR AND
        target.AREA_ID              = source.AREA_ID AND
        target.SPECIES_CODE         = source.SPECIES_CODE)
  
    -- Combined UPDATE and DELETE block
    WHEN MATCHED THEN 
        UPDATE SET              
            target.N_HAUL           = source.N_HAUL,
            target.N_WEIGHT         = source.N_WEIGHT,
            target.N_COUNT          = source.N_COUNT,
            target.N_LENGTH         = source.N_LENGTH,
            target.BIOMASS_MT       = source.BIOMASS_MT,
            target.BIOMASS_VAR      = source.BIOMASS_VAR,
            target.POPULATION_COUNT = source.POPULATION_COUNT,
            target.POPULATION_VAR   = source.POPULATION_VAR,
            target.CPUE_KGKM2_MEAN  = source.CPUE_KGKM2_MEAN,
            target.CPUE_NOKM2_MEAN  = source.CPUE_NOKM2_MEAN,
            target.CPUE_KGKM2_VAR   = source.CPUE_KGKM2_VAR,
            target.CPUE_NOKM2_VAR   = source.CPUE_NOKM2_VAR
        DELETE WHERE source.OPERATION = 'DELETE'
        
    WHEN NOT MATCHED THEN 
        INSERT (SURVEY_DEFINITION_ID, YEAR,
                SPECIES_CODE, AREA_ID,
                N_HAUL, N_WEIGHT, N_COUNT, N_LENGTH,
                CPUE_KGKM2_MEAN, CPUE_KGKM2_VAR,
                CPUE_NOKM2_MEAN, CPUE_NOKM2_VAR,
                BIOMASS_MT, BIOMASS_VAR,
                POPULATION_COUNT, POPULATION_VAR)
        VALUES (source.SURVEY_DEFINITION_ID, source.YEAR, 
                source.SPECIES_CODE, source.AREA_ID, 
                source.N_HAUL, source.N_WEIGHT, source.N_COUNT, source.N_LENGTH,
                source.CPUE_KGKM2_MEAN, source.CPUE_KGKM2_VAR,
                source.CPUE_NOKM2_MEAN, source.CPUE_NOKM2_VAR,
                source.BIOMASS_MT, source.BIOMASS_VAR,
                source.POPULATION_COUNT, source.POPULATION_VAR)
        WHERE source.OPERATION = 'INSERT';

    -- Commit the merge changes explicitly before DDL execution
    COMMIT;

    -- 2. Truncate the stage table
    EXECUTE IMMEDIATE 'TRUNCATE TABLE STAGE_BIOMASS';
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
