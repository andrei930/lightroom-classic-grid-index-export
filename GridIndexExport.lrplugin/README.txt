GRID INDEX EXPORT — Lightroom Classic plug-in
Version 1.1.0

PURPOSE
-------
Exports only the selected photos while naming each rendered file using that
photo's Index Number in the CURRENT VISIBLE Library Grid / Filmstrip.

Library filters are supported. If an Attribute / Metadata / Text filter is
active, the plug-in uses the numbering of that filtered view exactly as it is
currently displayed.

DESIGNED WORKFLOW
-----------------
1. Arrange/filter Lightroom so the Grid / Filmstrip displays the numbering you
   want to use.
2. Select the photos you want to export.
3. Open File > Export.
4. Choose "Grid Index Export" in the Export To destination selector.
5. Enter Custom Name / separator / padding / sequence start.
6. Choose a SEPARATE safety output folder.
7. Keep using Lightroom's normal File Settings, Image Sizing, Output
   Sharpening, Metadata and Watermarking controls.
8. Export.

EXAMPLES
--------
If the current visible Grid contains 17 filtered photos and selected photos
have displayed Index Numbers 2, 7 and 15, with:

  Custom Name: George-Max
  Separator: -
  Padding: 4
  Original sequence start: 1

then the exported files are:

  George-Max-0002.jpg
  George-Max-0007.jpg
  George-Max-0015.jpg

If no filter is active and those selected photos are positions 317, 842 and
1537 in the current Grid, they export as:

  George-Max-0317.jpg
  George-Max-0842.jpg
  George-Max-1537.jpg

IMPORTANT
---------
The plug-in deliberately follows the CURRENT displayed Grid / Filmstrip.
Changing a Library filter, source, sorting, stack visibility or other view
settings can therefore change the Index Numbers and the generated filenames.
Always verify the visible numbering before opening Export.

The plug-in blocks only when one or more selected photos are not visible in the
current Grid / Filmstrip, because it cannot assign a current displayed Index
Number to a hidden selected photo.

The plug-in does not modify originals and does not overwrite an existing output
file unless you explicitly enable its overwrite checkbox.

INSTALLATION
------------
1. Unzip GridIndexExport.lrplugin.zip.
2. In Lightroom Classic: File > Plug-in Manager.
3. Click Add.
4. Select GridIndexExport.lrplugin.
5. Close Plug-in Manager.

UPDATING FROM 1.0
-----------------
Replace/remove the old GridIndexExport.lrplugin folder and add this version in
Plug-in Manager. Version 1.1 allows active Library filters and uses the current
filtered Grid numbering.

NOTES
-----
- This is implemented as an Export Service Provider, not as a token inside
  Lightroom's native File Naming dropdown.
- Export Location and File Naming are replaced by the Grid Index Export panel.
  Other standard Lightroom rendering/export controls remain available.
- Video export is intentionally disabled.
