require "csv"
require "uuid"
require "option_parser"
require "shellwords"

module Musgas
  def self.read_csv(file : String) : Array(Hash(String, String))
    begin
      CSV.parse(File.read(file)).map do |row|
        {"name" => row[0], "url" => row[1], "start" => row[2], "end" => row[3]}
      end
    rescue ex
      puts "Error reading CSV file: #{ex.message}"
      [] of Hash(String, String)
    end
  end

  def self.download_video(url : String, filename : String)
    command = "yt-dlp '#{url}' -o '#{filename}'"
    puts "Downloading #{url} to #{filename}"

    begin
      system(command)
    rescue ex
      puts "Error downloading #{url}: #{ex.message}"
    end
  end

  def self.download_videos(videos : Array(Hash(String, String))) : Array(Hash(String, String))
    processes = [] of Fiber
    files = [] of Hash(String, String)

    videos.each do |video|
      processes << spawn do
        filename = (
          "/tmp/#{video["name"].downcase.gsub(/\s+/, "-")}-#{UUID.random.to_s[0..7]}"
        )

        files << {
          "video" => "#{filename}.webm",
          "start" => video["start"],
          "end" => video["end"]
        }

        download_video(video["url"], filename)
      end
    end

    processes.each(&.resume)

    files
  end

  def self.convert_to_music(video : String) : String?
    output_file = video.sub(/\.webm$/, ".mp3")
    command = "ffmpeg -i #{video.shellescape} -vn -ar 44100 -ac 2 -ab 192k -f mp3 #{output_file.shellescape}"
    system(command)

    if File.exists?(output_file)
      return output_file
    else
      return nil
    end
  end

  def self.convert_videos_to_music(files : Array(Hash(String, String))) : Array(Hash(String, String?))
    musics_converted = [] of Hash(String, String?)

    files.each do |file|
      musics_converted << {
        "music" => convert_to_music(file["video"]),
        "start" => file["start"],
        "end" => file["end"]
      }
    end

    musics_converted
  end

  def self.cut_music(music : String?, start_time : String?, end_time : String?) : String?
    if music.nil?
      return nil
    end

    input_file = music.shellescape
    output_file = "~/musgas/#{music.shellescape}"
    command = "ffmpeg -i #{input_file} -ss #{start_time} -to #{end_time} -c copy #{output_file}"
    system(command)

    output_file
  end

  def self.cut_musics(musics_to_cut : Array(Hash(String, String?))) : Array(String?)
    musics = [] of String?

    musics_to_cut.each do |music_to_cut|
      musics << cut_music(
        music_to_cut["music"], music_to_cut["start"], music_to_cut["end"]
      )
    end

    musics
  end

  def self.main(file : String)
    videos = read_csv(file)
    files = download_videos(videos)
    musics_converted = convert_videos_to_music(files)
    musics = cut_musics(musics_converted)
  end
end

parser = OptionParser.parse do |option|
  option.banner = "Usage: musgas [subcommand] [arguments]"

  option.on("download", "") do
    option.banner = "Usage: musgas download [arguments]"

    option.on("-f FILE", "--file=FILE", "") { |file| Musgas.main(file) }
  end

  option.on("-h", "--help", "Show this help") do
    puts option
    exit
  end

  option.invalid_option do |flag|
    STDERR.puts "ERROR: #{flag} is not a valid option."
    STDERR.puts option
    exit(1)
  end
end

parser.parse
