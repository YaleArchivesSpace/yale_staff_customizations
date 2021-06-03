
require_relative 'lib/XL_transformer'
require 'pp'



PrintToPDFRunner.class_eval do
 

  def get_ead3(id, include_unpublished, include_daos, use_numbered_c_tags)
    resolve = ['repository', 'linked_agents', 'subjects', 'digital_object', 'top_container', 'top_container::container_profile']

    resource = Resource.get_or_die(id)
    resource_jsonmodel = Resource.to_jsonmodel(resource)
    # Log.error("resource: #{resource_jsonmodel.pretty_inspect}")
    jsonmodel = JSONModel(:resource).new(URIResolver.resolve_references(Resource.to_jsonmodel(resource), resolve))
    # Log.error("eadjsonmodel: #{jsonmodel.pretty_inspect}")
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
      # Log.error("STYLESHEET PATH: #{@stylesheet_path}")
      # Log.error('Got the right job runner!')
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
        # request_uri = "/repositories/#{@job.repo_id}/resource_descriptions/#{parsed[:id]}.xml"
        # Log.error("URI: #{request_uri}\n OPTS: #{opts}")

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
        enum = get_ead3(parsed[:id], true, true, false) 
        enum.each {|x| xml << x}
        Log.error("EAD3 XML: #{xml.pretty_inspect}") 
        
        # now we have the ead3 xml run the transform to the "corrected" ead
        #xslt-to-update-the-ASpace-export/yale.aspace_v2_to_yale_ead3.xsl
        
        xslt_path = File.join(@stylesheet_path, 'xslt-to-update-the-ASpace-export','yale.aspace_v2_to_yale_ead3.xsl') 
        # Log.error("xsl path: #{xslt_path}")
        trans = XLTransformer.new(xml, xslt_path, @stylesheet_path)
        corrected_xml = trans.transform({"suppressInternalComponents" => "false()"})
        Log.error("CORRECTED: #{corrected_xml.pretty_inspect}")

         # now do the fop transform using ead3-to-pdf-ua.xsl
        pdftransformer = XLTransformer.new(corrected_xml,File.join(@stylesheet_path,'ead3-to-pdf-ua.xsl'), @stylesheet_path, nil, File.join(@stylesheet_path,'fop-preview.xconf'))
        pdf = pdftransformer.to_pdf
        # Log.error("pdf? #{pdf.pretty_inspect}")
        
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

