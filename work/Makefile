validate: sol2.xml
	xmllint --relaxng schema/tei_all.rng SOL2.xml

html: sol2.xml
	saxon test.xml test.xsl >test.html
