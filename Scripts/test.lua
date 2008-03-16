#!/bin/lua
-- vi: set foldmethod=marker foldlevel=0:
--
-- test.lua
-- ---------------------------------------------------------------------------
--  - 2008
-- ---------------------------------------------------------------------------
-- Author: Aitor Pérez Iturri - <aitor.iturri@gmail.com>	
-- Created: 20/01/08 20:23:44 CET
-- License: GNU GPL (see www.fsf.org for details)
-- ---------------------------------------------------------------------------
-- Description:
--
-- ---------------------------------------------------------------------------

require "env"
-- Create module {{{1

-- Importsa
require "GoboLinux.cui"
local cui = GoboLinux.cui

text1 = [[
This is something that's been talked about for a long time, but never been implemented. Now with general agreement that it should happen from list discussion and the developer meeting this morning, we need to think about how. I've volunteered to take the lead on this one, so I'd like to write up my ideas for how it should go.

Firstly, I want to have all the flags signalled in (Build)Dependencies. In most cases, the flags will be associated with dependencies, but for those that aren't (relating to enabling/disabling bundled libraries, say), I want them to be specified on their own. To that end, I'd like to redefine the rule format to consist of a current dependency specification, followed by a list of use flags that activate the rule: GTK+ >= 2.8 ?gtk, gui. I've chosen a question mark to offset the flags here, but the specifics aren't important - it's important to mark them somehow, so that they can be listed on lines of their own for the no-dependency cases. It's possible that we will want more complicated rules in the future (?foo && !bar), but I think this is enough to start with.
Storing the flags in Dependencies means CheckDependencies can handle all the work transparently to the rest of the system - Freshen and Manager will automatically get the correct list of dependencies for the enabled flags, and ChrootCompile will build the environment correctly. It's due to be merged into Compile itself in this cycle too, which makes this feasible.

Secondly, the Recipe file: we like to keep the format declarative for the common cases, so I plan to create some magic variables to deal with the usual situation of just adding a configure flag. with_gtk="--with-gtk=$gtk__path" would add that configure flag; in many cases, that wouldn't even be necessary, because it would be detected automatically within the chroot environment. For the more complex cases, a function using_gtk() would be defined in the recipe to perform the necessary customisations. If it turned out there were a lot of those functions doing a particular task, we could add another variable to handle it, in line with the recipe philosophy1. Most recipes would only need the variables, if anything, above mentioning the flags in Dependencies.
When a recipe was compiled, a file Resources/UseFlags would be created listing the flags enabled for the build. This would allow finding which packages needed to be rebuilt to take full advantage of changes in the flags on a system. It would also allow recipes to test for the flags enabled in their dependencies, if the need arose, and prompt for recompiling the necessary package. I'm not planning on implementing that at this point, but rather adding functionality as we need it.

We would need to adopt a default set of flags to use for binary packages and ISO releases, which I can foresee a little debate over. I guess they'll be largely determined by the packages we fit onto the ISO. That could be interesting if we do end up with larger LiveUSB or DVD releases, though. In any case, choosing the flags to use is almost the entire problem. ChrootCompile will make building packages with them simple, and with any luck the work someone (André?) has been doing on distributed package building will remove the bottleneck we've had there in the past.

I'm excited to be finally getting these in to the tools; they make the recipe system that much more powerful, and they're something I've been hankering for for a while. I expect we'll have some more discussion about how to implement the flags, and probably change things somewhat from what I've outlined here - I gather some people want a more procedural system, or a greater level of assumption about the flags, and there'll probably be a bit of give and take over that. I heard whispers of an interesting Makefile-like approach at one point, which I'd like to hear more about. Regardless, I'll be glad to see them make it in in whatever form, and I'm looking forward to getting the support into Freshen as well (more news there sometime too, I imagine).
]]

text2 = [[
Línea uno
Línea dos
Línea tres un poco más larga
Incluso una linea cuatro que es aún má larga
333
]]

local title_attrs = {
	"Level=2",
	"LevelPosition=Center",
	"Position=Left"
}

local title_attrs2 = {
	"Level=2",
	"LevelPosition=Right",
	"Position=Center"
}


local text_attrs = {
	"Level=2",
	"LevelPosition=Center",
	"Align=Right",
	"Position=Left",
	"Indent=False",
}

local text_attrs2 = {
	"Level=3",
	"LevelPosition=Right",
	"Align=Left",
	"Position=Right",
	"Indent=False",
}


--cui.title("Use Flags by mwh",unpack(title_attrs))
--cui.text(text1,unpack(text_attrs))

cui.title("PRUEBA ESTÚPIDA",unpack(title_attrs2))
cui.text(text2,unpack(text_attrs2))

local modifiers =
{
	"Align=Left",
	"Level=3",
	"LevelPosition=Left",
	"Position=Center",
}
local text = [[
Here you can choose the language of your GoboLinux system.
]]
	cui.title("Language Selection","Color=BoldGreen",unpack(modifiers))
	cui.text(text,unpack(modifiers))



