validate: sol2.xml
	xmllint --relaxng schema/tei_all.rng SOL2.xml

html: sol2.xml
	saxon SOL2.xml ../../../TEI/Stylesheets/html/html.xsl
