test: sol2.xml
	xmllint --relaxng schema/tei_all.rng SOL2.xml

smalltest: smalltest.xml
	xmllint --schema ../../../TEI/Stylesheets/profiles/iso/schema/isotei.xsd smalltest.xml

cotw: character-other-than-whitespace.xml
	xmllint --schema ../../../TEI/Stylesheets/profiles/iso/schema/isotei.xsd character-other-than-whitespace.xml

whereplace: where-are-placenames.xml
	xmllint --schema ../../../TEI/Stylesheets/profiles/iso/schema/isotei.xsd where-are-placenames.xml
