module Mime
  SET              = []
  EXTENSION_LOOKUP = Hash.new { |h, k| h[k] = Type.new(k) unless k == "" }
  LOOKUP           = Hash.new { |h, k| h[k] = Type.new(k) unless k == "" }

  # Encapsulates the notion of a mime type. Can be used at render time, for example, with:
  #
  #   class PostsController < ActionController::Base
  #     def show
  #       @post = Post.find(params[:id])
  #
  #       respond_to do |format|
  #         format.html
  #         format.ics { render :text => post.to_ics, :mime_type => Mime::Type["text/calendar"]  }
  #         format.xml { render :xml => @people.to_xml }
  #       end
  #     end
  #   end
  class Type
    # A simple helper class used in parsing the accept header
    class AcceptItem #:nodoc:
      attr_accessor :order, :name, :q

      def initialize(order, name, q=nil)
        @order = order
        @name = name.strip
        q ||= 0.0 if @name == "*/*" # default "*/*" to end of list
        @q = ((q || 1.0).to_f * 100).to_i
      end

      def to_s
        @name
      end

      def <=>(item)
        result = item.q <=> q
        result = order <=> item.order if result == 0
        result
      end

      def ==(item)
        name == (item.respond_to?(:name) ? item.name : item)
      end
    end

    class << self
      def lookup(string)
        LOOKUP[string]
      end

      def lookup_by_extension(extension)
        EXTENSION_LOOKUP[extension]
      end

      def register(string, symbol, mime_type_synonyms = [], extension_synonyms = [])
        Mime.send :const_set, symbol.to_s.upcase, Type.new(string, symbol, mime_type_synonyms)

        SET << Mime.send(:const_get, symbol.to_s.upcase)

        ([string] + mime_type_synonyms).each { |string| LOOKUP[string] = SET.last }
        ([symbol.to_s] + extension_synonyms).each { |ext| EXTENSION_LOOKUP[ext] = SET.last }
      end

      def parse(accept_header)
        # keep track of creation order to keep the subsequent sort stable
        index = 0
        list = accept_header.split(/,/).map! do |i| 
          AcceptItem.new(index += 1, *i.split(/;\s*q=/))
        end.sort!

        # Take care of the broken text/xml entry by renaming or deleting it
        text_xml = list.index("text/xml")
        app_xml = list.index("application/xml")

        if text_xml && app_xml
          # set the q value to the max of the two
          list[app_xml].q = [list[text_xml].q, list[app_xml].q].max

          # make sure app_xml is ahead of text_xml in the list
          if app_xml > text_xml
            list[app_xml], list[text_xml] = list[text_xml], list[app_xml]
            app_xml, text_xml = text_xml, app_xml
          end

          # delete text_xml from the list
          list.delete_at(text_xml)
  
        elsif text_xml
          list[text_xml].name = "application/xml"
        end

        # Look for more specific xml-based types and sort them ahead of app/xml

        if app_xml
          idx = app_xml
          app_xml_type = list[app_xml]

          while(idx < list.length)
            type = list[idx]
            break if type.q < app_xml_type.q
            if type.name =~ /\+xml$/
              list[app_xml], list[idx] = list[idx], list[app_xml]
              app_xml = idx
            end
            idx += 1
          end
        end

        list.map! { |i| Mime::Type.lookup(i.name) }.uniq!
        list
      end
    end
    
    def initialize(string, symbol = nil, synonyms = [])
      @symbol, @synonyms = symbol, synonyms
      @string = string
    end
    
    def to_s
      @string
    end
    
    def to_str
      to_s
    end
    
    def to_sym
      @symbol || @string.to_sym
    end

    def ===(list)
      if list.is_a?(Array)
        (@synonyms + [ self ]).any? { |synonym| list.include?(synonym) }
      else
        super
      end
    end
    
    def ==(mime_type)
      (@synonyms + [ self ]).any? { |synonym| synonym.to_s == mime_type.to_s } if mime_type
    end
  end
end

require File.dirname(__FILE__) + "/mime_types"