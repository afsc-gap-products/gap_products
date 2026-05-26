CREATE OR REPLACE VIEW CTD_SUMMARY_V AS 
SELECT * FROM (
    SELECT 
        d.hauljoin, 
        d.depth_m, 
        -- Convert DO in mmols/L to mL/L 
        CASE 
            WHEN c.var_name IN ('DOXY_ML_L', 'DOXY_MMOL_L') THEN 'DOXY_ML_L' 
            ELSE c.var_name 
        END AS var_name,
        CASE 
            WHEN c.var_name = 'DOXY_MMOL_L' THEN d.value / 44.6596
            
            ELSE d.value 
        END AS value
    FROM CTD_DATA d
    JOIN CTD_VARIABLE_CODES c ON d.variable = c.variable
    WHERE d.direction = 0
      AND c.var_name IN ('TEMPERATURE_C', 'SALINITY_PSS78', 'PH', 
                         'DOXY_ML_L', 'DOXY_MMOL_L')
)
PIVOT (
    MAX(value) 
    FOR var_name IN (
        'TEMPERATURE_C'    AS TEMPERATURE_C,
        'SALINITY_PSS78'   AS SALINITY_PSS78,
        'PH'               AS PH,
        'DOXY_ML_L'        AS DOXY_ML_L
    )
);
