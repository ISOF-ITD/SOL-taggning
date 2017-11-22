validate: sol2.xml
	xmllint --relaxng schema/tei_all.rng SOL2.xml

html: sol2.xml
	xsltproc test.xsl test.xml >test.html
