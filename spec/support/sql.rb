module SqlHelper
  def schema_hash_for(table)
    Hash[DB.schema(table)]
  end

  def extract_array(parent, field)
    DB[:"#{parent}$#{field.pluralize}"].map { |row| row[field.to_sym] }
  end
end
