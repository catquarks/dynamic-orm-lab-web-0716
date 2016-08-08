require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord

	def self.table_name
		self.to_s.downcase.pluralize
	end

	def table_name_for_insert
		self.class.table_name #=> this is necessary when calling from an instance method
	end

	def self.column_names
		sql = "PRAGMA TABLE_INFO(#{self.table_name})"
		table_info = DB[:conn].execute(sql)
		column_names = []
		table_info.each do |row|
			column_names << row["name"]
		end
		column_names.compact
	end

	def col_names_for_insert
		self.class.column_names.delete_if {|col| col == "id"}.join(", ")
	end

	def values_for_insert
		values = []
		self.class.column_names.compact.each do |col_name|
			values << "'#{send(col_name)}'" unless send(col_name).nil?
		end
		values.join(", ")
		
	end


	def initialize(options={})
		options.each do |property, value|
			self.send("#{property}=", value) #=> send("name="), Beatrice
		end
	end

	def self.find_by_name(name)
		sql = "SELECT * FROM #{self.table_name} WHERE name = #{name}"
		DB[:conn].execute(sql)
	end

	def save
		sql = "INSERT INTO #{self.table_name_for_insert} (#{self.col_names_for_insert}) VALUES (#{self.values_for_insert})"
		DB[:conn].execute(sql)
		sql = "SELECT last_insert_rowid() FROM #{self.table_name_for_insert}"
		@id = DB[:conn].execute(sql)[0][0]
	end

	def self.find_by_name(name)
		sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"

		DB[:conn].execute(sql)
	end

 	def self.find_by(attributes = {})
 		results = attributes.collect do |prop, value|
			sql = "SELECT * FROM #{self.table_name} WHERE #{prop} = '#{value}'"
			DB[:conn].execute(sql)
		end
		results.flatten
	end 

end