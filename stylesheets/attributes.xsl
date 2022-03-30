<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:fox="http://xmlgraphics.apache.org/fop/extensions"
    xmlns:ead3="http://ead3.archivists.org/schema/" exclude-result-prefixes="xs ead3 fox" version="2.0">

    <!-- this file is imported by "ead3-to-pdf-ua.xsl" -->

    <!-- Headings -->
    <!-- removed the Yale font since so many collection titles have characters not included in that font -->
    <xsl:attribute-set name="h1"> <!-- used only for the finding aid title on the cover page right now -->
        <xsl:attribute name="role">H1</xsl:attribute>
        <xsl:attribute name="font-size">22pt</xsl:attribute>
        <xsl:attribute name="font-weight">bold</xsl:attribute>
        <xsl:attribute name="margin-top">16pt</xsl:attribute>
        <xsl:attribute name="margin-bottom">8pt</xsl:attribute>
    </xsl:attribute-set>
    <xsl:attribute-set name="h2" use-attribute-sets="header-serif"> <!-- used only for the finding aid unitid on the covery page right now -->
        <xsl:attribute name="role">H2</xsl:attribute>
        <xsl:attribute name="font-size">18pt</xsl:attribute>
        <xsl:attribute name="font-weight">bold</xsl:attribute>
        <xsl:attribute name="margin-top">4pt</xsl:attribute>
        <xsl:attribute name="padding-top">8pt</xsl:attribute>
        <xsl:attribute name="padding-bottom">8pt</xsl:attribute>
        <xsl:attribute name="keep-with-next.within-page">always</xsl:attribute>
    </xsl:attribute-set>
    <xsl:attribute-set name="h3" use-attribute-sets="header-serif"> <!-- used for series-level titles outside of the dsc table -->
        <xsl:attribute name="role">H3</xsl:attribute>
        <xsl:attribute name="font-size">16pt</xsl:attribute>
        <xsl:attribute name="font-weight">bold</xsl:attribute>
        <xsl:attribute name="keep-with-next.within-page">always</xsl:attribute>
    </xsl:attribute-set>
    <xsl:attribute-set name="h4" use-attribute-sets="header-serif">
        <xsl:attribute name="role">H4</xsl:attribute>
        <xsl:attribute name="font-size">14pt</xsl:attribute>
        <xsl:attribute name="font-weight">bold</xsl:attribute>
        <xsl:attribute name="keep-with-next.within-page">always</xsl:attribute>
    </xsl:attribute-set>
    <xsl:attribute-set name="h5" use-attribute-sets="header-serif">
        <xsl:attribute name="role">H5</xsl:attribute>
        <xsl:attribute name="font-size">14pt</xsl:attribute>
        <xsl:attribute name="font-weight">bold</xsl:attribute>
        <xsl:attribute name="keep-with-next.within-page">always</xsl:attribute>
    </xsl:attribute-set>
    <xsl:attribute-set name="h6" use-attribute-sets="header-serif">
        <xsl:attribute name="role">H6</xsl:attribute>
        <xsl:attribute name="font-size">12pt</xsl:attribute>
        <xsl:attribute name="font-weight">bold</xsl:attribute>
        <xsl:attribute name="keep-with-next.within-page">always</xsl:attribute>
    </xsl:attribute-set>
    <!-- Linking attributes styles -->
    <xsl:attribute-set name="ref">
        <xsl:attribute name="color">#286DC0</xsl:attribute>
        <xsl:attribute name="text-decoration">underline</xsl:attribute>
    </xsl:attribute-set>

    <xsl:attribute-set name="paragraph">
        <xsl:attribute name="space-after">8pt</xsl:attribute>
        <xsl:attribute name="space-before">4pt</xsl:attribute>
    </xsl:attribute-set>

    <xsl:attribute-set name="paragraph-indent">
        <xsl:attribute name="space-before">4pt</xsl:attribute>
        <xsl:attribute name="text-indent">1.5em</xsl:attribute>
    </xsl:attribute-set>

    <xsl:attribute-set name="toc-block">
        <xsl:attribute name="margin">30pt 10pt 10pt 10pt</xsl:attribute>
        <xsl:attribute name="font-size">10pt</xsl:attribute>
    </xsl:attribute-set>

    <xsl:attribute-set name="center-text">
        <xsl:attribute name="text-align">center</xsl:attribute>
    </xsl:attribute-set>

    <xsl:attribute-set name="margin-after-large">
        <xsl:attribute name="margin-bottom">48pt</xsl:attribute>
    </xsl:attribute-set>

    <xsl:attribute-set name="margin-after-small">
        <xsl:attribute name="margin-bottom">12pt</xsl:attribute>
    </xsl:attribute-set>

    <xsl:attribute-set name="collection-overview-list">
        <xsl:attribute name="provisional-distance-between-starts">5cm</xsl:attribute>
        <xsl:attribute name="provisional-label-separation">0.25cm</xsl:attribute>
        <xsl:attribute name="font-size">10pt</xsl:attribute>
        <xsl:attribute name="padding-top">0.75cm</xsl:attribute>
        <xsl:attribute name="padding-bottom">0.75cm</xsl:attribute>
    </xsl:attribute-set>

    <xsl:attribute-set name="collection-overview-list-item">
        <xsl:attribute name="space-after">8pt</xsl:attribute>
    </xsl:attribute-set>

    <!-- not sure if we should use the serif or sans-serif font here.  for now, it's sans.
    mixing Yale and Mallory on the same line doesn't work very well.
    -->
    <xsl:attribute-set name="collection-overview-list-label">
        <xsl:attribute name="end-indent">label-end()</xsl:attribute>
        <xsl:attribute name="font-weight">bold</xsl:attribute>
        <xsl:attribute name="text-align">
            <xsl:text>end</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="text-transform">
            <xsl:text>uppercase</xsl:text>
        </xsl:attribute>
    </xsl:attribute-set>

    <xsl:attribute-set name="collection-overview-list-body">
        <xsl:attribute name="start-indent">body-start()</xsl:attribute>
    </xsl:attribute-set>

    <xsl:attribute-set name="dsc-container-key-list-label">
          <xsl:attribute name="end-indent">label-end()</xsl:attribute>
          <xsl:attribute name="width">3em</xsl:attribute>
    </xsl:attribute-set>

    <xsl:attribute-set name="page-number">
        <xsl:attribute name="font-size">9pt</xsl:attribute>
        <xsl:attribute name="text-align">end</xsl:attribute>
    </xsl:attribute-set>

    <!-- not currently used -->
    <xsl:attribute-set name="dsc-table-header" use-attribute-sets="header-serif">
        <xsl:attribute name="border-bottom-color">#000000</xsl:attribute>
        <xsl:attribute name="border-bottom-width">thin</xsl:attribute>
        <xsl:attribute name="border-bottom-style">solid</xsl:attribute>
    </xsl:attribute-set>

    <xsl:attribute-set name="header-serif-underline" use-attribute-sets="underline">
        <!-- no backups needed here -->
        <xsl:attribute name="font-family" select="$serif-font"/>
    </xsl:attribute-set>

    <xsl:attribute-set name="header-serif">
        <!-- should be some sugary syntax for this, but concat works -->
        <xsl:attribute name="font-family" select="concat($serif-font, ', ', $backup-font)"/>
    </xsl:attribute-set>

    <xsl:attribute-set name="white-font">
        <xsl:attribute name="color">#fff</xsl:attribute>
    </xsl:attribute-set>

    <xsl:attribute-set name="underline">
        <xsl:attribute name="text-decoration">underline</xsl:attribute>
    </xsl:attribute-set>

    <xsl:attribute-set name="dsc-table-cells">
        <xsl:attribute name="padding">5pt 2pt</xsl:attribute>
    </xsl:attribute-set>

    <xsl:attribute-set name="container-grouping">
        <xsl:attribute name="start-indent">1em</xsl:attribute>
        <xsl:attribute name="text-indent">-1em</xsl:attribute>
    </xsl:attribute-set>


    <!-- <list> Attribute Set -->
    <xsl:attribute-set name="list">
        <xsl:attribute name="font-weight">normal</xsl:attribute>
        <xsl:attribute name="margin-bottom">10pt</xsl:attribute>
    </xsl:attribute-set>

    <!-- <listhead> Attribute Set -->
    <xsl:attribute-set name="list.head" use-attribute-sets="header-serif">
        <xsl:attribute name="font-weight">bold</xsl:attribute>
    </xsl:attribute-set>

    <!-- <item> Attribute Set -->
    <xsl:attribute-set name="list.item">
        <xsl:attribute name="font-weight">normal</xsl:attribute>
        <xsl:attribute name="space-after">3pt</xsl:attribute>
    </xsl:attribute-set>

    <!-- <chronlist> Head Attribute Set -->
    <xsl:attribute-set name="chronlist.head" use-attribute-sets="header-serif">
        <xsl:attribute name="font-weight">bold</xsl:attribute>
        <xsl:attribute name="text-align">start</xsl:attribute>
        <xsl:attribute name="margin-top">10pt</xsl:attribute>
        <xsl:attribute name="margin-bottom">10pt</xsl:attribute>
    </xsl:attribute-set>

    <!-- Table  <table> Attribute Set -->
    <xsl:attribute-set name="table">
        <xsl:attribute name="table-layout">fixed</xsl:attribute>
        <xsl:attribute name="table-omit-header-at-break">false</xsl:attribute>
        <xsl:attribute name="margin-bottom">20pt</xsl:attribute>
        <xsl:attribute name="inline-progression-dimension.optimum">100%</xsl:attribute>
    </xsl:attribute-set>

    <!-- Table Head (<thead> and elsewhere) Attribute Set -->
    <xsl:attribute-set name="table.head" use-attribute-sets="header-serif">
        <xsl:attribute name="font-weight">bold</xsl:attribute>
    </xsl:attribute-set>

    <!-- Table Cell Attribute Set -->
    <xsl:attribute-set name="table.cell">
        <xsl:attribute name="padding" select="'5pt'"/>
    </xsl:attribute-set>

    <!-- Table Cell Block Attribute Set -->
    <xsl:attribute-set name="table.cell.block">
        <xsl:attribute name="margin-top">10pt</xsl:attribute>
    </xsl:attribute-set>

    <xsl:attribute-set name="unpublished">
        <xsl:attribute name="border-width">2pt</xsl:attribute>
        <xsl:attribute name="border-style">solid</xsl:attribute>
        <xsl:attribute name="border-color">red</xsl:attribute>
    </xsl:attribute-set>

</xsl:stylesheet>
