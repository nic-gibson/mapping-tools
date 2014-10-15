<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:axsl="http://www.w3.org/1999/XSL/TransformAlias"
	xmlns:map="http://www.corbas.co.uk/ns/transforms/map"
	xmlns:cfunc="http://www.corbas.co.uk/ns/functions"
	xpath-default-namespace="http://www.corbas.co.uk/ns/transforms/map"
	xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
	xmlns:doc="http://www.corbas.co.uk/ns/documentation"
	xmlns="http://www.w3.org/1999/XSL/TransformAlias"
	exclude-result-prefixes="doc cfunc xsd map axsl" version="2.0">



	<xd:doc>

		<xd:desc>
			<xd:p>This program and accompanying files are copyright 2008, 2009, 20011, 2012, 2013
				Corbas Consulting Ltd.</xd:p>

			<xd:p>This program is free software: you can redistribute it and/or modify it under the
				terms of the GNU General Public License as published by the Free Software
				Foundation, either version 3 of the License, or (at your option) any later
				version.</xd:p>

			<xd:p>This program is distributed in the hope that it will be useful, but WITHOUT ANY
				WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
				PARTICULAR PURPOSE. See the GNU General Public License for more details.</xd:p>

			<xd:p>You should have received a copy of the GNU General Public License along with this
				program. If not, see http://www.gnu.org/licenses/.</xd:p>

			<xd:p>If your organisation or company are a customer or client of Corbas Consulting Ltd
				you may be able to use and/or distribute this software under a different license. If
				you are not aware of any such agreement and wish to agree other license terms you
				must contact Corbas Consulting Ltd by email at corbas@corbas.co.uk.</xd:p>

		</xd:desc>
	</xd:doc>

	<xd:doc>
		<xd:desc>
			<xd:p>This stylesheet is used to read a mapping file (as defined by
					<xd:b>mapping.rng</xd:b> and convert it to an XSLT stylesheet that can be used
				to read an incoming XML file, read given elements and write out new ones. </xd:p>
			<xd:p>The script is part of the Word to XML mapping toolkit and run as part of that
				pipeline. It is intended to run after the Word document has been converted to
				elements in the output XML language but not structured. In general, word paragraphs
				are mapped to output language paragraphs unless they are tables, images or lists.
				These paragraphs are then refined as appropriate by the output of this stylesheet.
				See the documentation for <xd:b>mapping.rng</xd:b> for details on the definitions
				used.</xd:p>


			<xd:p>The main output of this stylesheet is driven by three pairs of templates. Each
				produces a new template. Three of these generate templates to suppress their input,
				three generate templates to transform their input to the mapping defined output.
				There is a pair for each of the options provided by the mapping schema (full match,
				prefix match and suffix match).</xd:p>

		</xd:desc>
	</xd:doc>

	<xsl:output method="xml" indent="yes" encoding="UTF-8"/>

	<!-- We need to create content in the axsl namespace to avoid collisions
	 	and then output it in the XSLT namespace. The namespace-alias does
	 	this for us -->
	<xsl:namespace-alias stylesheet-prefix="axsl" result-prefix="xsl"/>

	<xd:doc>
		<xd:desc>
			<xd:p>The <xd:b>default-source-element</xd:b> variable defines the element to be searched for in
				the incoming XML file. This is defined by the <xd:b>source-element</xd:b> attribute
				of the <xd:b>map</xd:b> element. This can be overridden by the attribute with the
			same name on a <xd:b>mapping</xd:b> element if required.</xd:p>
		</xd:desc>
	</xd:doc>
	<xsl:variable name="default-source-element" select="/map/@source-element"/>


	<xd:doc>
		<xd:desc>
			<xd:p>The <xd:b>default-source-attribute</xd:b> variable defines the name of attribute on input
				elements that contains the search values. This is defined by the
					<xd:b>source-attribute</xd:b> attribute of the <xd:b>map</xd:b> element.</xd:p>
		</xd:desc>
	</xd:doc>
	<xsl:variable name="default-source-attribute" select="/map/@source-attribute"/>

	<xd:doc>
		<xd:desc>
			<xd:p>The <xd:b>target-attribute</xd:b> variable defines the name of an attribute on
				output elements to be generated (when the mapping contains a
					<xd:b>target-attribute-value</xd:b> attribute. This is defined by the
					<xd:b>target-attribute</xd:b> attribute of the <xd:b>map</xd:b> element but can
				be overriding by individual <xd:b>mapping</xd:b> elements.</xd:p>
		</xd:desc>
	</xd:doc>
	<xsl:variable name="global-target-attribute" select="/map/@target-attribute"/>

	<xd:doc>
		<xd:desc>
			<xd:p>This template matches the <xd:b>map</xd:b> elements of the input and creates the
				stylesheet element for output. We set the default XPath namespace to the matching
				namespace to make the constructed XPath statements simpler. We include an identity
				transform as any element not processed by our constructed stylesheet must be passed
				through unchanged. We do force the output to be UTF-8 regardless of input.</xd:p>
		</xd:desc>
	</xd:doc>

	<xsl:template match="map" as="element()">
		<axsl:stylesheet xpath-default-namespace="{@ns}" version="2.0">
			<xsl:namespace name="" select="@ns"/>
			<axsl:output method="xml" encoding="UTF-8"/>

			<axsl:template match="@*|node()" mode="#all">
				<axsl:copy>
					<axsl:apply-templates select="@*|node()" mode="#current"/>
				</axsl:copy>
			</axsl:template>

			<!-- process all the mapping elements. -->
			<xsl:apply-templates/>

		</axsl:stylesheet>
	</xsl:template>

	<xd:doc>
		<xd:desc>
			<xd:p>These templates convert a <xd:b>mapping</xd:b> element to an
					<xd:b>xsl:template</xd:b> element. Each one processes a variant on the input.
				The operation is the same on each. A function is called to generate the XPath
				statement for the template and then <xd:b>generate-elements</xd:b>is called.
					<xd:b>generate-elements</xd:b> is passed a sequence of elements to create and a
				flag indicating that the process is starting.</xd:p>
			<xd:p>The suppress attribute is handled by a simple template for each type of input
				attribute.</xd:p>
		</xd:desc>
	</xd:doc>

	<xd:doc>
		<xd:desc><xd:p>When the <xd:b>suppress</xd:b> attribute is set, just suppress the content. Use a
			very high priority to ensure it executes. </xd:p></xd:desc>
	</xd:doc>
	<xsl:template match="mapping[@suppress='true']" priority="20" as="element()">
		<axsl:template>
			<xsl:apply-templates select="@source-value|@source-value-prefix|@source-value-suffix"/>
		</axsl:template>
	</xsl:template>

	<xd:doc>
		<xd:desc><xd:p>Abort if we have an input element with no source-value* attribute.</xd:p></xd:desc>
	</xd:doc>
	<xsl:template match="mapping[not(@source-value or @source-value-prefix or @source-value-suffix)]" priority="21">
		<xsl:message terminate="yes">Unable to continue - mapping with no source value
			found.</xsl:message>
	</xsl:template>

	<xd:doc>
		<xd:desc><xd:p>Abort if we have a mapping with target-attribute-value attribute but no defined
			target-attribute locally or globally.</xd:p></xd:desc>
	</xd:doc>
	<xsl:template
		match="mapping[@target-attribute-value][not(@target-attribute or $global-target-attribute)]"
		priority="21">
		<xsl:message terminate="yes">Unable to continue - with target attribute value but no target
			attribute.</xsl:message>
	</xsl:template>



	<xd:doc>
		<xd:desc><xd:p>Generate an xsl template from the mapping source.</xd:p></xd:desc>
	</xd:doc>
	<xsl:template match="mapping" as="element()">

		<axsl:template>
			<xsl:apply-templates select="@source-value|@source-value-prefix|@source-value-suffix"/>
			<xsl:apply-templates select="." mode="generate-elements"/>
		</axsl:template>

	</xsl:template>

	<xd:doc>
		<xd:desc><xd:p>Generate an xsl template from the mapping source. There is no target-element
		attribute so we copy the source element</xd:p></xd:desc>
	</xd:doc>
	<xsl:template match="mapping[not(@target-element)]" priority="1" as="element()">

		<axsl:template>
			<xsl:apply-templates select="@source-value|@source-value-prefix|@source-value-suffix"/>
			<axsl:copy>
				<xsl:apply-templates select="." mode="generate-elements"/>
			</axsl:copy>
		</axsl:template>

	</xsl:template>


	<xd:doc>
		<xd:desc><xd:p>Create a match attribute for the output template based on the value of a source
			attribute</xd:p></xd:desc>
	</xd:doc>
	<xsl:template match="@source-value">
	    <xsl:variable name="source-element" select="(../@source-element, $default-source-element)[1]"/>
	    <xsl:variable name="source-attribute" select="(../@source-attribute, $default-source-attribute)[1]"/>
		<xsl:attribute name="match"
			select="concat($source-element, '[@', $source-attribute, ' = ''', ., ''']')"/>
	</xsl:template>


	<xd:doc>
		<xd:desc><xd:p>Create a match attribute for the output template based on the start of a source
			attribute</xd:p></xd:desc>
	</xd:doc>

	<xsl:template match="@source-value-prefix">
	    <xsl:variable name="source-element" select="(../@source-element, $default-source-element)[1]"/>
	    <xsl:variable name="source-attribute" select="(../@source-attribute, $default-source-attribute)[1]"/>
		<xsl:attribute name="match"
			select="concat($source-element, '[starts-with(@', $source-attribute, ',''', ., ''')]')"
		/>
	</xsl:template>


	<xd:doc>
		<xd:desc><xd:p>Create a match attribute for the output template based on the end of a source
			attribute</xd:p></xd:desc>
	</xd:doc>
	<xsl:template match="@source-value-suffix">
	    <xsl:variable name="source-element" select="(../@source-element, $default-source-element)[1]"/>
	    <xsl:variable name="source-attribute" select="(../@source-attribute, $default-source-attribute)[1]"/>
		<xsl:attribute name="match"
			select="concat($source-element, '[ends-with(@', $source-attribute, ',''', ., ''')]')"/>
	</xsl:template>

	<xd:doc>
		<xd:desc><xd:p>Generate the attributes on an output element. If there is no target-attribute-value
			attribute it's a simply copy.</xd:p></xd:desc>
	</xd:doc>
	<xsl:template match="mapping" mode="copy-attributes">
		<axsl:apply-templates select="@*[not(local-name() = 'id')]"/>
	</xsl:template>

	<xd:doc>
		<xd:desc>Generate the attributes on an output element. Create the target attribute as
			well.</xd:desc>
	</xd:doc>
	<xsl:template match="mapping[@target-attribute-value]" mode="copy-attributes">
		<xsl:apply-templates select="@target-attribute-value"/>
		<axsl:apply-templates select="@*[not(local-name() = 'id')]"/>
	</xsl:template>

	<xd:doc>
		<xd:desc>Generate the attributes on an output element. If the target attribute is the same
			as the source attribute (we are overriding the input value in other words), we need to
			not copy it to the output. <xd:b>If there is more than one attribute with the same local
				name as the target attribute, they will all be suppressed.</xd:b></xd:desc>
	</xd:doc>
	<xsl:template
		match="mapping[@target-attribute-value]
		[(@target-attribute, $global-target-attribute)[1] = (@source-attribute, $default-source-attribute)[1]]"
		mode="copy-attributes" priority="1">
		<xsl:variable name="target-attribute"
			select="(@target-attribute, $global-target-attribute)[1]"/>
		<xsl:apply-templates select="@target-attribute-value"/>
		<axsl:apply-templates
			select="@*[not(local-name() = 'id')][not(local-name(.) = '{$target-attribute}')]"/>
	</xsl:template>

	<xsl:template match="@target-attribute-value">
		<xsl:variable name="target-attribute"
			select="(../@target-attribute, $global-target-attribute)[1]"/>
		<axsl:attribute name="{$target-attribute}" select="{.}"/>
	</xsl:template>

	<xd:doc>
		<xd:desc>
			<xd:p>This template is the core of the stylesheet. It is applied recursively to build
				the generated templates. Each application of this generates an element in the output
				and then recurses to create the next.</xd:p>


			<xd:p>When first applied, the default parameters are used. The <xd:b>top-level</xd:b>
				and <xd:b>element-list</xd:b> parameters are initialised.</xd:p>

			<xd:p> The first output element name is taken from the resulting sequence and generated.
				When first called the <xd:b>top-level</xd:b> attribute is set to a true value. This
				prompts the template to process the <xd:b>hint</xd:b>, <xd:b>heading-level</xd:b>
				and <xd:b>target-attribute-value</xd:b> attributes of the mapping. It additionally
				generates an <xd:b>xsl:apply-templates</xd:b> element to copy any id attributes
				over.</xd:p>

			<xd:p>Regardless of whether <xd:b>top-level</xd:b> is true, it then generates an
					<xd:b>xsl:apply-templates</xd:b> to copy all attributes except id attributes.
				This leads to most attributes being copied to all generated elements.</xd:p>

			<xd:p>The template then calls itself passing the unprocessed element names to the next
				recursion.</xd:p>

		</xd:desc>
	</xd:doc>
	<xsl:template match="mapping" mode="generate-elements">

		<xsl:param name="element-list" as="xsd:string*" select="tokenize(@target-element, '\s+')"/>
		<xsl:param name="top-level" as="xsd:boolean" select="true()"/>

		<xsl:choose>
			
			<!-- If there are no input elements in the sequence, create an apply-templates only - stop
				the recursion -->
			<xsl:when test="count($element-list) = 0">
				<axsl:apply-templates select="node()"/>
			</xsl:when>

			<xsl:otherwise>

				<!-- Generate a literal element -->
				<xsl:element name="{$element-list[1]}" namespace="{/map/@ns}">

					<!-- If top level, process mapping attributes and generate an apply-templates
						for the input ID attributes (if any) -->
					<xsl:if test="$top-level = true()">
						<xsl:apply-templates select="@hint|@heading-level"/>
						<axsl:apply-templates select="@*[local-name() = 'id']"/>
					</xsl:if>

					<xsl:apply-templates select="." mode="copy-attributes"/>

					<!-- Recursing passing the tail of the sequence and setting top-level to false -->
					<xsl:apply-templates select="." mode="generate-elements">
						<xsl:with-param name="element-list" select="subsequence($element-list, 2)"/>
						<xsl:with-param name="top-level" select="false()"/>
					</xsl:apply-templates>

				</xsl:element>

			</xsl:otherwise>

		</xsl:choose>

	</xsl:template>
	
	<xsl:template match="mapping[not(@target-element)]" mode="generate-elements">
		<xsl:apply-templates select="." mode="copy-attributes"/>
		<axsl:apply-templates select="node()"/>		
	</xsl:template>
	


	<xd:doc>
		<xd:desc>This template copies the <xd:b
			>hint</xd:b> attribute to a <xd:b>cword:hint</xd:b> attribute on
			the output.</xd:desc>
	</xd:doc>
	<xsl:template match="@hint">
		<xsl:attribute name="hint" namespace="http://www.corbas.co.uk/ns/transforms/map" select="."/>
	</xsl:template>

	<xd:doc>
		<xd:desc>
			This template copies the <xd:b>heading-level</xd:b> attribute to a
					<xd:b>cword:level</xd:b> attribute on the output.
		</xd:desc>
	</xd:doc>
	<xsl:template match="@heading-level">
		<xsl:attribute name="level" namespace="http://www.corbas.co.uk/ns/transforms/map" select="."/>
	</xsl:template>


</xsl:stylesheet>
