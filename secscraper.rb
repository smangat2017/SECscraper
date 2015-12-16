require 'mechanize'
require 'spreadsheet'
mechanize = Mechanize.new
spreadsheet = Spreadsheet::Workbook.new

sheet1 = spreadsheet.create_worksheet
sheet1.name = "13FDataScraped"

#link that contains the filtered documents 
page = mechanize.get('http://www.sec.gov/cgi-bin/browse-edgar?action=getcompany&CIK=0001345471&type=13F-HR&dateb=&owner=exclude&count=40')

sheet1[0,0] = "Date Entry"
sheet1[0,1] = "Company Name"
sheet1[0,4] = "Value x$1000"

counter = 0 
row_number = 1
column_number = 1 
is_text_file = false

#for each document button 
page.links_with(:id => "documentsbutton").each do |link|
	#limit the number of times we scrape for testing purposes
	if counter < 23
		#for more recent years - the html link 
		link_to_actual_data = link.click.search('//*[@id="formDiv"]/div[3]/table/tr[4]/td[3]/a').inner_html
		if link_to_actual_data == ""
			#if that link doesn't exist then we know we're going to be parsing a text file
			is_text_file = true
		end
		if !is_text_file
			#click on the html link and pull the actual data
			actual_data = link.click.link_with(:text => link_to_actual_data).click
			#pull the date entry to store in the spreadsheet 
			date_entry = link.click.search('//*[@id="formDiv"]/div[2]/div[1]/div[2]').inner_html

			#get all row tags on the html page
			all_rows = actual_data.search("//tr")
			all_rows.each do |row|
				valid_row = false
			    row.children.each do |child|
			    	class_name = child.attribute('class').to_s
			    	#filter the rows by the class name 
			    	if class_name.include? "FormData"
			    		valid_row = true
			    		sheet1[row_number,column_number] = child.inner_html
			    		#put in the date
			    		sheet1[row_number,0] = date_entry
			    		column_number = column_number + 1
			    	end
			    end
			    if valid_row
			    	row_number = row_number + 1
			    end
			    column_number = 1
			end
			puts date_entry
		else
			link_to_actual_data = link.click.search('//*[@id="formDiv"]/div[3]/table/tr[2]/td[3]/a').inner_html
			actual_data = link.click.link_with(:text => link_to_actual_data).click
			date_entry = link.click.search('//*[@id="formDiv"]/div[2]/div[1]/div[2]').inner_html
			actual_data.save! "#{date_entry}"
			text_data = File.new("#{date_entry}","r")
			table_data = false
			column_info = nil
			while line = text_data.gets
				if table_data == true
					#the name of the company
					if line.include? "</TABLE>"
						break
					end
					puts line
					sheet1[row_number,0] = date_entry
					scanned_line = line.scan(/\S+/)

					sheet1[row_number,1] = line[0,column_info[0].length + 7]
					# offset = column_info[0].length + column_info[1].length + column_info[2].length + 22
					puts scanned_line[scanned_line.length - 6]
					sheet1[row_number,4] = scanned_line[scanned_line.length - 6]
					row_number = row_number + 1
					text_data.gets
				end
				if line.include? "NAME OF ISSUER"
					dashes = text_data.gets
					column_info = dashes.scan(/-+/) 
					#move to data line in the table
					text_data.gets

					table_data = true
				end
			end
			text_data.close
		end
	end
	row_number = row_number + 1
	counter = counter + 1
end
spreadsheet.write '/Users/whitenite2013/Desktop/TrianFundScrapedData.xls'
