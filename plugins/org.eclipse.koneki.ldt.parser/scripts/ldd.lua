-------------------------------------------------------------------------------
-- Copyright (c) 2011 Sierra Wireless and others.
-- All rights reserved. This program and the accompanying materials
-- are made available under the terms of the Eclipse Public License v1.0
-- which accompanies this distribution, and is available at
-- http://www.eclipse.org/legal/epl-v10.html
--
-- Contributors:
--     Sierra Wireless - initial API and implementation
-------------------------------------------------------------------------------
require ('metalua.compiler')

local M = {} -- module
local lx -- lexer used to parse tag
local registeredparsers -- table {tagname => {list de parsers}}

-- raise an error if  result contains a node error
local function raiserror(result)
   for i, node in ipairs(result) do
      -- if node.tag == "Error" then table.print(node) end
   	assert(not node or node.tag ~= "Error")
   end
end


-- copy key and value from one table to an other
local function copykey(tablefrom, tableto)
   for key, value in pairs(tablefrom) do
      if key ~= "lineinfos" then
         tableto[key] = value
      end
   end
end

------------------------------------------------------
-- parse an id
-- return a table {name, lineinfo)
local idparser = gg.sequence({
         builder = function (result)
                     raiserror(result)
                     return { name = result[1][1] }
                   end,
         mlp.id
})
------------------------------------------------------
-- parse an modulename parser  (id.)?id
-- return a table {name, lineinfo)
local modulenameparser =  gg.list({
         builder = function (result)
                     raiserror(result)
                     local ids = {}
                     for i, id in ipairs(result) do
                        table.insert(ids,id.name)
                     end
                     return {name = table.concat(ids,".")}
                   end,
         primary  = idparser,
         separators = '.'
})
------------------------------------------------------
-- parse an modulename parser  (id.)?id
-- return a table {name, lineinfo)
local typenameparser= modulenameparser

------------------------------------------------------
-- parse an id
-- return a table {name, lineinfo)
local internaltyperefparser = gg.sequence({
         builder = function(result)
                     raiserror(result)
                     return {tag = "typeref",type=result[1].name}
                   end,
         "#", typenameparser
})

------------------------------------------------------
-- parse an id
-- return a table {name, lineinfo)
local externaltyperefparser = gg.sequence({
         builder = function(result)
                     raiserror(result)
                     return {tag = "typeref",module=result[1].name,type=result[2].name}
                   end,
         modulenameparser,"#", typenameparser
})


------------------------------------------------------
-- parse an id
-- return a table {name, lineinfo)
local typerefparser = gg.multisequence{
                           internaltyperefparser,
                           externaltyperefparser}

------------------------------------------------------     
-- parse an id
-- return a table {name, lineinfo)
local typereflistparser = gg.list({
         primary  = typerefparser,
         separators = ','
})

------------------------------------------------------
-- 
-- TODO use a more generic way to parse (modifier if not always a typeref)
-- TODO support more than one modifier 
local modifiersparser = gg.sequence({
         builder = function(result)
                     raiserror(result)
                     return {[result[1].name]=result[2]}
                   end,
         "[", idparser ,  "=" , internaltyperefparser , "]"
})


------------------------------------------------------
-- parse an module tag
local returnparsers = {
      -- full parser
      gg.sequence({
         builder = function (result)
                     raiserror(result)
                     return { types= result[1]}
                   end,
         '@','return', typereflistparser
      }),
      -- parser without typerefs
      gg.sequence({
         builder = function (result)
                     raiserror(result)
                     return { types = {}}
                   end,
         '@','return'
      })    
}  

------------------------------------------------------
-- parse an module tag
local paramparsers = {
      -- full parser
      gg.sequence({
         builder = function (result)
                     raiserror(result)
                     return { name = result[2].name, type = result[1]}
                   end,
         '@','param', typerefparser, idparser
      }),
      
      -- full parser
      gg.sequence({
         builder = function (result)
                     raiserror(result)
                     return { name = result[1].name}
                   end,
         '@','param', idparser
      })          
}  

------------------------------------------------------
-- parse an module tag
local fieldparsers = {
      -- full parser
      gg.sequence({
         builder = function (result)
                     raiserror(result)
                     local tag = {}
                     copykey(result[1],tag)
                     tag.type = result[2]
                     tag.name = result[3].name
                     return tag
                   end,
         '@','field', modifiersparser, typerefparser, idparser
      }),
      
      
      -- full parser
      gg.sequence({
         builder = function (result)
                     raiserror(result)
                     return { name = result[2].name, type = result[1]}
                   end,
         '@','field', typerefparser, idparser
      }),
      
      -- full parser
      gg.sequence({
         builder = function (result)
                     raiserror(result)
                     local tag = {}
                     copykey(result[1],tag)
                     tag.name = result[2].name
                     return tag
                   end,
         '@','field', modifiersparser, idparser
      }),
      
      -- full parser
      gg.sequence({
         builder = function (result)
                     raiserror(result)
                     return { name = result[1].name}
                   end,
         '@','field', idparser
      })          
}  

------------------------------------------------------
-- parse an module tag
-- TODO use a more generic way to parse modifier !
local functionparsers = {
      -- full parser
      gg.sequence({
         builder = function (result)
                     raiserror(result)
                     local tag = {}
                     copykey(result[1],tag)
                     tag.name = result[2].name
                     return tag
                   end,
         '@','function', modifiersparser, idparser
      })          
} 

------------------------------------------------------
-- parse an module tag
local typeparsers = {
      -- full parser
      gg.sequence({
         builder = function (result)
                     raiserror(result)
                     return { name = result[1].name}
                   end,
         '@','type', '#',typenameparser
      })          
}  

------------------------------------------------------
-- parse an module tag
local moduleparsers = {
      -- full parser
      gg.sequence({
         builder = function (result)
                     raiserror(result)
                     return { name = result[1].name }
                   end,
         '@','module', modulenameparser
      }),
      -- parser without name
      gg.sequence({
         builder = function (result)
                     raiserror(result)
                     return {}
                   end,
         '@','module'
      })    
}   

------------------------------------------------------------
-- init parser 

local function initparser()
   -- register parsers
   -- each tag name has several parsers
   registeredparsers  = {
     ["module"]   = moduleparsers,
     ["return"]   = returnparsers,
     ["type"]     = typeparsers,
     ["field"]    = fieldparsers,
     ["function"] = functionparsers,
     ["param"]    = paramparsers
   }
   
   -- create lexer used for parsing
   lx = lexer.lexer:clone()
   lx.extractors = {
      -- "extract_long_comment",
      -- "extract_short_comment",
      -- "extract_long_string",
      "extract_short_string",
      "extract_word",
      "extract_number",
      "extract_symbol"
   }
   
   -- add tag name as key word
   local tagnames = {}
   for tagname, _ in pairs(registeredparsers) do
      table.insert(tagnames,tagname)
   end
   lx:add(tagnames)   
   
   return lx, parsers
end

initparser()


------------------------------------------------------------
-- clean the description 
local function cleandescription (string)
   return  string:gsub("([%s\n\r]*)$","")    
end


------------------------------------------------------------
-- parse comment tag partition and return table structure  
local function parsetag(part)
   -- check if the part start by a supported tag
   for tagname,parsers in pairs(registeredparsers) do
      if (part.comment:find("^@"..tagname)) then
         -- try the registered parsers for this tag
         local result
         for i, parser in ipairs(parsers) do
            local valid, tag = pcall(parser, lx:newstream(part.comment, tagname .. 'tag lexer'))
            if valid then
                -- add tagname
                tag.tagname = tagname
                
                -- add description
                local endoffset = tag.lineinfo.last.offset
                tag.description = cleandescription(part.comment:sub(endoffset+2,-1))
                return tag
            end
         end
      end
   end
   return nil;
end

------------------------------------------------------------
-- split string comment in several part
-- return list of {comment = string, offset = number}
-- the first part is the part before the first tag
-- the others are the part from a tag to the next one
local function split(stringcomment,commentstart)
   local partstart = commentstart
   local result = {}
   
   -- manage case where the comment start by @
   local at_startoffset, at_endoffset = stringcomment:find("^%s+@",partstart)
   if at_endoffset then
      partstart = at_endoffset
   end
    
   -- split comment
   repeat
      at_startoffset, at_endoffset = stringcomment:find("[\n\r]%s?@",partstart)
      local partend = (at_endoffset or #stringcomment+1) -1
      table.insert(result,
                    { comment = stringcomment:sub (partstart,partend) ,
                      offset = partstart})
      partstart = partend+1
   until not at_endoffset
   
   return result
end



------------------------------------------------------------
-- parse a comment block and return a table 
function M.parse(stringcomment)

	local _comment = {description="", shortdescription=""}
	
	-- check if it's a ld comment
	-- get the begin of the comment
	-------------------------------
	if not stringcomment:find("^-") then
	  -- if this comment don't start by -, we will not handle it
	  return nil
	end
	
	-- retrieve the real start
	local commentstart = 2 --after the first hyphen
	-- if the first line is an empty comment line with at least 3 hyphens we ignore it
	local  _ , endoffset = stringcomment:find("^-+%s*[\n\r]")
	if endoffset then
	   commentstart = endoffset
	end
	
	
	-- split comment part
	-------------------------------
	local commentparts = split(stringcomment, commentstart)
--	table.print(commentparts,1)
--	io.flush()
	
	-- Extract descriptions
	-------------------------------
	local firstpart = commentparts[1].comment
	if firstpart:find("^[^@]") then
	   -- if the comment part don't start by @
	   -- it's the part which contains descriptions
	   local startoffset,endoffset = firstpart:find("[.?][%s\n\r]*")
	   if startoffset then
	     _comment.shortdescription = firstpart:sub(1,startoffset)
	     _comment.description = cleandescription(firstpart:sub(endoffset+1,-1))   
	   else
	     _comment.shortdescription = firstpart
	     _comment.description = firstpart
	   end
	end
   
   -- Extract tags
   -------------------------------
   -- parse tag
  for i, part in ipairs(commentparts) do
	   tag = parsetag(part)
		--if it's a supported tag (so tag is not nil, it's a table)
		if tag then 
   	  if not _comment[tag.tagname] then
   		 _comment[tag.tagname] = {}
   	  end
   	  table.insert(_comment[tag.tagname],tag)
		end
	end
		
	return _comment
end
return M
