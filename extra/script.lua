--[[

  This is a testing script.

  - Put this script on a same directory with tdbot.lua.
    You may need to define script name and path in the tdbot's config file
  - Install serpent, or put serpent.lua on the same directory with this script.
  - Edit this script to add functions you need to test
  - Run this script: tdbot -s script.lua

]]--

package.path = package.path .. ';.luarocks/share/lua/5.2/?.lua'
  .. ';.luarocks/share/lua/5.2/?/init.lua'
package.cpath = package.cpath .. ';.luarocks/lib/lua/5.2/?.so'

-- Load the libraries
local serpent = require 'serpent'
local tdbot = require 'tdbot'

-- Users who are allowed to use the bot
local test_users = {
  [1234567890] = 'blablabla'  -- user id as the key and a string as the value
}

-- Groups where the bot would response to the test
-- Remove single dash (minus sign) at the beginning of the chat_id
local test_groups = {
  [1234567890] = 'blablabla'  -- group id as the key and a string as the value
}

-- Print message
local function vardump(value)
  print '\n-------------------------------------------------------------- START'
  print(serpent.block(value, {comment=false}))
  print '---------------------------------------------------------------- END\n'
end

-- Print callback
function dl_cb(arg, data)
  vardump(arg)
  vardump(data)
end

local function getText(str, index)
  local text = tostring(str)
  local index = index or 5
  return text:sub(index, -1)
end

function tdbot_update_callback (data)
  -- Uncomment vardump below to print tdbot updates
  -- vardump(data)

  if (data["@type"] == 'updateNewMessage') then
    local msg = data.message
    local chat_id = msg.chat_id
    local user_id = msg.sender_user_id

    -- Only process messages from test_users
    if not test_users[user_id] then return end

    -- Only process messages from test_groups
    if not test_groups[tonumber(getText(chat_id, 2))] then return end

    -- This dump will print messages only
    vardump(msg)

    if msg.content["@type"] == 'messageText' then
      -- Only proccess my_id's messages
      if not user_id == my_id then return end

      local input = msg.content.text.text
      -- Example. This will returns our account properties when we type /pang
      if input:match('^/pang$') then
        tdbot.getMe()
      elseif input:match('^/peng$') then
        -- tdbot.
      elseif input:match('^/ping$') then
        -- tdbot.
      elseif input:match('^/pong$') then
        -- tdbot.
      elseif input:match('^/pung$') then
        -- tdbot.

      -- Example. This will returns information about a user if we type: tas STRING
      -- Where STRING is the user's id
      elseif input:match('^tas ') then
        tdbot.getUser(getText(input))
      elseif input:match('^tes ') then
        -- tdbot.
      elseif input:match('^tis ') then
        -- tdbot.
      elseif input:match('^tos ') then
        -- tdbot.
      elseif input:match('^tus ') then
        -- tdbot.
      end
    end
  end
end
