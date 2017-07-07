require "anomaly_detection/version"
require "active_record"

module AnomalyDetection

  def self.create_function
    ActiveRecord::Base.connection.execute <<-SQL

    CREATE type anomaly_row as (time_unit varchar, count bigint);

    CREATE OR REPLACE FUNCTION anom_detect_static(table_name regclass, groupby_col text, filter_column text,
    	  from_date timestamp,
    	  date_upto timestamp, time_unit text, threshold integer)
    	RETURNS SETOF anomaly_row AS
    	$func$
    	BEGIN
    	RETURN QUERY
    	EXECUTE
    	  'WITH COUNT_QUERY AS (
    	    SELECT extract(' || time_unit || ' from ' || groupby_col || ')::varchar AS gcol, count(1) as count' ||
    	    ' FROM ' || table_name
    	    || ' where ' || filter_column || ' >= ' || '''' || from_date || ''''
    	    ' group by gcol'
    	  || ')'
    	  || ' SELECT * from COUNT_QUERY where count >= ' || threshold;
    	END
    	$func$ language 'plpgsql';
    END;

    CREATE type anomaly_row_perc as (time_unit varchar, count bigint, percofmean numeric);

    CREATE OR REPLACE FUNCTION anom_detect_perc(table_name regclass, groupby_col text, filter_column text,
      	  from_date timestamp, date_upto timestamp, time_unit text, threshold numeric)
      	RETURNS SETOF anomaly_row_perc AS
      	$func$
      	BEGIN
      	RETURN QUERY
      	EXECUTE
      	  'WITH COUNT_QUERY AS (
      	    SELECT extract(' || time_unit || ' from ' || groupby_col || ')::varchar AS gcol, count(1) as count' ||
      	    ' FROM ' || table_name
      	    || ' where ' || filter_column || ' >= ' || '''' || from_date || ''''
      	    ' group by gcol'
      	  || '), COUNT_QUERY_WITH_PERC AS (
      	      select gcol, count, count/(avg(count) OVER ()) * 100 as pct_of_mean
      	      from COUNT_QUERY
      	  )'
      	  || ' SELECT * from COUNT_QUERY_WITH_PERC where pct_of_mean >= ' || threshold;
      	END
      	$func$ language 'plpgsql';
    END;

    create type anomaly_row_zscore as (time_unit varchar, count bigint, percofmean numeric);

    CREATE OR REPLACE FUNCTION anomaly_detect_std_dev(table_name regclass, groupby_col text, filter_column text,
    	  from_date timestamp, date_upto timestamp, time_unit text, threshold numeric)
       RETURNS setof anomaly_row_zscore AS
       $func$
       BEGIN
       RETURN QUERY
       EXECUTE
         'WITH COUNT_QUERY AS (
          SELECT extract(' || time_unit || ' from ' || groupby_col || ')::varchar AS gcol, count(1) as count' ||
          ' FROM ' || table_name
          || ' where ' || filter_column || ' >= ' || '''' || from_date || ''''
          ' group by gcol'
        || '), COUNT_QUERY_WITH_ZSCORE AS (
            select gcol, count, (count - avg(count) OVER ())/(stddev(value) OVER ()) as zscore
            from COUNT_QUERY
        )'
        || ' SELECT * from COUNT_QUERY_WITH_ZSCORE where pct_of_mean >= ' || threshold;
       END
       $func$ language 'plpgsql';
     END;
    SQL
    true
  end

  def self.drop_function
    ActiveRecord::Base.connection.execute <<-SQL
      DROP FUNCTION if exists anom_detect_static(regclass,text,text,timestamp without time zone,timestamp without time zone);
      DROP type if exists anomaly_row;

      drop function if exists anom_detect_perc(regclass,text,text,timestamp without time zone,timestamp without time zone,text, numeric);
      drop type if exists anomaly_row_perc;

      drop function if exists anomaly_detect_zscore(regclass,text,text,timestamp without time zone,timestamp without time zone,text, numeric);
      drop type if exists anomaly_row_zscore;
    SQL
    true
  end

end

module ActiveRecord
  module Querying
    delegate :anomaly_detect_static, to: (Gem::Version.new(Arel::VERSION) >= Gem::Version.new("4.0.1") ? :all : :scoped)
    delegate :anomaly_detect_percofmean, to: (Gem::Version.new(Arel::VERSION) >= Gem::Version.new("4.0.1") ? :all : :scoped)
    delegate :anomaly_detect_zscore, to: (Gem::Version.new(Arel::VERSION) >= Gem::Version.new("4.0.1") ? :all : :scoped)
  end
end

module ActiveRecord
  module Calculations

    def anomaly_detect_static(groupby_col, filter_column, from_date, date_upto, time_unit, threshold)
      table_name = self.table_name
      query = "select * from anom_detect_static('#{table_name}', '#{groupby_col}', '#{filter_column}',
        '#{from_date}', '#{date_upto}', '#{time_unit}', '#{threshold}');"
      return ActiveRecord::Base.connection.execute(query).as_json
    end

    def anomaly_detect_percofmean(groupby_col, filter_column, from_date, date_upto, time_unit, threshold)
      table_name = self.table_name
      query = "select * from anom_detect_static('#{table_name}', '#{groupby_col}', '#{filter_column}',
        '#{from_date}', '#{date_upto}', '#{time_unit}', '#{threshold}');"
      ActiveRecord::Base.connection.execute(query).as_json
    end

    def anomaly_detect_zscore
      table_name = self.table_name
      query = "select * from anom_detect_static('#{table_name}', '#{groupby_col}', '#{filter_column}',
        '#{from_date}', '#{date_upto}', '#{time_unit}', '#{threshold}');"
      ActiveRecord::Base.connection.execute(query).as_json
    end
  end
end
