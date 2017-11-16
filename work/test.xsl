<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/1999/xhtml">

<xsl:output method="html" indent="yes" encoding="UTF-8" />

<!--
<xsl:template match="/TEI/text/body/div[2]/div[23]">
  <html>
    <head>
      <meta encoding="UTF-8" />
      <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
      <title>Testing XSLT</title>
    </head>
    <body>
      <h2>Articles</h2>
      <ul>
        <xsl:apply-templates select="div">
          <xsl:sort select="head" />
        </xsl:apply-templates>
      </ul>
    </body>
  </html>
</xsl:template>

<xsl:template match="div">
  <li>
    <xsl:value-of select="head" />
  </li>
</xsl:template>
-->

<xsl:template match="/TEI/text/body/div[2]">
<xsl:for-each select="div[23]">
<xsl:value-of select="head/placeName" />
</xsl:for-each>
</xsl:template>

</xsl:stylesheet>
