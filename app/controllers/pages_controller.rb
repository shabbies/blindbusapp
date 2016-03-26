require 'eventmachine'
require 'rubygems'
require 'websocket-client-simple'
require 'json'
require 'uri'
require 'net/http'

class PagesController < ApplicationController
	skip_before_action :verify_authenticity_token
	$bus_stop = ["07571", "04189", "04159", "04149", "04229", "04239", "05059", "05049", "05039"]
	$counter = 0
	$alighting = false

	def board
		bus_stop_id = params[:stop_id].split("(")[1][0..4]
		if (!$blindman)
			$blindman = Hash.new
		end
		if $blindman[bus_stop_id]
			$blindman[bus_stop_id] += 1
		else
			$blindman[bus_stop_id] = 1
		end
	end

	def console
		
	end

	def help

	end

	def number

	end

	def new
	end

	def test

	end

	def alight
		$alighting = true
	end

	def blind_man_number
		if (!$blindman)
			$blindman = Hash.new
		end
		stop_id = $bus_stop[$counter]
		$counter += 1
		if $counter >= $bus_stop.length
			$counter = 0
		end
		blindman_count = $blindman[stop_id]
		if !blindman_count
			blindman_count = 0
		end
		var = Hash.new
		var["stop_id"] = stop_id.to_s
		var["count"] = blindman_count.to_s
		var["alighting"] = $alighting
		p var
		$alighting = false
		render json: var
	end

	def create
		attachment =  params[:attachment]

		params = {
     'action'             => "start",
     'content-type'       => "audio/wav", 
     'continuous'         => true,
     'inactivity_timeout' => -1,
     'interim_results'    => true
		}

		token = ''
		uri = URI.parse("https://stream.watsonplatform.net/authorization/api/v1/token?url=https://stream.watsonplatform.net/speech-to-text/api")
		Net::HTTP.start(uri.host, uri.port,:use_ssl => uri.scheme == 'https') do |http|
		    request = Net::HTTP::Get.new(uri)
		    request.basic_auth '171557d1-a33e-4f06-8d98-f1bee958b8b2', '3VPF0oYoiPF7'
		    token = http.request(request)
		end

		watson_url = "wss://stream.watsonplatform.net/speech-to-text/api/v1/recognize?watson-token=#{token.body}"
		file_url = "./0001.wav"#replace this with the file you want to read

		init_message = params.to_json
		ws = ''
		 # run websocket in an EventMachine
		EM.run {
		  ws = WebSocket::Client::Simple.connect watson_url
		   file_sent = false
		 
		   ws.on :message do |event|
		      puts "message: #{event.data}"
		      data = JSON.parse(event.data)
		      if data['results']
						$number = ""
						raw_array = (data['results'][0]['alternatives'][0]['transcript'].to_s.downcase).split
						raw_array.each do |number|
							case number
							when "one"
								$number += "1 ".to_s
							when "two"
								$number += "2 ".to_s
							when "three"
								$number += "3 ".to_s
							when "four"
								$number += "4 ".to_s
							when "five"
								$number += "5 ".to_s
							when "six"
								$number += "6 ".to_s
							when "seven"
								$number += "7 ".to_s
							when "eight"
								$number += "8 ".to_s
							when "nine"
								$number += "9 ".to_s
							when "zero"
								$number += "0 ".to_s
							else
								$number = "You have entered an invalid choice."
								break
							end
						end 
					end

		      if data['state'] && data['state'] == 'listening'
		         if file_sent == true          
		            EM::stop_event_loop
		         else
		            file_sent = true
		            # open(file_url, 'rb') do |file|
		            #    file.read_chunk {|chunk| ws.send(chunk, type: :binary) }
		            # end

	              attachment.tempfile.read_chunk {|chunk| ws.send(chunk, type: :binary) }
		            
		            ws.send("", type: :binary)
		         end      
		      end
		    
		   end
		 
		   ws.on :open do
		     puts "-- websocket open"
		     puts             init_message
		     ws.send(init_message)
		   end

		   ws.on :close do |e|
		     puts "-- websocket close #{if e!=nil then (e) end}"
		   end

		   ws.on :error do |e|
		     puts "-- error (#{e.inspect})"
		   end
		}
		ws.close
	end

	private
    def pages_params
      params.permit!
    end
end

class File
   def read_chunk(chunk_size=2000)
       yield read(chunk_size) until eof?
   end
end