CREATE OR REPLACE PROCEDURE check_mv_and_job_status (
    p_mv_cursor    OUT SYS_REFCURSOR
) AS
BEGIN
    -- Query 1: Open cursor for Materialized View Freshness
    OPEN p_mv_cursor FOR
        SELECT mview_name, 
               staleness, 
               last_refresh_date, 
               compile_state
        FROM user_mviews
        ORDER BY staleness, mview_name;
END;
/