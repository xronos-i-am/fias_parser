require "fias_parser/version"
require 'mechanize'
require 'ox'
require 'cocaine'

module FiasParser
  class Document
    def initialize( options, block )
      @block = block
      @batch = []
      @batch_size = options[:batch_size] || 10
      
      @root_name = nil
      @item_name = nil
    end

    def start_element( name )
      @item = nil

      if @root_name.nil?
        @root_name = name
        
        return
      end
      
      @item_name = name
      @item = {}
    end

    def attr( name, value )
      @item[ name ] = value unless @item.nil?
    end

    def end_element( name )
      self.yield_batch if name == @root_name && @batch.any?

      return if @item.nil? || name != @item_name
      
      @batch << @item

      self.yield_batch if @batch.size >= @batch_size
    end

    def yield_batch
      @block.call( @batch )      
      @batch = []      
    end
  end

  class Parser
    attr_accessor :date

    def initialize( options = {} )
      @base_dir = options[:base_dir] || Dir.tmpdir
    end

    def get_latest
      return unless self.check_executables

      self.download_latest
      self.unpack
    end

    def process( term, options = {}, &block ) 
      file_name = Dir.entries( self.archive_path ).find { |f| f =~ /#{term}/i }

      if file_name.nil?
        puts "File /#{term}/ not found in '#{self.archive_path}'"

        return
      end

      File.open( File.join( self.archive_path, file_name ) ) do |file|
        ::Ox.sax_parse( Document.new( options, block ), file )
      end
    end

    def check_executables
      line = Cocaine::CommandLine.new( "wget", "-h" )

      begin
        line.run
      rescue Cocaine::CommandNotFoundError => e
        puts 'wget is not installed. Run "sudo apt-get install wget"'

        return false
      end 

      line = Cocaine::CommandLine.new( "unar", "-h" )

      begin
        line.run
      rescue Cocaine::CommandNotFoundError => e
        puts 'unar is not installed. Run "sudo apt-get install unar"'

        return false
      end 

      true
    end

    def download_latest
      agent = Mechanize.new
      agent.user_agent = 'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:10.0.1) Gecko/20100101 Firefox/10.0.1'

      url = 'http://fias.nalog.ru/Public/DownloadPage.aspx'

      doc = agent.get( url ).root

      post_data = {}

      doc.css( 'form input[type="hidden"]' ).each do |input|
        post_data[ input['name'] ] = input['value']
      end

      @date = doc.css( '#ctl00_contentPlaceHolder_downloadRadGrid_ctl00__0 tr td:first-child' ).text.gsub( /[^\d]/, '' )

      post_data['__EVENTTARGET'] = 'ctl00$contentPlaceHolder$downloadRadGrid$ctl00$ctl04$fullSZLinkButton'

      if File.exists?( self.archive_file_path )
        puts "File '#{self.archive_file_path}' already exists."        
        
        return
      end

      line = Cocaine::CommandLine.new( "wget", "--output-document=:out --post-data=:post_data :url" )

      line.run( {
        out: self.archive_file_path,
        post_data: Mechanize::Util.build_query_string( post_data ),
        url: url,
      } )
    end

    def unpack
      dir = File.join( @base_dir )

      FileUtils.mkdir_p ( dir ) unless File.exists?( dir )

      line = Cocaine::CommandLine.new( "unar", "-o :dir :archive" )

      line.run( {
        dir: dir,
        archive: self.archive_file_path,
      } )
    end

    def archive_path
      @archive_path ||= get_archive_path
    end

    def get_archive_path
      File.join( @base_dir, @date )
    end

    def archive_file_path
      @archive_file_path ||= get_archive_file_path
    end

    def get_archive_file_path
      File.join( @base_dir,  "#{@date}.rar" )
    end
  end
end