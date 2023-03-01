Sequel.migration do
  up do
    self.transaction do
      # Migrate all existing authority IDs into record identifiers
      [:person, :family, :corporate_entity, :software].each do |agent_type|
        agent_table = :"agent_#{agent_type}"
        name_table = :"name_#{agent_type}"

        ids_needing_generation = self[agent_table]
                                   .left_join(:agent_record_identifier, Sequel.qualify(agent_table, :id) => Sequel.qualify(:agent_record_identifier, :"#{agent_table}_id"))
                                   .filter(Sequel.qualify(:agent_record_identifier, :id) => nil)
                                   .select(Sequel.qualify(agent_table, :id))
                                   .map(:id)
                                   .sort

        now = Time.now

        ids_needing_generation.each do |id|
          name_to_promote = self[name_table].filter(:"agent_#{agent_type}_id" => id, :authorized => 1).first
          name_to_promote ||= self[name_table].filter(:"agent_#{agent_type}_id" => id, :is_display_name => 1).first
          name_to_promote ||= self[name_table].filter(:"agent_#{agent_type}_id" => id).order(:id).first

          if name_to_promote &&
             (source_id = name_to_promote.fetch(:source_id, nil)) &&
             (authority_id = self[:name_authority_id].filter(:"name_#{agent_type}_id" => name_to_promote.fetch(:id)).first)

            unless self[:agent_record_identifier].filter(:source_id => source_id,
                                                         :primary_identifier => 1,
                                                         :record_identifier => authority_id.fetch(:authority_id),
                                                         :"#{agent_table}_id" => id).count > 0

              self[:agent_record_identifier].insert(
                :source_id => source_id,
                :primary_identifier => 1,
                :record_identifier => authority_id.fetch(:authority_id),
                :"#{agent_table}_id" => id,
                :created_by => 'admin',
                :last_modified_by => 'admin',
                :create_time => now,
                :system_mtime => now,
                :user_mtime => now,
                :lock_version => 0,
              )
            end

            # Reindex the agent
            self[agent_table].filter(:id => id).update(:system_mtime => now)
          end
        end
      end
    end
  end
end
