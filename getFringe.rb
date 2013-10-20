require 'mechanize'
require 'logger'
require 'pry'
require 'zip/zip'

class GetFringe
  attr_accessor :agent, :first_page, :chapter_markers

  def initialize()
    @agent = Mechanize.new
    @agent.log = Logger.new "mech.log"
    @agent.user_agent_alias = 'Mac Safari'
  end

  def start_download
    # Start with first page of first Chapter
    buffer_url = "http://fringe.wikia.com/wiki/Fringe_Issue_"
    6.times{|i|
      i += 1
      base_url = buffer_url + i.to_s
      page = @agent.get("#{base_url}")
      puts @agent.current_page().uri()
      current_chapter = i
      puts "Chapter switched to -> " + current_chapter.to_s
      results = page.search("#mw-content-text .image")
      results.each_with_index{ |image, index|
        index = index + 1
        comic_url = image.attributes["href"].to_s
        image_name = comic_url.split('/')[-1]
        begin
          puts "Currently Downloading: #{current_chapter}"
          puts "Downloading comic address: #{comic_url}"
          @agent.get("#{comic_url}").save("#{chapter_directory(current_chapter)}/#{index}_#{image_name}")
        rescue Net::HTTPNotFound, Mechanize::ResponseCodeError => e
          puts "Error Downloading: #{comic_url}"
        rescue Mechanize::UnsupportedSchemeError => e
          begin
            File.open("#{chapter_directory(current_chapter)}/#{index}_#{image_name}.jpeg", 'wb') do |f|
              jpg = Base64.decode64(comic_url['data:image/jpeg;base64,'.length..-1])
              f.write(jpg)
            end
          rescue
            puts "saving failed on base 64 jpg..."
          end
        end

        if index == results.count
          zip_previous_chapter(current_chapter)
        end
      }
    }
  end

  def chapter_directory(chapter_id)
    "fringe_comics/fringe_chapter_#{chapter_id}"
  end

  def zip_file_path(chapter_id)
    directory_name = "saved_comics"
    unless File.directory?(directory_name)
      FileUtils.mkdir_p(directory_name)
    end
    "#{directory_name}/Fringe_chapter_#{chapter_id}.cbz"
  end

  def zip_previous_chapter(chapter_id)
    directory = chapter_directory(chapter_id)
    zipfile_name = zip_file_path(chapter_id)
    if File.exist?(zipfile_name)
      File.delete(zipfile_name)
    end
    Zip::ZipFile.open(zipfile_name, 'w') do |zipfile|
      Dir["#{directory}/**/**"].reject{|f|f==zipfile_name}.each do |file|
        zipfile.add(file.sub(directory+'/',''),file)
      end
    end
  end

  class << self
    def new_download()
      scary_downloader = self.new()
      scary_downloader.start_download
    end
  end

end

GetFringe.new_download()

exit
