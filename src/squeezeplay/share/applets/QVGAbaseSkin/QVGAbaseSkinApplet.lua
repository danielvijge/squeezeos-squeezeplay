
--[[
=head1 NAME

applets.QVGAbaseSkin.QVGAbaseSkinApplet - The skin base for any 320x240 or 240x320 screen 

=head1 DESCRIPTION

This applet implements the base skin for Qvga screens

=head1 FUNCTIONS

Applet related methods are described in L<jive.Applet>.

=cut
--]]


-- stuff we use
local ipairs, pairs, setmetatable, type = ipairs, pairs, setmetatable, type

local oo                     = require("loop.simple")

local Applet                 = require("jive.Applet")
local Audio                  = require("jive.ui.Audio")
local Font                   = require("jive.ui.Font")
local Framework              = require("jive.ui.Framework")
local Icon                   = require("jive.ui.Icon")
local Label                  = require("jive.ui.Label")
local RadioButton            = require("jive.ui.RadioButton")
local RadioGroup             = require("jive.ui.RadioGroup")
local SimpleMenu             = require("jive.ui.SimpleMenu")
local Surface                = require("jive.ui.Surface")
local Textarea               = require("jive.ui.Textarea")
local Tile                   = require("jive.ui.Tile")
local Window                 = require("jive.ui.Window")

local table                  = require("jive.utils.table")
local debug                  = require("jive.utils.debug")
local autotable              = require("jive.utils.autotable")

local LAYER_FRAME            = jive.ui.LAYER_FRAME
local LAYER_CONTENT_ON_STAGE = jive.ui.LAYER_CONTENT_ON_STAGE

local LAYOUT_NORTH           = jive.ui.LAYOUT_NORTH
local LAYOUT_EAST            = jive.ui.LAYOUT_EAST
local LAYOUT_SOUTH           = jive.ui.LAYOUT_SOUTH
local LAYOUT_WEST            = jive.ui.LAYOUT_WEST
local LAYOUT_CENTER          = jive.ui.LAYOUT_CENTER
local LAYOUT_NONE            = jive.ui.LAYOUT_NONE

local WH_FILL                = jive.ui.WH_FILL

local jiveMain               = jiveMain
local appletManager          = appletManager


module(..., Framework.constants)
oo.class(_M, QVGAbaseSkinApplet)


-- Define useful variables for this skin
local imgpath = "applets/QVGAbaseSkin/images/"
local fontpath = "fonts/"
local FONT_NAME = "FreeSans"
local BOLD_PREFIX = "Bold"


function init(self)
	self.images = {}
	-- not just yet
--	self.C = self:getConstants()
end


function getConstants(self)
	-- define common constants
	local CONSTANTS =  {
	}
	self:addChildConstants(CONSTANTS)
end


function addChildConstants(self, CONSTANTS)
	assert(false)
end


function param(self)
	return {
		THUMB_SIZE = 41,
		NOWPLAYING_MENU = true,
		nowPlayingBrowseArtworkSize = 154,
		nowPlayingSSArtworkSize     = 186,
		nowPlayingLargeArtworkSize  = 240,
        }
end


-- reuse images instead of loading them twice
-- FIXME can be removed after Bug 10001 is fixed
function _loadImage(self, file)
	if not self.images[file] then
		self.images[file] = Surface:loadImage(imgpath .. file)
	end

	return self.images[file]
end


-- define a local function to make it easier to create icons.
function _icon(self, x, y, img)
	local var = {}
	var.x = x
	var.y = y
	var.img = _loadImage(self, img)
	var.layer = LAYER_FRAME
	var.position = LAYOUT_SOUTH

	return var
end

-- define a local function that makes it easier to set fonts
function _font(fontSize)
	return Font:load(fontpath .. FONT_NAME .. ".ttf", fontSize)
end

-- define a local function that makes it easier to set bold fonts
function _boldfont(fontSize)
	return Font:load(fontpath .. FONT_NAME .. BOLD_PREFIX .. ".ttf", fontSize)
end

-- defines a new style that inherrits from an existing style
function _uses(parent, value)
	if parent == nil then
		log:warn("nil parent in _uses at:\n", debug.traceback())
	end
	local style = {}
	setmetatable(style, { __index = parent })
	for k,v in pairs(value or {}) do
		if type(v) == "table" and type(parent[k]) == "table" then
			-- recursively inherrit from parent style
			style[k] = _uses(parent[k], v)
		else
			style[k] = v
		end
	end

	return style
end


-- skin
-- The meta arranges for this to be called to skin Jive.
function skin(self, s, reload, useDefaultSize)
	local screenWidth, screenHeight = Framework:getScreenSize()

	--init lastInputType so selected item style is not shown on skin load
	Framework.mostRecentInputType = "scroll"

	s.img = {}

	-- Images and Tiles
	s.img.iconBackground =
		Tile:loadVTiles({
					imgpath .. "Toolbar/toolbar_highlight.png",
					imgpath .. "Toolbar/toolbar.png",
					nil,
			       })

	s.img.titleBox =
		Tile:loadVTiles({
					nil,
				       imgpath .. "Titlebar/titlebar.png",
				       imgpath .. "Titlebar/titlebar_shadow.png",
			       })
	s.img.textinputBackground =
		Tile:loadHTiles({
					imgpath .. "UNOFFICIAL/text_entry_bkgrd_l.png",
					imgpath .. "UNOFFICIAL/text_entry_bkgrd.png",
					imgpath .. "UNOFFICIAL/text_entry_bkgrd_r.png",
			       })

	s.img.textinputWheel      = Tile:loadImage(imgpath .. "UNOFFICIAL/text_entry_select.png")
	s.img.textinputCursor     = Tile:loadImage(imgpath .. "UNOFFICIAL/text_entry_letter.png")
	s.img.textinputRightArrow = Tile:loadImage(imgpath .. "Icons/selection_right_sel.png")


	s.img.oneLineItemSelectionBox =
		Tile:loadHTiles({
				       --imgpath .. "Menu_Lists/menu_sel_box_l.png",
					nil,
				       imgpath .. "Menu_Lists/menu_sel_box.png",
				       imgpath .. "Menu_Lists/menu_sel_box_r.png",
			       })

	s.img.sliderBackground =
		Tile:loadHTiles({
					imgpath .. "Song_Progress_Bar/progressbar_bkgrd_l.png",
					imgpath .. "Song_Progress_Bar/progressbar_bkgrd.png",
					imgpath .. "Song_Progress_Bar/progressbar_bkgrd_r.png",
			       })

	s.img.sliderBar =
		Tile:loadHTiles({
					nil, nil,
					imgpath .. "Song_Progress_Bar/progressbar_slider.png",
			       })

	s.img.volumeBar =
		Tile:loadHTiles({
					-- FIXME: need these still
					imgpath .. "MISSING_VOLUME_BAR",
					nil, nil
			       })

	s.img.volumeBackground =
		Tile:loadHTiles({
					-- FIXME: need these still
					imgpath .. "MISSING_VOLUME_BACKGROUND",
					nil, nil
				})

	s.img.popupMask = Tile:fillColor(0x000000e5)

	s.img.blackBackground = Tile:fillColor(0x000000ff)

	local THUMB_SIZE = self:param().THUMB_SIZE

	local TITLE_PADDING  = 0
	local CHECK_PADDING  = { 0, 0, 0, 0 }
	local CHECKBOX_RADIO_PADDING  = { 2, 8, 8, 0 }

	local MENU_ALBUMITEM_PADDING = { 4, 2, 4, 2 }
	local MENU_ALBUMITEM_TEXT_PADDING = { 10, 8, 8, 9 }
	local MENU_PLAYLISTITEM_TEXT_PADDING = { 6, 6, 8, 10 }

	local MENU_CURRENTALBUM_TEXT_PADDING = { 6, 20, 0, 10 }
	local TEXTAREA_PADDING = { 13, 8, 8, 8 }

	local MENU_ITEM_ICON_PADDING = { 0, 0, 10, 0 }
	local TEXT_COLOR = { 0xE7, 0xE7, 0xE7 }
	local TEXT_COLOR_BLACK = { 0x00, 0x00, 0x00 }
	local TEXT_SH_COLOR = { 0x37, 0x37, 0x37 }

	local SELECT_COLOR = TEXT_COLOR
	local SELECT_SH_COLOR = { }


        local TITLE_FONT_SIZE = 18
        local ALBUMMENU_TITLE_FONT_SIZE = 14
        local ALBUMMENU_FONT_SIZE = 14
        local ALBUMMENU_SMALL_FONT_SIZE = 14
        local ALBUMMENU_SELECTED_FONT_SIZE = 14
        local ALBUMMENU_SELECTED_SMALL_FONT_SIZE = 14
        local TEXTMENU_FONT_SIZE = 15
        local TEXTMENU_SELECTED_FONT_SIZE = 18
        local POPUP_TEXT_SIZE_1 = 14
        local POPUP_TEXT_SIZE_2 = 22
        local TEXTAREA_FONT_SIZE = 16
        local CENTERED_TEXTAREA_FONT_SIZE = 28
        local TEXTINPUT_FONT_SIZE = 16
        local TEXTINPUT_SELECTED_FONT_SIZE = 24
        local HELP_FONT_SIZE = 16
	local UPDATE_SUBTEXT_SIZE = 20
	local ICONBAR_FONT = 12

	local ITEM_ICON_ALIGN   = 'right'
	local ONE_LINE_ITEM_HEIGHT = 27
	local FOUR_LINE_ITEM_HEIGHT = 45
	local TITLE_BUTTON_WIDTH = 76
	local TITLE_BUTTON_HEIGHT = 47
	local TITLE_BUTTON_PADDING = { 4, 0, 4, 0 }


	s.img.smallSpinny = {
		-- FIXME: need this asset
		img = _loadImage(self, "UNOFFICIAL/wifi_connecting_sm.png"),
		frameRate = 8,
		frameWidth = 26,
		padding = { 4, 0, 0, 0 },
		h = WH_FILL,
	}

	s.img.playArrow = {
		img = _loadImage(self, "Icons/selection_play_sel.png"),
		h = WH_FILL
	}
	s.img.addArrow  = {
		img = _loadImage(self, "Icons/selection_ad_sel.png"),
		h = WH_FILL
	}
	s.img.rightArrowSel = {
		img = _loadImage(self, "Icons/selection_right_sel.png"),
		padding = { 4, 0, 0, 0 },
		h = WH_FILL,
		align = "center",
	}
	s.img.rightArrow = {
		img = _loadImage(self, "Icons/selection_right_off.png"),
		padding = { 4, 0, 0, 0 },
		h = WH_FILL,
		align = "center",
	}
	s.img.checkMark = {
		align = ITEM_ICON_ALIGN,
		padding = CHECK_PADDING,
		img = _loadImage(self, "Icons/icon_check_off.png"),
	}
	s.img.checkMarkSelected = {
		align = ITEM_ICON_ALIGN,
		padding = CHECK_PADDING,
		img = _loadImage(self, "Icons/icon_check_sel.png"),
	}


--------- DEFAULT WIDGET STYLES ---------
	--
	-- These are the default styles for the widgets

	s.window = {
		w = screenWidth,
		h = screenHeight,
	}

	-- window with absolute positioning
	s.absolute = _uses(s.window, {
		layout = Window.noLayout,
	})

	s.popup = _uses(s.window, {
		border = { 0, 0, 0, 0 },
		maskImg = s.img.popupMask,
	})

	s.title = {
		h = 31,
		border = 0,
		position = LAYOUT_NORTH,
		bgImg = s.img.titleBox,
		order = { "text" },
		text = {
			w = WH_FILL,
			h = WH_FILL,
			padding = { 8, 7, 0, 9 },
			align = 'center',
			font = _boldfont(TITLE_FONT_SIZE),
			fg = SELECT_COLOR,
			sh = SELECT_SH_COLOR,
		},
	}

	s.menu = {
		h = 243,
		position = LAYOUT_CENTER,
		padding = { 0, 0, 4, 2 },
		border = { 0, 0, 5, 0 },
		itemHeight = FOUR_LINE_ITEM_HEIGHT,
	}

	s.item = {
		order = { "icon", "text", "arrow" },
		padding = { 10, 6, 6, 6 },
		text = {
			padding = { 0, 0, 0, 0 },
			align = "left",
			w = WH_FILL,
			h = WH_FILL,
			font = _boldfont(TEXTMENU_FONT_SIZE),
			fg = TEXT_COLOR,
			sh = TEXT_SH_COLOR,
		},
		icon = {
			border = MENU_ITEM_ICON_PADDING,
			align = 'center',
			w = THUMB_SIZE,
			h = THUMB_SIZE,
		},
		arrow = s.img.rightArrow,
	}

	s.item_play = _uses(s.item)
	s.item_add = _uses(s.item)

	-- Checkbox
        s.checkbox = {}
        s.checkbox.img_on = _loadImage(self, "Icons/checkbox_on.png")
        s.checkbox.img_off = _loadImage(self, "Icons/checkbox_off_sel.png")


        -- Radio button
        s.radio = {}
        s.radio.img_on = _loadImage(self, "Icons/radiobutton_on.png")
        s.radio.img_off = _loadImage(self, "Icons/radiobutton_off.png")
		
	s.choice = {
		align = 'right',
		font = _boldfont(TEXTMENU_FONT_SIZE),
		fg = TEXT_COLOR,
		sh = TEXT_SH_COLOR,
		h = WH_FILL,
	}

	s.item_choice = _uses(s.item, {
		order  = { 'icon', 'text', 'check' },
		check = {
			align = 'right',
			h = WH_FILL,
		},
	})
	s.item_checked = _uses(s.item, {
		order = { 'icon', "text", "check" },
		check = s.img.checkMark,
	})

	s.item_no_arrow = _uses(s.item, {
		order = { 'icon', 'text' },
	})
	s.item_checked_no_arrow = _uses(s.item, {
		order = { 'icon', 'text', 'check' },
	})

        -- selected menu item
        s.selected = {}
	s.selected.item = _uses(s.item, {
		order = { 'icon', 'text', 'arrow' },
		text = {
			font = _boldfont(TEXTMENU_SELECTED_FONT_SIZE),
			fg = SELECT_COLOR,
			sh = SELECT_SH_COLOR
		},
		bgImg = s.img.oneLineItemSelectionBox,
		arrow = s.img.rightArrowSel,
	})
	--FIXME: doesn't seem to take effect...
	s.selected.choice = _uses(s.choice, {
		fg = SELECT_COLOR,
		sh = SELECT_SH_COLOR,
	})
	s.selected.item_choice = _uses(s.selected.item, {
		order = { 'icon', 'text', 'check' },
		check = {
			align = 'right',
			font = _boldfont(TEXTMENU_FONT_SIZE),
			fg = SELECT_COLOR,
			sh = SELECT_SH_COLOR,
		},
	})

	s.selected.item_play = _uses(s.selected.item, {
		arrow = s.img.playArrow
	})
	s.selected.item_add = _uses(s.selected.item, {
		arrow = s.img.addArrow
	})
	s.selected.item_checked = _uses(s.selected.item, {
		order = { "text", "check", "arrow" },
		check = s.img.checkMarkSelected,
	})
        s.selected.item_no_arrow = _uses(s.selected.item, {
		order = { 'text' },
	})
        s.selected.item_checked_no_arrow = _uses(s.selected.item, {
		order = { 'text', 'check' },
		check = s.img.checkMark,
	})

	s.pressed = {
		item = _uses(s.selected.item, {
			bgImg = threeItemPressedBox,
		}),
		item_checked = _uses(s.selected.item_checked, {
			bgImg = threeItemPressedBox,
		}),
		item_play = _uses(s.selected.item_play, {
			bgImg = threeItemPressedBox,
		}),
		item_add = _uses(s.selected.item_add, {
			bgImg = threeItemPressedBox,
		}),
		item_no_arrow = _uses(s.selected.item_no_arrow, {
			bgImg = threeItemPressedBox,
		}),
		item_checked_no_arrow = _uses(s.selected.item_checked_no_arrow, {
			bgImg = threeItemPressedBox,
		}),
		item_choice = _uses(s.selected.item_choice, {
			bgImg = threeItemPressedBox,
		}),
	}

	s.locked = {
		item = _uses(s.pressed.item, {
			arrow = s.img.smallSpinny
		}),
		item_checked = _uses(s.pressed.item_checked, {
			arrow = s.img.smallSpinny
		}),
		item_play = _uses(s.pressed.item_play, {
			arrow = s.img.smallSpinny
		}),
		item_add = _uses(s.pressed.item_add, {
			arrow = s.img.smallSpinny
		}),
		item_no_arrow = _uses(s.pressed.item_no_arrow, {
			arrow = s.img.smallSpinny
		}),
		item_checked_no_arrow = _uses(s.pressed.item_checked_no_arrow, {
			arrow = s.img.smallSpinny
		}),
	}
	s.item_blank = {
		padding = {  },
		text = {},
	}

	s.pressed.item_blank = _uses(s.item_blank)
	s.selected.item_blank = _uses(s.item_blank)

	s.help_text = {
		w = screenWidth - 10,
		padding = TEXTAREA_PADDING,
		font = _boldfont(TEXTAREA_FONT_SIZE - 2),
		lineHeight = TEXTAREA_FONT_SIZE - 2 + 5,
		fg = TEXT_COLOR,
		sh = TEXT_SH_COLOR,
		align = "top-left",
	}

        s.help_text_small = _uses(s.help_text,{
                padding = { 18, 6, 0, 2 },
                font = _font(14),
                lineHeight = 16,
        })

	s.text = {
		w = screenWidth,
		padding = TEXTAREA_PADDING,
		font = _boldfont(TEXTAREA_FONT_SIZE),
		fg = TEXT_COLOR,
		sh = TEXT_SH_COLOR,
		align = "left",
	}

	s.slider = {
		border = 5,
		w = WH_FILL,
		horizontal = 1,
		bgImg = s.img.sliderBackground,
		img = s.img.sliderBar,
	}

	s.slider_group = {
		w = WH_FILL,
		border = { 15, 5, 7, 10 },
		order = { "min", "slider", "max" },
	}


--------- SPECIAL WIDGETS ---------


	-- text input
	s.textinput = {
		border     = { 8, -5, 8, 0 },
		padding    = { 6, 0, 6, 0 },
		font       = _font(TEXTINPUT_FONT_SIZE),
		cursorFont = _boldfont(TEXTINPUT_SELECTED_FONT_SIZE),
		wheelFont  = _boldfont(TEXTINPUT_FONT_SIZE),
		charHeight = TEXTINPUT_SELECTED_FONT_SIZE + 2,
		fg         = TEXT_COLOR_BLACK,
		wh         = { 0x55, 0x55, 0x55 },
		bgImg      = s.img.textinputBackground,
		cursorImg  = s.img.textinputCursor,
		wheelImg   = s.img.textinputWheel,
		enterImg   = s.img.textinputRightArrow,
	}


--------- WINDOW STYLES ---------
	--
	-- These styles override the default styles for a specific window

	-- typical text list window
	s.text_list = _uses(s.window)

	--hack until SC changes are in place
	s.text_list.title = _uses(s.title, {
		text = {
			line = {
					{
						font = _boldfont(ALBUMMENU_TITLE_FONT_SIZE + 5),
						height = ALBUMMENU_TITLE_FONT_SIZE + 6,
					},
					{
						font = _boldfont(ALBUMMENU_TITLE_FONT_SIZE - 4),
						height = ALBUMMENU_TITLE_FONT_SIZE -5,
					},
					{
						--minimize visibility of this...
						font = _font(1),
						height = 1,
					}
			},
		},
	})
	-- popup "spinny" window
	s.waiting_popup = _uses(s.popup)

	s.waiting_popup.text = {
		padding = { 0, 0, 0, 40 },
		fg = TEXT_COLOR,
		sh = TEXT_SH_COLOR,
		align = "center",
		position = LAYOUT_SOUTH ,
		h = 16
	}

	s.waiting_popup.text.line = {
		{
			font = _boldfont(POPUP_TEXT_SIZE_1),
			height = 16,
		},
		{
			font = _boldfont(POPUP_TEXT_SIZE_2),
		},
	}

	s.waiting_popup.subtext = {
		padding = { 0, 0, 0, 32 },
		font = _boldfont(POPUP_TEXT_SIZE_2),
		fg = TEXT_COLOR,
		sh = TEXT_SH_COLOR,
		align = "center",
		position = LAYOUT_SOUTH,
--		h = 40,
	}

	-- input window (including keyboard)
	-- XXX: needs layout
	s.input = _uses(s.window)

	-- error window
	-- XXX: needs layout
	s.error = _uses(s.window)

	-- update window
	s.update_popup = _uses(s.popup)

	s.update_popup.subtext = {
		padding = { 0, 0, 0, 60 },
		font = _boldfont(POPUP_TEXT_SIZE_1),
		fg = TEXT_COLOR,
		sh = TEXT_SH_COLOR,
		align = "center",
		position = LAYOUT_SOUTH,
	}

	s.update_popup.text = {
		padding = { 0, 14, 0, 0 },
		fg = TEXT_COLOR,
		sh = TEXT_SH_COLOR,
		align = "center",
		position = LAYOUT_SOUTH ,
	}

	s.update_popup.text.line = {
		{
			font = _boldfont(POPUP_TEXT_SIZE_1),
			height = 16,
		},
		{
			font = _boldfont(POPUP_TEXT_SIZE_2),
		},
	}

	-- icon_list window
	s.icon_list = _uses(s.window, {
		menu = _uses(s.menu, {
			itemHeight = FOUR_LINE_ITEM_HEIGHT,
			item = {
				order = { "icon", "text", "arrow" },
				padding = MENU_ALBUMITEM_PADDING,
				text = {
					align = "top-left",
					w = WH_FILL,
					h = WH_FILL,
					padding = MENU_ALBUMITEM_TEXT_PADDING,
					font = _font(ALBUMMENU_SMALL_FONT_SIZE),
					line = {
						{
							font = _boldfont(ALBUMMENU_FONT_SIZE),
							height = ALBUMMENU_FONT_SIZE + 2
						}
					},
					fg = TEXT_COLOR,
					sh = TEXT_SH_COLOR,
				},
				icon = {
					w = THUMB_SIZE,
					h = THUMB_SIZE,
				},
				arrow = s.img.rightArrow,
			},
		}),
	})


	s.icon_list.menu.item_checked = _uses(s.icon_list.menu.item, {
		order = { 'icon', 'text', 'check' },
		check = {
			align = ITEM_ICON_ALIGN,
			padding = CHECK_PADDING,
			img = _loadImage(self, "Icons/icon_check_off.png")
		},
	})

	s.icon_list.menu.albumcurrent = _uses(s.icon_list.menu.item_checked)
	s.icon_list.menu.item_play = _uses(s.icon_list.menu.item)
	s.icon_list.menu.item_add  = _uses(s.icon_list.menu.item)
	s.icon_list.menu.item_no_arrow = _uses(s.icon_list.menu.item)
	s.icon_list.menu.item_checked_no_arrow = _uses(s.icon_list.menu.item_checked)

	s.icon_list.menu.selected = {}
	s.icon_list.menu.selected.item = _uses(s.icon_list.menu.item, {
		order = { 'icon', 'text', 'arrow' },
		text = {
			fg = SELECT_COLOR,
			sh = SELECT_SH_COLOR,
		},
		bgImg = s.img.oneLineItemSelectionBox,
		arrow = s.img.rightArrowSel,
	})

	s.icon_list.menu.selected.item_checked          = _uses(s.icon_list.menu.selected.item, {
		order = { 'icon', 'text', 'check', 'arrow' },
	})
	s.icon_list.menu.selected.albumcurrent          = _uses(s.icon_list.menu.selected.item, {
	})
	s.icon_list.menu.selected.item_play             = _uses(s.icon_list.menu.selected.item, {
		arrow = s.img.playArrow,
	})
	s.icon_list.menu.selected.item_add              = _uses(s.icon_list.menu.selected.item, {
		arrow = s.img.addArrow,
	})
	s.icon_list.menu.selected.item_no_arrow         = _uses(s.icon_list.menu.selected.item, {
		order = { 'icon', 'text' },
	})
	s.icon_list.menu.selected.item_checked_no_arrow = _uses(s.icon_list.menu.selected.item, {
		order = { 'icon', 'text', 'check' },
		check = s.img.checkMark,
	})

        s.icon_list.menu.pressed = {
                item = _uses(s.icon_list.menu.selected.item, {
			bgImg = threeItemPressedBox
		}),
                item_checked = _uses(s.icon_list.menu.selected.item_checked, {
			bgImg = threeItemPressedBox
		}),
                item_play = _uses(s.icon_list.menu.selected.item_play, {
			bgImg = threeItemPressedBox
		}),
                item_add = _uses(s.icon_list.menu.selected.item_add, {
			bgImg = threeItemPressedBox
		}),
                item_no_arrow = _uses(s.icon_list.menu.selected.item_no_arrow, {
			bgImg = threeItemPressedBox
		}),
                item_checked_no_arrow = _uses(s.icon_list.menu.selected.item_checked_no_arrow, {
			bgImg = threeItemPressedBox
		}),
        }
	s.icon_list.menu.locked = {
		item = _uses(s.icon_list.menu.pressed.item, {
			arrow = s.img.smallSpinny
		}),
		item_checked = _uses(s.icon_list.menu.pressed.item_checked, {
			arrow = s.img.smallSpinny
		}),
		item_play = _uses(s.icon_list.menu.pressed.item_play, {
			arrow = s.img.smallSpinny
		}),
		item_add = _uses(s.icon_list.menu.pressed.item_add, {
			arrow = s.img.smallSpinny
		}),
	}


	-- information window
	s.information = _uses(s.window)


	-- help window (likely the same as information)
	s.help_info = _uses(s.window)


	--track_list window
	-- XXXX todo
	s.track_list = _uses(s.text_list)

	s.track_list.title = _uses(s.title, {
		h = FOUR_LINE_ITEM_HEIGHT - 1,
		border = 4,
		order = { 'icon', 'text' },
		icon  = {
			w = THUMB_SIZE,
			h = WH_FILL,
			padding = { 9,0,0,0 },
		},
		text = {
			padding = MENU_ALBUMITEM_TEXT_PADDING,
			align = "top-left",
			font = _font(ALBUMMENU_TITLE_FONT_SIZE),
			lineHeight = ALBUMMENU_TITLE_FONT_SIZE + 1,
			line = {
					{
						font = _boldfont(ALBUMMENU_TITLE_FONT_SIZE),
						height = ALBUMMENU_TITLE_FONT_SIZE + 2,
					}
			},
		},
	})

	--playlist window
	-- identical to icon_list but with some different formatting on the text
	s.play_list = _uses(s.icon_list, {
		title = {
			order = { 'text' },
		},
		menu = {
			item = {
				text = {
					padding = MENU_PLAYLISTITEM_TEXT_PADDING,
					font = _font(ALBUMMENU_FONT_SIZE),
					lineHeight = 16,
					line = {
						{
							font = _boldfont(ALBUMMENU_FONT_SIZE),
							height = ALBUMMENU_FONT_SIZE + 3
						},
					},
				},
			},
		},
	})
	s.play_list.menu.item_checked = _uses(s.play_list.menu.item, {
		order = { 'icon', 'text', 'check', 'arrow' },
		check = {
			align = ITEM_ICON_ALIGN,
			padding = CHECK_PADDING,
			img = _loadImage(self, "Icons/icon_check_off.png")
		},
	})
	s.play_list.menu.selected = {
                item = _uses(s.play_list.menu.item, {
			text = {
				fg = SELECT_COLOR,
				sh = SELECT_SH_COLOR,
			},
			bgImg = s.img.oneLineItemSelectionBox,
		}),
                item_checked = _uses(s.play_list.menu.item_checked),
        }
        s.play_list.menu.pressed = {
                item = _uses(s.play_list.menu.item, { bgImg = threeItemPressedBox }),
                item_checked = _uses(s.play_list.menu.item_checked, { bgImg = threeItemPressedBox }),
        }
	s.play_list.menu.locked = {
		item = _uses(s.play_list.menu.pressed.item, {
			arrow = s.img.smallSpinny
		}),
		item_checked = _uses(s.play_list.menu.pressed.item_checked, {
			arrow = s.img.smallSpinny
		}),
	}


	-- toast_popup popup
	s.toast_popup = {
		x = 0,
		y = screenHeight - 93,
		w = screenWidth,
		h = 93,
		bgImg = s.img.helpBox,
		group = {
			padding = { 12, 12, 12, 0 },
			order = { 'icon', 'text' },
			text = {
				padding = { 6, 3, 8, 8 } ,
				align = 'top-left',
				w = WH_FILL,
				h = WH_FILL,
				font = _font(HELP_FONT_SIZE),
				lineHeight = 17,
				line = {
					{
						font = _boldfont(HELP_FONT_SIZE),
						height = 17
					},
				},
			},
			icon = {
				align = 'top-left',
				border = { 12, 12, 0, 0 },
				-- FIXME: need this asset
				img = _loadImage(self, "MISSING_PLACEHOLDER_ARTWORK"),
				h = WH_FILL,
				w = THUMB_SIZE,
			}
		}
	}

	-- slider popup (volume/scanner)
	s.slider_popup = {
		x = 0,
		y = screenHeight - 80,
		w = screenWidth,
		h = 80,
		bgImg = s.img.helpBox,
		title = {
		      border = 10,
		      fg = TEXT_COLOR,
		      font = _boldfont(HELP_FONT_SIZE),
		      align = "center",
		      bgImg = false,
		},
		slider_group = {
			w = WH_FILL,
			--border = { 0, 5, 0, 10 },
			order = { "min", "slider", "max" },
			max = {
				align = 'right',
			},
			min = {
				align = 'left',
			},
			text = {
				w = 75,
				align = 'right',
				padding = { 8, 0, 8, 15 },
				font = _boldfont(HELP_FONT_SIZE),
				fg = TEXT_COLOR,
				sh = TEXT_SH_COLOR,
			}
		},
	}

	s.image_popup = _uses(s.popup, {
		image = {
			align = "center",
		},
	})


--------- SLIDERS ---------


	s.volume_slider = _uses(s.slider, {
		img = s.img.volumeBar,
		bgImg = s.img.volumeBackground,
	})

	s.scanner_slider = _uses(s.slider, {
		img = s.img.volumeBar,
		bgImg = s.img.volumeBackground,
	})


--------- BUTTONS ---------


--------- ICONS --------

	-- icons used for 'waiting' and 'update' windows
	s._icon = {
		w = WH_FILL,
		align = "center",
		position = LAYOUT_CENTER,
		padding = { 0, 0, 0, 10 }
	}

	-- icon for albums with no artwork
	s.icon_no_artwork = {
		--FIXME: need this asset
		img = _loadImage(self, "MISSING_PLACEHOLDER_ARTWORK"),
		w   = THUMB_SIZE,
		h   = THUMB_SIZE,
	}

	s.icon_connecting = _uses(s._icon, {
		img = _loadImage(self, "UNOFFICIAL/wifi_connecting.png"),
		frameRate = 8,
		frameWidth = 120,
		padding = { 0, 20, 0, 10 }
	})

	s.icon_connected = _uses(s._icon, {
		img = _loadImage(self, "UNOFFICIAL/connecting_success_icon.png"),
	})

	s.icon_software_update = _uses(s.icon_connecting)

	s.icon_power = _uses(s._icon, {
		img = _loadImage(self, "MISSING_POWER_ICON"),
	})

	s.icon_locked = _uses(s._icon, {
		img = _loadImage(self, "MISSING_LOCKED_ICON"),
	})

	s.icon_alarm = _uses(s._icon, {
		img = _loadImage(self, "MISSING_ALARM_ICON"),
	})

	-- button icons, on left of menus
	s._buttonicon = {
		border = MENU_ITEM_ICON_PADDING,
		align = 'center',
		w = THUMB_SIZE,
		h = THUMB_SIZE,
	}

	s.player_transporter = _uses(s._buttonicon, {
		img = _loadImage(self, "IconsResized/icon_transporter.png"),
	})
	s.player_squeezebox = _uses(s._buttonicon, {
		img = _loadImage(self, "IconsResized/icon_SB1n2.png"),
	})
	s.player_squeezebox2 = _uses(s._buttonicon, {
		img = _loadImage(self, "IconsResized/icon_SB1n2.png"),
	})
	s.player_squeezebox3 = _uses(s._buttonicon, {
		img = _loadImage(self, "IconsResized/icon_SB3.png"),
	})
	s.player_boom = _uses(s._buttonicon, {
		img = _loadImage(self, "IconsResized/icon_boom.png"),
	})
	s.player_slimp3 = _uses(s._buttonicon, {
		img = _loadImage(self, "IconsResized/icon_slimp3.png"),
	})
	s.player_softsqueeze = _uses(s._buttonicon, {
		img = _loadImage(self, "IconsResized/icon_softsqueeze.png"),
	})
	s.player_controller = _uses(s._buttonicon, {
		img = _loadImage(self, "IconsResized/icon_controller.png"),
	})
	s.player_receiver = _uses(s._buttonicon, {
		img = _loadImage(self, "IconsResized/icon_receiver.png"),
	})
	s.player_squeezeplay = _uses(s._buttonicon, {
		img = _loadImage(self, "IconsResized/icon_squeezeplay.png"),
	})
	s.player_http = _uses(s._buttonicon, {
		--FIXME: need an asset for this
		img = _loadImage(self, "MISSING_HTTPSTREAMING_PLAYER_ICON"),
	})

	-- misc home menu icons
	local skinSuffix = '_selected.png'
	s.hm_appletAppGuide = _uses(s._buttonicon, {
		img = _loadImage(self, "IconsResized/icon_app_guide" .. skinSuffix),
	})
	s.hm_music_services = _uses(s._buttonicon, {
		img = _loadImage(self, "IconsResized/icon_app_guide" .. skinSuffix),
	})
	s.hm_settings = _uses(s._buttonicon, {
		img = _loadImage(self, "IconsResized/icon_settings" .. skinSuffix),
	})
	s.hm_radio = _uses(s._buttonicon, {
		img = _loadImage(self, "IconsResized/icon_internet_radio" .. skinSuffix),
	})
	s.hm_myMusic = _uses(s._buttonicon, {
		img = _loadImage(self, "IconsResized/icon_mymusic" .. skinSuffix),
	})
	s.hm__myMusic = _uses(s.hm_myMusic)
	s.hm_myMusicSelector = _uses(s.hm_myMusic)

	s.hm_favorites = _uses(s._buttonicon, {
		img = _loadImage(self, "IconsResized/icon_favorites" .. skinSuffix),
	})
	s.hm_settingsAlarm = _uses(s._buttonicon, {
		img = _loadImage(self, "IconsResized/icon_alarm" .. skinSuffix),
	})
	s.hm_settingsSync = _uses(s._buttonicon, {
		img = _loadImage(self, "IconsResized/icon_sync" .. skinSuffix),
	})
	s.hm_selectPlayer = _uses(s._buttonicon, {
		img = _loadImage(self, "IconsResized/icon_choose_player" .. skinSuffix),
	})
	s.hm_quit = _uses(s._buttonicon, {
		img = _loadImage(self, "IconsResized/icon_power_off2" .. skinSuffix),
	})
	s.hm_settingsScreen = _uses(s._buttonicon, {
		img = _loadImage(self, "IconsResized/icon_blank" .. skinSuffix),
	})
	s.hm_myMusicArtists = _uses(s._buttonicon, {
		img = _loadImage(self, "IconsResized/icon_ml_artist" .. skinSuffix),
	})
	s.hm_myMusicAlbums = _uses(s._buttonicon, {
		img = _loadImage(self, "IconsResized/icon_ml_albums" .. skinSuffix),
	})
	s.hm_myMusicGenres = _uses(s._buttonicon, {
		img = _loadImage(self, "IconsResized/icon_ml_genres" .. skinSuffix),
	})
	s.hm_myMusicYears = _uses(s._buttonicon, {
		img = _loadImage(self, "IconsResized/icon_ml_years" .. skinSuffix),
	})

	s.hm_myMusicNewMusic = _uses(s._buttonicon, {
		img = _loadImage(self, "IconsResized/icon_ml_new_music" .. skinSuffix),
	})
	s.hm_myMusicPlaylists = _uses(s._buttonicon, {
		img = _loadImage(self, "IconsResized/icon_ml_playlist" .. skinSuffix),
	})
	s.hm_myMusicSearch = _uses(s._buttonicon, {
		img = _loadImage(self, "IconsResized/icon_ml_search" .. skinSuffix),
	})
	s.hm_myMusicSearchArtists = _uses(s._buttonicon, {
		img = _loadImage(self, "IconsResized/icon_ml_search" .. skinSuffix),
	})
	s.hm_myMusicSearchSongs = _uses(s._buttonicon, {
		img = _loadImage(self, "IconsResized/icon_ml_search" .. skinSuffix),
	})
	s.hm_myMusicSearchPlaylists = _uses(s._buttonicon, {
		img = _loadImage(self, "IconsResized/icon_ml_search" .. skinSuffix),
	})
	s.hm_myMusicMusicFolder = _uses(s._buttonicon, {
		img = _loadImage(self, "IconsResized/icon_ml_folder" .. skinSuffix),
	})
	s.hm_randomplay = _uses(s._buttonicon, {
		img = _loadImage(self, "IconsResized/icon_ml_random" .. skinSuffix),
	})
	s.hm_skinTest = _uses(s._buttonicon, {
		img = _loadImage(self, "IconsResized/icon_blank" .. skinSuffix),
	})
	s.hm_randomtracks = _uses(s.hm_randomplay)
	s.hm_randomartists = _uses(s.hm_randomplay)
	s.hm_randomalbums = _uses(s.hm_randomplay)
	s.hm_randomyears = _uses(s.hm_randomplay)

	s.hm_settingsBrightness = _uses(s._buttonicon, {
		img = _loadImage(self, "IconsResized/icon_settings_brightness" .. skinSuffix),
	})
	s.hm_settingsRepeat = _uses(s._buttonicon, {
		img = _loadImage(self, "IconsResized/icon_settings_repeat" .. skinSuffix),
	})
	s.hm_settingsShuffle = _uses(s._buttonicon, {
		img = _loadImage(self, "IconsResized/icon_settings_shuffle" .. skinSuffix),
	})
	s.hm_settingsSleep = _uses(s._buttonicon, {
		img = _loadImage(self, "IconsResized/icon_settings_sleep" .. skinSuffix),
	})
	s.hm_settingsScreen = _uses(s._buttonicon, {
		img = _loadImage(self, "IconsResized/icon_settings_screen" .. skinSuffix),
	})
	s.hm_appletCustomizeHome = _uses(s._buttonicon, {
		img = _loadImage(self, "IconsResized/icon_settings_home" .. skinSuffix),
	})
	s.hm_settingsAudio = _uses(s._buttonicon, {
		img = _loadImage(self, "IconsResized/icon_settings_audio" .. skinSuffix),
	})
	s.hm_linein = _uses(s._buttonicon, {
		img = _loadImage(self, "IconsResized/icon_linein" .. skinSuffix),
	})
	-- ??
	s.hm_loading = _uses(s._buttonicon, {
		img = _loadImage(self, "IconsResized/icon_loading" .. skinSuffix),
	})
	-- ??
	s.hm_settingsPlugin = _uses(s._buttonicon, {
		img = _loadImage(self, "IconsResized/icon_settings_plugin" .. skinSuffix),
	})

	-- indicator icons, on right of menus
	s._indicator = {
		align = "right",
	}

	s.wirelessLevel0 = _uses(s._indicator, {
		img = _loadImage(self, "Icons/icon_wireless_0_sel.png")
	})

	s.wirelessLevel1 = _uses(s._indicator, {
		img = _loadImage(self, "Icons/icon_wireless_1_sel.png")
	})

	s.wirelessLevel2 = _uses(s._indicator, {
		img = _loadImage(self, "Icons/icon_wireless_2_sel.png")
	})

	s.wirelessLevel3 = _uses(s._indicator, {
		img = _loadImage(self, "Icons/icon_wireless_3_sel.png")
	})

	s.wirelessLevel4 = _uses(s._indicator, {
		img = _loadImage(self, "Icons/icon_wireless_4_sel.png")
	})


--------- ICONBAR ---------

	s.iconbar_icon_width = 24

	-- button icons, on left of menus
	s._iconbar_icon = {
		h = WH_FILL,
		w = s.iconbar_icon_width,
		padding = { 0,0,0,0 },
		border = { 3, 0, 3, 0 },
		layer = LAYER_FRAME,
		position = LAYOUT_SOUTH,
	}

	s._button_playmode = _uses(s._iconbar_icon)
	s.button_playmode_OFF = _uses(s._button_playmode, {
		img = false,
	})
	s.button_playmode_STOP = _uses(s._button_playmode, {
		img = _loadImage(self, "MISSING_PLAYMODE_STOP_ICON"),
	})
	s.button_playmode_PLAY = _uses(s._button_playmode, {
		img = _loadImage(self, "Icons/icon_mode_play.png"),
	})
	s.button_playmode_PAUSE = _uses(s._button_playmode, {
		img = _loadImage(self, "Icons/icon_mode_pause.png"),
	})

	s._button_repeat = _uses(s._iconbar_icon)
	s.button_repeat_OFF = _uses(s._button_repeat, {
		img = false,
	})
	s.button_repeat_0 = _uses(s._button_repeat, {
		img = false,
	})
	s.button_repeat_1 = _uses(s._button_repeat, {
		img = _loadImage(self, "Icons/icon_repeat_song.png"),
	})
	s.button_repeat_2 = _uses(s._button_repeat, {
		img = _loadImage(self, "Icons/icon_repeat_on.png"),
	})

	s.button_playlist_mode_OFF = _uses(s._button_repeat, {
		img = false,
	})
	s.button_playlist_mode_DISABLED = _uses(s._button_repeat, {
		img = false,
	})
	s.button_playlist_mode_ON = _uses(s._button_repeat, {
		img = _loadImage(self, "MISSING_PLAYLIST_MODE_ICON"),
	})
	s.button_playlist_mode_PARTY = _uses(s._button_repeat, {
		img = _loadImage(self, "MISSING_PARTY_MODE_ICON"),
	})

	s._button_shuffle = _uses(s._iconbar_icon)
	s.button_shuffle_OFF = _uses(s._button_shuffle, {
		img = false,
	})
	s.button_shuffle_0 = _uses(s._button_shuffle, {
		img = false,
	})
	s.button_shuffle_1 = _uses(s._button_shuffle, {
		img = _loadImage(self, "Icons/icon_shuffle_on.png"),
	})
	s.button_shuffle_2 = _uses(s._button_shuffle, {
		img = _loadImage(self, "Icons/icon_shuffle_album.png"),
	})

	s._button_battery = _uses(s._iconbar_icon)
	s.button_battery_AC = _uses(s._button_battery, {
		img = _loadImage(self, "Icons/icon_battery_AC.png"),
	})
	s.button_battery_CHARGING = _uses(s._button_battery, {
		img = _loadImage(self, "Icons/icon_battery_charging.png"),
		frameRate = 1,
		frameWidth = s.iconbar_icon_width,
	})
	s.button_battery_0 = _uses(s._button_battery, {
		img = _loadImage(self, "Icons/icon_battery_0.png"),
	})
	s.button_battery_1 = _uses(s._button_battery, {
		img = _loadImage(self, "Icons/icon_battery_1.png"),
	})
	s.button_battery_2 = _uses(s._button_battery, {
		img = _loadImage(self, "Icons/icon_battery_2.png"),
	})
	s.button_battery_3 = _uses(s._button_battery, {
		img = _loadImage(self, "Icons/icon_battery_3.png"),
	})
	s.button_battery_4 = _uses(s._button_battery, {
		img = _loadImage(self, "Icons/icon_battery_4.png"),
	})
	s.button_battery_NONE = _uses(s._button_battery, {
		img = false,
	})

	s._button_wireless = _uses(s._iconbar_icon)
	s.button_wireless_1 = _uses(s._button_wireless, {
		img = _loadImage(self, "Icons/icon_wireless_1_sel.png"),
	})
	s.button_wireless_2 = _uses(s._button_wireless, {
		img = _loadImage(self, "Icons/icon_wireless_2_sel.png"),
	})
	s.button_wireless_3 = _uses(s._button_wireless, {
		img = _loadImage(self, "Icons/icon_wireless_3_sel.png"),
	})
	s.button_wireless_4 = _uses(s._button_wireless, {
		img = _loadImage(self, "Icons/icon_wireless_4_sel.png"),
	})
	s.button_wireless_ERROR = _uses(s._button_wireless, {
		img = _loadImage(self, "Icons/icon_wireless_disabled.png"),
	})
	s.button_wireless_SERVERERROR = _uses(s._button_wireless, {
		img = _loadImage(self, "Icons/icon_wireless_cantconnect.png"),
	})
	s.button_wireless_NONE = _uses(s._button_wireless, {
		img = false,
	})

	-- time
	s.button_time = {
		w = 55,
		align = "right",
		layer = LAYER_FRAME,
		position = LAYOUT_SOUTH,
		fg = TEXT_COLOR,
		font = _boldfont(ICONBAR_FONT),
	}

	s.iconbar_group = {
		x = 0,
		y = screenHeight - 23,
		w = WH_FILL,
		h = 23,
		border = 0,
		padding = { 4, 2, 4, 0 },
		bgImg = s.img.iconBackground,
		layer = LAYER_FRAME,
		position = LAYOUT_SOUTH,
		order = {'play', 'repeat_mode', 'shuffle', 'spacer', 'wireless', 'battery', 'button_time' }, --'repeat' is a Lua reserved word
		spacer = { w = 100 },

	}

	s.keyboard = { hidden = 1 }

	s.debug_canvas = {
			zOrder = 9999
	}

end


--[[

=head1 LICENSE

Copyright 2007 Logitech. All Rights Reserved.

This file is subject to the Logitech Public Source License Version 1.0. Please see the LICENCE file for details.

=cut
--]]

