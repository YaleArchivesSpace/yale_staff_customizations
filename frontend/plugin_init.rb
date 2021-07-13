Rails.application.config.after_initialize do

  # over ride the get_ancester_title method to include the Collection ID (id_0) for a Resource
  SearchHelper.module_eval do
    def get_ancestor_title(field)
        field_json = JSONModel::HTTP.get_json(field)
        unless field_json.nil?
          if field.include?('resources') 
            resource_display_string(field_json['title'],(field_json.has_key?('id_0') ? field_json['id_0'] : nil))
          elsif field.include?('digital_objects')
            clean_mixed_content(field_json['title']) 
          else
            clean_mixed_content(field_json['display_string'])
          end
        end
      end
    # create a resource display string to include the Collection ID
    def resource_display_string(title, coll_id)
      if coll_id.nil?
        coll_id = '<span label label-important">Missing</span>'
      end
      "#{clean_mixed_content(title)} (#{coll_id})"
    end

  end
    
end
