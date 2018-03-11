# Convert a query in SQL for Oracle Database to JSON/CSV

This program converts a result from Oracle Database to JSON/CVS format.

# How to use

Place ojdbc7.jar to lib/ and

	$ cd oracle-json-api-jruby/
	$ jruby -S gem install bundler
	$ jruby -S bundle install --path vendor/bundle

To run

	$ jruby -S bundle exec rackup

POST to http://localhost:9292/api/v1/query
	{
	  "type": "json",
	  "query": "select * from schema.table"
	}

or

	{
	  "type": "csv",
	  "query": "select * from schema.table"
	}

You will receive the result as JSON or CSV respectively.

Or GET http://localhost:9292/api/v1/ to test
You will receive Hello, world! JSON.

## License
2-clause BSD License

## Author
Ryo ONODERA <ryo@tetera.org>
