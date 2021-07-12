require 'db/migrations/utils'

Sequel.migration do
  up do
    alter_table(:file_version) do
      add_column(:is_display_thumbnail, Integer, :null => true, :default => nil)

      add_unique_constraint([:is_display_thumbnail, :digital_object_id],
                            :name => "digital_object_display_thumbnail_uniq")
    end
  end
end