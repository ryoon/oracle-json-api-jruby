# Copyright (c) 2018 Ryo ONODERA <ryo@tetera.org>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE NETBSD FOUNDATION, INC. AND CONTRIBUTORS
# ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
# TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE FOUNDATION OR CONTRIBUTORS
# BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

require 'csv'
require 'sinatra'
require 'sinatra/namespace'
require_relative "lib/ojdbc7.jar"

def exec_sql(sql_string, type)
	begin
		# java.lang.Class.forName does not work for me.
		# It causes ClassNotFoundException.
		# Use java_import instead.
		#java.lang.Class.forName('oracle.jdbc.driver.OracleDriver').newInstance
		java_import('oracle.jdbc.driver.OracleDriver')
		conn = java.sql.DriverManager.getConnection('jdbc:oracle:thin:@SERVER_NAME:1521:SID_NAME', 'USER_NAME', 'PASSWORD');
		stmt = conn.create_statement
		rs = stmt.execute_query(sql_string)
		meta = rs.get_meta_data

		ret = []
		if type.downcase == 'json' then
			while rs.next
				record = []
				for i in 1..meta.get_column_count do
					elem = {}
					label = meta.get_column_label(i)
					elem[:label] = label
					elem[:value] = rs.getString(label)
					record << elem
				end
				ret << record
			end
			content_type = 'application/json'
		elsif type.downcase == 'csv' then
			record = []
			for i in 1..meta.get_column_count do
				record << meta.get_column_label(i)
			end
			ret << record

			while rs.next
				record = []
				for i in 1..meta.get_column_count do
					label = meta.get_column_label(i)
					record << rs.getString(label)
				end
				ret << record
			end
			content_type = 'text/csv'
		else
			ret = 'Invalid type.'
			content_type = 'application/json'
		end

	rescue => e
		ret = e
	ensure
		conn.close if conn
	end
	return ret, content_type
end


namespace '/api/v1' do
	# For test
	get '/' do
		content_type 'application/json'
		ret = {}
		ret[:response] = 'Hello, world!'
		ret.to_json
	end

	post '/query' do
		post_body = JSON.parse(request.body.read).symbolize_keys
		result = exec_sql(post_body[:query], post_body[:type])
		content_type_string = result[1]
		content_body = result[0]

		content_type content_type_string
		if content_type_string == 'application/json' then
			ret = {}
			ret[:records] = content_body
			ret.to_json
		elsif content_type_string == 'text/csv' then
			ret = []
			ret = content_body
			ret.map(&:to_csv).join
		end
	end
end
