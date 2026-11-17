-- =============================================================================
-- 00_run_all.sql
-- Builds the project in one go. Run from the repository root:
--     mysql --local-infile=1 -u root -p < sql/00_run_all.sql
-- =============================================================================

SELECT '== 1/5 Create tables' AS step;
SOURCE sql/01_create_tables.sql;
SELECT '== 2/5 Load data' AS step;
SOURCE sql/02_load_data.sql;
SELECT '== 3/5 Insert, update, delete (rolled back)' AS step;
SOURCE sql/03_insert_update_delete.sql;
SELECT '== 4/5 Views for Power BI' AS step;
SOURCE sql/05_views_for_power_bi.sql;
SELECT '== 5/5 Business questions' AS step;
SOURCE sql/04_basic_queries.sql;
