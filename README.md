# orclapex-rw-server
Capture Oracle Reports queue data to help migration analysis. 

This is a copy of
`$ORACLE_HOME/reports/admin/sql/rw_server.sql`

Following the instructions in [this blog](http://www.snapdba.com/2016/10/configuring-oracle-reports-server-job-queue-monitoring/#.XUOozegzZaQ), we can record the Oracle Report requests in a table. This means we can analyse who is running which reports how often, which will help drive a migration plan to declarative APEX solutions, or perhaps integrate something like [AOP](https://apexofficeprint.com).

- Create schema
- Create tables in schema
- Add configuration to WLS, restart
- Bathe in delicious log data (who, what, when, how long)

Identify those poorly performing reports by comparing the start and finish time.

I also raved about this on [#ThanksOGB](http://www.grassroots-oracle.com/2019/10/ogb-appreciation-day-oracle-reports-queue-monitoring.html) day.
