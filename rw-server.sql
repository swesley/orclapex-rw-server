REM
REM
REM Name
REM ----
REM rw_server.sql
REM
REM Version
REM -------
REM 9.0.4.0.0
REM
REM Description
REM -----------
REM  Reports Server Queue PL/SQL Table and API. This is a read-only copy of the
REM  Report Server job queue (i.e. manually inserting a row in the table will
REM  not submit a job).
REM
REM  The Event-Based Publishing API can be used to submit jobs to the Reports
REM  Server from the database (e.g. from a DB Trigger on a Table, AQ, etc.).
REM  For more info, please see the "Publishing Reports" manual.
REM
REM History
REM -------
REM  26-Mar-99 P Narth   Created
REM  31-Mar-99 P Narth   Updated per SLIN's comments
REM  01-Apr-99 P Narth   Updated per SLIN's comments
REM  29-Mar-01 S Lin     Added two new fields: cache_key and cache_hit
REM  28-Feb-02 S Lin     Added 9.0.2 features and create view for backward
REM                      compatibility
REM  04-Mar-02 P Narth   Updated comments throughout. Increased size of fields
REM  12-Dec-06 vajacob   Removed unused status codes
REM
REM Comments
REM --------
REM  Note: This script is only certified to work against Oracle RDBMS 8.1.7 or
REM  later
REM
 
DECLARE
    stmt         VARCHAR2(2000);
    stmt_cursor  NUMBER;
    dummy        NUMBER;
BEGIN
  BEGIN
    stmt        := 'DROP package rw_server.rw_server';
    stmt_cursor := dbms_sql.open_cursor;
    dbms_sql.parse(stmt_cursor, stmt, dbms_sql.v7);
    dummy       := dbms_sql.execute(stmt_cursor);
    dbms_sql.close_cursor(stmt_cursor);
  EXCEPTION
    WHEN OTHERS THEN NULL;
  END;
  BEGIN
    stmt        := 'DROP TABLE rw_server.rw_server_queue';
    stmt_cursor := dbms_sql.open_cursor;
    dbms_sql.parse(stmt_cursor, stmt, dbms_sql.v7);
    dummy       := dbms_sql.execute(stmt_cursor);
    dbms_sql.close_cursor(stmt_cursor);
  EXCEPTION
    WHEN OTHERS THEN NULL;
  END;
  BEGIN
    stmt        := 'DROP VIEW rw_server.rw_server_queue';
    stmt_cursor := dbms_sql.open_cursor;
    dbms_sql.parse(stmt_cursor, stmt, dbms_sql.v7);
    dummy       := dbms_sql.execute(stmt_cursor);
    dbms_sql.close_cursor(stmt_cursor);
  EXCEPTION
    WHEN OTHERS THEN NULL;
  END;
  BEGIN
    stmt        := 'DROP TABLE rw_server.rw_server_job_queue';
    stmt_cursor := dbms_sql.open_cursor;
    dbms_sql.parse(stmt_cursor, stmt, dbms_sql.v7);
    dummy       := dbms_sql.execute(stmt_cursor);
    dbms_sql.close_cursor(stmt_cursor);
  EXCEPTION
    WHEN OTHERS THEN NULL;
  END;
  BEGIN
    stmt        := 'DROP TABLE rw_server.rw_jobs';
    stmt_cursor := dbms_sql.open_cursor;
    dbms_sql.parse(stmt_cursor, stmt, dbms_sql.v7);
    dummy       := dbms_sql.execute(stmt_cursor);
    dbms_sql.close_cursor(stmt_cursor);
  EXCEPTION
    WHEN OTHERS THEN NULL;
  END;
  BEGIN
    stmt        := 'DROP SEQUENCE rw_server.REPORTS_JOBS';
    stmt_cursor := dbms_sql.open_cursor;
    dbms_sql.parse(stmt_cursor, stmt, dbms_sql.v7);
    dummy       := dbms_sql.execute(stmt_cursor);
    dbms_sql.close_cursor(stmt_cursor);
  EXCEPTION
    WHEN OTHERS THEN NULL;
  END;
  COMMIT;
END;
/
 
CREATE SEQUENCE  rw_server.REPORTS_JOBS  MINVALUE 1 INCREMENT BY 1 START WITH 1 CACHE 20 ORDER;
 
CREATE TABLE rw_server.RW_JOBS
   (    "JOBID" NUMBER,
    "SERVERNAME" VARCHAR2(100),
    "JOB" BLOB,
    "OWNER" VARCHAR2(25),
    "ID" NUMBER default  rw_server.REPORTS_JOBS.nextval,
    "STATUS" NUMBER(1,1),
    "QUEUE" NUMBER(1,0),
    "MASTERJOB" NUMBER,
    "CACHEKEY" VARCHAR2(500),
    "EXPIRATION" NUMBER,
     CONSTRAINT "job_server" PRIMARY KEY ("JOBID", "SERVERNAME")
) ;
 
CREATE TABLE rw_server.rw_server_job_queue
(
  job_queue       VARCHAR2(30),   -- States whether the job listed is CURRENT,
                                  -- PAST, or SCHEDULED
  job_id          NUMBER,         -- a generated job identification number
  job_type        VARCHAR2(30),   -- job type, such as report, rwurl, etc,
                                  -- defined in server config file
  job_name        VARCHAR2(4000), -- the report name (or file name if no value
                                  -- for JOBNAME is specified)
  status_code     NUMBER,         -- the current status of the job - see
                                  -- Constants for status_code below
  status_message  VARCHAR2(4000), -- the full status message
  command_line    VARCHAR2(4000), -- all the command line parameters submitted
                                  -- for this report
  owner           VARCHAR2(30),   -- the user that owns and submitted the job
  destype         VARCHAR2(80),   -- the format of the report output
  desname         VARCHAR2(4000), -- the name the report output will be written
                                  -- to (if not going to cache)
  server          VARCHAR2(80),   -- name of server that is running the report
  queued          DATE,           -- date and time this request was received and
                                  -- queued by the reports server
  started         DATE,           -- date and time this job started running
  finished        DATE,           -- date and time this job completed
  run_elapse      NUMBER,         -- elapsed time between started and finished
                                  -- time, in units of milliseconds
  total_elapse    NUMBER,         -- elapsed time between queued and finished
                                  -- time, in units of milliseconds
  last_run        DATE,           -- date and time this job was last run
  next_run        DATE,           -- date and time this job is scheduled to run
                                  -- next
  repeat_interval NUMBER,         -- frequency that scheduled job will run
  repeat_pattern  NUMBER,         -- repeat pattern (every x minutes, hours,
                                  -- days, etc.)
  cache_key       VARCHAR2(4000), -- the criteria used to determine if it was a
                                  -- cache hit or miss
  cache_hit       NUMBER)         -- whether the job had a cache hit. jobid of
                                  -- the hit, or 0 if not hit
/
 
CREATE VIEW rw_server.rw_server_queue
    AS SELECT job_queue job_type,
              job_id,
              job_name,
              status_code,
              status_message,
              command_line,
              owner,
              destype,
              desname,
              server,
              queued,
              started,
              finished,
              last_run,
              next_run,
              repeat_interval,
              repeat_pattern,
              cache_key,
              decode(cache_hit,0,0,1) cache_hit
         FROM rw_server_job_queue
/
 
SET LINESIZE 1000
 
CREATE OR REPLACE PACKAGE rw_server.rw_server IS
 
  /* Public Dataypes */
 
  -- Constants for p_repeat_pattern
  -- The value for <interval> or <weekday> or <day> is IN repeat_interval.
 
  NONE      CONSTANT NUMBER(2)   := 0;   -- job does not repeat
  MINUTES   CONSTANT NUMBER(2)   := 1;   -- every <interval> munites
  DAYS      CONSTANT NUMBER(2)   := 2;   -- every <interval> days
  MONTHS    CONSTANT NUMBER(2)   := 3;   -- every <interval> months
  FIRST     CONSTANT NUMBER(2)   := 4;   -- every 1st <weekday> of each month
  SECOND    CONSTANT NUMBER(2)   := 5;   -- every 2nd <weekday> of each month
  THIRD     CONSTANT NUMBER(2)   := 6;   -- every 3rd <weekday> of each month
  FOURTH    CONSTANT NUMBER(2)   := 7;   -- every 4th <weekday> of each month
  FIFTH     CONSTANT NUMBER(2)   := 8;   -- every 5th <weekday> of each month
  SUNDAY    CONSTANT NUMBER(2)   := 9;   -- last sunday of each month before <day>th
  MONDAY    CONSTANT NUMBER(2)   := 10;  -- last monday of each month before <day>th
  TUESDAY   CONSTANT NUMBER(2)   := 11;  -- last tuesday of each month before <day>th
  WEDNESDAY CONSTANT NUMBER(2)   := 12;  -- last wednesday of each month before <day>th
  THURSDAY  CONSTANT NUMBER(2)   := 13;  -- last thursday of each month before <day>th
  FRIDAY    CONSTANT NUMBER(2)   := 14;  -- last friday of each month before <day>th
  SATURDAY  CONSTANT NUMBER(2)   := 15;  -- last saturday of each month before <day>th
  WEEKDAY   CONSTANT NUMBER(2)   := 16;  -- last weekday of each month before <day>th
  WEEKEND   CONSTANT NUMBER(2)   := 17;  -- last weekend of each month before <day>th
 
 
  -- Constants for p_status_code and status_code in rw_server_queue table (same as zrcct_jstype)
 
  ENQUEUED          CONSTANT NUMBER(2) := 1; -- job is waiting in queue
  RUNNING           CONSTANT NUMBER(2) := 3; -- running report
  FINISHED          CONSTANT NUMBER(2) := 4; -- job has finished
  TERMINATED_W_ERR  CONSTANT NUMBER(2) := 5; -- job has terminated with error
  CANCELED          CONSTANT NUMBER(2) := 7; -- job is canceled upon user request
  SERVER_SHUTDOWN   CONSTANT NUMBER(2) := 8; -- job is canceled as server is shut down
  TRANSFERED        CONSTANT NUMBER(2) := 11;-- job is transfered to another server in the cluster
  VOID_FINISHED     CONSTANT NUMBER(2) := 12;-- job is finished but void because of reaching limit of cache capacity
  ERROR_FINISHED    CONSTANT NUMBER(2) := 13;-- output is successfully generated but failed to send to destinations
  EXPIRED           CONSTANT NUMBER(2) := 15;-- job has expired
 
  /* Public Functions */
 
  FUNCTION insert_job( p_job_queue       IN VARCHAR2,      -- States whether the job listed is CURRENT, COMPLETED, or SCHEDULED
                       p_job_id          IN NUMBER,        -- a generated job identification number
                       p_job_name        IN VARCHAR2,      -- the report name (or file name if no value for JOBNAME is specified)
                       p_status_code     IN NUMBER,        -- the current status of the job - see above constants
                       p_status_message  IN VARCHAR2,      -- the full status message
                       p_command_line    IN VARCHAR2,      -- all the command line parameters submitted for this report
                       p_owner           IN VARCHAR2,      -- the user that owns and submitted the job
                       p_destype         IN VARCHAR2,      -- the format of the report output
                       p_desname         IN VARCHAR2,      -- the name the report output will be written to (if not going to cache)
                       p_server          IN VARCHAR2,      -- name of server that is running the report
                       p_queued          IN DATE,          -- date and time this request was received and queued by the reports server
                       p_started         IN DATE,          -- date and time this reports started running
                       p_finished        IN DATE,          -- date and time this report completed
                       p_last_run        IN DATE,          -- date and time this report was last run
                       p_next_run        IN DATE,          -- date and time this report is scheduled to run next
                       p_repeat_interval IN NUMBER,        -- frequency that scheduled report will run
                       p_repeat_pattern  IN NUMBER,        -- Repeat Pattern (every minutes, hours, days, etc)
                       p_cache_key       IN VARCHAR2,      -- cache detection key
                       p_cache_hit       IN NUMBER,        -- whether the job has a cache hit
                       p_job_type        IN VARCHAR2 DEFAULT 'report', -- job type defined in server config file
                       p_run_elapse      IN NUMBER,        -- elapse time between started and finished time,
                                                           -- in unit of milliseconds
                       p_total_elapse    IN NUMBER)        -- elapse time between queued and finished time,
                                                           -- in unit of milliseconds
  RETURN NUMBER;
 
  FUNCTION remove_job( p_job_id          IN NUMBER,        -- job id number
                       p_server          IN VARCHAR2)      -- server name
  RETURN NUMBER;
 
  FUNCTION clean_up_queue RETURN NUMBER;
 
 
END rw_server;
/
 
CREATE OR REPLACE PACKAGE BODY rw_server.rw_server IS
 
  FUNCTION insert_job( p_job_queue       IN VARCHAR2,
                       p_job_id          IN NUMBER,
                       p_job_name        IN VARCHAR2,
                       p_status_code     IN NUMBER,
                       p_status_message  IN VARCHAR2,
                       p_command_line    IN VARCHAR2,
                       p_owner           IN VARCHAR2,
                       p_destype         IN VARCHAR2,
                       p_desname         IN VARCHAR2,
                       p_server          IN VARCHAR2,
                       p_queued          IN DATE,
                       p_started         IN DATE,
                       p_finished        IN DATE,
                       p_last_run        IN DATE,
                       p_next_run        IN DATE,
                       p_repeat_interval IN NUMBER,
                       p_repeat_pattern  IN NUMBER,
                       p_cache_key       IN VARCHAR2,
                       p_cache_hit       IN NUMBER,
                       p_job_type        IN VARCHAR2,
                       p_run_elapse      IN NUMBER,
                       p_total_elapse    IN NUMBER)
  RETURN NUMBER IS
  BEGIN
    -- suspend logging at any time using
    -- return 0;
    INSERT INTO rw_server_job_queue VALUES (
      p_job_queue,
      p_job_id,
      p_job_type,
      p_job_name,
      p_status_code,
      p_status_message,
      p_command_line,
      p_owner,
      p_destype,
      p_desname,
      p_server,
      p_queued,
      p_started,
      p_finished,
      p_run_elapse,
      p_total_elapse,
      p_last_run,
      p_next_run,
      p_repeat_interval,
      p_repeat_pattern,
      p_cache_key,
      p_cache_hit);
    COMMIT;
    RETURN (SQLCODE);
  EXCEPTION
    WHEN OTHERS THEN RETURN (SQLCODE);
  END insert_job;
 
  FUNCTION remove_job( p_job_id   IN NUMBER,
                       p_server   IN VARCHAR2)
  RETURN NUMBER IS
  BEGIN
    DELETE FROM rw_server_job_queue WHERE job_id = p_job_id AND
                                      server = p_server;
    COMMIT;
    RETURN(SQLCODE);
  EXCEPTION
    WHEN OTHERS THEN RETURN (SQLCODE);
  END remove_job;
 
  FUNCTION clean_up_queue RETURN NUMBER IS
    stmt         VARCHAR2(2000);
    stmt_cursor  NUMBER;
    dummy        NUMBER;
  BEGIN
    stmt        := 'TRUNCATE TABLE RW_SERVER_JOB_QUEUE';
    stmt_cursor := dbms_sql.open_cursor;
    dbms_sql.parse(stmt_cursor, stmt, dbms_sql.v7);
    dummy       := dbms_sql.execute(stmt_cursor);
    dbms_sql.close_cursor(stmt_cursor);
    COMMIT;
    RETURN (SQLCODE);
  EXCEPTION
    WHEN OTHERS THEN RETURN (SQLCODE);
  END clean_up_queue;
 
END rw_server;
/
 
 
SHOW ERRORS
