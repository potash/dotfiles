-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
awful.rules = require("awful.rules")
awful.client = require("awful.client")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
local vicious = require("vicious")
local APW = require("apw/widget")
local cal = require("utils/cal")

-- Load Debian menu entries
require("debian.menu")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

function notify(s)
    naughty.notify({text = tostring(s), screen = mouse.screen})
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
local home      = os.getenv("HOME")
beautiful.init(home .. "/.config/awesome/zenburn.lua")

-- This is used later as the default terminal and editor to run.
terminal = "xterm"
editor = os.getenv("EDITOR") or "editor"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
local layouts =
{
    awful.layout.suit.max,
    --awful.layout.suit.floating,
    --awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    --awful.layout.suit.fair.horizontal,
    --awful.layout.suit.spiral,
    --awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max.fullscreen,
    --awful.layout.suit.magnifier
}
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {}
for s = 1, screen.count() do
    -- Each screen has its own tag table.
    tags[s] = awful.tag({ 1, 2, 3, 4, 5, 6, 7, 8, 9 }, s, layouts[1])
end
-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu
myawesomemenu = {
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", awesome.quit }
}

-- mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
--                                     { "Debian", debian.menu.Debian_menu.Debian },
--                                    { "open terminal", terminal }
--                                  }
--                         })

--- Spawns cmd if no client can be found matching properties
-- If one such client is found, toggle its visibility
-- If multiple found, cycle between them
-- @param cmd the command to execute
-- @param properties a table of properties to match against clients.  Possible entries: any properties of the client object
function run_or_raise(cmd, properties, scr)
	local scr = scr or mouse.screen
	local clients = client.get(scr)
	local focused = awful.client.next(0)
	local findex = 0
	local matched_clients = {}
	local n = 0

	local s = scr

    for i, c in pairs(client.get(s)) do
	   --make an array of matched clients
	   if match(properties, c) then
		  n = n + 1
		  matched_clients[n] = c
		  if c == focused then
			 findex = n
		  end
	   end
	end

   	if n > 0 then
      local c = matched_clients[1]
      -- if the focused window matched switch focus to next in list
      if 0 < findex and findex < n then
         c = matched_clients[findex+1]
      end

	  if c:isvisible() and c == client.focus then
		c.hidden = true
	  else
      	local ctags = c:tags()
      --if #ctags == 0 then
         -- ctags is empty, show client on current tag
         local curtag = awful.tag.selected(scr)
         awful.client.movetotag(curtag, c)
      --else
         -- Otherwise, pop to first tag client is visible on
      --   awful.tag.viewonly(ctags[1])
      --end
      -- And then focus the client
      	client.focus = c
		c.hidden = false
      	c:raise()
	  end 
      return
   end
   awful.util.spawn(cmd)
end

-- Returns true if all pairs in table1 are present in table2
function match (table1, table2)
   for k, v in pairs(table1) do
      if table2[k] ~= v and not table2[k]:find(v) then
         return false
      end
   end
   return true
end

function launcher(cmd, props, scr)
	return function()
		run_or_raise(cmd, props, scr)
	end
end

mymainmenu = awful.menu({ items = { 
	{ "&mutt", launcher(terminal .. " -cd /home/eric/www/ -name mutt -e mutt",{instance="mutt"}, 1)  },
	{ "offline&imap", launcher(terminal .. " -name offlineimap -e offlineimap", {instance="offlineimap"}, 1) },
	{ "&sonata", launcher("sonata", {class="Sonata"}) },
	{ "&configs", launcher("gvim -name configs -p .config/awesome/rc.lua .Xresources .muttrc", {instance = "configs"}, 1) },
	{ "&firefox", launcher("iceweasel", {class = "Iceweasel"}) },
	{ "&org", launcher("gvim -name org -p docs/org/todo.org docs/org/log.org", {instance="org"}, 1) }
}})

mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = mymainmenu })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- {{{ Wibox
-- Create a textclock widget
mytextclock = awful.widget.textclock()
--calendar2.addCalendarToWidget(mytextclock, "<span color='yellow'>%s</span>")
cal.register(mytextclock)


-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() then
                                                      awful.tag.viewonly(c:tags()[1])
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({ width=250 })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", screen = s })

    -- Widgets that are aligned to the left
    local left_layout = wibox.layout.fixed.horizontal()
    left_layout:add(mylauncher)
    left_layout:add(mytaglist[s])
    left_layout:add(mypromptbox[s])

    -- Widgets that are aligned to the right
    local right_layout = wibox.layout.fixed.horizontal()
    if s == 1 then right_layout:add(wibox.widget.systray()) end
    right_layout:add(mytextclock)
    right_layout:add(mylayoutbox[s])

    -- Now bring it all together (with the tasklist in the middle)
    local layout = wibox.layout.align.horizontal()
    layout:set_left(left_layout)
    layout:set_middle(mytasklist[s])
    layout:set_right(right_layout)

    mywibox[s]:set_widget(layout)
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
	awful.key({ }, "XF86Launch1", launcher(terminal .. " -name console", {instance="console"}) ),
	awful.key({ modkey            }, "F11", function ()
        awful.prompt.run({ prompt = "Calculate: " }, mypromptbox[mouse.screen].widget,
            function (expr)
                local result = awful.util.eval("return (" .. expr .. ")")
                naughty.notify({ text = expr .. " = " .. result, timeout = 10 })
            end
        )
    end),
	awful.key({ }, "Print", function () awful.util.spawn('import ' .. home .. '/docs/screenshots/' .. os.time() .. '.png') end),
	awful.key({ modkey }, "F10", function () awful.util.spawn('xdotool click --clearmodifiers 3') end),
	awful.key({ modkey }, "F5", function () awful.util.spawn('xdotool click --clearmodifiers 2') end),
	awful.key({ modkey            }, "F3", function ()
		awful.util.spawn("/bin/sh -c 'xset dpms force off && sleep 2 & slock'")
    end),
	awful.key({ modkey            }, "F4", function ()
		awful.util.spawn("/bin/sh -c 'slock && pm-suspend'")
    end),
	awful.key({ modkey, "Shift" }, "F7", function ()
        if screen.count() == 2 then
			awful.util.spawn('xrandr --output VGA1 --off')
        else 
            awful.util.spawn('xrandr --output VGA1 --mode 1440x900 --above LVDS1')
        end
    end),
	awful.key({ modkey, "" }, "F8", function ()
		awful.util.spawn('xbacklight -time 0 -dec 10%')
    end),
	awful.key({ modkey, "" }, "F9", function ()
		awful.util.spawn('xbacklight -time 0 -inc 10%')
    end),
	awful.key({ modkey, "Shift" }, "r",
              function ()
                 awful.prompt.run({ prompt = "New tag name: " },
                                  mypromptbox[mouse.screen].widget,
                                  function(new_name)
                                     local screen = mouse.screen
                                     local tag = awful.tag.selected(screen)
                                     if tag then
									 	local idx = tostring(awful.tag.getidx(tag))
                                        if not new_name or #new_name == 0 then
                                           new_name=idx
                                        else
                                           new_name = tostring(idx) .. ':' .. new_name
                                        end
										tag.name = new_name
                                     end
                                  end)
              end),
	awful.key({ modkey }, "b", function () mystatebar.visible = not mystatebar.visible end),
	awful.key({ }, "XF86AudioRaiseVolume",  APW.Up),
    awful.key({ }, "XF86AudioLowerVolume",  APW.Down),
	awful.key({ }, "XF86AudioMute",         APW.ToggleMute),

    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "w", function () mymainmenu:show() end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    awful.key({ modkey, "Control" }, "n", awful.client.restore),

    -- Prompt
    awful.key({ modkey },            "r",     function () mypromptbox[mouse.screen]:run() end),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end),
    -- Menubar
    awful.key({ modkey }, "p", function() menubar.show() end)
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end)
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        local tag = awful.tag.gettags(screen)[i]
                        if tag then
                           awful.tag.viewonly(tag)
                        end
                  end),
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      local tag = awful.tag.gettags(screen)[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = awful.tag.gettags(client.focus.screen)[i]
                          if tag then
                              awful.client.movetotag(tag)
                          end
                     end
                  end),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = awful.tag.gettags(client.focus.screen)[i]
                          if tag then
                              awful.client.toggletag(tag)
                          end
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

local modal_properties = { ontop = true, above = true, sticky = true, floating = true, skip_taskbar = true, hidden=true, width = 800, height=500 };

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     keys = clientkeys,
                     buttons = clientbuttons } },
    { rule = { class = "gimp" },
      properties = { floating = true } },
	{ rule = { class = "Pidgin" },
     properties = { floating = true, sticky = true, ontop = true } },
    { rule = { class = "Pavucontrol" },
     properties = { floating = true } },
    { rule = { class = "feh" },
     properties = { floating = true } },
    { rule = { class = "Display" },
     properties = { floating = true } },
    { rule = { class = "gimp" },
      properties = { floating = true } },
    { rule = { instance = "Navigator" },
      properties = { floating = false } },
	{rule = {class = "Thunar", name = "File Operation Progress"},
	  properties = { floating = true} },
	{rule = {class = "Askpass.tcl"},
	  properties = { floating = true, ontop = true} },
	{rule = {class = "Java", name = "Eclipse"},
	  properties = { floating = true, screen=screen.count()} },
    { rule = { instance = "mutt" },
      properties = modal_properties },
    { rule = { instance = "offlineimap" },
      properties = modal_properties },
    { rule = { class = "Sonata" },
      properties = modal_properties },
	{ rule = { instance = "console" },
      properties = modal_properties, 
	  callback = function(c) 
		s = c.screen
		screengeom = screen[c.screen].workarea
		height = 200
		c.hidden = true
		c:geometry({
		  	x = 0,
		  	y = screengeom.height + screengeom.y - height,
			width = screengeom.width -1,
			height = height,
	  	})
		awful.client.movetoscreen(c,s)
		c.hidden = false
		c:raise()
	  end},
    { rule = { instance = "org", class = "Gvim" },
      properties = modal_properties },

}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c, startup)
    -- Enable sloppy focus
    c:connect_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end

    local titlebars_enabled = false
    if titlebars_enabled and (c.type == "normal" or c.type == "dialog") then
        -- buttons for the titlebar
        local buttons = awful.util.table.join(
                awful.button({ }, 1, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.move(c)
                end),
                awful.button({ }, 3, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.resize(c)
                end)
                )

        -- Widgets that are aligned to the left
        local left_layout = wibox.layout.fixed.horizontal()
        left_layout:add(awful.titlebar.widget.iconwidget(c))
        left_layout:buttons(buttons)

        -- Widgets that are aligned to the right
        local right_layout = wibox.layout.fixed.horizontal()
        right_layout:add(awful.titlebar.widget.floatingbutton(c))
        right_layout:add(awful.titlebar.widget.maximizedbutton(c))
        right_layout:add(awful.titlebar.widget.stickybutton(c))
        right_layout:add(awful.titlebar.widget.ontopbutton(c))
        right_layout:add(awful.titlebar.widget.closebutton(c))

        -- The title goes in the middle
        local middle_layout = wibox.layout.flex.horizontal()
        local title = awful.titlebar.widget.titlewidget(c)
        title:set_align("center")
        middle_layout:add(title)
        middle_layout:buttons(buttons)

        -- Now bring it all together
        local layout = wibox.layout.align.horizontal()
        layout:set_left(left_layout)
        layout:set_right(right_layout)
        layout:set_middle(middle_layout)

        awful.titlebar(c):set_widget(layout)
    end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}

mystatebar = awful.wibox( {position = "bottom", fg = beautiful.fg_normal, bg = beautiful.bg_normal, screen=1} )
local layout = wibox.layout.fixed.horizontal()

local spacer    = wibox.widget.textbox()
local separator = wibox.widget.textbox()
spacer:set_text(" ")
separator:set_text("|")
local icondir 	= home .. "/.config/awesome/icons/"

uptimewidget = wibox.widget.textbox()
vicious.register(uptimewidget, vicious.widgets.uptime,
        function (widget, args)
                return string.format('%2dd ', args[1])
                                end, 1511)
local dateicon = wibox.widget.imagebox()
dateicon:set_image(icondir .. "time.png")

layout:add(dateicon)
layout:add(uptimewidget)

volicon = wibox.widget.imagebox()
volicon:set_image(icondir .. "vol.png")

layout:add(volicon)
layout:add(APW)
layout:add(spacer)


local batwidget = wibox.widget.textbox()
vicious.register(batwidget, vicious.widgets.bat,
        function(widget, args)
                str = args[1] .. ' ' .. args[2] .. '%'
                if args[3] ~= 'N/A' then str = str .. ' ' .. args[3] end
                return str
        end
,61, "BAT0")

local baticon = wibox.widget.imagebox()
baticon:set_image(icondir .. "bat.png")

layout:add(baticon)
layout:add(batwidget)

local memicon =  wibox.widget.imagebox()
memicon:set_image(icondir .. "mem.png")
memwidget = wibox.widget.textbox()
--vicious.enable_caching(vicious.widgets.mem)
vicious.register(memwidget, vicious.widgets.mem, '$1%', 13)

layout:add(memicon)
layout:add(memwidget)

local cpuicon = wibox.widget.imagebox()
cpuicon:set_image(icondir .. "cpu.png")
local tempwidget = wibox.widget.textbox()
vicious.register(tempwidget, vicious.widgets.thermal, "$1°C", 19, "thermal_zone0")
cpuwidget = awful.widget.graph()
cpuwidget:set_width(50)
--cpuwidget:set_max_value(100)
cpuwidget:set_background_color("#494B4F")
cpuwidget:set_color("#FF5656")
--cpuwidget:set_gradient_colors({ "#FF5656", "#88A175", "#AECF96" })
vicious.register(cpuwidget, vicious.widgets.cpu, "$1", 3)

layout:add(cpuicon)
layout:add(cpuwidget)


local dnicon = wibox.widget.imagebox()
local upicon = wibox.widget.imagebox()
dnicon:set_image(icondir .. "down.png")
upicon:set_image(icondir .. "up.png")


local netwidget = wibox.widget.textbox()
---- Enable caching
--vicious.enable_caching(vicious.widgets.net)
-- Register ethernet widget
vicious.register(netwidget, vicious.widgets.net,
        function (widget, args)
                up = args['{eth0 up_kb}'] + 
				     args['{wlan0 up_kb}']
                down = args['{eth0 down_kb}'] + 
				       args['{wlan0 down_kb}']
                --return string.format('%-3g %3g', args['{eth0 down_kb}'], args['{eth0 up_kb}']) 
                return string.format('%-3g %3g', down, up)
        end, 3)

layout:add(dnicon)
layout:add(netwidget)
layout:add(upicon)

kbdcfg = {}
kbdcfg.cmd = "setxkbmap"
kbdcfg.layout = { { "us", "" }, { "ru", "phonetic" } }
kbdcfg.current = 1  -- us is our default layout
kbdcfg.widget = wibox.widget.textbox()
kbdcfg.widget:set_text (" " .. kbdcfg.layout[kbdcfg.current][1] .. " ")
kbdcfg.switch = function ()
   kbdcfg.current = kbdcfg.current % #(kbdcfg.layout) + 1
   local t = kbdcfg.layout[kbdcfg.current]
   os.execute( kbdcfg.cmd .. " " .. t[1] .. " " .. t[2] )
	   os.execute( "xmodmap ~/.Xmodmap" )
   kbdcfg.widget:set_text(" " .. t[1] .. " ")
end

-- Mouse bindings
kbdcfg.widget:buttons(awful.util.table.join(
      awful.button({ }, 1, function () kbdcfg.switch() end)
))

layout:add(kbdcfg.widget)

--
mailicon = wibox.widget.imagebox()
mailicon:set_image(icondir .. "mail.png")
mailwidget = wibox.widget.textbox()
vicious.register(mailwidget, vicious.widgets.mdir, "$1", 101, {home .. "/mail/INBOX"})

--newsicon = wibox.widget.imagebox()
--newsicon:set_image(icondir .. "rss.png")
--newswidget = wibox.widget.textbox()
--vicious.register(newswidget, vicious.widgets.mdir, "$1", 101, {home .. "/mail/News"})

layout:add(mailicon)
layout:add(mailwidget)

--


mystatebar:set_widget(layout)
