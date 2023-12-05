
require_relative 'lib/XL_transformer'
require 'pp'



PrintToPDFRunner.class_eval do
 

  def get_ead3(id, include_unpublished, include_daos, use_numbered_c_tags)
    resolve = ['repository', 'linked_agents', 'subjects', 'digital_object', 'top_container', 'top_container::container_profile']

    resource = Resource.get_or_die(id)
    resource_jsonmodel = Resource.to_jsonmodel(resource)
    jsonmodel = JSONModel(:resource).new(URIResolver.resolve_references(Resource.to_jsonmodel(resource), resolve))
    opts = {
      :include_unpublished => include_unpublished,
      :include_daos => include_daos,
      :use_numbered_c_tags => use_numbered_c_tags,
      :ead3 => true,
      :serializer => :ead3
    }

    ead = ASpaceExport.model(:ead).from_resource(jsonmodel, resource.tree(:all, mode = :sparse), opts)
    ASpaceExport::stream(ead, opts)
  end

  def run
    begin
      @stylesheet_path = ASUtils.find_local_directories('stylesheets', 'yale_staff_customizations')[0]
      RequestContext.open( :repo_id => @job.repo_id) do
        parsed = JSONModel.parse_reference(@json.job["source"])
        resource = Resource.get_or_die(parsed[:id])
        resource_jsonmodel = Resource.to_jsonmodel(resource)

        @job.write_output("Generating PDF for #{resource_jsonmodel["title"]}  ")

        obj = URIResolver.resolve_references(resource_jsonmodel,
                                              [ "repository", "linked_agents", "subjects", "digital_objects", 'top_container', 'top_container::container_profile'])
        opts = {
          :include_unpublished => @json.job["include_unpublished"] || false,
          :include_daos => true,
          :numbered_cs => false,
          :ead3 => true,
        }
        

        if obj["repository"]["_resolved"]["image_url"]
          image_for_pdf = obj["repository"]["_resolved"]["image_url"]
        else
          image_for_pdf = nil
        end

        record = JSONModel(:resource).new(obj)

        if record['publish'] === false
          @job.write_output("-" * 50)
          @job.write_output("Warning: this resource has not been published")
          @job.write_output("-" * 50)
        end

        xml = ""
        # local method based on  ExportHelpers::generate_ead because
        # enum =  ExportHelpers.generate_ead(parsed[:id], true, true, false, true)
        # doesn't WORK?
        enum = get_ead3(parsed[:id], opts[:include_unpublished], true, false) 
        enum.each {|x| xml << x}
        # Log.error("EAD3 XML: #{xml.pretty_inspect}") 
        
        # now we have the ead3 xml run the transform to the "corrected" ead
        #xslt-to-update-the-ASpace-export/yale.aspace_v2_to_yale_ead3.xsl
        
        xslt_path = File.join(@stylesheet_path, 'xslt-to-update-the-ASpace-export','yale.aspace_v2_to_yale_ead3.xsl')
        trans = XLTransformer.new(xml, xslt_path, @stylesheet_path)
        corrected_xml = trans.transform({"suppressInternalComponents" => "false()"})
        # Log.error("CORRECTED: #{corrected_xml.pretty_inspect}")

         # now do the fop transform using ead3-to-pdf-ua.xsl
        pdftransformer = XLTransformer.new(corrected_xml,File.join(@stylesheet_path,'ead3-to-pdf-ua.xsl'), @stylesheet_path, nil, File.join(@stylesheet_path,'fop-preview.xconf'))
        pdf = pdftransformer.to_pdf
        
        # # ANW-267: For windows machines, run FOP to generate PDF externally with a system() call instead of through JRuby to fix PDF corruption issues
        # if RbConfig::CONFIG['host_os'] =~ /win32/
        #   pdf = ASFopExternal.new(corrected_xml, @job, image_for_pdf).to_pdf
        # else
        #   pdf = ASFop.new(corrected_xml, image_for_pdf).to_pdf
        # end

        job_file = @job.add_file( pdf )
        @job.write_output("File generated at #{job_file.full_file_path.inspect} ")

        # pdf will be either a Tempfile or File object, depending on whether it was created externally.
        if pdf.class == Tempfile
          pdf.unlink
        elsif pdf.class == File
          File.unlink(pdf.path)
        end

        @job.record_modified_uris( [@json.job["source"]] )
        @job.write_output("All done. Please click refresh to view your download link.")
        self.success!
        job_file
      end
    rescue Exception => e
      @job.write_output(e.message)
      @job.write_output(e.backtrace)
      raise e
    end
  end
end

MarcXMLAuthAgentBaseMap.module_eval do

  def agent_person_base(import_events)
    {
      'self::datafield' => agent_person_name_map(:name_person, :names),
      "parent::record/datafield[@tag='400' and (@ind1='1' or @ind1='0')]" => agent_person_name_map(:name_person, :names)
      #"parent::record/datafield[@tag='372']/subfield[@code='a']" => agent_topic_map
      #"parent::record/datafield[@tag='375']/subfield[@code='a']" => agent_gender_map
    }.merge(shared_subrecord_map(import_events))
  end

  def agent_corporate_entity_base(import_events)
    {
      'self::datafield' => agent_corporate_entity_name_map(:name_corporate_entity, :names),
      "parent::record/datafield[@tag='410' or @tag='411']" => agent_corporate_entity_name_map(:name_corporate_entity, :names)
      #"parent::record/datafield[@tag='372']/subfield[@code='a']" => agent_function_map
    }.merge(shared_subrecord_map(import_events))
  end

  def agent_family_base(import_events)
    {
      'self::datafield' => agent_family_name_map(:name_family, :names),
      "parent::record/datafield[@tag='400' and @ind1='3']" => agent_family_name_map(:name_family, :names)
      #"parent::record/datafield[@tag='372']/subfield[@code='a']" => agent_function_map
    }.merge(shared_subrecord_map(import_events))
  end

  def shared_subrecord_map(import_events)
    h = {
      'parent::record/leader' => agent_record_control_map,
      "parent::record/controlfield[@tag='001'][not(following-sibling::controlfield[@tag='003']/text()='DLC' and following-sibling::datafield[@tag='010'])]" => agent_record_identifiers_base_map("//record/controlfield[@tag='001']"),
      "parent::record/datafield[@tag='010']" => agent_record_identifiers_base_map("parent::record/datafield[@tag='010']/subfield[@code='a']"),
      "parent::record/datafield[@tag='016']" => agent_record_identifiers_base_map("parent::record/datafield[@tag='016']/subfield[@code='a']"),
      "parent::record/datafield[@tag='024']" => agent_record_identifiers_base_map("parent::record/datafield[@tag='024']/subfield[@code='a' or @code='0' or @code='1'][1]"),
      "parent::record/datafield[@tag='035']" => agent_record_identifiers_base_map("parent::record/datafield[@tag='035']/subfield[@code='a']"),
      #{}"parent::record/datafield[@tag='040']/subfield[@code='e']" => convention_declaration_map,
      "parent::record/datafield[@tag='046']" => dates_map,
    # lots of stuff removed here, until we can figure out how to handle IDs, etc. (also, once we have these IDs, can't we just merge this extra subject data at the time of export / display?)
      "parent::record/datafield[@tag='377']" => used_language_map,

      #{}"parent::record/datafield[@tag='670']" => agent_sources_map,
      "parent::record/datafield[@tag='678']" => bioghist_note_map,
      # "parent::record/datafield[@tag='040']/subfield[@code='d']" => {
      #   :obj => :agent_other_agency_codes,
      #   :rel => :agent_other_agency_codes,
      #   :map => {
      #     "self::subfield" => proc { |aoac, node|
      #       aoac['maintenance_agency'] = node.inner_text
      #     }
      #   }
      # },
      # "parent::record" => proc { |record, node|
      #   # apply the more complicated inter-leaf logic
      #   record['agent_other_agency_codes'].reject! { |subrecord|
      #     subrecord['maintenance_agency'] == record['agent_record_controls'][0]['maintenance_agency']
      #   }
      # }
    }

    if import_events
      h.merge!({
        "parent::record/controlfield[@tag='005']" => maintenance_history_map
      })
    end
    h
  end
end

