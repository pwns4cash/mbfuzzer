require './lib/xmlparser.rb'
require './lib/jsonparser.rb'


class MBContent

	def initialize()
		@head = ""
		@type = ""
		@schema = ""
		@head_content = []
		@body_content = []
		@xml_parser = XMLParser.new()
		@json_parser = JSONParser.new()
	end

	#gets content and decide which type of content
	def analyse_content(content)
		#puts "Incoming content : "
		#puts content

		if content =~ /Content-Type: text\/xml/
			@type = "XML"
			puts "XML content"
			extract_head_content(content)
			
			# get xml body from content
			x_content = extract_body_content(content)
			@body_content = @xml_parser.parse(x_content)

		elsif content =~ /Content-Type: application\/json/
			#json parsing part will be added
			@type = "JSON"
			puts "JSON Content"

			extract_head_content(content)
			@body_content = @json_parser.convert_to_hash(extract_body_content(content))
		
		else
			return content
		end

		#content is in an array

		puts @head
		puts @head_content
		puts @schema
		puts @body_content
		
		return create_new_content()
	end


	def extract_head_content(content)
		#getting head of content
		@head = content.split("\r\n")[0]
		
		content.each_line do |content_line|
			#puts content_line
			if content_line =~ /:\ /
				key = content_line.split(":")[0]
				value = content_line.split(": ")[1].split("\r\n")[0]
				@head_content << { key => value}
			end
		end
	end


	def extract_body_content(content)
		#getting body of content
		control = false
		body = ""

		
		content.each_line do |content_line|
			if content_line == "\r\n"
				control = true
			end
			if control == true
				if content_line =~ /xml\ version/
					@schema = content_line
				end
				body = "#{body}#{content_line}"
			end
		end

		return body
	end


	# generate request/response content
	def create_new_content()
		#gets only xml for now
		old_length = ""
		new_length = ""
		gen_body = ""
		gen_cont = ""
        
		case @type
			when "XML" then gen_body = @xml_parser.convert_from_hash(@body_content)
			when "JSON" then gen_body = @json_parser.convert_to_json(@body_content)
		end

    
		@head_content.each() do |cont|
			cont.each do |key,value|
				if key == "Content-Length"
					old_length = "#{key}: #{value}"  #calculate new content length
				end
				gen_cont = "#{gen_cont}#{key}: #{value}\r\n"
			end
		end

		new_length = "Content-Length: #{@schema.length + gen_body.length}"
		puts "#{old_length} --- #{new_length}"
		gen_cont.gsub!(old_length,new_length)  
    
		gen_cont = "#{@head}\r\n#{gen_cont}\r\n#{@schema}#{gen_body}"    
     
		puts gen_cont

		return gen_cont
	end
end
