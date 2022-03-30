# Yale Staff Customizations

This plugin contains general customizations of the ArchivesSpace staff interface:


1. Locale and enum files to support digitization events
2. Support of Yale logo
3. Providing the Collection ID for Resources
4. Support for Yale-branded and styled PDFs
5. Remove the need for the separate  [YaleArchivesSpace/ead_export_addon  plugin](https://github.com/YaleArchivesSpace/ead_export_addon) ) 

## Providing the Collection ID for Resources

Addition of a  _[/frontend/plugin-init.rb](frontend/plugin-init.rb) that has a method to concatenate the Resource ID to the Resource Title for display purposes.

Addition of three views that use this method:

-  [/frontend/views/resources/_show.html.erb](frontend/views/resources/_show.html.erb)

-  [/frontend/views/resources/_edit.html.erb](frontend/views/resources/_edit.html.erb)

-  [/frontend/views/search/_listing.html.erb ](frontend/views/search/_listing.html.erb )



## Support for Yale-branded and styled PDFs

 Uses the stylesheets, fonts, and logos in the [YaleArchivesSpace/EAD3-to-PDF-UA repository](https://github.com/YaleArchivesSpace/EAD3-to-PDF-UA), which are now found at _/stylesheets_, as a base.

Addition of a _[/backend/plugin-init.rb](backend/plugin-init.rb)_, that overrides some methods of the ArchivesSpace PrintToPDFRunner class, that:

-  using an additional new method, get__ead3_, gets the initial EAD3 xml (including the changes originally instituted in the [YaleArchivesSpace/ead_export  plugin](https://github.com/YaleArchivesSpace/ead_export), but now included in this plugin ) ;
-    using the new [XLTransformer](backend/lib/XL_transformer.rb) class, processes that EAD3 to reflect Yale's best practice
    again using the XLTransformer class, converts the resulting EAD3 to a PDF.

**NOTE**:  Since the target ArchivesSpace version is 2.7.1, work will have to be done on the XLTransformer class when upgrading to ArchivesSpace 3.0.*, which has more recent jars that support PDF transformations, allowing for support for accessibility.

## Remove the **ead__export__addon** plugin

The one file that was still needed to support the EAD3 work for Yale has now been included in *this* plugin.




