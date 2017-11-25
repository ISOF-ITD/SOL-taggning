places = []
sol2.each_element('/TEI/text/body/div/p/span[@type="locale"]') { |locale| if locale.text == 'sn' then placenode = XPath.first(locale.parent.parent, 'head/placeName'); if placenode then place = placenode.text; puts place; places << place end end }

