<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:axsl="http://www.w3.org/1999/XSL/TransformAlias"
	xmlns:content-map="http://www.corbas.co.uk/ns/transforms/content-map"
	xmlns:cfunc="http://www.corbas.co.uk/ns/functions" 
	xpath-default-namespace="http://www.corbas.co.uk/ns/transforms/content-map"
	xmlns:xsd="http://www.w3.org/2001/XMLSchema"
	xmlns:doc="http://www.corbas.co.uk/ns/documentation"
	xmlns="http://www.w3.org/1999/XSL/TransformAlias"
	exclude-result-prefixes="doc cfunc xsd content-map axsl" version="2.0">
	
	

<!--		
		This program and accompanying files are copyright 2008, 2009, 2011, 2012, 2013 Corbas Consulting Ltd.
		
		This program is free software: you can redistribute it and/or modify
		it under the terms of the GNU General Public License as published by
		the Free Software Foundation, either version 3 of the License, or
		(at your option) any later version.
		
		This program is distributed in the hope that it will be useful,
		but WITHOUT ANY WARRANTY; without even the implied warranty of
		MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
		GNU General Public License for more details.
		
		You should have received a copy of the GNU General Public License
		along with this program.  If not, see http://www.gnu.org/licenses/.
		
		If your organisation or company are a customer or client of Corbas Consulting Ltd you may
		be able to use and/or distribute this software under a different license. If you are
		not aware of any such agreement and wish to agree other license terms you must
		contact Corbas Consulting Ltd by email at corbas@corbas.co.uk.
-->		
	
	<xsl:import href="identity.xsl"/>
	
	<doc:title>Build Content Mapping Stylesheet</doc:title>

	<doc:documentation scope="global">
		<p xmlns="http://www.w3.org/1999/xhtml">This stylesheet is used to read a mapping file (as
			defined by <code>content-mapping.rng</code> and convert it to an XSLT stylesheet that can be
			used to read an incoming XML file, read given elements and write out new ones. </p>
		<p xmlns="http://www.w3.org/1999/xhtml">The script is part of the Word to XML mapping toolkit and run as part of that pipeline.
			It is intended to run after the Word document has been converted to elements in the
			output XML language but not structured. In general, word paragraphs are mapped to output
			language paragraphs unless they are tables, images or lists. These paragraphs are then
			refined as appropriate by the output of this stylesheet. See the documentation for
				<code>content-mapping.rng</code> for details on the definitions used.</p>

	</doc:documentation>

	<xsl:output method="xml" indent="yes" encoding="UTF-8"/>

	<!-- We need to create content in the axsl namespace to avoid collisions
	 	and then output it in the XSLT namespace. The namespace-alias does
	 	this for us -->
	<xsl:namespace-alias stylesheet-prefix="axsl" result-prefix="xsl"/>
	
	<xsl:variable name="sq"><xsl:text>'</xsl:text></xsl:variable>
	
	<doc:documentation scope="template">
		<p xmlns="http://www.w3.org/1999/xhtml">This template matches the <code class="element"
			>map</code> elements of the input and creates the stylesheet element for output. 
			We include an identity transform as any element not processed by our
			constructed stylesheet must be passed through unchanged. We do force the output to be
			UTF-8 regardless of input.</p>
	</doc:documentation>
	
	<xsl:template match="map" as="element()">
		<axsl:stylesheet version="2.0">
			
			<xsl:apply-templates select="namespace"/>
			
			<!-- avoid painful to read content -->
			<xsl:variable name="axsl-name">{name()}</xsl:variable>
			<xsl:variable name="axsl-uri">{namespace-uri()}</xsl:variable>
			
			
			<axsl:output method="xml" encoding="UTF-8"/>
			
			<axsl:template match="@*|node()" mode="#all">
				<axsl:element name="{$axsl-name}" namespace="{$axsl-uri}">
					<axsl:apply-templates select="@*|node()" mode="#current"/>
				</axsl:element>
			</axsl:template>
			
			<!-- process all the mapping elements. -->
			<xsl:apply-templates select="mapping"/>
			
		</axsl:stylesheet>
	</xsl:template>
	
	
	<doc:documentation>
		<p xmlns="http://www.w3.org/1999/xhtml">Convert namespace elements in the input to
		namespace nodes in the output</p>
	</doc:documentation>

	<xsl:template match="namespace">
		<xsl:namespace name="{@prefix}" select="@uri"/>
	</xsl:template>
	
	<doc:documentation>
		<p xmlns="http://www.w3.org/1999/xhtml">Generate the template for a single
			mapping element.
		</p>
	</doc:documentation>
	
	<xsl:template match="mapping">
		<xsl:apply-templates select="equals|starts-with|ends-with|matches"/>
	</xsl:template>

	<xsl:template match="equals|starts-with|ends-with|matches">
			
		<xsl:variable name="matcher">
			<xsl:apply-templates select="." mode="write-matcher">
				<xsl:with-param name="context" select="parent::mapping/@context"/>
			</xsl:apply-templates>
		</xsl:variable>
		
		<axsl:template match="{parent::mapping/@node}[{$matcher}]">
			<xsl:apply-templates select="parent::mapping/output"/>	
		</axsl:template>
		
	</xsl:template>
	
	<xsl:template match="output">
		<xsl:apply-templates/>
	</xsl:template>
	
	<xsl:template match="apply">
		<axsl:apply-templates/>
	</xsl:template>
	
	<xsl:template match="copy">
		<axsl:copy-of select="node()"/>
	</xsl:template>
	
	
	<xsl:template match="equals[@case-sensitive = 'yes']" mode="write-matcher">
		<xsl:param name="context"/>
		<xsl:variable name="match" select="."/>
		<xsl:value-of select="concat($context, ' = ', $sq, $match, $sq)"/>
	</xsl:template>
	
	<xsl:template match="starts-with[@case-sensitive = 'yes']" mode="write-matcher">
		<xsl:param name="context"/>
		<xsl:variable name="match" select="."/>
		<xsl:value-of select="concat('starts-with(', $context, ', ', $sq, $match, $sq, ')')"/>
	</xsl:template>
	
	<xsl:template match="ends-with[@case-sensitive = 'yes']" mode="write-matcher">
		<xsl:param name="context"/>
		<xsl:variable name="match" select="."/>
		<xsl:value-of select="concat('ends-with(', $context, ', ', $sq, $match, $sq, ')')"/>
	</xsl:template>
	
	<xsl:template match="matches[@case-sensitive = 'yes']" mode="write-matcher">
		<xsl:param name="context"/>
		<xsl:variable name="match" select="."/>
		<xsl:value-of select="concat('matches(', $context ,', ', $sq, $match, $sq, ')')"/>
	</xsl:template>


	<xsl:template match="equals[not(@case-sensitive) or @case-sensitive = 'no']" mode="write-matcher">
		<xsl:param name="context"/>
		<xsl:variable name="match" select="lower-case(.)"/>
		<xsl:value-of select="concat('lower-case(', $context, ') = ', $sq, $match, $sq)"/>
	</xsl:template>
	
	<xsl:template match="starts-with[not(@case-sensitive) or @case-sensitive = 'no']" mode="write-matcher">
		<xsl:param name="context"/>
		<xsl:variable name="match" select="lower-case(.)"/>
		<xsl:value-of select="concat('starts-with(lower-case', $context, '), ', $sq, $match, $sq, ')')"/>
	</xsl:template>
	
	<xsl:template match="ends-with[not(@case-sensitive) or @case-sensitive = 'no']" mode="write-matcher">
		<xsl:param name="context"/>
		<xsl:variable name="match" select="lower-case(.)"/>
		<xsl:value-of select="concat('ends-with(lower-case(', $context, '), ', $sq, $match, $sq, ')')"/>
	</xsl:template>
	
	<xsl:template match="matches[not(@case-sensitive) or @case-sensitive = 'no']" mode="write-matcher">
		<xsl:param name="context"/>
		<xsl:variable name="match" select="lower-case(.)"/>
		<xsl:value-of select="concat('matches(lower-case(', $context ,'), ', $sq, $match, $sq, ')')"/>
	</xsl:template>

</xsl:stylesheet>
