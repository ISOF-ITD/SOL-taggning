<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/1999/xhtml" xpath-default-namespace="http://www.tei-c.org/ns/1.0">

  <xsl:output method="xml" indent="yes" encoding="UTF-8" />

  <xsl:template match="/TEI/teiHeader" />

  <xsl:template match="/TEI/text/body">
    <html>
      <head>
        <meta encoding="UTF-8" />
      </head>

      <body>
        <h2>First test</h2>
        <xsl:apply-templates select="div" />
      </body>
    </html>
  </xsl:template>

  <xsl:template match="div[@xml:id='introduction']" />
  <xsl:template match="div">
    <div>
      <strong><xsl:value-of select="head/placeName" /></strong><xsl:text> </xsl:text><xsl:value-of select="p" />
    </div>
  </xsl:template>

  <xsl:template match="location">
    <xsl:for-each select="*">
      <xsl:value-of select="*" />
    </xsl:for-each>
  </xsl:template>

</xsl:stylesheet>
