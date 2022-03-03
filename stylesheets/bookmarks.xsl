<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:fox="http://xmlgraphics.apache.org/fop/extensions"
    xmlns:ead3="http://ead3.archivists.org/schema/" exclude-result-prefixes="xs ead3 fox"
    version="2.0">

    <!-- this file is imported by "ead3-to-pdf-ua.xsl" -->

    <!--parameterize the names so that "Collection" is not hard coded ? -->

    <xsl:template match="ead3:archdesc" mode="bookmarks">
        <fo:bookmark-tree>
            <fo:bookmark internal-destination="cover-page">
                <fo:bookmark-title>Finding Aid Title Page</fo:bookmark-title>
            </fo:bookmark>
            <fo:bookmark internal-destination="toc">
                <fo:bookmark-title>Table of Contents</fo:bookmark-title>
            </fo:bookmark>
            <fo:bookmark internal-destination="contents">
                <fo:bookmark-title><xsl:value-of select="$archdesc-did-title"/></fo:bookmark-title>
            </fo:bookmark>
            <xsl:if test="$include-paging-info">
                <fo:bookmark internal-destination="paging-info">
                    <fo:bookmark-title><xsl:value-of select="$paging-info-title"/></fo:bookmark-title>
                </fo:bookmark>
            </xsl:if>
            <xsl:if test="ead3:acqinfo, ead3:custodhist, ead3:accessrestrict, ead3:userestrict, ead3:prefercite
                , ead3:processinfo, ead3:altformavail, ead3:relatedmaterial, ead3:separatedmaterial, ead3:accruals, ead3:appraisals
                , ead3:originalsloc, ead3:otherfindaid, ead3:phystech, ead3:fileplan">
                <fo:bookmark internal-destination="admin-info">
                    <xsl:attribute name="starting-state">hide</xsl:attribute>
                    <fo:bookmark-title>Adminstrative Information</fo:bookmark-title>
                    <!-- do we even want these here?  we can still display them in the ToC -->
                    <xsl:apply-templates select="ead3:acqinfo, ead3:custodhist, ead3:accessrestrict, ead3:userestrict, ead3:prefercite
                        , ead3:processinfo, ead3:altformavail, ead3:relatedmaterial, ead3:separatedmaterial, ead3:accruals, ead3:appraisals
                        , ead3:originalsloc, ead3:otherfindaid, ead3:phystech, ead3:fileplan" mode="bookmarks"/>
                </fo:bookmark>
            </xsl:if>
            <xsl:apply-templates select="ead3:bioghist, ead3:scopecontent
                , ead3:odd[not(matches(lower-case(normalize-space(ead3:head)), $odd-headings-to-add-at-end))]
                , ead3:bibliography, ead3:arrangement" mode="bookmarks"/>
            <xsl:apply-templates select="ead3:dsc[*[local-name()=('c', 'c01')]]" mode="bookmarks"/>
            
            <xsl:apply-templates select="ead3:odd[matches(lower-case(normalize-space(ead3:head)), $odd-headings-to-add-at-end)]
                , ead3:index
                , ead3:controlaccess" mode="bookmarks"/>
        </fo:bookmark-tree>
    </xsl:template>
    
    <xsl:template match="ead3:dsc" mode="bookmarks">
        <fo:bookmark internal-destination="dsc-contents">
            <fo:bookmark-title><xsl:value-of select="$dsc-title"/></fo:bookmark-title>
            <xsl:apply-templates select="ead3:*[@level=$levels-to-include-in-toc or @otherlevel=$otherlevels-to-include-in-toc]" mode="bookmarks"/>
        </fo:bookmark>
    </xsl:template>
    
    <xsl:template match="ead3:*" mode="bookmarks">
        <xsl:if test="not(ead3:head)">
            <xsl:message terminate="yes">
                <xsl:text>No head element. Need to update the post-process to include a header, otherwise the links won't work.</xsl:text>
            </xsl:message>
        </xsl:if>
        <fo:bookmark internal-destination="{if (@id) then @id else generate-id(.)}">
            <fo:bookmark-title><xsl:value-of select="ead3:head"/></fo:bookmark-title>
        </fo:bookmark>
    </xsl:template>
    
    <xsl:template match="ead3:*[matches(local-name(), '^c0|^c1') or local-name()='c']
        [@level=$levels-to-include-in-toc or @otherlevel=$otherlevels-to-include-in-toc]"
        mode="bookmarks" priority="2">
        <fo:bookmark internal-destination="{if (@id) then @id else generate-id(.)}">
            <xsl:attribute name="starting-state">hide</xsl:attribute>
            <!-- update here to use a Combine that Title and Date function, or something else that will use Dates when a unittitle is missing. -->
            <!-- do we want Series I stuff here, too? -->
            <!-- keeping as is for now, though we should add a test to ensure we always have a unittitle.
                i tried adding the dates, and it looks way too cluttered in the bookmarks section, i think -->
            <fo:bookmark-title>
                <xsl:value-of select="ead3:did/ead3:unitid/normalize-space()"/>
                <xsl:if test="ead3:did/ead3:unitid[not(ends-with(normalize-space(), $unitid-trailing-punctuation))]">
                    <xsl:value-of select="$unitid-separator"/>
                </xsl:if>
                <xsl:value-of select="ead3:did/ead3:unittitle/normalize-space()"/>
            </fo:bookmark-title>
            <xsl:apply-templates select="ead3:*[@level=$levels-to-include-in-toc or @otherlevel=$otherlevels-to-include-in-toc]" mode="#current"/>
        </fo:bookmark>
    </xsl:template>
    
    <xsl:template match="ead3:controlaccess" mode="bookmarks">
        <fo:bookmark internal-destination="control-access">
            <fo:bookmark-title><xsl:value-of select="$control-access-title"/></fo:bookmark-title>
        </fo:bookmark>
    </xsl:template>
    
</xsl:stylesheet>
