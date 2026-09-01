local LrApplication = import 'LrApplication'
local LrDialogs = import 'LrDialogs'
local LrExportSettings = import 'LrExportSettings'
local LrFileUtils = import 'LrFileUtils'
local LrPathUtils = import 'LrPathUtils'
local LrView = import 'LrView'

local bind = LrView.bind

local provider = {}

-- Lightroom renders into a temporary folder. This plug-in is responsible for
-- copying the rendered files to the user-selected destination using Grid Index
-- based names. All standard rendering controls except Export Location and File
-- Naming remain available in the Export dialog.
provider.hideSections = { 'exportLocation', 'fileNaming' }
provider.canExportVideo = false

provider.exportPresetFields = {
    { key = 'gie_destinationPath', default = '' },
    { key = 'gie_customName', default = '' },
    { key = 'gie_separator', default = '-' },
    { key = 'gie_padding', default = 4 },
    { key = 'gie_sequenceStart', default = 1 },
    { key = 'gie_overwriteExisting', default = false },
}

local function trim(s)
    s = tostring(s or '')
    return (s:gsub('^%s+', ''):gsub('%s+$', ''))
end

local function formatIndex(value, padding)
    value = math.floor(tonumber(value) or 0)
    padding = math.floor(tonumber(padding) or 0)

    if padding <= 0 then
        return tostring(value)
    end

    return string.format('%0' .. tostring(padding) .. 'd', value)
end

local function serializeIndexMap(indexMap)
    local entries = {}

    for localId, index in pairs(indexMap) do
        entries[#entries + 1] = tostring(localId) .. ':' .. tostring(index)
    end

    table.sort(entries)
    return table.concat(entries, ';')
end

local function parseIndexMap(serialized)
    local result = {}

    for item in tostring(serialized or ''):gmatch('[^;]+') do
        local localId, index = item:match('^(%-?%d+):(%-?%d+)$')
        if localId and index then
            result[tonumber(localId)] = tonumber(index)
        end
    end

    return result
end

local function captureCurrentGrid()
    local catalog = LrApplication.activeCatalog()
    local selectedPhotos = catalog:getTargetPhotos()
    local primaryPhoto = catalog:getTargetPhoto()

    if not primaryPhoto or not selectedPhotos or #selectedPhotos == 0 then
        return nil, 'No photos are selected.'
    end

    local visiblePhotos = nil
    local selectionWasTemporarilyChanged = false

    local ok, err = pcall(function()
        -- getMultipleSelectedOrAllPhotos() returns all visible photos when one
        -- (or zero) photo is selected. Temporarily reduce a multi-selection to
        -- the primary photo so Lightroom returns the complete Filmstrip/Grid in
        -- its current displayed order.
        if #selectedPhotos > 1 then
            catalog:setSelectedPhotos(primaryPhoto, {})
            selectionWasTemporarilyChanged = true
        end

        visiblePhotos = catalog:getMultipleSelectedOrAllPhotos()
    end)

    if selectionWasTemporarilyChanged then
        pcall(function()
            catalog:setSelectedPhotos(primaryPhoto, selectedPhotos)
        end)
    end

    if not ok then
        return nil, 'Could not read the current Grid/Filmstrip order: ' .. tostring(err)
    end

    if not visiblePhotos or #visiblePhotos == 0 then
        return nil, 'The current Grid/Filmstrip contains no visible photos.'
    end

    local selectedSet = {}
    for _, photo in ipairs(selectedPhotos) do
        selectedSet[photo.localIdentifier] = true
    end

    local indexMap = {}
    local matched = 0
    local firstIndex = nil
    local lastIndex = nil

    for index, photo in ipairs(visiblePhotos) do
        local localId = photo.localIdentifier
        if selectedSet[localId] then
            indexMap[localId] = index
            matched = matched + 1
            if not firstIndex or index < firstIndex then
                firstIndex = index
            end
            if not lastIndex or index > lastIndex then
                lastIndex = index
            end
        end
    end

    if matched ~= #selectedPhotos then
        return nil,
            'Only ' .. tostring(matched) .. ' of ' .. tostring(#selectedPhotos)
            .. ' selected photos are visible in the current Grid/Filmstrip. Adjust the current source/filter/stack visibility so every selected photo is visible.'
    end

    return {
        indexMap = indexMap,
        selectedCount = #selectedPhotos,
        gridCount = #visiblePhotos,
        firstIndex = firstIndex,
        lastIndex = lastIndex,
    }, nil
end

local function previewExtension(propertyTable)
    local format = propertyTable.LR_format
    if not format then
        return '<ext>'
    end

    if format == 'ORIGINAL' then
        return '<original ext>'
    end

    local ok, ext = pcall(function()
        return LrExportSettings.extensionForFormat(format)
    end)

    if ok and ext and ext ~= '' then
        return tostring(ext):lower()
    end

    return tostring(format):lower()
end

local function updatePreview(propertyTable)
    local customName = trim(propertyTable.gie_customName)
    local separator = tostring(propertyTable.gie_separator or '')
    local padding = tonumber(propertyTable.gie_padding) or 4
    local sequenceStart = tonumber(propertyTable.gie_sequenceStart) or 1
    local firstIndex = tonumber(propertyTable.gie_firstIndex) or 1

    local number = firstIndex + sequenceStart - 1
    local stem = customName .. separator .. formatIndex(number, padding)
    propertyTable.gie_preview = stem .. '.' .. previewExtension(propertyTable)
end

local function updateCantExportBecause(propertyTable)
    updatePreview(propertyTable)

    if propertyTable.gie_captureValid ~= true then
        propertyTable.LR_cantExportBecause = propertyTable.gie_captureError or 'Grid Index information is not ready.'
        return
    end

    local destination = trim(propertyTable.gie_destinationPath)
    if destination == '' then
        propertyTable.LR_cantExportBecause = 'Choose a destination folder for the corrected exports.'
        return
    end

    if LrFileUtils.exists(destination) ~= 'directory' then
        propertyTable.LR_cantExportBecause = 'The selected destination folder does not exist.'
        return
    end

    local customName = trim(propertyTable.gie_customName)
    if customName == '' then
        propertyTable.LR_cantExportBecause = 'Enter the Custom Name used for the original export.'
        return
    end

    if customName:find('[\\/:]') then
        propertyTable.LR_cantExportBecause = 'Custom Name cannot contain /, \\, or : characters.'
        return
    end

    local separator = tostring(propertyTable.gie_separator or '')
    if separator:find('[\\/:]') then
        propertyTable.LR_cantExportBecause = 'Separator cannot contain /, \\, or : characters.'
        return
    end

    local padding = tonumber(propertyTable.gie_padding)
    if not padding or padding < 0 or padding > 8 or padding ~= math.floor(padding) then
        propertyTable.LR_cantExportBecause = 'Number padding must be a whole number from 0 to 8.'
        return
    end

    local sequenceStart = tonumber(propertyTable.gie_sequenceStart)
    if not sequenceStart or sequenceStart < 0 or sequenceStart ~= math.floor(sequenceStart) then
        propertyTable.LR_cantExportBecause = 'Original sequence start must be a whole number of 0 or greater.'
        return
    end

    propertyTable.LR_cantExportBecause = nil
end

local function refreshGridCapture(propertyTable)
    local capture, err = captureCurrentGrid()

    if not capture then
        propertyTable.gie_captureValid = false
        propertyTable.gie_captureError = err
        propertyTable.gie_status = 'BLOCKED — ' .. tostring(err)
        propertyTable.gie_indexMap = ''
        propertyTable.gie_firstIndex = 1
        propertyTable.gie_lastIndex = 1
        propertyTable.gie_gridCount = 0
        propertyTable.gie_selectedCount = 0
    else
        propertyTable.gie_captureValid = true
        propertyTable.gie_captureError = nil
        propertyTable.gie_indexMap = serializeIndexMap(capture.indexMap)
        propertyTable.gie_firstIndex = capture.firstIndex
        propertyTable.gie_lastIndex = capture.lastIndex
        propertyTable.gie_gridCount = capture.gridCount
        propertyTable.gie_selectedCount = capture.selectedCount
        propertyTable.gie_status =
            'Ready — ' .. tostring(capture.selectedCount) .. ' selected photo(s), '
            .. tostring(capture.gridCount) .. ' photos in the current visible Grid/Filmstrip; index range '
            .. tostring(capture.firstIndex) .. '–' .. tostring(capture.lastIndex) .. '.'
    end

    updateCantExportBecause(propertyTable)
end

function provider.startDialog(propertyTable)
    local function changed()
        updateCantExportBecause(propertyTable)
    end

    propertyTable:addObserver('gie_destinationPath', changed)
    propertyTable:addObserver('gie_customName', changed)
    propertyTable:addObserver('gie_separator', changed)
    propertyTable:addObserver('gie_padding', changed)
    propertyTable:addObserver('gie_sequenceStart', changed)
    propertyTable:addObserver('LR_format', changed)

    refreshGridCapture(propertyTable)
end

function provider.sectionsForTopOfDialog(f, propertyTable)
    return {
        {
            title = 'Grid Index Export',
            synopsis = bind 'gie_preview',

            f:column {
                spacing = f:control_spacing(),

                f:static_text {
                    title = 'Uses the Index Numbers from the CURRENT visible Grid / Filmstrip, including when a Library filter is active.',
                    width_in_chars = 62,
                    height_in_lines = 2,
                    wrap = true,
                },

                f:static_text {
                    title = bind 'gie_status',
                    width_in_chars = 62,
                    height_in_lines = 2,
                    wrap = true,
                },

                f:separator { fill_horizontal = 1 },

                f:row {
                    spacing = f:label_spacing(),

                    f:static_text {
                        title = 'Destination:',
                        width = 105,
                        alignment = 'right',
                    },

                    f:static_text {
                        title = bind 'gie_destinationPath',
                        width_in_chars = 38,
                        truncation = 'middle',
                    },

                    f:push_button {
                        title = 'Choose…',
                        action = function()
                            local result = LrDialogs.runOpenPanel {
                                title = 'Choose Grid Index Export Destination',
                                prompt = 'Choose',
                                canChooseFiles = false,
                                canChooseDirectories = true,
                                allowsMultipleSelection = false,
                            }

                            if result and result[1] then
                                propertyTable.gie_destinationPath = result[1]
                            end
                        end,
                    },
                },

                f:row {
                    spacing = f:label_spacing(),

                    f:static_text {
                        title = 'Custom Name:',
                        width = 105,
                        alignment = 'right',
                    },

                    f:edit_field {
                        value = bind 'gie_customName',
                        immediate = true,
                        width_in_chars = 28,
                    },
                },

                f:row {
                    spacing = f:label_spacing(),

                    f:static_text {
                        title = 'Separator:',
                        width = 105,
                        alignment = 'right',
                    },

                    f:edit_field {
                        value = bind 'gie_separator',
                        immediate = true,
                        width_in_chars = 6,
                    },

                    f:static_text { title = 'Padding:' },

                    f:popup_menu {
                        value = bind 'gie_padding',
                        items = {
                            { title = 'None', value = 0 },
                            { title = '1 digit', value = 1 },
                            { title = '2 digits', value = 2 },
                            { title = '3 digits', value = 3 },
                            { title = '4 digits', value = 4 },
                            { title = '5 digits', value = 5 },
                            { title = '6 digits', value = 6 },
                            { title = '7 digits', value = 7 },
                            { title = '8 digits', value = 8 },
                        },
                    },
                },

                f:row {
                    spacing = f:label_spacing(),

                    f:static_text {
                        title = 'Original sequence start:',
                        width = 105,
                        alignment = 'right',
                    },

                    f:edit_field {
                        value = bind 'gie_sequenceStart',
                        immediate = true,
                        width_in_chars = 6,
                    },

                    f:static_text {
                        title = '(normally 1)',
                    },
                },

                f:row {
                    spacing = f:label_spacing(),

                    f:static_text {
                        title = 'Example:',
                        width = 105,
                        alignment = 'right',
                    },

                    f:static_text {
                        title = bind 'gie_preview',
                        width_in_chars = 38,
                    },
                },

                f:row {
                    spacing = f:label_spacing(),

                    f:static_text {
                        title = '',
                        width = 105,
                    },

                    f:checkbox {
                        title = 'Overwrite files if they already exist in this safety folder',
                        value = bind 'gie_overwriteExisting',
                    },
                },

                f:static_text {
                    title = 'The plug-in never writes to your original gallery unless you explicitly choose that folder as the destination.',
                    width_in_chars = 62,
                    height_in_lines = 2,
                    wrap = true,
                },
            },
        },
    }
end

function provider.updateExportSettings(exportSettings)
    -- Because exportLocation is hidden, Lightroom normally uses a temporary
    -- folder automatically. Set these explicitly as a defensive measure.
    exportSettings.LR_export_destinationType = 'tempFolder'
    exportSettings.LR_renamingTokensOn = false
    exportSettings.LR_collisionHandling = 'rename'
    exportSettings.LR_reimportExportedPhoto = false

    updateCantExportBecause(exportSettings)
end

function provider.processRenderedPhotos(functionContext, exportContext)
    local exportSettings = assert(exportContext.propertyTable)
    local destination = LrPathUtils.standardizePath(trim(exportSettings.gie_destinationPath))
    local customName = trim(exportSettings.gie_customName)
    local separator = tostring(exportSettings.gie_separator or '')
    local padding = tonumber(exportSettings.gie_padding) or 4
    local sequenceStart = tonumber(exportSettings.gie_sequenceStart) or 1
    local overwriteExisting = exportSettings.gie_overwriteExisting == true
    local indexMap = parseIndexMap(exportSettings.gie_indexMap)

    local nPhotos = exportContext.exportSession:countRenditions()
    local progressScope = exportContext:configureProgress {
        title = nPhotos == 1 and 'Exporting 1 photo by Grid Index' or ('Exporting ' .. tostring(nPhotos) .. ' photos by Grid Index'),
    }

    for _, rendition in exportContext:renditions {
        progressScope = progressScope,
        stopIfCanceled = true,
    } do
        local success, pathOrMessage = rendition:waitForRender()

        if not success then
            rendition:uploadFailed(pathOrMessage)
        else
            local photo = rendition.photo
            local gridIndex = photo and indexMap[photo.localIdentifier] or nil

            if not gridIndex then
                rendition:uploadFailed('No captured Grid Index was found for this photo. Reopen Export and try again.')
            else
                local sequenceNumber = gridIndex + sequenceStart - 1
                local extension = LrPathUtils.extension(pathOrMessage) or ''
                local stem = customName .. separator .. formatIndex(sequenceNumber, padding)
                local targetName = extension ~= '' and (stem .. '.' .. extension) or stem
                local targetPath = LrPathUtils.child(destination, targetName)

                local existing = LrFileUtils.exists(targetPath)
                if existing and not overwriteExisting then
                    rendition:uploadFailed('Target file already exists: ' .. targetName)
                else
                    local canContinue = true

                    if existing then
                        local deleted, deleteMessage = LrFileUtils.delete(targetPath)
                        if not deleted then
                            rendition:uploadFailed('Could not replace existing file ' .. targetName .. ': ' .. tostring(deleteMessage))
                            canContinue = false
                        end
                    end

                    if canContinue then
                        local copied, copyMessage = LrFileUtils.copy(pathOrMessage, targetPath)
                        if not copied then
                            rendition:uploadFailed('Could not create ' .. targetName .. ': ' .. tostring(copyMessage))
                        end
                    end
                end
            end
        end
    end
end

return provider
