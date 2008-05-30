###########################################################################
#   Copyright (C) 2008 by Paul Betts                                      #
#   paul.betts@gmail.com                                                  #
#                                                                         #
#   This program is free software; you can redistribute it and/or modify  #
#   it under the terms of the GNU General Public License as published by  #
#   the Free Software Foundation; either version 2 of the License, or     #
#   (at your option) any later version.                                   #
#                                                                         #
#   This program is distributed in the hope that it will be useful,       #
#   but WITHOUT ANY WARRANTY; without even the implied warranty of        #
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         #
#   GNU General Public License for more details.                          #
#                                                                         #
#   You should have received a copy of the GNU General Public License     #
#   along with this program; if not, write to the                         #
#   Free Software Foundation, Inc.,                                       #
#   59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.             #
###########################################################################

require File.join(File.dirname(__FILE__), 'config')

# Standard library
require 'rubygems'
require 'logger'
require 'gettext'
require 'singleton'
require 'fileutils'
require 'pathname'
require 'yaml'

# Yikes
require 'platform'
require 'utility'
require 'state'

include GetText

$logging_level ||= Logger::ERROR

class Engine 
	def initialize(transcoder = FFMpegTranscoder)
		@transcoder = transcoder.new
	end

	# Main function for converting a video file and writing it to a folder
	def convert_file(item, state)
		if create_path_and_convert(item)
			logger.debug "Convert succeeded"
			state.encode_succeeded!(item)
		else
			logger.debug "Convert failed"
			state.encode_failed!(item)
		end
	end

	def create_path_and_convert(item)
		dest_file = Pathname.new(item.target_path)
		FileUtils.mkdir_p(dest_file.dirname.to_s)
		transcode(item.source_path, dest_file.to_s)
	end

	def transcode(input, output)
		p = Pathname.new(output)
		if p.exist?
			logger.info "#{p.basename.to_s} already exists, skipping"
			return true
		end
		logger.info "#{p.basename.to_s} doesn't exist, starting transcode..."
		@transcoder.transcode(input, output)
	end
end

module ExternalTranscoder
	def transcode(input, output)
		cmd = get_command(input, output)
		#puts "Running #{cmd}"
		
		# FIXME: Dumb hack code!
		pid = nil
		unless (pid = fork)
			STDOUT.reopen '/dev/null'
			STDERR.reopen '/dev/null'
			logger.debug "Executing: #{cmd}"
			system(cmd)
			Kernel.exit!
		end
		e = Process.wait pid
		exitcode = ($?) ? ($?.exitstatus) : -1
		logger.info "Process returned #{exitcode}"
		return exitcode == 0

#                 IO.popen cmd do |i,o,e|
#                         break
#                         o.readlines.each do |line|
#                                 p line
#                         end
#                 end

#		if Platform.os == :windows
#			# TODO: Implement me
#			return
#		end
#
#		# Platform is Posix so we have fork
#		Kernel.fork do
#			before_transcode() if self.respond_to? :before_transcode
#			Kernel.exec 
#			after_transcode() if self.respond_to? :before_transcode
#		end

	end
end

class FFMpegTranscoder
	include ExternalTranscoder

	# Encoding notes:
	# 	Getting QuickTime to read the videos we generate is a *giant* pain in the
	# 	ass; it barfs at anything that's nonstandard and I've spent lots of time
	# 	trying to find the ffmpeg "magic words" that make it happen. The relevant
	# 	parts seem to be:
	#
	# 	Framerate MUST be NTSC i.e. 30000/1001
	# 	vcodec MUST be either xvid or libx264, acodec MUST be aac
	#
	# 	Versions of ffmpeg call we've tried:
	#
	#	# One-pass known-working with QT
	#	$FFMPEG -y -i "$1" -f mov -vcodec libx264 -s 480x320 -r 30000/1001 -bufsize 8192 -qscale 5 -acodec libfaac -ab 96 -ac 2 -async 1 -threads auto "$2"
	#
	# 	# Revised 2-pass code
	#	$FFMPEG -y -threads auto -i "$1" -f mov -vcodec libx264 -s 432x320 -r 30000/1001 -bufsize 8192 -qscale 5
	#	-refs 1 -loop 1 -deblockalpha 0 -deblockbeta 0 -parti4x4 1 -partp8x8 1 -me full -subq 1 -me_range 21 \
	#	-chroma 1 -slice 2 -bf 0 -level 30 -g 300 -keyint_min 30 -sc_threshold 40 -rc_eq 'blurCplx^(1-qComp)' \
	#	-qcomp 0.7 -qmax 51 -qdiff 4 -i_qfactor 0.71428572 -maxrate 768000 -cmp 1 -s 480x320 -f mov -pass 1 \
	#	/dev/null
	#
	#	$FFMPEG -y -i "$1" -v 1 -threads auto -vcodec libx264 -r 30000/1001 -bufsize 8192 -qscale 5 -refs 1 \
	#	-loop 1 -deblockalpha 0 -deblockbeta 0 -parti4x4 1 -partp8x8 1 -me full -subq 6 -me_range 21 -chroma 1 \
	#	-slice 2 -bf 0 -level 30 -g 300 -keyint_min 30 -sc_threshold 40 -rc_eq 'blurCplx^(1-qComp)' -qcomp 0.7 \
	#	-qmax 51 -qdiff 4 -i_qfactor 0.71428572 -maxrate 768000 -cmp 1 -s 480x320 -acodec libfaac -ab 96 -ar \
	#	48000 -ac 2 -f mov -pass 2 "$2"
	#
	#	# Original 2-pass code
	#	# $FFMPEG -y -i "$1" -an -v 1 -threads auto -vcodec libx264 -b 500000 -bt 175000 \
	#	-refs 1 -loop 1 -deblockalpha 0 -deblockbeta 0 -parti4x4 1 -partp8x8 1 -me full -subq 1 -me_range 21 \
	#	-chroma 1 -slice 2 -bf 0 -level 30 -g 300 -keyint_min 30 -sc_threshold 40 -rc_eq 'blurCplx^(1-qComp)' \
	#	-qcomp 0.7 -qmax 51 -qdiff 4 -i_qfactor 0.71428572 -maxrate 768000 -bufsize 2M -cmp 1 -s 480x320 -f mp4\
	#	-pass 1 /dev/null
	#
	#	$FFMPEG -y -i "$1" -v 1 -threads auto -vcodec libx264 -b 500000 -bt 175000 -refs 1 -loop 1 -deblockalpha\
	#	0 -deblockbeta 0 -parti4x4 1 -partp8x8 1 -me full -subq 6 -me_range 21 -chroma 1 -slice 2 -bf 0 -level \
	#	30 -g 300 -keyint_min 30 -sc_threshold 40 -rc_eq 'blurCplx^(1-qComp)' -qcomp 0.7 -qmax 51 -qdiff 4 \
	#	-i_qfactor 0.71428572 -maxrate 768000 -bufsize 2M -cmp 1 -s 480x320 -acodec libfaac -ab 96 -ar 48000 -ac\
	#	2 -f mp4 -pass 2 "$2"

	MiscParams = %w(-y -threads auto -maxrate 3584000 -bufsize 1536000 -async 1)

	VideoParams = %w(-vcodec libx264 -r 30000/1001 -b 1536000 -level 30 -mbd 2 -cmp 2 -subcmp 2 -g 300 -qmin 20
	-qmax 31 -flags +loop -chroma 1 -partitions partp8x8+partb8x8 -flags2 +mixed_refs -me_method 8 -subq 7
	-trellis 2 -refs 1 -coder 0 -me_range 16 -bf 0 -sc_threshold 40 -keyint_min 25 -s 488x328
	-croptop 4 -cropbottom 4 -cropleft 4 -cropright 4 -aspect 4:3 )

	AudioParams = %w( -acodec libfaac -ac 2 -ar 44100 -ab 0 -aq 120 -alang ENG )

	FFMpegPath = File.join(AppConfig::RootDir, 'libexec', 'bin', 'ffmpeg')
	def get_command(input, output)
		ret = ["#{FFMpegPath} -i \"#{input}\""] + MiscParams + VideoParams + AudioParams + ["\"#{output}\""]
		ret.join ' '
	end

	def before_transcode
		ENV["LD_LIBRARY_PATH"] = File.join(AppConfig::RootDir, 'libexec', 'lib')
	end
end
