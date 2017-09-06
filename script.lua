--[[

  This is a testing script.

  - Put this script on a same directory with tdbot.lua.
    You may need to define script name and path in the telegram-bot's config file
  - Install serpent, or put serpent.lua on the same directory with this script.
  - Call functions

]]--

package.path = package.path .. ';.luarocks/share/lua/5.2/?.lua'
  .. ';.luarocks/share/lua/5.2/?/init.lua'
package.cpath = package.cpath .. ';.luarocks/lib/lua/5.2/?.so'

-- Load the libraries
local my_id = 123456789 -- our user id here, in number
local serpent = require 'serpent'
local tdbot = require 'tdbot'

-- Print message
local function vardump(value)
  print '\n-------------------------------------------------------------- START'
  print(serpent.block(value, {comment=false}))
  print '--------------------------------------------------------------- STOP\n'
end

-- Print callback
function dl_cb(arg, data)
  -- print '\n===================================================================='
  vardump(arg)
  vardump(data)
  -- print '--==================================================================\n'
end

local function getText(str)
  return str:sub(5, -1)
end

function tdbot_update_callback (data)
  -- vardump(data)
  if (data._ == 'updateNewMessage') then
    local msg = data.message
    local chat_id = msg.chat_id
    local user_id = msg.sender_user_id
    vardump(msg)

    if msg.content._ == 'messageText' then
      -- Only proccess my_id's messages
      if not user_id == my_id then return end

      local input = msg.content.text

      if input == '^/pang' then
        tdbot.getMe()
      elseif input == '^/peng' then
        -- tdbot.
      elseif input == '^/ping' then
        -- tdbot.
      elseif input == '^/pong' then
        -- tdbot.
      elseif input == '^/pung' then
        -- tdbot.
      elseif input:match('^tas ') then
        local text = input:sub(5, -1)
      elseif input:match('^tes ') then
        tdbot.sendText(chat_id, msg.id, getText(input), 0, 1, nil, 0, 'html', 0, nil)
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
