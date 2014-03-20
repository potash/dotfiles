-- Standard awesome library
require("awful")
require("awful.autofocus")
require("awful.rules")
-- Theme handling library
require("beautiful")
-- Notification library
require("naughty")
require("vicious")

local calendar2 = require("calendar2")
local APW = require("apw/widget")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end


local home 	 	= os.getenv("HOME")

function notify(s)
  	naughty.notify({text = tostring(s), screen = mouse.screen})
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.add_signal("debug::error", function (err)
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
beautiful.init(home .. "/.config/awesome/zenburn.lua")
naughty.config.default_preset.bg = beautiful.bg_normal

-- This is used later as the default terminal and editor to run.
local terminal = "urxvt"
editor = os.getenv("EDITOR") or "editor"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
layouts =
{
    --awful.layout.suit.floating,
    --awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.max,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    --awful.layout.suit.fair,
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
   
   local from = 1
   to = screen.count()
   if scr then 
	 from = scr
	 to = scr
   end

   for s = from, to do
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


mymainmenu = awful.menu({ items = { 
	{ "&mutt", function() run_or_raise(terminal .. " -name mutt -e mutt", {instance="mutt"}, 1)  end },
	{ "&sonata", function() run_or_raise("sonata", {class="Sonata"}, 1) end },
	{ "&rc.lua", function() run_or_raise("gvim .config/awesome/rc.lua", {name = "rc.lua"}, 1) end },
	{ "&firefox",  function() run_or_raise("iceweasel", {class = "Iceweasel"}) end },
	{ "&org", function () run_or_raise("gvim -name org -p docs/org/todo.org docs/org/log.org", {instance="org"}, 1) end  }
}})

mylauncher = awful.widget.launcher({ image = image(beautiful.awesome_icon),
                                     menu = mymainmenu })
-- }}}

-- {{{ Wibox
-- Create a textclock widget
mytextclock = awful.widget.textclock({ align = "right" })
calendar2.addCalendarToWidget(mytextclock, "<span color='yellow'>%s</span>")

-- Create a systray
mysystray = widget({ type = "systray" })

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
                    awful.button({ }, 4, awful.tag.viewnext),
                    awful.button({ }, 5, awful.tag.viewprev)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
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
    mypromptbox[s] = awful.widget.prompt({ layout = awful.widget.layout.horizontal.leftright })
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.label.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(function(c)
                                              return awful.widget.tasklist.label.currenttags(c, s)
                                          end, mytasklist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", screen = s })
    -- Add widgets to the wibox - order matters
    mywibox[s].widgets = {
        {
            mylauncher,
            mytaglist[s],
            mypromptbox[s],
            layout = awful.widget.layout.horizontal.leftright
        },
        mylayoutbox[s],
        mytextclock,
        s == 1 and mysystray or nil,
        mytasklist[s],
        layout = awful.widget.layout.horizontal.rightleft
    }
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
	awful.key({ }, "XF86Launch1", function () run_or_raise(terminal .. " -name console", {instance="console"}) end),
	awful.key({ }, "Print", function () awful.util.spawn('import -window ' .. client.focus.window .. ' ' .. home .. '/docs/screenshots/' .. os.time() .. '.png') end),
	awful.key({ "Alt"}, "Print", function () awful.util.spawn('import '  .. home .. '/docs/screenshots/' .. os.time() .. '.png') end),
	awful.key({ }, "XF86AudioRaiseVolume",  APW.Up),
    awful.key({ }, "XF86AudioLowerVolume",  APW.Down),
	awful.key({ }, "XF86AudioMute",         APW.ToggleMute),
	awful.key({ modkey, "Control" }, "Shift_R", function () kbdcfg.switch() end),
	awful.key({ modkey, "Shift" }, "F7", function ()
        if screen.count() == 2 then
            awful.util.spawn('xrandr --output VGA1 --off')
        elseif screen.count() == 1 then
            awful.util.spawn('xrandr --output VGA1 --mode 1440x900 --right-of LVDS1')
        end
    end),
	awful.key({ modkey            }, "F11", function ()
        awful.prompt.run({ prompt = "Calculate: " }, 
			mypromptbox[mouse.screen].widget,
            function (expr)
                local result = awful.util.eval("return (" .. expr .. ")")
                naughty.notify({ text = expr .. " = " .. result, timeout = 10 })
            end
        )
    end),
	awful.key({ modkey }, "b", function () mystatebar.visible = not mystatebar.visible end),
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
    awful.key({ modkey,           }, "w", function () mymainmenu:show({keygrabber=true}) end),

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
	awful.key({ modkey, "Shift" }, "r",
          function ()
              awful.prompt.run({ prompt = "Run in terminal: " },
                  mypromptbox[mouse.screen].widget,
                  function (...) awful.util.spawn("bash -ic " .. ...) end,
                  awful.completion.shell,
                  awful.util.getdir("cache") .. "/history")
          end),
    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end)
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey, "Shift"   }, "r",      function (c) c:redraw()                       end),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "s",      function (c) c.sticky = not c.sticky            end),
    awful.key({ modkey,  "Shift"         }, "u",      function (c) c.urgent = not c.urgent            end),
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

-- Compute the maximum number of digit we need, limited to 9
keynumber = 0
for s = 1, screen.count() do
   keynumber = math.min(9, math.max(#tags[s], keynumber));
end

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, keynumber do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        if tags[screen][i] then
                            awful.tag.viewonly(tags[screen][i])
                        end
                  end),
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      if tags[screen][i] then
                          awful.tag.viewtoggle(tags[screen][i])
                      end
                  end),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.movetotag(tags[client.focus.screen][i])
                      end
                  end),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.toggletag(tags[client.focus.screen][i])
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

-- {{{ Rules
local modal_properties = { ontop = true, above = true, sticky = true, floating = true, skip_taskbar = true };

awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
				 	 size_hints_honor = false} },
    { rule = { class = "Pidgin" },
     properties = { floating = true, sticky = true, ontop = true } },
    { rule = { class = "Pavucontrol" },
     properties = { floating = true } },
    { rule = { class = "feh" },
     properties = { floating = true } },
    { rule = { class = "gimp" },
      properties = { floating = true } },
    --{ rule = { instance = "Navigator" },
    --  properties = { floating = false } },
    { rule = { instance = "mutt" },
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
			width = screengeom.width,
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
client.add_signal("manage", function (c, startup)
    -- Add a titlebar
    -- awful.titlebar.add(c, { modkey = modkey })

    -- Enable sloppy focus
    c:add_signal("mouse::enter", function(c)
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
end)


client.add_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.add_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

-- }}}

mystatebar = awful.wibox( {position = "bottom", fg = beautiful.fg_normal, bg = beautiful.bg_normal, screen=1} )

local spacer    = widget({ type = "textbox" })
local separator = widget({ type = "textbox" })
spacer.text     = " "
separator.text  = "|"
local icondir 	= home .. "/.config/awesome/icons/"

uptimewidget = widget({ type = 'textbox' })
vicious.register(uptimewidget, vicious.widgets.uptime,
        function (widget, args)
                return string.format('%2dd ', args[1])
                                end, 1511)
local dateicon = widget({ type = "imagebox" })
dateicon.image = image(icondir .. "time.png")

local batwidget = widget({ type = "textbox" })
vicious.register(batwidget, vicious.widgets.bat,
        function(widget, args)
                str = args[1] .. ' ' .. args[2] .. '%'
                if args[3] ~= 'N/A' then str = str .. ' ' .. args[3] end
                return str
        end
,61, "BAT0")
local baticon = widget({ type = "imagebox" })
baticon.image = image(icondir .. "ac.png")


local memicon = widget({ type = "imagebox" })
memicon.image = image(icondir .. "mem.png")
memwidget = widget({ type = 'textbox' })
--vicious.enable_caching(vicious.widgets.mem)
vicious.register(memwidget, vicious.widgets.mem, '$1%', 13)

-- {{{ CPU usage and temperature
local cpuicon = widget({ type = "imagebox" })
cpuicon.image = image(icondir .. "cpu.png")
-- Initialize widgets
local tempwidget = widget({ type = "textbox" })
vicious.register(tempwidget, vicious.widgets.thermal, "$1°C", 19, "thermal_zone0")
-- Initialize widget
cpuwidget = awful.widget.graph()
-- Graph properties
cpuwidget:set_width(50)
--cpuwidget:set_max_value(100)
cpuwidget:set_background_color("#494B4F")
cpuwidget:set_color("#FF5656")
cpuwidget:set_gradient_colors({ "#FF5656", "#88A175", "#AECF96" })
-- Register widget
vicious.register(cpuwidget, vicious.widgets.cpu, "$1", 3)
-- }}}

-- {{{ Network usage
local dnicon = widget({ type = "imagebox" })
local upicon = widget({ type = "imagebox" })
dnicon.image = image(icondir .. "down.png")
upicon.image = image(icondir .. "up.png")
-- Initialize widgets
local netwidget = widget({ type = "textbox" })
-- Enable caching
--vicious.enable_caching(vicious.widgets.net)
-- Register ethernet widget
vicious.register(netwidget, vicious.widgets.net,
        function (widget, args)
                up = -- args['{eth0 up_kb}'] + 
				      args['{wlan0 up_kb}']
                down = -- args['{eth0 down_kb}'] + 
				      args['{wlan0 down_kb}']
                --return string.format('%-3g %3g', args['{eth0 down_kb}'], args['{eth0 up_kb}']) 
                return string.format('%-3g %3g', down, up)
        end, 3)

    kbdcfg = {}
    kbdcfg.cmd = "setxkbmap"
    kbdcfg.layout = { { "us", "" }, { "ru", "phonetic" } }
    kbdcfg.current = 1  -- us is our default layout
    kbdcfg.widget = widget({ type = "textbox", align = "right" })
    kbdcfg.widget.text = " " .. kbdcfg.layout[kbdcfg.current][1] .. " "
    kbdcfg.switch = function ()
       kbdcfg.current = kbdcfg.current % #(kbdcfg.layout) + 1
       local t = kbdcfg.layout[kbdcfg.current]
       os.execute( kbdcfg.cmd .. " " .. t[1] .. " " .. t[2] )
           os.execute( "xmodmap ~/.Xmodmap" )
       kbdcfg.widget.text = " " .. t[1] .. " "
    end

-- Mouse bindings
kbdcfg.widget:buttons(awful.util.table.join(
      awful.button({ }, 1, function () kbdcfg.switch() end)
))

-- {{{ Mail subject
mailicon = widget({ type = "imagebox" })
mailicon.image = image(icondir .. "mail.png")
-- -- Initialize widget
mailwidget = widget({ type = "textbox" })
-- Register widget
vicious.register(mailwidget, vicious.widgets.mdir, "$1", 101, {home .. "/mail/INBOX"})

-- {{{ News subject
newsicon = widget({ type = "imagebox" })
newsicon.image = image(icondir .. "rss.png")
-- -- Initialize widget
newswidget = widget({ type = "textbox" })
-- Register widget
vicious.register(newswidget, vicious.widgets.mdir, "$1", 101, {home .. "/mail/News"})

volicon = widget({ type = "imagebox" })
volicon.image = image(icondir .. "vol.png")

mystatebar.widgets = {
    dateicon, uptimewidget, separator,
	baticon, batwidget, separator,
	volicon, APW, separator,
	kbdcfg.widget, separator,
	cpuicon, cpuwidget, tempwidget, separator,
	memicon, memwidget, separator,
	dnicon, netwidget, upicon, separator,
	mailicon, mailwidget, newsicon, newswidget, separator,
    layout = awful.widget.layout.horizontal.leftright
}

