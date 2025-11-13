# Automatically use UUID type for all binary(16) columns
ActiveSupport.on_load(:active_record) do
  module MysqlUuidAdapter
    # Add UUID to MySQL's native database types
    def native_database_types
      @native_database_types_with_uuid ||= super.merge(uuid: { name: "binary", limit: 16 })
    end

    # Override type_to_sql to use binary instead of varbinary for UUID columns
    def type_to_sql(type, limit: nil, **options)
      if type.to_s == "binary" && limit == 16
        "binary(16)"
      else
        super
      end
    end

    # Override lookup_cast_type to recognize binary(16) as UUID type
    def lookup_cast_type(sql_type)
      if sql_type == "binary(16)"
        ActiveRecord::Type.lookup(:uuid, adapter: :trilogy)
      else
        super
      end
    end
  end

  ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter.prepend(MysqlUuidAdapter)

  module SchemaDumperBinaryLimit
    def prepare_column_options(column)
      spec = super
      # Ensure binary columns with limits always include them in schema
      if column.type == :binary && column.sql_type =~ /binary\((\d+)\)/
        spec[:limit] = $1.to_i
      end
      spec
    end
  end

  ActiveRecord::ConnectionAdapters::MySQL::SchemaDumper.prepend(SchemaDumperBinaryLimit)

  module TableDefinitionUuidSupport
    def uuid(name, **options)
      column(name, :uuid, **options)
    end
  end

  ActiveRecord::ConnectionAdapters::TableDefinition.prepend(TableDefinitionUuidSupport)
end
