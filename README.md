# Lightroom Classic Visible Index Export

A small Adobe Lightroom Classic plug-in that lets you export photos using the **index number currently displayed in Lightroom's Grid view / Filmstrip** as part of the exported filename.

It is useful when you originally exported a large set of images with sequential filenames, later re-edited only a handful of them, and want to export just those corrected images with the same sequence numbers so they can easily replace the previous exports.

## Why this exists

A typical workflow might look like this:

1. Export a full wedding or shoot using a custom filename + sequence.
2. Later notice a few images that need corrections.
3. Mark those images with a color label, flag, rating, or another Library filter.
4. Re-edit them.
5. Export only those images again.

The problem is that Lightroom's normal sequence renaming starts a **new sequence for the current export**, so the corrected files no longer match their original sequence numbers.

This plug-in uses the **number Lightroom is currently showing for each image in the active Grid/Filmstrip view** instead.

## Features

- Uses Lightroom's **visible photo index** for exported filenames.
- Works with **Library Filters active**.
- Uses the numbering from the **current filtered view**.
- Works with selected photos, so you can export only the images you need.
- Leaves Lightroom in charge of the rest of the export process.
- Compatible with your normal Lightroom export settings, including:
  - export location
  - file format
  - JPEG quality
  - color space
  - image sizing
  - output sharpening
  - metadata
  - watermarking
  - post-processing
- Does not modify, rename, move, or delete the original files.

## Important: the number is view-dependent

The plug-in uses the index Lightroom is displaying **at the time of export**.

That means the result depends on the current:

- source / collection / folder
- sort order
- Library Filter

For example, if a Library Filter is active and Lightroom shows the selected photos as:

```text
1
2
3
4
```

then those are the numbers the plug-in will use.

If you need the numbers from the complete unfiltered shoot, remove the filter before exporting while keeping the desired images selected.

## Installation

1. Download the `.lrplugin` folder or the ZIP from the GitHub Releases page.
2. If downloaded as a ZIP, extract it first.
3. Open **Adobe Lightroom Classic**.
4. Go to:

   **File → Plug-in Manager**

5. Click **Add**.
6. Select the `.lrplugin` folder.
7. Make sure Lightroom reports the plug-in as installed and enabled.

The plug-in folder can be stored anywhere permanent on your computer. Do not delete or move it after adding it to Lightroom unless you also update its location in Plug-in Manager.

## Usage

### Example: re-export corrected images

1. Open the folder or collection containing the original shoot.
2. Apply your desired Library Filter, if any.
3. Select the images you want to re-export.
4. Check the index numbers shown by Lightroom in Grid view or the Filmstrip.
5. Open Lightroom's **Export** dialog.
6. Enable/use the Visible Index Export naming option provided by the plug-in.
7. Configure the rest of the export settings normally.
8. For safety, export to a separate folder first.
9. Verify the filenames and files before replacing your previous exports.

## Recommended safety workflow

When using the plug-in to replace already-delivered or already-exported files, it is strongly recommended to export into a **temporary/separate destination folder** first.

This gives you a chance to confirm that:

- the sequence numbers are correct
- the filenames are correct
- the expected photos were exported
- no unrelated files will be overwritten

Once verified, you can copy the corrected files into the final destination and replace the old versions.

## What the plug-in does not do

The plug-in does **not** attempt to reconstruct the numbering from an older export.

It only knows the index numbers Lightroom displays in the current view. If the photos have since been:

- reordered
- moved to another differently ordered collection
- filtered differently
- sorted differently

then Lightroom may display different indices, and those are the indices the plug-in will use.

It also does not modify Lightroom's Develop settings or source files.

## Compatibility

Designed for **Adobe Lightroom Classic** using the Lightroom Classic Plug-in SDK.

It is not intended for the cloud-based Lightroom application.

## Troubleshooting

### The numbers are different from my original export

Check your current Library Filter and sort order. The plug-in uses the numbers Lightroom displays in the current view.

If the original export was based on the complete unfiltered sequence, remove the Library Filter before exporting and verify the numbers shown in Grid/Filmstrip.

### My selected images are renumbered 1, 2, 3...

Make sure you are looking at the exact source/filter/sort state you want to use. The plug-in does not preserve historical export numbering; it uses Lightroom's current visible indices.

### Lightroom says the plug-in is missing

The `.lrplugin` folder was probably moved or deleted after being added to Lightroom. Open **File → Plug-in Manager** and add the plug-in again from its permanent location.

## Disclaimer

Use the plug-in at your own risk and verify exported filenames before overwriting existing work. Keeping a backup of the original export is strongly recommended.


---

Built for photographers who need to re-export a small subset of an already-sequenced Lightroom Classic job without manually reconstructing filenames.
