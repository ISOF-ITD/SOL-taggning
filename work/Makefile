validate: SOL2.xml
	xmllint --relaxng schema/tei_all.rng SOL2.xml

html: SOL2.xml
	saxon SOL2.xml test.xsl >test.html
