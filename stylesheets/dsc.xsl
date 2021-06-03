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

        what if i go back to no tables, floating the dates to the right,
            and just adding containers in a new block?

        other ideas:
            autogenerate a series/subseries overview, with container ranges and first pargraph of scope note?

            take the regular DSC out of a table, and put the container information inline.

            and add a container-inventory section at the end that's a real table, with box, folder, etc., plus title,
            date, etc., sorted by container numbers.
     -->
    <xsl:param name="dsc-first-c-levels-to-process-before-a-table" select="('series', 'collection', 'fonds', 'recordgrp')"/>
    <xsl:param name="levels-to-force-a-page-break" select="('series', 'collection', 'fonds', 'recordgrp')"/>
    <xsl:param name="otherlevels-to-force-a-page-break-and-process-before-a-table" select="('accession', 'acquisition')"/>

    <!-- new function... might move elsewhere, but adding it here for now since it's only called on containers -->
    <xsl:function name="mdc:find-the-ultimate-parent-id" as="xs:string">
        <!-- given that there can be multiple parent/id pairings, this occasionally recursive function will find and select the top container ID attribute, which will be used to do the groupings, rather than depenidng on entirely document order -->
        <xsl:param name="current-container" as="node()"/>
        <xsl:variable name="parent" select="$current-container/@parent"/>
        <xsl:choose>
            <xsl:when test="not ($parent)">
                <xsl:value-of select="$current-container/@id"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="mdc:find-the-ultimate-parent-id($current-container/preceding-sibling::ead3:container[@id eq $parent])"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <!-- not worrying about multiple DSC sections.  ASpace can only export 1 DSC -->
    <xsl:template match="ead3:dsc">
        <xsl:variable name="column-types" select="
            if
            (ead3:*[matches(local-name(), '^c0|^c1') or local-name()='c'][descendant-or-self::ead3:unitdate or descendant-or-self::ead3:unitdatestructured][descendant-or-self::ead3:container])
            then 'c-d-d'
            else
            if (ead3:*[matches(local-name(), '^c0|^c1') or local-name()='c'][descendant-or-self::ead3:unitdate or descendant-or-self::ead3:unitdatestructured])
            then 'd-d'
            else
            if (ead3:*[matches(local-name(), '^c0|^c1') or local-name()='c'][descendant-or-self::ead3:container])
            then 'c-d'
            else 'd'"/>

        <fo:page-sequence master-reference="contents">
            <!-- Page header -->
            <fo:static-content flow-name="xsl-region-before">
                <xsl:call-template name="header-dsc"/>
            </fo:static-content>
            <!-- Page footer-->
            <fo:static-content flow-name="xsl-region-after" role="artifact">
                <xsl:call-template name="footer"/>
            </fo:static-content>
            <!-- Content of page -->
            <fo:flow flow-name="xsl-region-body">
                <xsl:call-template name="section-start"/>
                <fo:block xsl:use-attribute-sets="h3" id="dsc-contents"><xsl:value-of select="$dsc-title"/></fo:block>
                <xsl:choose>
                    <xsl:when test="ead3:*[matches(local-name(), '^c0|^c1') or local-name()='c'][@level=$dsc-first-c-levels-to-process-before-a-table or @otherlevel=$otherlevels-to-force-a-page-break-and-process-before-a-table]">
                        <xsl:apply-templates select="ead3:*[matches(local-name(), '^c0|^c1') or local-name()='c']" mode="dsc-block">
                            <xsl:with-param name="column-types" select="$column-types"/>
                        </xsl:apply-templates>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="tableBody">
                            <xsl:with-param name="column-types" select="$column-types"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
                <!-- adding this to grab the last page number-->
                <xsl:if test="$last-page eq 'dsc'">
                    <fo:wrapper id="last-page"/>
                </xsl:if>
            </fo:flow>
        </fo:page-sequence>
    </xsl:template>

    <xsl:template match="ead3:*[matches(local-name(), '^c0|^c1') or local-name()='c']" mode="dsc-block">
        <xsl:variable name="depth" select="count(ancestor::*) - 3"/> <!-- e.g. c01 = 0, c02 = 1, etc. -->
        <xsl:variable name="cell-margin" select="concat(xs:string($depth * 6), 'pt')"/> <!-- e.g. 0, 8pt for c02, 16pt for c03, etc.-->
        <xsl:variable name="column-types" select="
            if
            (ead3:*[matches(local-name(), '^c0|^c1') or local-name()='c'][descendant-or-self::ead3:unitdate or descendant-or-self::ead3:unitdatestructured][descendant-or-self::ead3:container])
            then 'c-d-d'
            else
            if (ead3:*[matches(local-name(), '^c0|^c1') or local-name()='c'][descendant-or-self::ead3:unitdate or descendant-or-self::ead3:unitdatestructured])
            then 'd-d'
            else
            if (ead3:*[matches(local-name(), '^c0|^c1') or local-name()='c'][descendant-or-self::ead3:container])
            then 'c-d'
            else 'd'"/>
        <!-- do a second grouping based on the container grouping's primary localtype (i.e. box, volume, reel, etc.)
            then add a custom sort, or just sort those alphabetically -->
        <xsl:variable name="container-groupings">
            <xsl:for-each-group select="ead3:did/ead3:container" group-by="mdc:find-the-ultimate-parent-id(.)">
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
        <!-- removed keep-with-next.within-page="always" -->
        <fo:block margin-left="{$cell-margin}" id="{if (@id) then @id else generate-id(.)}">
            <xsl:if test="preceding-sibling::ead3:*[@level=$levels-to-force-a-page-break or @otherlevel=$otherlevels-to-force-a-page-break-and-process-before-a-table]">
                <xsl:attribute name="break-before" select="'page'"/>
            </xsl:if>
            <xsl:if test="@audience='internal' and $suppressInternalComponentsInPDF eq false()">
                <xsl:attribute name="border-right-style">solid</xsl:attribute>
                <xsl:attribute name="border-right-width">2px</xsl:attribute>
                <xsl:attribute name="border-right-color">red</xsl:attribute>
            </xsl:if>
            <xsl:choose>
                <xsl:when test="parent::ead3:dsc and  (@level = ('series', 'collection', 'recordgrp') or @otherlevel = $otherlevels-to-force-a-page-break-and-process-before-a-table)">
                    <fo:marker marker-class-name="continued-header-text">
                        <fo:inline>
                            <xsl:value-of select="ead3:did/ead3:unitid/normalize-space()"/>
                            <xsl:if test="ead3:did/ead3:unitid[not(ends-with(normalize-space(), $unitid-trailing-punctuation))]">
                                <xsl:value-of select="$unitid-separator"/>
                            </xsl:if>
                            <xsl:choose>
                                <!-- bad hack to deal with really-long series titles. think of another way to handle this with FOP -->
                                <xsl:when test="string-length(ead3:did/ead3:unittitle[1]) gt 140">
                                    <xsl:value-of select="concat(substring(., 1, 140), '[...]')"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:apply-templates select="ead3:did/ead3:unittitle[1]"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </fo:inline>
                    </fo:marker>
                </xsl:when>
                <xsl:otherwise>
                    <fo:marker marker-class-name="continued-header-text"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
                <xsl:when test="$depth = 0 and (@level = ('series', 'collection', 'recordgrp') or @otherlevel = $otherlevels-to-force-a-page-break-and-process-before-a-table)">
                    <fo:block xsl:use-attribute-sets="h4">
                        <xsl:call-template name="combine-identifier-title-and-dates"/>
                    </fo:block>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="dsc-block-identifier-and-title"/>
                </xsl:otherwise>
            </xsl:choose>

            <!-- still need to add the other did elements, and select an order -->
            <xsl:apply-templates select="ead3:did" mode="dsc"/>
            <xsl:apply-templates select="ead3:bioghist, ead3:scopecontent
                , ead3:acqinfo, ead3:custodhist, ead3:accessrestrict, ead3:userestrict, ead3:prefercite
                , ead3:processinfo, ead3:altformavail, ead3:relatedmaterial, ead3:separatedmaterial, ead3:accruals, ead3:appraisals
                , ead3:originalsloc, ead3:otherfindaid, ead3:phystech, ead3:fileplan, ead3:odd, ead3:bibliography, ead3:arrangement, ead3:controlaccess" mode="dsc"/>
            <!-- still need to add templates here for digital objects.  anything else?  -->
            <xsl:call-template name="container-layout">
                <xsl:with-param name="containers-sorted-by-localtype" select="$containers-sorted-by-localtype"/>
            </xsl:call-template>
        </fo:block>
        <xsl:choose>
            <xsl:when test="not(ead3:*[matches(local-name(), '^c0|^c1') or local-name()='c'])"/>
            <xsl:otherwise>
               <xsl:call-template name="tableBody">
                   <xsl:with-param name="column-types" select="$column-types"/>
               </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="ead3:*[matches(local-name(), '^c0|^c1') or local-name()='c']" mode="dsc-table">
        <xsl:param name="first-row" select="if (position() eq 1 and (
                parent::ead3:dsc
                or parent::*[@level=$dsc-first-c-levels-to-process-before-a-table]
                or parent::*[@otherlevel=$otherlevels-to-force-a-page-break-and-process-before-a-table])
            )
            then true() else false()"/>
        <xsl:param name="no-children" select="if (not(ead3:*[matches(local-name(), '^c0|^c1') or local-name()='c'])) then true() else false()"/>
        <xsl:param name="last-row" select="if (position() eq last() and $no-children) then true() else false()"/>
        <xsl:param name="depth"/> <!-- e.g. c01 = 0, c02 = 1, etc. -->
        <xsl:param name="column-types"/>
        <xsl:variable name="cell-margin" select="concat(xs:string($depth * 8), 'pt')"/> <!-- e.g. 0, 8pt for c02, 16pt for c03, etc.-->
        <xsl:variable name="container-groupings">
            <xsl:for-each-group select="ead3:did/ead3:container" group-by="mdc:find-the-ultimate-parent-id(.)">
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
        <!--  need to do something here to fix rows that have REALLY long notes. see 15.pdf -->
        <fo:table-row>
            <xsl:call-template name="dsc-table-row-border">
                <xsl:with-param name="last-row" select="$last-row"/>
                <xsl:with-param name="no-children" select="$no-children"/>
                <xsl:with-param name="audience" select="@audience"/>
                <xsl:with-param name="component-string-length" select="sum(for $x in child::*[not(local-name()='c')] return string-length($x))"/>
            </xsl:call-template>
            <xsl:choose>
                <xsl:when test="$column-types eq 'c-d-d'">
                    <fo:table-cell xsl:use-attribute-sets="dsc-table-cells">
                        <xsl:call-template name="container-layout">
                            <xsl:with-param name="containers-sorted-by-localtype" select="$containers-sorted-by-localtype"/>
                        </xsl:call-template>
                    </fo:table-cell>
                    <fo:table-cell xsl:use-attribute-sets="dsc-table-cells">
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
                        <fo:block-container margin-left="{$cell-margin}" id="{if (@id) then @id else generate-id(.)}">
                            <fo:block-container>
                                <fo:block>
                                    <xsl:call-template name="dsc-block-identifier-and-title"/>
                                </fo:block>
                                <!-- still need to add the other did elements, and select an order -->
                                <fo:block>
                                    <xsl:apply-templates select="ead3:did" mode="dsc"/>
                                </fo:block>
                            </fo:block-container>
                            <fo:block-container>
                                <fo:block>
                                    <xsl:apply-templates select="ead3:bioghist, ead3:scopecontent
                                        , ead3:acqinfo, ead3:custodhist, ead3:accessrestrict, ead3:userestrict, ead3:prefercite
                                        , ead3:processinfo, ead3:altformavail, ead3:relatedmaterial, ead3:separatedmaterial, ead3:accruals, ead3:appraisals
                                        , ead3:originalsloc, ead3:otherfindaid, ead3:phystech, ead3:fileplan, ead3:odd, ead3:bibliography, ead3:arrangement, ead3:controlaccess" mode="dsc"/>
                                </fo:block>
                            </fo:block-container>
                        </fo:block-container>
                    </fo:table-cell>
                    <fo:table-cell xsl:use-attribute-sets="dsc-table-cells">
                        <fo:block>
                            <xsl:apply-templates select="ead3:did/ead3:unitdatestructured | ead3:did/ead3:unitdate" mode="dsc"/>
                        </fo:block>
                    </fo:table-cell>
                </xsl:when>
                <xsl:when test="$column-types eq 'd-d'">
                    <fo:table-cell xsl:use-attribute-sets="dsc-table-cells">
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
                        <fo:block-container margin-left="{$cell-margin}" id="{if (@id) then @id else generate-id(.)}">
                            <fo:block-container>
                                <fo:block>
                                    <xsl:call-template name="dsc-block-identifier-and-title"/>
                                </fo:block>
                                <!-- still need to add the other did elements, and select an order -->
                                <fo:block>
                                    <xsl:apply-templates select="ead3:did" mode="dsc"/>
                                </fo:block>
                            </fo:block-container>
                            <fo:block-container>
                                <fo:block>
                                    <xsl:apply-templates select="ead3:bioghist, ead3:scopecontent
                                        , ead3:acqinfo, ead3:custodhist, ead3:accessrestrict, ead3:userestrict, ead3:prefercite
                                        , ead3:processinfo, ead3:altformavail, ead3:relatedmaterial, ead3:separatedmaterial, ead3:accruals, ead3:appraisals
                                        , ead3:originalsloc, ead3:otherfindaid, ead3:phystech, ead3:fileplan, ead3:odd, ead3:bibliography, ead3:arrangement, ead3:controlaccess" mode="dsc"/>
                                </fo:block>
                            </fo:block-container>
                        </fo:block-container>
                    </fo:table-cell>
                    <fo:table-cell xsl:use-attribute-sets="dsc-table-cells">
                        <fo:block>
                            <xsl:apply-templates select="ead3:did/ead3:unitdatestructured | ead3:did/ead3:unitdate" mode="dsc"/>
                        </fo:block>
                    </fo:table-cell>
                </xsl:when>
                <xsl:when test="$column-types eq 'c-d'">
                    <fo:table-cell xsl:use-attribute-sets="dsc-table-cells">
                        <xsl:call-template name="container-layout">
                            <xsl:with-param name="containers-sorted-by-localtype" select="$containers-sorted-by-localtype"/>
                        </xsl:call-template>
                    </fo:table-cell>
                    <fo:table-cell xsl:use-attribute-sets="dsc-table-cells">
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
                        <fo:block-container margin-left="{$cell-margin}" id="{if (@id) then @id else generate-id(.)}">
                            <fo:block-container>
                                <fo:block>
                                    <xsl:call-template name="dsc-block-identifier-and-title"/>
                                </fo:block>
                                <!-- still need to add the other did elements, and select an order -->
                                <fo:block>
                                    <xsl:apply-templates select="ead3:did" mode="dsc"/>
                                </fo:block>
                            </fo:block-container>
                            <fo:block-container>
                                <fo:block>
                                    <xsl:apply-templates select="ead3:bioghist, ead3:scopecontent
                                        , ead3:acqinfo, ead3:custodhist, ead3:accessrestrict, ead3:userestrict, ead3:prefercite
                                        , ead3:processinfo, ead3:altformavail, ead3:relatedmaterial, ead3:separatedmaterial, ead3:accruals, ead3:appraisals
                                        , ead3:originalsloc, ead3:otherfindaid, ead3:phystech, ead3:fileplan, ead3:odd, ead3:bibliography, ead3:arrangement, ead3:controlaccess" mode="dsc"/>
                                </fo:block>
                            </fo:block-container>
                        </fo:block-container>
                    </fo:table-cell>
                </xsl:when>
                <xsl:otherwise>
                    <fo:table-cell xsl:use-attribute-sets="dsc-table-cells">
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
                        <fo:block-container margin-left="{$cell-margin}" id="{if (@id) then @id else generate-id(.)}">
                            <fo:block-container>
                                <fo:block>
                                    <xsl:call-template name="dsc-block-identifier-and-title"/>
                                </fo:block>
                                <!-- still need to add the other did elements, and select an order -->
                                <fo:block>
                                    <xsl:apply-templates select="ead3:did" mode="dsc"/>
                                </fo:block>
                            </fo:block-container>
                            <fo:block-container>
                                <fo:block>
                                    <xsl:apply-templates select="ead3:bioghist, ead3:scopecontent
                                        , ead3:acqinfo, ead3:custodhist, ead3:accessrestrict, ead3:userestrict, ead3:prefercite
                                        , ead3:processinfo, ead3:altformavail, ead3:relatedmaterial, ead3:separatedmaterial, ead3:accruals, ead3:appraisals
                                        , ead3:originalsloc, ead3:otherfindaid, ead3:phystech, ead3:fileplan, ead3:odd, ead3:bibliography, ead3:arrangement, ead3:controlaccess" mode="dsc"/>
                                </fo:block>
                            </fo:block-container>
                        </fo:block-container>
                    </fo:table-cell>
                </xsl:otherwise>
            </xsl:choose>
        </fo:table-row>
        <xsl:apply-templates select="ead3:*[matches(local-name(), '^c0|^c1') or local-name()='c']" mode="dsc-table">
            <xsl:with-param name="depth" select="$depth + 1"/>
            <xsl:with-param name="column-types" select="$column-types"/>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="ead3:did" mode="dsc">
        <xsl:apply-templates select="ead3:abstract, ead3:physdescstructured, ead3:physdesc,
            ead3:physdescset, ead3:physloc,
            ead3:langmaterial, ead3:materialspec, ead3:origination, ead3:repository, ead3:dao, ead3:daoset/ead3:dao" mode="#current"/>
    </xsl:template>

    <xsl:template match="ead3:container">
        <xsl:variable name="container-lower-case" select="lower-case(@localtype)"/>
        <!-- removed box from here for now.  seeing if it looks less busy without it. -->
        <xsl:variable name="use-fontawesome" as="xs:boolean">
            <xsl:value-of select="if ($container-lower-case = ('volume', 'item_barcode')) then true() else false()"/>
        </xsl:variable>
        <xsl:variable name="container-abbr">
            <xsl:value-of select="if ($container-lower-case = ('box', 'folder')) then concat(substring($container-lower-case, 1, 1), '.')
                else if ($container-lower-case eq 'volume') then 'vol.'
                else ''"/>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$use-fontawesome eq false()">
                <fo:inline color="#4A4A4A">
                    <xsl:if test="$container-abbr/normalize-space()">
                        <xsl:attribute name="alt-text" namespace="http://xmlgraphics.apache.org/fop/extensions" select="$container-lower-case"/>
                    </xsl:if>
                    <xsl:value-of select="if ($container-abbr/normalize-space()) then $container-abbr else $container-lower-case"/>
                </fo:inline>
            </xsl:when>
            <xsl:otherwise>
                <fo:inline font-family="FontAwesomeSolid" color="#4A4A4A">
                    <xsl:value-of select="if ($container-lower-case eq 'box') then '&#xf187; '
                        else if ($container-lower-case eq 'folder') then '&#xf07b; '
                        else if ($container-lower-case eq 'volume') then '&#xf02d; '
                        else if ($container-lower-case eq 'item_barcode') then '&#xf02a;'
                        else '&#xf0a0; '"/>
                </fo:inline>
                <fo:inline color="#4A4A4A">
                    <xsl:if test="$container-abbr/normalize-space()">
                        <xsl:attribute name="alt-text" namespace="http://xmlgraphics.apache.org/fop/extensions" select="$container-lower-case"/>
                    </xsl:if>
                    <xsl:value-of select="if ($container-lower-case eq 'item_barcode') then ''
                        else if ($container-abbr/normalize-space()) then $container-abbr
                        else $container-lower-case"/>
                </fo:inline>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text> </xsl:text>
        <!-- and here's where we print out the actual container indicator... and since barcodes could extend the margin without having a space for a newline, we'll make those smaller, at 7pt. -->
        <xsl:choose>
            <xsl:when test="$container-lower-case eq 'item_barcode'">
                <fo:inline font-size="7pt">
                    <xsl:apply-templates/>
                </fo:inline>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>

        <!-- comma separator or no? -->
        <xsl:if test="position() ne last()">
            <xsl:text>, </xsl:text>
        </xsl:if>
    </xsl:template>

</xsl:stylesheet>
