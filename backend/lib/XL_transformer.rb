

require 'java'
require 'saxon-rb'
require 'stringio'


java_import Java::org::apache::fop::apps::FopFactory
java_import Java::org::apache::fop::apps::Fop
java_import Java::org::apache::fop::apps::MimeConstants



class XLTransformer

  import javax.xml.transform.stream.StreamSource
  import javax.xml.transform.TransformerFactory
  import javax.xml.transform.sax.SAXResult


  attr_accessor :source
  attr_accessor :output
  attr_accessor :xslt
  attr_accessor :xslt_path
  attr_accessor :config
  attr_accessor :base
  

  def initialize(source, xslt_path, base, output= nil, config = nil)
   @source = source
   @output = output ? output : ASUtils.tempfile('xform.pdf')
   @config = config
   @base = base
   if !@base.start_with?('http')
      @base = "file:///#{@base}"
   end
   if !@base.end_with?('/')
    @base << '/'
   end

   @xslt_path = xslt_path
   @xslt = File.read(@xslt_path)
  end

  
  def transform(params = {})
    transformer = Saxon.XSLT(@xslt, system_id: @xslt_path )
    transformer.transform(Saxon.XML(@source), params).to_s
  end
#   def to_fo
#     transformer = Saxon.XSLT(@xslt, system_id: File.join(ASUtils.find_base_directory, 'stylesheets', 'as-ead-pdf.xsl') )
#     transformer.transform(Saxon.XML(@source), {"pdf_image" => "\'#{@pdf_image}\'"}).to_s
#   end

  # returns a temp file with the converted PDF
  def to_pdf
    begin
      params = {
        "primary-font-for-pdf" => "'Open_Sans'", 
      "sans-serif-font" => "'Open_Sans'",
      "serif-font" => "'Open_Sans'",
      "backup-font" =>"'NotoSans, KurintoText'",
      # "logo-location" => "'https://raw.githubusercontent.com/YaleArchivesSpace/EAD3-to-PDF-UA/master/'",
       "logo-location" => "'#{@base}'",
      "suppressInternalComponentsInPDF" => "false()"
      }
      fo = StringIO.new(transform(params)).to_inputstream
      fopfac = FopFactory.newInstance
      # Log.error("Settin fop base to #{@base}")
      fopfac.setBaseURL( @base )
      fopfac.setUserConfig(@config)
      fop = fopfac.newFop(MimeConstants::MIME_PDF, @output.to_outputstream)
      pdftransformer = TransformerFactory.newInstance.newTransformer()
      res = SAXResult.new(fop.getDefaultHandler)
      pdftransformer.transform(StreamSource.new(fo), res)
    ensure
     @output.close
    end
    @output
  end

#   def to_pdf_stream
#     begin
#       fo = StringIO.new(to_fo).to_inputstream
#       fopfac = FopFactory.newInstance
#       fopfac.setBaseURL( File.join(ASUtils.find_base_directory, 'stylesheets') )
#       fopfac.setUserConfig(@config)
#       fop = fopfac.newFop(MimeConstants::MIME_PDF, @output.to_outputstream)
#       transformer = TransformerFactory.newInstance.newTransformer()
#       res = SAXResult.new(fop.getDefaultHandler)
#       transformer.transform(StreamSource.new(fo), res)
#       @output.rewind
#       @output.read
#     ensure
#      @output.close
#      @output.unlink
#     end
#   end

end

 