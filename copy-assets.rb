# This file copies images and PDF files to a local database for improved performance
# PDF files are compressed to reduce file size

require 'json'

f = File.read('landmarks.geojson')
data_hash = JSON.parse(f)
system 'mkdir -p downloads'

s3_uploads = `aws s3 ls  s3://nyclandmarks`
s3_uploads = s3_uploads.split(/\n+/)
s3_uploads = s3_uploads.map{ |a| a.split[3]}

data_hash['features'].each do |feature|
	pdf = feature['properties']['URL_REPORT']
	image = feature['properties']['URL_IMAGE']
	
	downloaded_pdf = "downloads/#{File.basename(pdf)}"
	downloaded_image = "downloads/#{File.basename(image)}"

	if !File.exists? downloaded_pdf
		puts "downloading #{pdf}"
		system "curl -L #{pdf} > #{downloaded_pdf}" 
	end

	optimized_pdf = "downloads/small_#{File.basename(pdf)}"
	if !File.exists? optimized_pdf
		puts "Compressing PDF #{optimized_pdf}"
		system("gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/screen -dNOPAUSE -dQUIET -dBATCH -sOutputFile=#{optimized_pdf} #{downloaded_pdf}")
	end


	if !File.exists? downloaded_image
		puts "downloading #{image}"
		system "curl -L #{image} > #{downloaded_image}" 
	end

	if !s3_uploads.include?("small_#{File.basename(pdf)}")
		system "aws s3 cp #{optimized_pdf} s3://nyclandmarks/small_#{File.basename(pdf)} --acl public-read-write"
		system "aws s3 cp #{downloaded_image} s3://nyclandmarks/#{File.basename(image)} --acl public-read-write"
	end


end

