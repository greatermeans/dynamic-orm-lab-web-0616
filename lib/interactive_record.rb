require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'

class InteractiveRecord

  def self.table_name
    "#{self}".downcase.pluralize
  end

  def self.column_names
    DB[:conn].results_as_hash = true
    sql = <<-SQL 
    pragma table_info(#{table_name})
    SQL
    table = DB[:conn].execute(sql)
    attributes = []
    table.each do |row|
      attributes << row["name"]
    end
    attributes.compact
  end

  self.column_names.each do |name|
  	attr_accessor name.to_sym
  end

  def initialize(options={})
    options.each do |property,value|
      self.send("#{property}=",value)
    end
  end

  def table_name_for_insert
  	self.class.table_name
  end

  def col_names_for_insert
  	self.class.column_names.delete_if {|key| key == "id"}.join(", ")
  end

  def values_for_insert
  	values = []
  	col_names_for_insert.split(", ").each do |value|
  		values << "'#{send(value)}'"
  	end
  	values.join(", ")
  end

  def self.find_by(options)

  	sql = <<-SQL
  	SELECT * FROM #{table_name} WHERE #{options.key(options.values.compact[0])} = '#{options.values.compact[0]}'
  	SQL
  	DB[:conn].execute(sql)
  end

  def self.find_by_name(name)
  	sql = <<-SQL
  	SELECT * FROM #{table_name} WHERE name = '#{name}'
  	SQL
  	DB[:conn].execute(sql)
  end

  def save
  	sql = <<-SQL
  	INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})
  	SQL
  	DB[:conn].execute(sql)
  	@id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end


end
