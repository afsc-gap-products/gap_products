-- Merge CPUE table updates
BEGIN
    -- Merge records based on operation type
    MERGE INTO CPUE target
    USING STAGE_CPUE source
    ON (target.HAULJOIN = source.HAULJOIN AND 
        target.SPECIES_CODE = source.SPECIES_CODE)
  
    -- Combined UPDATE and DELETE block
    WHEN MATCHED THEN 
        UPDATE SET              
            target.WEIGHT_KG      = source.WEIGHT_KG,
            target.COUNT          = source.COUNT,
            target.AREA_SWEPT_KM2 = source.AREA_SWEPT_KM2,
            target.CPUE_KGKM2     = source.CPUE_KGKM2,
            target.CPUE_NOKM2     = source.CPUE_NOKM2
        DELETE WHERE source.OPERATION = 'DELETE'
        
    WHEN NOT MATCHED THEN 
        INSERT (HAULJOIN, SPECIES_CODE, WEIGHT_KG, 
                COUNT, AREA_SWEPT_KM2, 
                CPUE_KGKM2, CPUE_NOKM2)
        VALUES (source.HAULJOIN, source.SPECIES_CODE, source.WEIGHT_KG, 
                source.COUNT, source.AREA_SWEPT_KM2, 
                source.CPUE_KGKM2, source.CPUE_NOKM2)
        WHERE source.OPERATION = 'INSERT';

    -- Commit the merge changes explicitly before DDL execution
    COMMIT;

    -- 2. Truncate the stage table
    EXECUTE IMMEDIATE 'TRUNCATE TABLE STAGE_CPUE';
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
