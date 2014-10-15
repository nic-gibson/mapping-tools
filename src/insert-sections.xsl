<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:map="http://www.corbas.co.uk/ns/transforms/map"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" 
    exclude-result-prefixes="xs xd map"
    version="2.0">

    <xd:doc scope="stylesheet">
        
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
    

    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p >This stylesheet builds structure from
                unstructured mapped through the mapping mechanism. It inserts structural elements as
                appropriate driven by the map:level attributes on the input</xd:p>
            <xd:p >It operates by processing elements that contain
                two additional attributes. The input document is part way through the conversion
                pipeline and the generated mapping stylesheet (see <span class="filename"
                    >build-mapping-stylesheet.xsl</span> and <span class="filename"
                    >mapping.rng</span>) <code class="attribute">map:level</code> attributes into
                the content.</xd:p>

            <xd:p >The stylesheet operates by finding the max title
                level (which corresponds to the lowest level title). The main template
                (process-titles) is then called recursively to convert the sequences of elements
                beginning with titles into sections.</xd:p>
            
            <xd:p>Section elements are defined by the <xd:ref name="section-element" type="parameter">section-element</xd:ref> parameter and namespaces
                by the <xd:ref name="section-namespace" type="parameter">section-namespace</xd:ref> parameter. These default to the HTML 5 'section' element.</xd:p>

            <xd:p><xd:b>Warning</xd:b></xd:p>
            <xd:p >If header levels increase by more than one at a
                time this stylesheet may produce incorrect output. This can be corrected by
                post-processing if required.</xd:p>

        </xd:desc>
    </xd:doc>


    <xsl:preserve-space elements="*"/>

    <xd:doc>
        <xd:desc><xd:p>The namespace in which section element should be created.</xd:p></xd:desc>
    </xd:doc>
    <xsl:param name="section-namespace" select="'http://www.w3.org/1999/xhtml'"/>
    
    <xd:doc><xd:desc><xd:p>The name of the sectioning element.</xd:p></xd:desc></xd:doc>
    <xsl:param name="section-element" select="'section'"/>

    <xd:doc>
        <xd:desc >
            <xd:p>This variable identifies the highest level heading defined in the input. This is
                used by process-titles to recursively create sections starting at the lowest level
                and working upwards.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:variable name="max-title-level" select="max(//*[@map:level]/@map:level)"/>


    <xd:doc>
        <xd:desc>
            <xd:p>We pass all nodes throught without changing them unless matched below</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="node()|@*" mode="#all">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*" mode="#current"/>
        </xsl:copy>
    </xsl:template>

    <xd:doc>
        <xd:desc>
            <xd:p >Matches the root element. Copies it to output
                and then calls process-titles to start the recursive processing.</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="/*">

        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:call-template name="process-titles"/>
        </xsl:copy>

    </xsl:template>

    <xd:doc>
        <xd:desc>
            <xd:p >This template is called recursively to
                generate nested sections (part, chapter or section). It uses grouping against local
                element names to group elements starting with titles at the current level
                (defaulting to the highest number/lowest level heading). Groups which match are
                wrapped in the appropriate section type, others are copied to the output (we can use
                copy-of here because we work from the bottom up and know that higher level titles
                will be processed later).</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template name="process-titles" as="node()*">

        <!-- Default the current processing level to the maximum value in the document. -->
        <xsl:param name="level" select="$max-title-level" as="xs:integer"/>

        <!-- If no content parameter is provided use the node() children of the current
			element -->
        <xsl:param name="content" select="node()" as="node()*"/>
        
        <!-- Store the result of our processing as sequence of nodes in a variable - we'll
			be using it again -->
        <xsl:variable name="result" as="node()*">

            <!-- group over the current content sequence, creating groups that start with
				titles at the current level. Don't group on things which are already sectioned. -->
            <xsl:for-each-group select="$content"
                group-starting-with="node()[not(local-name() = $section-element) and not(namespace-uri() = $section-namespace)][@map:level]">

                <xsl:choose>

                    <!-- if we have a current level title based group, wrap it -->
                    <xsl:when test="self::*[not(local-name() = $section-element) and not(namespace-uri() = $section-namespace)][@map:level] 
                        and @map:level = $level">

                        <xsl:element name="{$section-element}" namespace="{$section-namespace}">
                            <!-- copy all of the attributes of the current node - remember . is set
								to the first member of the current group bar the id -->
                            <xsl:apply-templates
                                select="@* except @*[lower-case(local-name()) = 'id']"/>

                            <!-- insert the whole group into our section -->
                            <xsl:copy-of select="current-group()"/>
                        </xsl:element>

                    </xsl:when>

                    <xsl:otherwise>

                        <!-- copy to output without processing -->
                        <xsl:copy-of select="current-group()"/>

                    </xsl:otherwise>

                </xsl:choose>

            </xsl:for-each-group>

        </xsl:variable>
        <!-- Once we have created sections around our title based groups, then we need to
			recurse if the current level is greater than one. If not, we return the 
			content. The content for the next level of the processing is the result
			from this one.-->
        <xsl:choose>

            <xsl:when test="$level gt 1">
                <xsl:call-template name="process-titles">
                    <xsl:with-param name="level" select="$level - 1"/>
                    <xsl:with-param name="content" select="$result"/>
                </xsl:call-template>
            </xsl:when>

            <xsl:otherwise>

                <xsl:sequence select="$result"/>

            </xsl:otherwise>

        </xsl:choose>

    </xsl:template>




</xsl:stylesheet>
