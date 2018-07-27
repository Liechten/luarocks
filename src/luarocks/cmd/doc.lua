--- Module implementing the LuaRocks "doc" command.
-- Shows documentation for an installed rock.

local doc = {}

local luarocks = require("luarocks.init")
local fs = require("luarocks.fs")
local util = require("luarocks.util")

doc.help_summary = "Show documentation for an installed rock."

doc.help = [[
<argument> is an existing package name.
Without any flags, tries to load the documentation
using a series of heuristics.
With these flags, return only the desired information:

--home      Open the home page of project.
--list      List documentation files only.

For more information about a rock, see the 'show' command.
]]

local function show_homepage(homepage)
   util.printout("Opening " .. homepage .. "...")
   fs.browser(homepage)
   return true
end

--- Driver function for "doc" command.
-- @param name or nil: an existing package name.
-- @param version string or nil: a version may also be passed.
-- @return boolean: True if succeeded, nil on errors.
function doc.command(flags, name, version)
   if not name then
      return nil, "Argument missing. " .. util.see_help("doc")
   end

   name = util.adjust_name_and_namespace(name, flags)
   luarocks.set_rock_tree(flags["tree"])
   local homepage, homepage_err = luarocks.homepage(name, version, flags["tree"])
   local docdir, docfile, files = luarocks.doc(name, version, flags["tree"])
   local doc_err = docfile

   if not docdir then
      if doc_err:match("not installed") then
         util.printout(doc_err)
         util.printout("Looking for it in the rocks servers...")
         if not homepage then return nil, homepage_err end
         return show_homepage(homepage)
      end
      return nil, doc_err
   end

   if flags["home"] then
      if not homepage then return nil, homepage_err end
      return show_homepage(homepage)
   end

   if not docdir then
      if homepage and not flags["list"] then
         util.printout(doc_err)
         return show_homepage(homepage)
      end
      return nil, doc_err 
   end
   
   local porcelain = flags["porcelain"]
   if #files > 0 then
      util.title("Documentation files for " .. name, porcelain)
      if porcelain then
         for _, file in ipairs(files) do
            util.printout(docdir .. "/" .. file)
         end
      else
         util.printout(docdir .. "/")
         for _, file in ipairs(files) do
            util.printout("\t" .. file)
         end
      end
   end
   
   if flags["list"] then
      return true
   end
   
   local ok = fs.browser(docfile)
   if not ok and not docfile:match("%.html?$") then
      local fd = io.open(docfile, "r")
      util.printout(fd:read("*a"))
      fd:close()
   end

   return true
end

return doc
