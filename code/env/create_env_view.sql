CREATE OR REPLACE VIEW ENVIRONMENTAL_SUMMARY_V AS 
SELECT * FROM (
    SELECT 
        d.hauljoin, 
        d.depth_m, 
        -- Convert DO in mmols/L to mL/L 
        CASE 
            WHEN c.name IN ('DOXY_ML_L', 'DOXY_MMOL_L') THEN 'DOXY_ML_L' 
            ELSE c.name 
        END AS name,
        CASE 
            WHEN c.name = 'DOXY_MMOL_L' THEN d.value / 44.6596
            
            ELSE d.value 
        END AS value
    FROM ENVIRONMENTAL d
    JOIN VARIABLE_CODES c ON d.variable = c.variable
    WHERE d.direction = 0
    AND INSTRUMENT IN (1,2,3,4,5) -- only CTD data
    AND c.name IN ('TEMPERATURE_C', 'SALINITY_PSS78', 'PH', 
                         'DOXY_ML_L', 'DOXY_MMOL_L')
)
PIVOT (
    MAX(value) 
    FOR name IN (
        'TEMPERATURE_C'    AS TEMPERATURE_C,
        'SALINITY_PSS78'   AS SALINITY_PSS78,
        'PH'               AS PH,
        'DOXY_ML_L'        AS DOXY_ML_L
    )
);
