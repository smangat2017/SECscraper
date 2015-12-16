require 'mechanize'
mechanize = Mechanize.new

page = mechanize.get('http://www.sec.gov/cgi-bin/browse-edgar?action=getcompany&CIK=0001061768&type=13F-HR&dateb=&owner=exclude&count=100')

counter = 0 

page.links_with(:id => "documentsbutton").each do |link|
	if counter == 0
		document_links = link.click.link_with(:text => "form13fInfoTable.html")
		puts document_links.click.body
		puts link.click.search('//*[@id="formDiv"]/div[2]/div[1]/div[2]')
	end
	counter = counter + 1
end
