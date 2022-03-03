<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:fox="http://xmlgraphics.apache.org/fop/extensions"
    xmlns:mdc="http://mdc"
    xmlns:ead3="http://ead3.archivists.org/schema/" exclude-result-prefixes="xs ead3 fox mdc"
    version="2.0">

    <!-- this file is imported by "ead3-to-pdf-ua.xsl" -->
    
    <!-- to do:
        change so that the only thing in tables are files/items with containers ?
        
        everything else can be handled in blocks.
        
        other ideas:
            autogenerate a series/subseries overview, with container ranges and first pargraph of scope note?
            
            take the regular DSC out of a table, and put the container information inline.
            and add a container-inventory section at the end that's a real table, with box, folder, etc., plus title,
            date, etc., sorted by container numbers.
              
     -->
    
    <xsl:param name="dsc-first-c-levels-to-process-before-a-table" select="('series', 'collection', 'fonds', 'recordgrp')"/>
    <xsl:param name="levels-to-force-a-page-break" select="('series', 'collection', 'fonds', 'recordgrp')"/>
    <xsl:param name="otherlevels-to-force-a-page-break-and-process-before-a-table" select="('accession', 'acquisition')"/>
    
    
    <!-- not worrying about multiple DSC sections.  ASpace can only export 1 DSC -->
    <xsl:template match="ead3:dsc">
        <fo:page-sequence master-reference="contents">
            <!-- Page header -->
            <fo:static-content flow-name="xsl-region-before">
                <fo:block/>
            </fo:static-content>
            <!-- Page footer-->
            <fo:static-content flow-name="xsl-region-after" role="artifact">
                <fo:block xsl:use-attribute-sets="page-number" text-align="center">
                    <xsl:text>Page </xsl:text>
                    <fo:page-number/>
                    <xsl:text> of </xsl:text>
                    <fo:page-number-citation ref-id="last-page"/>
                </fo:block>
            </fo:static-content>
            <!-- Content of page -->
            <fo:flow flow-name="xsl-region-body">
                <xsl:call-template name="section-start"/>
                <fo:block xsl:use-attribute-sets="h3" id="dsc-contents"><xsl:value-of select="$dsc-title"/></fo:block>
                <xsl:choose>
                    <xsl:when test="ead3:*[matches(local-name(), '^c0|^c1')][@level=$dsc-first-c-levels-to-process-before-a-table or @otherlevel=$otherlevels-to-force-a-page-break-and-process-before-a-table]
                        | ead3:c[@level=$dsc-first-c-levels-to-process-before-a-table or @otherlevel=$otherlevels-to-force-a-page-break-and-process-before-a-table]">
                        <xsl:apply-templates select="ead3:*[matches(local-name(), '^c0|^c1')] | ead3:c" mode="dsc-block"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="tableBody"/>
                    </xsl:otherwise>
                </xsl:choose>

                <!-- adding this to grab the last page number
                i don't think this is the preferred method of doing that, so review when needed.  if i use this method, then we'll need to move this to the real last page!
                which could be an index, a control access section, or the container list. -->
                <fo:wrapper id="last-page"/>
            </fo:flow>
        </fo:page-sequence>
    </xsl:template>
    
    <xsl:template match="ead3:*[matches(local-name(), '^c0|^c1')] | ead3:c" mode="dsc-block">
        <xsl:variable name="depth" select="count(ancestor::*) - 3"/> <!-- e.g. c01 = 0, c02 = 1, etc. -->
        <xsl:variable name="cell-margin" select="concat(xs:string($depth * 8), 'pt')"/> <!-- e.g. 0, 8pt for c02, 16pt for c03, etc.-->
        <!-- do a second grouping based on the container grouping's primary localtype (i.e. box, volume, reel, etc.)
            then add a custom sort, or just sort those alphabetically -->
        <xsl:variable name="container-groupings">
            <xsl:for-each-group select="ead3:did/ead3:container" group-by="if (@parent) then @parent else @id">
                <xsl:sort select="mdc:container-to-number(.)"/>
                <container-group>
                    <xsl:apply-templates select="current-group()" mode="copy"/>
                </container-group>
            </xsl:for-each-group>
        </xsl:variable>
        <xsl:variable name="containers-sorted-by-localtype">
            <xsl:for-each-group select="$container-groupings/container-group" group-by="ead3:container[1]/@localtype">
                <xsl:sort select="current-grouping-key()" data-type="text"/>
                <!-- i don't use this element for anything right now, but it could be used, if 
                    additional grouping in the presentation was desired -->
                <xsl:element name="{current-grouping-key()}">
                    <xsl:apply-templates select="current-group()" mode="copy"/>
                </xsl:element>
            </xsl:for-each-group>
        </xsl:variable>
        <fo:block margin-left="{$cell-margin}" keep-with-next.within-page="always">
            <xsl:if test="preceding-sibling::ead3:*[@level=$levels-to-force-a-page-break or @otherlevel=$otherlevels-to-force-a-page-break-and-process-before-a-table]">
                <xsl:attribute name="break-before" select="'page'"/>
            </xsl:if>
            
            <!-- change to a combine title and date function later on, or keep in 3 columns? -->
            <xsl:apply-templates select="if (ead3:did/ead3:unittitle) then ead3:did/ead3:unittitle else ead3:did/ead3:unitdatestructured" mode="dsc"/>
            <xsl:apply-templates select="ead3:did/ead3:unitid" mode="dsc"/>

            <!-- still need ot add the other did elements, and select an order -->
            <xsl:apply-templates select="ead3:did" mode="dsc"/>
            <xsl:apply-templates select="ead3:bioghist, ead3:scopecontent
                , ead3:acqinfo, ead3:custodhist, ead3:accessrestrict, ead3:userestrict, ead3:prefercite
                , ead3:processinfo, ead3:altformavail, ead3:relatedmaterial, ead3:separatedmaterial, ead3:accruals, ead3:appraisals
                , ead3:originalsloc, ead3:otherfindingaid, ead3:phystech, ead3:fileplan, ead3:odd, ead3:bibliography, ead3:arrangement" mode="dsc"/>
            <!-- should write something else to sort, etc., as needed -->
            <xsl:call-template name="container-layout">
                <xsl:with-param name="containers-sorted-by-localtype" select="$containers-sorted-by-localtype"/>
            </xsl:call-template>
        </fo:block>
        <xsl:choose>
            <xsl:when test="not(ead3:*[matches(local-name(), '^c0|^c1')] | ead3:c)"/>
            <xsl:otherwise>
               <xsl:call-template name="tableBody">
                   <xsl:with-param name="cell-margin" select="$cell-margin"/>
               </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    
    <xsl:template match="ead3:*[matches(local-name(), '^c0|^c1')] | ead3:c" mode="dsc-table">            
        <xsl:param name="first-row" select="if (position() eq 1 and (
                parent::ead3:dsc 
                or parent::*[@level=$dsc-first-c-levels-to-process-before-a-table]
                or parent::*[@otherlevel=$otherlevels-to-force-a-page-break-and-process-before-a-table])
            )
            then true() else false()"/>     
        
        <xsl:variable name="depth" select="count(ancestor::*) - 3"/> <!-- e.g. c01 = 0, c02 = 1, etc. -->
        <xsl:variable name="cell-margin" select="concat(xs:string($depth * 8), 'pt')"/> <!-- e.g. 0, 8pt for c02, 16pt for c03, etc.-->
        <xsl:variable name="container-groupings">
            <xsl:for-each-group select="ead3:did/ead3:container" group-by="if (@parent) then @parent else @id">
                <xsl:sort select="mdc:container-to-number(.)"/>
                <container-group>
                    <xsl:apply-templates select="current-group()" mode="copy"/>
                </container-group>
            </xsl:for-each-group>
        </xsl:variable>
        <xsl:variable name="containers-sorted-by-localtype">
            <xsl:for-each-group select="$container-groupings/container-group" group-by="ead3:container[1]/@localtype">
                <xsl:sort select="current-grouping-key()" data-type="text"/>
                <xsl:element name="{current-grouping-key()}">
                    <xsl:apply-templates select="current-group()" mode="copy"/>
                </xsl:element>
            </xsl:for-each-group>
        </xsl:variable>
        <fo:table-row>
            <fo:table-cell>
                <fo:block>
                    <xsl:choose>
                        <xsl:when test="$first-row eq true()">
                            <fo:marker marker-class-name="continued-text"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <fo:marker marker-class-name="continued-text">
                                <fo:inline>
                                    <xsl:call-template name="ancestor-info"/>
                                </fo:inline>
                            </fo:marker>
                        </xsl:otherwise>
                    </xsl:choose> 
                </fo:block>
                <!-- do the title and/or date stuff here -->
                <fo:block margin-left="{$cell-margin}">
                    <!-- change to a combine title and date function later on, or keep in 3 columns? -->
                    <xsl:apply-templates select="if (ead3:did/ead3:unittitle/normalize-space()) then ead3:did/ead3:unittitle else ead3:did/ead3:unitdatestructured" mode="dsc"/>
                    <xsl:apply-templates select="ead3:did/ead3:unitid" mode="dsc"/>

                    <!-- still need ot add the other did elements, and select an order -->
                    <xsl:apply-templates select="ead3:did" mode="dsc"/>
                    <fo:block margin-left="4pt">          
                        <xsl:apply-templates select="ead3:bioghist, ead3:scopecontent
                            , ead3:acqinfo, ead3:custodhist, ead3:accessrestrict, ead3:userestrict, ead3:prefercite
                            , ead3:processinfo, ead3:altformavail, ead3:relatedmaterial, ead3:separatedmaterial, ead3:accruals, ead3:appraisals
                            , ead3:originalsloc, ead3:otherfindingaid, ead3:phystech, ead3:fileplan, ead3:odd, ead3:bibliography, ead3:arrangement" mode="dsc"/>
                    </fo:block>
                </fo:block>
            </fo:table-cell>
            <fo:table-cell>
                <xsl:call-template name="container-layout">
                    <xsl:with-param name="containers-sorted-by-localtype" select="$containers-sorted-by-localtype"/>
                </xsl:call-template>
            </fo:table-cell>
        </fo:table-row>
        <xsl:apply-templates select="ead3:*[matches(local-name(), '^c0|^c1')] | ead3:c" mode="dsc-table"/>
    </xsl:template>
    
    <xsl:template name="tableBody">
        <xsl:param name="cell-margin"/>
        <fo:table inline-progression-dimension="100%" table-layout="fixed" font-size="10pt"
            border-collapse="separate" border-spacing="5pt 8pt" keep-with-previous.within-page="always">
            <fo:table-column column-number="1" column-width="proportional-column-width(75)"/>
            <fo:table-column column-number="2" column-width="proportional-column-width(25)"/>
            <xsl:call-template name="tableHeaders">
                <xsl:with-param name="cell-margin" select="$cell-margin"/>
            </xsl:call-template>
            <fo:table-body>
                <xsl:apply-templates select="ead3:*[matches(local-name(), '^c0|^c1')] | ead3:c" mode="dsc-table"/>
            </fo:table-body>
        </fo:table>
    </xsl:template>
    
    <xsl:template name="tableHeaders">
        <xsl:param name="cell-margin"/>
        <fo:table-header>
            <fo:table-row>
                <fo:table-cell number-columns-spanned="2">
                    <fo:block>
                        <fo:retrieve-table-marker retrieve-class-name="continued-text" 
                            retrieve-position-within-table="first-starting" 
                            retrieve-boundary-within-table="table-fragment"/> 
                            &#x00A0;
                    </fo:block>
                </fo:table-cell>
            </fo:table-row>
            <fo:table-row>
                <fo:table-cell padding-left="{if ($cell-margin) then $cell-margin else '0pt'}">
                    <!-- since FOP doesn't support "visibility", and since we might not want the table headers to display
                    on the PDFs, perhaps we can add a fox attribute here to keep up with the accessibility requirements for tables-->
                    <!--
                <fo:block>
                   necessary due to: https://stackoverflow.com/questions/30974903/xslfo-retrieve-marker-not-valid-child ???
                    &#x00A0;
                </fo:block>
                -->
                    <fo:block text-decoration="underline">Description</fo:block>
                </fo:table-cell>
                <fo:table-cell>
                    <fo:block text-decoration="underline">Physical Storage Information</fo:block>
                </fo:table-cell>    
            </fo:table-row>
        </fo:table-header>
    </xsl:template>
    
    <!-- process dates here, if we don't go the route of combining titles and dates. this would actually be much simpler, becauuse then we could skip processing dates if
    the unittitle was empty (since we use that in its place)-->
    <xsl:template match="ead3:did" mode="dsc">
        <xsl:apply-templates select="ead3:abstract, ead3:physdesc, 
            ead3:physdestructured, ead3:physdescset, ead3:physloc, 
            ead3:langmaterial, ead3:materialspec, ead3:origination, ead3:repository" mode="#current"/>
    </xsl:template>
    
    <xsl:template name="container-layout">
        <xsl:param name="containers-sorted-by-localtype"/>
        <xsl:choose>
            <!-- the middle step, i.e. *, in these cases is the localtype (e.g. box, volume, etc.) -->
            <xsl:when test="count($containers-sorted-by-localtype/*/container-group) gt 1">
                <fo:list-block provisional-distance-between-starts="0.3cm" provisional-label-separation="0.15cm">
                    <xsl:for-each select="$containers-sorted-by-localtype/*/container-group">
                        <fo:list-item>
                            <fo:list-item-label end-indent="label-end()">
                                <fo:block>
                                    <fo:inline>•</fo:inline>
                                </fo:block>
                            </fo:list-item-label>
                            <fo:list-item-body start-indent="body-start()">
                                <fo:block>
                                    <xsl:apply-templates/>
                                </fo:block> 
                            </fo:list-item-body>
                        </fo:list-item>
                    </xsl:for-each>
                </fo:list-block>
            </xsl:when>
            <xsl:otherwise>
                <fo:block>
                    <xsl:apply-templates select="$containers-sorted-by-localtype/*/container-group"/>
                </fo:block> 
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="ead3:container">
        <xsl:value-of select="concat(lower-case(@localtype), ' ', .)"/>
        <xsl:if test="position() ne last()">
            <xsl:text>, </xsl:text>
        </xsl:if>
    </xsl:template>
    
    <!-- not sure how to handle this yet, but ideally i'd like to include extra blocks of text
        to indicate when the table is continued -->
    <xsl:template name="ancestor-info">
        <xsl:variable name="immediate-ancestor" select="ancestor::ead3:*[ead3:did/ead3:unittitle][ancestor::ead3:dsc][1]"/>
        <xsl:variable name="folder-title-plus-unitid">
            <xsl:choose>
                <!-- if there's just a unitid, use that in place of the title and don't inherit anything.
                            the "inherited" title will still appear as an ancestor title on the label due to the sequence-of-series -->
                <xsl:when test="not(ead3:did/ead3:unittitle[normalize-space()]) and ead3:did/ead3:unitid[normalize-space()][not(@audience='internal')]">
                    <xsl:value-of select="ead3:did/ead3:unitid[not(@audience='internal')][1]"/>
                </xsl:when>
                <!-- if there's no unitid or title, then grab an ancestor title and unitid, since 
                            the component might only have a unitdate.  later, we'll filter this out of the sequence-of-series list of titles. -->
                <xsl:when test="not(ead3:did/ead3:unittitle[normalize-space()])">
                    <xsl:if test="$immediate-ancestor[ead3:did/ead3:unitid]">
                        <xsl:value-of select="concat($immediate-ancestor/ead3:did/ead3:unitid[not(@audience='internal')][1], ' ')"/>
                    </xsl:if>
                    <xsl:value-of select="$immediate-ancestor/ead3:did/ead3:unittitle[1]"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:if test="normalize-space(ead3:did/ead3:unitid[not(@audience='internal')][1])">
                        <xsl:value-of select="normalize-space(ead3:did/ead3:unitid[not(@audience='internal')][1])"/>
                        <xsl:text> </xsl:text>
                    </xsl:if>
                    <xsl:value-of select="normalize-space(ead3:did/ead3:unittitle[1])"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="ancestor-sequence">
            <xsl:sequence select="string-join(
                for $ancestor in ancestor::*[ead3:did][ancestor::ead3:dsc] return 
                if ($ancestor/ead3:did/ead3:unitid/not(ends-with(normalize-space(), '.'))
                and $ancestor/lower-case(@level) eq 'series') 
                then concat($ancestor/ead3:did/ead3:unitid, '. ', $ancestor/ead3:did/ead3:unittitle)
                else if (ends-with($ancestor/ead3:did/ead3:unitid/normalize-space(), '.'))
                then concat($ancestor/ead3:did/ead3:unitid/normalize-space(), ' ', $ancestor/ead3:did/ead3:unittitle)
                else if ($ancestor/ead3:did/ead3:unitid/normalize-space()) then concat($ancestor/ead3:did/ead3:unitid, ' ', $ancestor/ead3:did/ead3:unittitle)
                else $ancestor/ead3:did/ead3:unittitle
                , 'xx*****yz')"/>
        </xsl:variable>
        <xsl:variable name="ancestor-sequence-filtered">
            <xsl:sequence select="string-join(remove($ancestor-sequence
                , if (exists(index-of($ancestor-sequence, $folder-title-plus-unitid))) 
                then index-of($ancestor-sequence, $folder-title-plus-unitid)
                else 0)
                , 'xx*****yz')"/>
        </xsl:variable>
        <xsl:variable name="series-of-series" select="if (contains($ancestor-sequence-filtered, 'xx*****yz'))
            then tokenize($ancestor-sequence-filtered, 'xx\*\*\*\*\*yz') else $ancestor-sequence-filtered"/>
        <xsl:for-each select="$series-of-series[normalize-space()]">
            <fo:inline font-style="italic">
                <xsl:value-of select="."/>
                <xsl:if test="position() ne last()">
                    <xsl:text> > </xsl:text>
                </xsl:if>
                <xsl:if test="position() eq last()">
                    <xsl:text> (Continued)</xsl:text>
                </xsl:if>
            </fo:inline>
        </xsl:for-each>
    </xsl:template>

</xsl:stylesheet>