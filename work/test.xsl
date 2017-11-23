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
        <xsl:apply-templates select="span" />
      </body>
    </html>
  </xsl:template>

  <xsl:template match="div[@xml:id='introduction']" />
  <xsl:template match="div">
    <div>
      <xsl:apply-templates />
    </div>
  </xsl:template>

  <xsl:template match="head">
    <strong><xsl:value-of select="placeName" /></strong>
  </xsl:template>

  <xsl:template match="p">
    <xsl:apply-templates />
  </xsl:template>

  <!-- <xsl:text> </xsl:text><xsl:value-of select="p" /> -->

  <xsl:template match="location">
    <xsl:variable name='count' select='count(*)' />
    <xsl:for-each select="*">
      <xsl:apply-templates />
      <xsl:if test="position()=$count">
        <xsl:text>, </xsl:text>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="location/*">
    <xsl:apply-templates />
  </xsl:template>

  <xsl:template match="settlement|district|region">
    <xsl:apply-templates />
  </xsl:template>

  <xsl:template match="span[@type='locale']">
    <xsl:apply-templates />
  </xsl:template>

  <xsl:template match="span[@type='kursiv']">
    <em><xsl:apply-templates /></em>
  </xsl:template>

</xsl:stylesheet>
