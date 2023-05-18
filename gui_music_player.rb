require 'rubygems'
require 'gosu'

# 7.3 - 9.2 Extension

# THINGS TO DO TOMORROW:
# Set a defined volume value across all songs.

LEFT_COLOR = Gosu::Color.new(0xFF1EB1FA)
RIGHT_COLOR = Gosu::Color.new(0xFF1D4DB5)

module ZOrder
  BACKGROUND, PLAYER, UI = *0..2
end

module Genre
  POP, CLASSIC, JAZZ, ROCK, ORCHESTRAL, VARIOUS = *1..6
end

GENRE_NAMES = ['Null', 'Pop', 'Classic', 'Jazz', 'Rock', 'Orchestral', 'Various']

class ArtWork
	attr_accessor :bmp, :x, :y

	def initialize (file, x, y)
		@bmp = Gosu::Image.new(file)
	end
end

class Album
	attr_accessor :title, :artist, :genre, :tracks, :cover, :custom

	def initialize (title, artist, genre, tracks, cover, custom)
		@title = title
		@artist = artist
		@genre = genre
		@tracks = tracks
		@cover = cover
		@custom = custom
	end
end

class Track
	attr_accessor :name, :location, :selected
 
	def initialize (name, location, selected)
		@name = name
		@location = location
		@selected = selected
	end
end

# Global Variables
WIN_HEIGHT = 900
WIN_WIDTH = 1100

# Put your record definitions here

class MusicPlayerMain < Gosu::Window

	def initialize
	    super WIN_WIDTH, WIN_HEIGHT
	    self.caption = "Music Player"
		#========================================#
		#          Initialise Variables          #
		#========================================#
		# Initialise Background Colours 
		@background_top = LEFT_COLOR
		@background_bot = RIGHT_COLOR
		# Initialise Fonts and TrackLeftX
		@track_font = Gosu::Font.new(30)
		@info_font = Gosu::Font.new(20)
		@playlist_font = Gosu::Font.new(30)
		@TrackLeftX = 620

		@album_notclicked = true
		@song_marker = Gosu::Color.new(0xeb9d21)

		# Indexes for album and track arrays respectively
		@song_index = 0
		@album_index = 0

		@album_prev = 0 # Remembers previous value of @album_index
		@song_selection = nil # Variable to put selected song
		@song = nil
		@album_count_checked = false
		@row_change_checked = false # Check if second row
		@custom_num_limit = 1 # Limit no. of custom playlists
		@saved_song = nil # Song stored in right click
		@is_song_looping = false

		# Relating to Pause and Play buttons
		@isPausePressed = false
		@pause_button = Gosu::Image.new("images/pause.png")
		@play_button = Gosu::Image.new("images/play.png")

		# Reads in an array of albums from a file and then prints all the albums in the
		# array to the terminal
		music_file = File.new("album.txt", "r")
		read_album(music_file)
		music_file.close()
	end

	#=============================#
	#      READ-IN FUNCTIONS      #
	#=============================#
  	# Put in your code here to load albums and tracks
	def read_album(music_file)
		@albums = Array.new() # Create album array
		# Ensures program only reads in ONE album count
		if @album_count_checked == false
			album_count = music_file.gets().chomp()
			@album_count_checked = true
		end

		i = 0
		while (i < album_count.to_i())
			# Read in all the Album's fields/attributes
			album_title  = music_file.gets().chomp()
        	album_artist = music_file.gets().chomp()
        	album_genre  = music_file.gets().chomp()
			# Read in directory path for album cover image
			cover = music_file.gets().to_s().chomp()
			album_cover = ArtWork.new(cover, 0, 0) # Creates album cover instance
			album_tracks = read_tracks(music_file)
			# Create instance of Album object
			album = Album.new(album_title, album_artist, album_genre, album_tracks, album_cover, false)
			@albums << album # Append album to albums array
			i += 1
		end
		return @albums
	end

	# Returns an array of tracks read from the given file
	def read_tracks(music_file)
    	tracks = Array.new()
		count = music_file.gets().to_i()
		# A while loop to read and append each track
		index = 0
    	while(index < count)
 			tracks << read_track(music_file)
			index += 1
		end
 		return tracks
	end

	# Reads in and returns a single track from the given file
	def read_track(music_file)
    	# fill in the missing code
    	return Track.new(music_file.gets().chomp(), music_file.gets().chomp(), false)
	end

  	# Detects if a 'mouse sensitive' area has been clicked on
  	# i.e either an album or a track. returns true or false
  	def area_clicked(leftX, topY, rightX, bottomY)
		i = 0
		j = 0
		albumBottomBorder = 300 # The bottom border of the list of albums
		while i < @albums.length
			albumMultiplier = i + 1
			# The valid area produced by this statement increases
			# for every album in the array, up until this statement
			# can return true (1: 300x300, 2: 300x600 etc.)
			if (rightX <= 600 && bottomY <= albumBottomBorder * albumMultiplier)
				if rightX <= 300
					@album_index = i
					return true
				else
					@album_prev = @album_index
					# Need to look for second column
					@album_index = i + 3
					# Return false when clicking on a non-album space
					if @album_index < @albums.length
						# Forces @album_index back to previous valid value
						@album_prev = @album_index
						@song_index = 0 # Reset song index
						@song_selection = nil
						return true
					else
						@album_index = @album_prev
						return false
					end
				end
			# Defining area for pause/Play buttons & Tracks
			elsif (rightX > 600 && @album_notclicked == false)
				# Hitbox for Pause Button
				if topY > 800 && (rightX.between?(823, 880))
					return true
				# Hitbox for Create Playlist Button
				elsif mouse_x.between?(600, 1100) && (mouse_y.between?(750, 800))
					create_custom_album(@albums)
				end
				trackBottomBorder = 30 # Bottom border for list of tracks
				trackMultiplier = 1
				while j < @albums[@album_index].tracks.length
					# The valid area produced by this statement increases
					# for every track in the array, up until this statement
					# can return true (1: 10+30, 2: 10+60 etc.)
					if bottomY <= (10 + (trackBottomBorder * trackMultiplier))
						if button_down?(Gosu::MsLeft)
							@song_index = j
							return true
						elsif button_down?(Gosu::MsRight)
							@song_selection = j
							return true
						end
					else
						trackMultiplier += 1
					end
					j += 1
				end
			end
			i += 1
		end
  	end

  	#======================#
	#    DRAW FUNCTIONS    #
	#======================#
	# Draws the artwork on the screen for all the albums
	def draw_albums(album, xpos, ypos)
    	# complete this code
		album.cover.bmp.draw(xpos, ypos, ZOrder::PLAYER)
  	end
	
	  # Draws pause and play button when appropriate
	def draw_play_pause_button(xpos, ypos)
		if @isPausePressed
			@play_button.draw(xpos, ypos, ZOrder::UI)
		else
			@pause_button.draw(xpos, ypos, ZOrder::UI)
		end
	end

	# Draws track when called
  	def display_track(title, ypos, color)
		@track_font.draw_text(title, @TrackLeftX, ypos, ZOrder::UI, 1.0, 1.0, color)
  	end

	# Draw a coloured background using TOP_COLOR and BOTTOM_COLOR
	def draw_background
		Gosu.draw_rect(0, 0, WIN_WIDTH, WIN_HEIGHT, @background_top, ZOrder::BACKGROUND, mode=:default)
		Gosu.draw_rect(600, 0, WIN_WIDTH, WIN_HEIGHT, @background_bot, ZOrder::BACKGROUND, mode=:default)
	end

	def draw_debug
		# Checks and prints Mouse Position (DEBUG ONLY)
		#@info_font.draw_text("mouse_x: #{mouse_x}", 310, 600, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::BLACK)
		#@info_font.draw_text("mouse_y: #{mouse_y}", 310, 620, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::BLACK)
		# Keyboard Shortcuts
		@info_font.draw_text("KEYBOARD SHORTCUTS:", 610, 570, ZOrder::PLAYER, 1.5, 1.5, Gosu::Color::BLACK)
		@info_font.draw_text("Use LEFT and RIGHT keys to change track.", 610, 600, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::BLACK)
		@info_font.draw_text("Use UP and DOWN keys to change volume.", 610, 620, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::BLACK)
		@info_font.draw_text("Press SPACE to pause and play tracks.", 610, 640, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::BLACK)
		@info_font.draw_text("Right click a track to select it.", 610, 660, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::BLACK)
		@info_font.draw_text("Right click a playlist to add a selected track to it.", 610, 680, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::BLACK)
		if @is_song_looping == true
			@info_font.draw_text("LOOP: ON", 610, 720, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::BLACK)
		end
	end

	def draw_playlist_button
		Gosu.draw_rect(600, 750, 500, 50, Gosu::Color::BLACK, ZOrder::UI)
		@playlist_font.draw_text("+ Create New Playlist", 720, 760, ZOrder::UI, 1.0, 1.0, Gosu::Color::YELLOW)
	end

	#================#
	#   DRAW LOGIC   #
 	#================#
	# Draws the album images and the track list for the selected album
	def draw
		# Complete the missing code
		draw_background()
		albumX = 0
		albumY = 0
		index = 0
		while index < @albums.length
			# Allows function to print multiple columns of albums.
			if index >= 3
				albumX = 300
					albumY = 0
					# Multiples 2nd row index by 300
					albumDrawProduct = (index - 3) * 300
				draw_albums(@albums[index], albumX, albumDrawProduct)
			else
				draw_albums(@albums[index], albumX, albumY)
			end
			albumY += 300
			index += 1
		end
		j = 0
		track_ypos = 10
		# Draw Tracks 
		if !@album_notclicked
			draw_debug()
			draw_play_pause_button(800, 800)
			draw_playlist_button()
			while (j < @albums[@album_index].tracks.length)
				# Highlights playing track
				if j == @song_selection
					display_track(@albums[@album_index].tracks[j].name, track_ypos, Gosu::Color::YELLOW)
				elsif j == @song_index
					display_track(@albums[@album_index].tracks[j].name, track_ypos, Gosu::Color::WHITE)
				else
					display_track(@albums[@album_index].tracks[j].name, track_ypos, Gosu::Color::BLACK)
				end
				track_ypos += 30
				j += 1
			end
		end
	end

	# Plays track of album index and song index
	def playTrack(track, album)
		if album.tracks.length > 0
			@song = Gosu::Song.new(album.tracks[track].location)
  	    	@song.play(false)
			@isPausePressed = false
		end
	end

	# Not used? Everything depends on mouse actions.
	# ^^^ WRONG ^^^
	#====================#
	#    UPDATE LOGIC    #
	#====================#
	def update
		if @song != nil
			# Do nothing if the song is PAUSED
			if @song.paused?
			# If a song is not playing (returning nil) and it isn't the end of the album
			# @song.playing? returns either TRUE or FALSE
			# @song.play(false) returns NIL after song is finished playing
			elsif Gosu::Song.current_song == nil
				if @is_song_looping == false
					@song_index += 1
				end
				if @song_index < @albums[@album_index].tracks.length
		 			playTrack(@song_index, @albums[@album_index])
				else
					@isPausePressed = true
				end
			end
		end
	end

	# Displays mouse in the window
 	def needs_cursor?; true; end

	#========================================#
	#        BUTTON DOWN INPUT LOGIC         #
	#========================================#
	# When a button is pressed, this is called.
	def button_down(id)
		case id
	    when Gosu::MsLeft
			# If an Album Cover in the first or second row is clicked
			if (area_clicked(0, 0, mouse_x, mouse_y) && mouse_x <= 300) || (area_clicked(300, 0, mouse_x, mouse_y) && mouse_x <= 600)
				# Prevents errors when clicking on empty playlists
				if @albums[@album_index] != nil
					@album_prev = @album_index
					@song_index = 0 # Reset song index
					area_clicked(0, 0, mouse_x, mouse_y)
					@album_notclicked = false
					@isPausePressed = false
					@song_selection = nil
					playTrack(@song_index, @albums[@album_index])
				end
			# If a Track is clicked
			elsif area_clicked(600, 0, mouse_x, mouse_y)
				@isPausePressed = false
				playTrack(@song_index, @albums[@album_index])
			# If Pause/Play is clicked
			elsif area_clicked(800, mouse_y, mouse_x, 900)
				pause_play_track()
			# If Create Playlist is clicked
			elsif area_clicked(600, 750, 1100, 800) # L, T, R, B
				create_custom_album(@albums)
			end
		# If Right Mouse Button is clicked
		when Gosu::MsRight
			if (area_clicked(0, 0, mouse_x, mouse_y) && mouse_x <= 300) || (area_clicked(300, 0, mouse_x, mouse_y) && mouse_x <= 600)
				if @albums[@album_index].custom != true
				else
					# Check if a song has been selected
					if @saved_song != nil
						add_to_playlist(@saved_song)
					end
				end
			elsif area_clicked(600, 0, mouse_x, mouse_y)
				puts "<< Selected Track: " + @albums[@album_index].tracks[@song_selection].name.to_s + " >>"
				@saved_song = save_track_selection(@song_selection)
			end
		# Increase/Decrease Volume
		when Gosu::KbUp
			increase_volume()
		when Gosu::KbDown
			decrease_volume()
		# Switching through tracks in an album
		when Gosu::KbLeft
		 	next_track()
		when Gosu::KbRight
		 	prev_track()
		# Pause/Play the current song
		when Gosu::KbSpace
			pause_play_track()
		when Gosu::KbR
			loop_song()
		# Scroll Up
		when Gosu::MsWheelUp
			if mouse_x > 600
				@isPausePressed = false
				next_track()
			end
		# Scroll Down
		when Gosu::MsWheelDown
			if mouse_x > 600
				@isPausePressed = false
				prev_track()
			end
	    end
	end

	#=======================================#
	#          HD CUSTOM EXTENSION          #
	#=======================================#
	# Custom Album/Playlist Creation (HD Extension Pt 1)
	def create_custom_album(albums)
		if @custom_num_limit <= 1
			tracks = Array.new()
			album_cover = ArtWork.new('images/custom' + @custom_num_limit.to_s + '.png', 0, 0)
			@albums << Album.new("Custom Playlist", "N/A", "N/A", tracks, album_cover, true)
			@custom_num_limit += 1
		end
	end

	# Save song selection into right mouse click (HD Extension Pt 2)
	def save_track_selection(selection)
		saved_song = @albums[@album_index].tracks[selection]
		return saved_song
	end

	# Append saved song to custom playlist (HD Extension Pt 3)
	def add_to_playlist(song)
		if @albums[@album_index].custom
			@albums[@album_index].tracks << song
			puts "<< Added Track: " + song.name + " >>"
		end
	end

	#=====================================#
	#     TRACK HANDLING SHENANIGANS      #
	#=====================================#
	# Changes to next track
	def next_track()
		if @song != nil
			@song_index -= 1
			if @song_index < 0
				@song_index = 0
			end
			playTrack(@song_index, @albums[@album_index])
		end
	end

	# Changes to previous track
	def prev_track()
		if @song != nil
			@song_index += 1
			if @song_index > @albums[@album_index].tracks.length - 1
				@song_index = @albums[@album_index].tracks.length - 1
			end
			playTrack(@song_index, @albums[@album_index]) 
		end
	end

	# Pauses/Plays current track
	def pause_play_track()
		if @song_index < @albums[@album_index].tracks.length
			if @isPausePressed == true
				@isPausePressed = false
				@song.play
			else
				@isPausePressed = true
				@song.pause
			end
		end
	end

	# Self-explanatory
	def increase_volume()
		if @song != nil
			if @song.volume < 1.0
				@song.volume += 0.1
			end
		end
	end

	# Self-explanatory
	def decrease_volume()
		if @song != nil
			if @song.volume > 0.0
				@song.volume -= 0.1
			end
		end
	end

	def loop_song()
		if @is_song_looping == false
			@is_song_looping = true
		else
			@is_song_looping = false
		end
	end
end

# Show is a method that loops through update and draw
MusicPlayerMain.new.show if __FILE__ == $0