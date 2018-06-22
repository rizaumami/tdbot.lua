--[[
  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
  MA 02110-1301, USA.
--]]

local tdbot = {}

-- Does nothing, suppress 'lua: attempt to call a nil value' warning
function dl_cb(arg, data)
end

-- Type of chats:
-- @chat_id = users, basic groups, supergroups, channels and secret chats
-- @basicgroup_id = basic groups
-- @supergroup_id = supergroups and channels
local function getChatId(chat_id)
  local chat = {}
  local chat_id = tostring(chat_id)

  if chat_id:match('^-100') then
    local supergroup_id = string.sub(chat_id, 5)
    chat = {id = supergroup_id, type = 'supergroup'}
  else
    local basicgroup_id = string.sub(chat_id, 2)
    chat = {id = basicgroup_id, type = 'basicgroup'}
  end

  return chat
end

-- Get points to a file
local function getInputFile(file, conversion_str, expected_size)
  local input = tostring(file)
  local infile = {}

  if (conversion_str and expectedsize) then
    infile = {
      ["@type"] = 'inputFileGenerated',
      original_path = tostring(file),
      conversion = tostring(conversion_str),
      expected_size = expected_size
    }
  else
    if input:match('/') then
      infile = {["@type"] = 'inputFileLocal', path = file}
    elseif input:match('^%d+$') then
      infile = {["@type"] = 'inputFileId', id = file}
    else
      infile = {["@type"] = 'inputFileRemote', id = file}
    end
  end

  return infile
end

tdbot.getInputFile = getInputFile

-- Get the way the text should be parsed for TextEntities
local function getParseMode(parse_mode)
  local P = {}
  if parse_mode then
    local mode = parse_mode:lower()

    if mode == 'markdown' or mode == 'md' then
      P["@type"] = 'textParseModeMarkdown'
    elseif mode == 'html' then
      P["@type"] = 'textParseModeHTML'
    end
  end
  return P
end

-- Parses Bold, Italic, Code, Pre, PreCode and TextUrl entities contained in the text.
-- This is an offline method.
-- May be called before authorization.
-- Can be called synchronously
-- @text The text which should be parsed
-- @parse_mode Text parse mode
local function parseTextEntities(text, parse_mode, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'parseTextEntities',
    text = tostring(text),
    parse_mode = getParseMode(parse_mode)
  }, callback or dl_cb, data))
end

tdbot.parseTextEntities = parseTextEntities

-- Sends a message.
-- Returns the sent message
-- @chat_id Target chat
-- @reply_to_message_id Identifier of the message to reply to or 0
-- @disable_notification Pass true to disable notification for the message. Not supported in secret chats
-- @from_background Pass true if the message is sent from the background
-- @reply_markup Markup for replying to the message; for bots only
-- @input_message_content The content of the message to be sent
local function sendMessage(chat_id, reply_to_message_id, input_message_content, parse_mode, disable_notification, from_background, reply_markup, callback, data)
  local tdbody = {
    ["@type"] = 'sendMessage',
    chat_id = chat_id,
    reply_to_message_id = reply_to_message_id or 0,
    disable_notification = disable_notification or 0,
    from_background = from_background or 1,
    reply_markup = reply_markup,
    input_message_content = input_message_content
  }
  local text

  if input_message_content.text then
    text = input_message_content.text.text
  elseif input_message_content.caption then
    text = input_message_content.caption.text
  end

  if text then
    if parse_mode then
      parseTextEntities(text, parse_mode, function(a, d)
        if a.tdbody.input_message_content.text then
          a.tdbody.input_message_content.text = d
        else
          a.tdbody.input_message_content.caption = d
        end
        assert (tdbot_function (a.tdbody, a.callback or dl_cb, a.data))
      end, {tdbody = tdbody, callback = callback, data = data})
    else
      local message = {}
      local n = 1
      -- Send multiple messages if text is longer than 4096 characters.
      -- https://core.telegram.org/method/messages.sendMessage
      while #text > 4096 do
        message[n] = text:sub(1, 4096)
        text = text:sub(4096, #text)
        parse_mode = nil
        n = n + 1
      end
      message[n] = text

      for i = 1, #message do
        tdbody.reply_to_message_id = i > 1 and 0 or reply_to_message_id
        if input_message_content.text and input_message_content.text.text then
          tdbody.input_message_content.text.text = message[i]
        else
          tdbody.input_message_content.caption.text = message[i]
        end
        assert (tdbot_function (tdbody, callback or dl_cb, data))
      end
    end
  else
    assert (tdbot_function (tdbody, callback or dl_cb, data))
  end
end

tdbot.sendMessage = sendMessage

-- Set limit.
local function setLimit(limit, num)
  local limit = tonumber(limit)
  local number = tonumber(num or limit)

  return (number >= limit) and limit or number
end


-- (Temporary) workaround for currently buggy tdbot's vector
-- This will return lua array from strings:
-- - {one, two, three}
-- - {[0] = one, two, three}
-- - {[0] = one, [1] = two, [2] = three}
local function vectorize(str)
  local v = {}
  local i = 1

  if not str then return v end

  for k in string.gmatch(str, '(-?%d+)') do
    v[i] = '[' .. i-1 .. ']="' .. k .. '"'
    i = i+1
  end
  v = table.concat(v, ',')
  return load('return {' .. v .. '}')()
end

-- Returns the current authorization state; this is an offline request.
-- For informational purposes only.
-- Use updateAuthorizationState instead to maintain the current authorization state
function tdbot.getAuthorizationState(callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getAuthorizationState'
  }, callback or dl_cb, data))
end

-- Sets the parameters for TDLib initialization
-- @parameters Parameters
-- @use_test_dc If set to true, the Telegram test environment will be used instead of the production environment
-- @database_directory The path to the directory for the persistent database; if empty, the current working directory will be used
-- @files_directory The path to the directory for storing files; if empty, database_directory will be used
-- @use_file_database If set to true, information about downloaded and uploaded files will be saved between application restarts
-- @use_chat_info_database If set to true, the library will maintain a cache of users, basic groups, supergroups, channels and secret chats. Implies use_file_database
-- @use_message_database If set to true, the library will maintain a cache of chats and messages. Implies use_chat_info_database
-- @use_secret_chats If set to true, support for secret chats will be enabled
-- @api_id Application identifier for Telegram API access, which can be obtained at https:-- my.telegram.org
-- @api_hash Application identifier hash for Telegram API access, which can be obtained at https:-- my.telegram.org
-- @system_language_code IETF language tag of the user's operating system language
-- @device_model Model of the device the application is being run on
-- @system_version Version of the operating system the application is being run on
-- @application_version Application version
-- @enable_storage_optimizer If set to true, old files will automatically be deleted
-- @ignore_file_names If set to true, original file names will be ignored. Otherwise, downloaded files will be saved under names as close as possible to the original name
function tdbot.setTdlibParameters(use_test_dc, database_directory, files_directory, use_file_database, use_chat_info_database, use_message_database, use_secret_chats, api_id, api_hash, system_language_code, device_model, system_version, application_version, enable_storage_optimizer, ignore_file_names, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'setTdlibParameters',
    parameters = {
      ["@type"] = 'tdlibParameters',
      use_test_dc = use_test_dc,
      database_directory = tostring(database_directory),
      files_directory = tostring(files_directory),
      use_file_database = use_file_database,
      use_chat_info_database = use_chat_info_database,
      use_message_database = use_message_database,
      use_secret_chats = use_secret_chats,
      api_id = api_id,
      api_hash = tostring(api_hash),
      system_language_code = tostring(system_language_code),
      device_model = tostring(device_model),
      system_version = tostring(system_version),
      application_version = tostring(application_version),
      enable_storage_optimizer = enable_storage_optimizer,
      ignore_file_names = ignore_file_names
    }
  }, callback or dl_cb, data))
end

-- Checks the database encryption key for correctness.
-- Works only when the current authorization state is authorizationStateWaitEncryptionKey
-- @encryption_key Encryption key to check or set up
function tdbot.checkDatabaseEncryptionKey(encryption_key, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'checkDatabaseEncryptionKey',
    encryption_key = encryption_key
  }, callback or dl_cb, data))
end

-- Sets the phone number of the user and sends an authentication code to the user.
-- Works only when the current authorization state is authorizationStateWaitPhoneNumber
-- @phone_number The phone number of the user, in international format
-- @allow_flash_call Pass true if the authentication code may be sent via flash call to the specified phone number
-- @is_current_phone_number Pass true if the phone number is used on the current device.
-- Ignored if allow_flash_call is false
function tdbot.setAuthenticationPhoneNumber(phone_number, allow_flash_call, is_current_phone_number, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'setAuthenticationPhoneNumber',
    phone_number = tostring(phone_number),
    allow_flash_call = allow_flash_call,
    is_current_phone_number = is_current_phone_number
  }, callback or dl_cb, data))
end

-- Re-sends an authentication code to the user.
-- Works only when the current authorization state is authorizationStateWaitCode and the next_code_type of the result is not null
function tdbot.resendAuthenticationCode(callback, data)
  assert (tdbot_function ({
    ["@type"] = 'resendAuthenticationCode'
  }, callback or dl_cb, data))
end

-- Checks the authentication code.
-- Works only when the current authorization state is authorizationStateWaitCode
-- @code The verification code received via SMS, Telegram message, phone call, or flash call
-- @first_name If the user is not yet registered, the first name of the user; 1-255 characters
-- @last_name If the user is not yet registered; the last name of the user; optional; 0-255 characters
function tdbot.checkAuthenticationCode(code, first_name, last_name, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'checkAuthenticationCode',
    code = tostring(code),
    first_name = tostring(first_name),
    last_name = tostring(last_name)
  }, callback or dl_cb, data))
end

-- Checks the authentication password for correctness.
-- Works only when the current authorization state is authorizationStateWaitPassword
-- @password The password to check
function tdbot.checkAuthenticationPassword(password, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'checkAuthenticationPassword',
    password = tostring(password)
  }, callback or dl_cb, data))
end

-- Requests to send a password recovery code to an email address that was previously set up.
-- Works only when the current authorization state is authorizationStateWaitPassword
function tdbot.requestAuthenticationPasswordRecovery(callback, data)
  assert (tdbot_function ({
    ["@type"] = 'requestAuthenticationPasswordRecovery'
  }, callback or dl_cb, data))
end

-- Recovers the password with a password recovery code sent to an email address that was previously set up.
-- Works only when the current authorization state is authorizationStateWaitPassword
-- @recovery_code Recovery code to check
function tdbot.recoverAuthenticationPassword(recovery_code, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'recoverAuthenticationPassword',
    recovery_code = tostring(recovery_code)
  }, callback or dl_cb, data))
end

-- Checks the authentication token of a bot; to log in as a bot.
-- Works only when the current authorization state is authorizationStateWaitPhoneNumber.
-- Can be used instead of setAuthenticationPhoneNumber and checkAuthenticationCode to log in
-- @token The bot token
function tdbot.checkAuthenticationBotToken(token, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'checkAuthenticationBotToken',
    token = tostring(token)
  }, callback or dl_cb, data))
end

-- Closes the TDLib instance after a proper logout.
-- Requires an available network connection.
-- All local data will be destroyed.
-- After the logout completes, updateAuthorizationState with authorizationStateClosed will be sent
function tdbot.logOut(callback, data)
  assert (tdbot_function ({
    ["@type"] = 'logOut'
  }, callback or dl_cb, data))
end

-- Closes the TDLib instance.
-- All databases will be flushed to disk and properly closed.
-- After the close completes, updateAuthorizationState with authorizationStateClosed will be sent
function tdbot.close(callback, data)
  assert (tdbot_function ({
    ["@type"] = 'close'
  }, callback or dl_cb, data))
end

-- Closes the TDLib instance, destroying all local data without a proper logout.
-- The current user session will remain in the list of all active sessions.
-- All local data will be destroyed.
-- After the destruction completes updateAuthorizationState with authorizationStateClosed will be sent
function tdbot.destroy(callback, data)
  assert (tdbot_function ({
    ["@type"] = 'destroy'
  }, callback or dl_cb, data))
end

-- Changes the database encryption key.
-- Usually the encryption key is never changed and is stored in some OS keychain
-- @new_encryption_key New encryption key
function tdbot.setDatabaseEncryptionKey(new_encryption_key, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'setDatabaseEncryptionKey',
    new_encryption_key = new_encryption_key
  }, callback or dl_cb, data))
end

-- Returns the current state of 2-step verification
function tdbot.getPasswordState(callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getPasswordState'
  }, callback or dl_cb, data))
end

-- Changes the password for the user.
-- If a new recovery email address is specified, then the error EMAIL_UNCONFIRMED is returned and the password change will not be applied until the new recovery email address has been confirmed.
-- The application should periodically call getPasswordState to check whether the new email address has been confirmed
-- @old_password Previous password of the user
-- @new_password New password of the user; may be empty to remove the password
-- @new_hint New password hint; may be empty
-- @set_recovery_email_address Pass true if the recovery email address should be changed
-- @new_recovery_email_address New recovery email address; may be empty
function tdbot.setPassword(old_password, new_password, new_hint, set_recovery_email_address, new_recovery_email_address, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'setPassword',
    old_password = tostring(old_password),
    new_password = tostring(new_password),
    new_hint = tostring(new_hint),
    set_recovery_email_address = set_recovery_email_address,
    new_recovery_email_address = tostring(new_recovery_email_address)
  }, callback or dl_cb, data))
end

-- Returns a recovery email address that was previously set up.
-- This method can be used to verify a password provided by the user
-- @password The password for the current user
function tdbot.getRecoveryEmailAddress(password, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getRecoveryEmailAddress',
    password = tostring(password)
  }, callback or dl_cb, data))
end

-- Changes the recovery email address of the user.
-- If a new recovery email address is specified, then the error EMAIL_UNCONFIRMED is returned and the email address will not be changed until the new email has been confirmed.
-- The application should periodically call getPasswordState to check whether the email address has been confirmed.
-- If new_recovery_email_address is the same as the email address that is currently set up, this call succeeds immediately and aborts all other requests waiting for an email confirmation
-- @password Password of the current user
-- @new_recovery_email_address New recovery email address
function tdbot.setRecoveryEmailAddress(password, new_recovery_email_address, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'setRecoveryEmailAddress',
    password = tostring(password),
    new_recovery_email_address = tostring(new_recovery_email_address)
  }, callback or dl_cb, data))
end

-- Requests to send a password recovery code to an email address that was previously set up
function tdbot.requestPasswordRecovery(callback, data)
  assert (tdbot_function ({
    ["@type"] = 'requestPasswordRecovery'
  }, callback or dl_cb, data))
end

-- Recovers the password using a recovery code sent to an email address that was previously set up
-- @recovery_code Recovery code to check
function tdbot.recoverPassword(recovery_code, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'recoverPassword',
    recovery_code = tostring(recovery_code)
  }, callback or dl_cb, data))
end

-- Creates a new temporary password for processing payments
-- @password Persistent user password
-- @valid_for Time during which the temporary password will be valid, in seconds; should be between 60 and 86400
function tdbot.createTemporaryPassword(password, valid_for, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'createTemporaryPassword',
    password = tostring(password),
    valid_for = valid_for
  }, callback or dl_cb, data))
end

-- Returns information about the current temporary password
function tdbot.getTemporaryPasswordState(callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getTemporaryPasswordState'
  }, callback or dl_cb, data))
end

-- Handles a DC_UPDATE push service notification.
-- Can be called before authorization
-- @dc Value of the "dc" parameter of the notification
-- @addr Value of the "addr" parameter of the notification
function tdbot.processDcUpdate(dc, addr, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'processDcUpdate',
    dc = tostring(dc),
    addr = tostring(addr)
  }, callback or dl_cb, data))
end

-- Returns the current user
function tdbot.getMe(callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getMe'
  }, callback or dl_cb, data))
end

-- Returns information about a user by their identifier.
-- This is an offline request if the current user is not a bot
-- @user_id User identifier
function tdbot.getUser(user_id, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getUser',
    user_id = user_id
  }, callback or dl_cb, data))
end

-- Returns full information about a user by their identifier
-- @user_id User identifier
function tdbot.getUserFullInfo(user_id, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getUserFullInfo',
    user_id = user_id
  }, callback or dl_cb, data))
end

-- Returns information about a basic group by its identifier.
-- This is an offline request if the current user is not a bot
-- @basic_group_id Basic group identifier
function tdbot.getBasicGroup(basic_group_id, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getBasicGroup',
    basic_group_id = getChatId(basic_group_id).id
  }, callback or dl_cb, data))
end

-- Returns full information about a basic group by its identifier
-- @basic_group_id Basic group identifier
function tdbot.getBasicGroupFullInfo(basic_group_id, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getBasicGroupFullInfo',
    basic_group_id = getChatId(basic_group_id).id
  }, callback or dl_cb, data))
end

-- Returns information about a supergroup or channel by its identifier.
-- This is an offline request if the current user is not a bot
-- @supergroup_id Supergroup or channel identifier
function tdbot.getSupergroup(supergroup_id, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getSupergroup',
    supergroup_id = getChatId(supergroup_id).id
  }, callback or dl_cb, data))
end

-- Returns full information about a supergroup or channel by its identifier, cached for up to 1 minute
-- @supergroup_id Supergroup or channel identifier
function tdbot.getSupergroupFullInfo(supergroup_id, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getSupergroupFullInfo',
    supergroup_id = getChatId(supergroup_id).id
  }, callback or dl_cb, data))
end

-- Returns information about a secret chat by its identifier.
-- This is an offline request
-- @secret_chat_id Secret chat identifier
function tdbot.getSecretChat(secret_chat_id, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getSecretChat',
    secret_chat_id = secret_chat_id
  }, callback or dl_cb, data))
end

-- Returns information about a chat by its identifier, this is an offline request if the current user is not a bot
-- @chat_id Chat identifier
function tdbot.getChat(chat_id, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getChat',
    chat_id = chat_id
  }, callback or dl_cb, data))
end

-- Returns information about a message
-- @chat_id Identifier of the chat the message belongs to
-- @message_id Identifier of the message to get
function tdbot.getMessage(chat_id, message_id, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getMessage',
    chat_id = chat_id,
    message_id = message_id
  }, callback or dl_cb, data))
end

-- Returns information about a message that is replied by given message
-- @chat_id Identifier of the chat the message belongs to
-- @message_id Identifier of the message reply to which get
function tdbot.getRepliedMessage(chat_id, message_id, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getRepliedMessage',
    chat_id = chat_id,
    message_id = message_id
  }, callback or dl_cb, data))
end

-- Returns information about a pinned chat message
-- @chat_id Identifier of the chat the message belongs to
function tdbot.getChatPinnedMessage(chat_id, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getChatPinnedMessage',
    chat_id = chat_id
  }, callback or dl_cb, data))
end

-- Returns information about messages.
-- If a message is not found, returns null on the corresponding position of the result
-- @chat_id Identifier of the chat the messages belong to
-- @message_ids Identifiers of the messages to get
function tdbot.getMessages(chat_id, message_ids, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getMessages',
    chat_id = chat_id,
    message_ids = vectorize(message_ids)
  }, callback or dl_cb, data))
end

-- Returns information about a file; this is an offline request
-- @file_id Identifier of the file to get
function tdbot.getFile(file_id, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getFile',
    file_id = file_id
  }, callback or dl_cb, data))
end

-- Returns information about a file by its remote ID; this is an offline request.
-- Can be used to register a URL as a file for further uploading, or sending as a message
-- @remote_file_id Remote identifier of the file to get
-- @file_type File type, if known: None|Animation|Audio|Document|Photo|ProfilePhoto|Secret|Sticker|Thumbnail|Unknown|Video|VideoNote|VoiceNote|Wallpaper|SecretThumbnail
function tdbot.getRemoteFile(remote_file_id, file_type, callback, data)
  local file_type = file_type or 'Unknown'
  assert (tdbot_function ({
    ["@type"] = 'getRemoteFile',
    remote_file_id = tostring(remote_file_id),
    file_type = {
      ["@type"] = 'fileType' .. file_type
    }
  }, callback or dl_cb, data))
end

-- Returns an ordered list of chats.
-- Chats are sorted by the pair (order, chat_id) in decreasing order.
-- (For example, to get a list of chats from the beginning, the offset_order should be equal to 2^63 - 1).
-- For optimal performance the number of returned chats is chosen by the library.
-- @offset_order Chat order to return chats from
-- @offset_chat_id Chat identifier to return chats from
-- @limit The maximum number of chats to be returned.
-- It is possible that fewer chats than the limit are returned even if the end of the list is not reached
function tdbot.getChats(offset_chat_id, limit, offset_order, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getChats',
    offset_order = offset_order or '9223372036854775807',
    offset_chat_id = offset_chat_id or 0,
    limit = limit or 20
  }, callback or dl_cb, data))
end

-- Searches a public chat by its username.
-- Currently only private chats, supergroups and channels can be public.
-- Returns the chat if found; otherwise an error is returned
-- @username Username to be resolved
function tdbot.searchPublicChat(username, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'searchPublicChat',
    username = tostring(username)
  }, callback or dl_cb, data))
end

-- Searches public chats by looking for specified query in their username and title.
-- Currently only private chats, supergroups and channels can be public.
-- Returns a meaningful number of results.
-- Returns nothing if the length of the searched username prefix is less than 5.
-- Excludes private chats with contacts and chats from the chat list from the results
-- @query Query to search for
function tdbot.searchPublicChats(query, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'searchPublicChats',
    query = tostring(query)
  }, callback or dl_cb, data))
end

-- Searches for the specified query in the title and username of already known chats, this is an offline request.
-- Returns chats in the order seen in the chat list
-- @query Query to search for.
-- If the query is empty, returns up to 20 recently found chats
-- @limit Maximum number of chats to be returned
function tdbot.searchChats(query, limit, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'searchChats',
    query = tostring(query),
    limit = limit
  }, callback or dl_cb, data))
end

-- Searches for the specified query in the title and username of already known chats via request to the server.
-- Returns chats in the order seen in the chat list
-- @query Query to search for
-- @limit Maximum number of chats to be returned
function tdbot.searchChatsOnServer(query, limit, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'searchChatsOnServer',
    query = tostring(query),
    limit = limit
  }, callback or dl_cb, data))
end

-- Returns a list of frequently used chats.
-- Supported only if the chat info database is enabled
-- @category Category of chats to be returned: Users|Bots|Groups|Channels|InlineBots|Calls
-- @limit Maximum number of chats to be returned; up to 30
function tdbot.getTopChats(category, limit, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getTopChats',
    category = {
      ["@type"] = 'topChatCategory' .. category
    },
    limit = setLimit(30, limit)
  }, callback or dl_cb, data))
end

-- Removes a chat from the list of frequently used chats.
-- Supported only if the chat info database is enabled
-- @category Category of frequently used chats
-- @chat_id Chat identifier
function tdbot.removeTopChat(category, chat_id, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'removeTopChat',
    category = {
      ["@type"] = 'topChatCategory' .. category
    },
    chat_id = chat_id
  }, callback or dl_cb, data))
end

-- Adds a chat to the list of recently found chats.
-- The chat is added to the beginning of the list.
-- If the chat is already in the list, it will be removed from the list first
-- @chat_id Identifier of the chat to add
function tdbot.addRecentlyFoundChat(chat_id, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'addRecentlyFoundChat',
    chat_id = chat_id
  }, callback or dl_cb, data))
end

-- Removes a chat from the list of recently found chats
-- @chat_id Identifier of the chat to be removed
function tdbot.removeRecentlyFoundChat(chat_id, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'removeRecentlyFoundChat',
    chat_id = chat_id
  }, callback or dl_cb, data))
end

-- Clears the list of recently found chats
function tdbot.clearRecentlyFoundChats(callback, data)
  assert (tdbot_function ({
    ["@type"] = 'clearRecentlyFoundChats'
  }, callback or dl_cb, data))
end

-- Checks whether a username can be set for a chat
-- @chat_id Chat identifier; should be identifier of a supergroup chat, or a channel chat, or a private chat with self, or zero if chat is being created
-- @username Username to be checked
function tdbot.checkChatUsername(chat_id, username, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'checkChatUsername',
    chat_id = chat_id,
    username = tostring(username)
  }, callback or dl_cb, data))
end

-- Returns a list of public chats created by the user
function tdbot.getCreatedPublicChats(callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getCreatedPublicChats'
  }, callback or dl_cb, data))
end

-- Returns a list of common chats with a given user.
-- Chats are sorted by their type and creation date
-- @user_id User identifier
-- @offset_chat_id Chat identifier starting from which to return chats; use 0 for the first request
-- @limit Maximum number of chats to be returned; up to 100
function tdbot.getGroupsInCommon(user_id, offset_chat_id, limit, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getGroupsInCommon',
    user_id = user_id,
    offset_chat_id = offset_chat_id or 0,
    limit = setLimit(100, limit)
  }, callback or dl_cb, data))
end

-- Returns messages in a chat.
-- The messages are returned in a reverse chronological order (i.e., in order of decreasing message_id).
-- For optimal performance the number of returned messages is chosen by the library.
-- This is an offline request if only_local is true
-- @chat_id Chat identifier
-- @from_message_id Identifier of the message starting from which history must be fetched; use 0 to get results from the beginning (i.e., from oldest to newest)
-- @offset Specify 0 to get results from exactly the from_message_id or a negative offset to get the specified message and some newer messages
-- @limit The maximum number of messages to be returned; must be positive and can't be greater than 100.
-- If the offset is negative, the limit must be greater than -offset.
-- Fewer messages may be returned than specified by the limit, even if the end of the message history has not been reached
-- @only_local If true, returns only messages that are available locally without sending network requests
function tdbot.getChatHistory(chat_id, from_message_id, offset, limit, only_local, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getChatHistory',
    chat_id = chat_id,
    from_message_id = from_message_id,
    offset = offset,
    limit = setLimit(100, limit),
    only_local = only_local
  }, callback or dl_cb, data))
end

-- Deletes all messages in the chat only for the user.
-- Cannot be used in channels and public supergroups
-- @chat_id Chat identifier
-- @remove_from_chat_list Pass true if the chat should be removed from the chats list
function tdbot.deleteChatHistory(chat_id, remove_from_chat_list, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'deleteChatHistory',
    chat_id = chat_id,
    remove_from_chat_list = remove_from_chat_list
  }, callback or dl_cb, data))
end

-- Searches for messages with given words in the chat.
-- Returns the results in reverse chronological order, i.e.
-- in order of decreasing message_id.
-- Cannot be used in secret chats with a non-empty query (searchSecretMessages should be used instead), or without an enabled message database.
-- For optimal performance the number of returned messages is chosen by the library
-- @chat_id Identifier of the chat in which to search messages
-- @query Query to search for
-- @sender_user_id If not 0, only messages sent by the specified user will be returned.
-- Not supported in secret chats
-- @from_message_id Identifier of the message starting from which history must be fetched; use 0 to get results from the beginning
-- @offset Specify 0 to get results from exactly the from_message_id or a negative offset to get the specified message and some newer messages
-- @limit The maximum number of messages to be returned; must be positive and can't be greater than 100.
-- If the offset is negative, the limit must be greater than -offset.
-- Fewer messages may be returned than specified by the limit, even if the end of the message history has not been reached
-- @filter Filter for message content in the search results: Empty|Animation|Audio|Document|Photo|Video|VoiceNote|PhotoAndVideo|Url|ChatPhoto|Call|MissedCall|VideoNote|VoiceAndVideoNote|Mention|UnreadMention
function tdbot.searchChatMessages(chat_id, query, filter, sender_user_id, from_message_id, offset, limit, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'searchChatMessages',
    chat_id = chat_id,
    query = tostring(query),
    sender_user_id = sender_user_id or 0,
    from_message_id = from_message_id or 0,
    offset = offset or 0,
    limit = setLimit(100, limit),
    filter = {
      ["@type"] = 'searchMessagesFilter' .. filter
    }
  }, callback or dl_cb, data))
end

-- Searches for messages in all chats except secret chats.
-- Returns the results in reverse chronological order (i.e., in order of decreasing (date, chat_id, message_id)).
-- For optimal performance the number of returned messages is chosen by the library
-- @query Query to search for
-- @offset_date The date of the message starting from which the results should be fetched.
-- Use 0 or any date in the future to get results from the beginning
-- @offset_chat_id The chat identifier of the last found message, or 0 for the first request
-- @offset_message_id The message identifier of the last found message, or 0 for the first request
-- @limit The maximum number of messages to be returned, up to 100.
-- Fewer messages may be returned than specified by the limit, even if the end of the message history has not been reached
function tdbot.searchMessages(query, offset_date, offset_chat_id, offset_message_id, limit, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'searchMessages',
    query = tostring(query),
    offset_date = offset_date or 0,
    offset_chat_id = offset_chat_id or 0,
    offset_message_id = offset_message_id or 0,
    limit = setLimit(100, limit)
  }, callback or dl_cb, data))
end

-- Searches for messages in secret chats.
-- Returns the results in reverse chronological order.
-- For optimal performance the number of returned messages is chosen by the library
-- @chat_id Identifier of the chat in which to search.
-- Specify 0 to search in all secret chats
-- @query Query to search for.
-- If empty, searchChatMessages should be used instead
-- @from_search_id The identifier from the result of a previous request, use 0 to get results from the beginning
-- @limit Maximum number of messages to be returned; up to 100.
-- Fewer messages may be returned than specified by the limit, even if the end of the message history has not been reached
-- @filter A filter for the content of messages in the search results: Empty|Animation|Audio|Document|Photo|Video|VoiceNote|PhotoAndVideo|Url|ChatPhoto|Call|MissedCall|VideoNote|VoiceAndVideoNote|Mention|UnreadMention
function tdbot.searchSecretMessages(chat_id, query, from_search_id, limit, filter, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'searchSecretMessages',
    chat_id = chat_id or 0,
    query = tostring(query),
    from_search_id = from_search_id or 0,
    limit = setLimit(100, limit),
    filter = {
      ["@type"] = 'searchMessagesFilter' .. filter
    }
  }, callback or dl_cb, data))
end

-- Searches for call messages.
-- Returns the results in reverse chronological order (i.
-- e., in order of decreasing message_id).
-- For optimal performance the number of returned messages is chosen by the library
-- @from_message_id Identifier of the message from which to search; use 0 to get results from the beginning
-- @limit The maximum number of messages to be returned; up to 100.
-- Fewer messages may be returned than specified by the limit, even if the end of the message history has not been reached
-- @only_missed If true, returns only messages with missed calls
function tdbot.searchCallMessages(from_message_id, limit, only_missed, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'searchCallMessages',
    from_message_id = from_message_id or 0,
    limit = setLimit(100, limit),
    only_missed = only_missed
  }, callback or dl_cb, data))
end

-- Returns information about the recent locations of chat members that were sent to the chat.
-- Returns up to 1 location message per user
-- @chat_id Chat identifier
-- @limit Maximum number of messages to be returned
function tdbot.searchChatRecentLocationMessages(chat_id, limit, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'searchChatRecentLocationMessages',
    chat_id = chat_id,
    limit = limit
  }, callback or dl_cb, data))
end

-- Returns all active live locations that should be updated by the client.
-- The list is persistent across application restarts only if the message database is used
function tdbot.getActiveLiveLocationMessages(callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getActiveLiveLocationMessages'
  }, callback or dl_cb, data))
end

-- Returns the last message sent in a chat no later than the specified date
-- @chat_id Chat identifier
-- @date Point in time (Unix timestamp) relative to which to search for messages
function tdbot.getChatMessageByDate(chat_id, date, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getChatMessageByDate',
    chat_id = chat_id,
    date = date
  }, callback or dl_cb, data))
end

-- Returns a public HTTPS link to a message.
-- Available only for messages in public supergroups and channels
-- @chat_id Identifier of the chat to which the message belongs
-- @message_id Identifier of the message
-- @for_album Pass true if a link for a whole media album should be returned
function tdbot.getPublicMessageLink(chat_id, message_id, for_album, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getPublicMessageLink',
    chat_id = chat_id,
    message_id = message_id,
    for_album = for_album
  }, callback or dl_cb, data))
end

-- Sends messages grouped together into an album.
-- Currently only photo and video messages can be grouped into an album.
-- Returns sent messages
-- @chat_id Target chat
-- @reply_to_message_id Identifier of a message to reply to or 0
-- @disable_notification Pass true to disable notification for the messages.
-- Not supported in secret chats
-- @from_background Pass true if the messages are sent from the background
-- @input_message_contents Contents of messages to be sent
function tdbot.sendMessageAlbum(chat_id, reply_to_message_id, input_message_contents, disable_notification, from_background, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'sendMessageAlbum',
    chat_id = chat_id,
    reply_to_message_id = reply_to_message_id or 0,
    disable_notification = disable_notification,
    from_background = from_background,
    input_message_contents = vectorize(input_message_contents)
  }, callback or dl_cb, data))
end

-- Invites a bot to a chat (if it is not yet a member) and sends it the /start command.
-- Bots can't be invited to a private chat other than the chat with the bot.
-- Bots can't be invited to channels (although they can be added as admins) and secret chats.
-- Returns the sent message
-- @bot_user_id Identifier of the bot
-- @chat_id Identifier of the target chat
-- @parameter A hidden parameter sent to the bot for deep linking purposes (https://api.telegram.org/bots#deep-linking)
function tdbot.sendBotStartMessage(bot_user_id, chat_id, parameter, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'sendBotStartMessage',
    bot_user_id = bot_user_id,
    chat_id = chat_id,
    parameter = tostring(parameter)
  }, callback or dl_cb, data))
end

-- Sends the result of an inline query as a message.
-- Returns the sent message.
-- Always clears a chat draft message
-- @chat_id Target chat
-- @reply_to_message_id Identifier of a message to reply to or 0
-- @disable_notification Pass true to disable notification for the message.
-- Not supported in secret chats
-- @from_background Pass true if the message is sent from background
-- @query_id Identifier of the inline query
-- @result_id Identifier of the inline result
function tdbot.sendInlineQueryResultMessage(chat_id, reply_to_message_id, disable_notification, from_background, query_id, result_id, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'sendInlineQueryResultMessage',
    chat_id = chat_id,
    reply_to_message_id = reply_to_message_id,
    disable_notification = disable_notification,
    from_background = from_background,
    query_id = query_id,
    result_id = tostring(result_id)
  }, callback or dl_cb, data))
end

-- Forwards previously sent messages.
-- Returns the forwarded messages in the same order as the message identifiers passed in message_ids.
-- If a message can't be forwarded, null will be returned instead of the message
-- @chat_id Identifier of the chat to which to forward messages
-- @from_chat_id Identifier of the chat from which to forward messages
-- @message_ids Identifiers of the messages to forward
-- @disable_notification Pass true to disable notification for the message, doesn't work if messages are forwarded to a secret chat
-- @from_background Pass true if the message is sent from the background
-- @as_album True, if the messages should be grouped into an album after forwarding.
-- For this to work, no more than 10 messages may be forwarded, and all of them must be photo or video messages
function tdbot.forwardMessages(chat_id, from_chat_id, message_ids, disable_notification, from_background, as_album, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'forwardMessages',
    chat_id = chat_id,
    from_chat_id = from_chat_id,
    message_ids = vectorize(message_ids),
    disable_notification = disable_notification,
    from_background = from_background,
    as_album = as_album
  }, callback or dl_cb, data))
end

-- Changes the current TTL setting (sets a new self-destruct timer) in a secret chat and sends the corresponding message
-- @chat_id Chat identifier
-- @ttl New TTL value, in seconds
function tdbot.sendChatSetTtlMessage(chat_id, ttl, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'sendChatSetTtlMessage',
    chat_id = chat_id,
    ttl = ttl
  }, callback or dl_cb, data))
end

-- Sends a notification about a screenshot taken in a chat.
-- Supported only in private and secret chats
-- @chat_id Chat identifier
function tdbot.sendChatScreenshotTakenNotification(chat_id, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'sendChatScreenshotTakenNotification',
    chat_id = chat_id
  }, callback or dl_cb, data))
end

-- Deletes messages
-- @chat_id Chat identifier
-- @message_ids Identifiers of the messages to be deleted
-- @revoke Pass true to try to delete outgoing messages for all chat members (may fail if messages are too old).
-- Always true for supergroups, channels and secret chats
function tdbot.deleteMessages(chat_id, message_ids, revoke, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'deleteMessages',
    chat_id = chat_id,
    message_ids = vectorize(message_ids),
    revoke = revoke
  }, callback or dl_cb, data))
end

-- Deletes all messages sent by the specified user to a chat.
-- Supported only in supergroups; requires can_delete_messages administrator privileges
-- @chat_id Chat identifier
-- @user_id User identifier
function tdbot.deleteChatMessagesFromUser(chat_id, user_id, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'deleteChatMessagesFromUser',
    chat_id = chat_id,
    user_id = user_id
  }, callback or dl_cb, data))
end

-- Edits the text of a message (or a text of a game message).
-- Non-bot users can edit messages for a limited period of time.
-- Returns the edited message after the edit is completed on the server side
-- @chat_id The chat the message belongs to
-- @message_id Identifier of the message
-- @reply_markup The new message reply markup; for bots only
-- @input_message_content New text content of the message.
-- Should be of type InputMessageText
function tdbot.editMessageText(chat_id, message_id, text, parse_mode, disable_web_page_preview, clear_draft, reply_markup, callback, data)
  local tdbody = {
    ["@type"] = 'editMessageText',
    chat_id = chat_id,
    message_id = message_id,
    reply_markup = reply_markup,
    input_message_content = {
      ["@type"] = 'inputMessageText',
      disable_web_page_preview = disable_web_page_preview,
      text = {text = text},
      clear_draft = clear_draft
    }
  }
  if parse_mode then
    parseTextEntities(text, parse_mode, function(a, d)
      a.tdbody.input_message_content.text = d
      assert (tdbot_function (a.tdbody, a.callback or dl_cb, a.data))
    end, {tdbody = tdbody, callback = callback, data = data})
  else
    assert (tdbot_function (tdbody, callback or dl_cb, data))
  end
end

-- Edits the message content of a live location.
-- Messages can be edited for a limited period of time specified in the live location.
-- Returns the edited message after the edit is completed server-side
-- @chat_id The chat the message belongs to
-- @message_id Identifier of the message
-- @reply_markup Tew message reply markup; for bots only
-- @location New location content of the message; may be null.
-- Pass null to stop sharing the live location
function tdbot.editMessageLiveLocation(chat_id, message_id, latitude, longitude, reply_markup, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'editMessageLiveLocation',
    chat_id = chat_id,
    message_id = message_id,
    reply_markup = reply_markup,
    location = {
      ["@type"] = 'location',
      latitude = latitude,
      longitude = longitude
    }
  }, callback or dl_cb, data))
end

-- Edits the message content caption.
-- Non-bots can edit messages for a limited period of time.
-- Returns the edited message after the edit is completed server-side
-- @chat_id The chat the message belongs to
-- @message_id Identifier of the message
-- @reply_markup The new message reply markup; for bots only
-- @caption New message content caption; 0-200 characters
function tdbot.editMessageCaption(chat_id, message_id, caption, reply_markup, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'editMessageCaption',
    chat_id = chat_id,
    message_id = message_id,
    reply_markup = reply_markup,
    caption = {
      ["@type"] = 'formattedText',
      text = tostring(caption)
    }
  }, callback or dl_cb, data))
end

-- Edits the message reply markup; for bots only.
-- Returns the edited message after the edit is completed server-side
-- @chat_id The chat the message belongs to
-- @message_id Identifier of the message
-- @reply_markup New message reply markup
function tdbot.editMessageReplyMarkup(chat_id, message_id, reply_markup, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'editMessageReplyMarkup',
    chat_id = chat_id,
    message_id = message_id,
    reply_markup = reply_markup
  }, callback or dl_cb, data))
end

-- Edits the text of an inline text or game message sent via a bot; for bots only
-- @inline_message_id Inline message identifier
-- @reply_markup New message reply markup
-- @input_message_content New text content of the message.
-- Should be of type InputMessageText
function tdbot.editInlineMessageText(inline_message_id, reply_markup, input_message_content, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'editInlineMessageText',
    inline_message_id = tostring(inline_message_id),
    reply_markup = reply_markup,
    input_message_content = input_message_content
  }, callback or dl_cb, data))
end

-- Edits the content of a live location in an inline message sent via a bot; for bots only
-- @inline_message_id Inline message identifier
-- @reply_markup New message reply markup
-- @location New location content of the message; may be null.
-- Pass null to stop sharing the live location
function tdbot.editInlineMessageLiveLocation(inline_message_id, latitude, longitude, reply_markup, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'editInlineMessageLiveLocation',
    inline_message_id = tostring(inline_message_id),
    reply_markup = reply_markup,
    location = {
      ["@type"] = 'location',
      latitude = latitude,
      longitude = longitude
    }
  }, callback or dl_cb, data))
end

-- Edits the caption of an inline message sent via a bot; for bots only
-- @inline_message_id Inline message identifier
-- @reply_markup New message reply markup
-- @caption New message content caption; 0-200 characters
function tdbot.editInlineMessageCaption(inline_message_id, caption, reply_markup, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'editInlineMessageCaption',
    inline_message_id = tostring(inline_message_id),
    reply_markup = reply_markup,
    caption = {
      ["@type"] = 'formattedText',
      text = tostring(caption)
    }
  }, callback or dl_cb, data))
end

-- Edits the reply markup of an inline message sent via a bot; for bots only
-- @inline_message_id Inline message identifier
-- @reply_markup New message reply markup
function tdbot.editInlineMessageReplyMarkup(inline_message_id, reply_markup, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'editInlineMessageReplyMarkup',
    inline_message_id = tostring(inline_message_id),
    reply_markup = reply_markup
  }, callback or dl_cb, data))
end

-- Returns all entities (mentions, hashtags, cashtags, bot commands, URLs, and email addresses) contained in the text.
-- This is an offline method.
-- Can be called before authorization.
-- Can be called synchronously
-- @text The text in which to look for entites
function tdbot.getTextEntities(text, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getTextEntities',
    text = tostring(text)
  }, callback or dl_cb, data))
end

-- Returns the MIME type of a file, guessed by its extension.
-- Returns an empty string on failure.
-- This is an offline method.
-- Can be called before authorization.
-- Can be called synchronously
-- @file_name The name of the file or path to the file
function tdbot.getFileMimeType(file_name, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getFileMimeType',
    file_name = tostring(file_name)
  }, callback or dl_cb, data))
end

-- Returns the extension of a file, guessed by its MIME type.
-- Returns an empty string on failure.
-- This is an offline method.
-- Can be called before authorization.
-- Can be called synchronously
-- @mime_type The MIME type of the file
function tdbot.getFileExtension(mime_type, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getFileExtension',
    mime_type = tostring(mime_type)
  }, callback or dl_cb, data))
end

-- Sends an inline query to a bot and returns its results.
-- Returns an error with code 502 if the bot fails to answer the query before the query timeout expires
-- @bot_user_id The identifier of the target bot
-- @chat_id Identifier of the chat, where the query was sent
-- @user_location Location of the user, only if needed
-- @query Text of the query
-- @offset Offset of the first entry to return
function tdbot.getInlineQueryResults(bot_user_id, chat_id, latitude, longitude, query, offset, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getInlineQueryResults',
    bot_user_id = bot_user_id,
    chat_id = chat_id,
    user_location = {
      ["@type"] = 'location',
      latitude = latitude,
      longitude = longitude
    },
    query = tostring(query),
    offset = tostring(offset)
  }, callback or dl_cb, data))
end

-- Sets the result of an inline query; for bots only
-- @inline_query_id Identifier of the inline query
-- @is_personal True, if the result of the query can be cached for the specified user
-- @results The results of the query
-- @cache_time Allowed time to cache the results of the query, in seconds
-- @next_offset Offset for the next inline query; pass an empty string if there are no more results
-- @switch_pm_text If non-empty, this text should be shown on the button that opens a private chat with the bot and sends a start message to the bot with the parameter switch_pm_parameter
-- @switch_pm_parameter The parameter for the bot start message
function tdbot.answerInlineQuery(inline_query_id, is_personal, results, cache_time, next_offset, switch_pm_text, switch_pm_parameter, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'answerInlineQuery',
    inline_query_id = inline_query_id,
    is_personal = is_personal,
    --results = vector<InputInlineQueryResult>,
    cache_time = cache_time,
    next_offset = tostring(next_offset),
    switch_pm_text = tostring(switch_pm_text),
    switch_pm_parameter = tostring(switch_pm_parameter)
  }, callback or dl_cb, data))
end

-- Sends a callback query to a bot and returns an answer.
-- Returns an error with code 502 if the bot fails to answer the query before the query timeout expires
-- @chat_id Identifier of the chat with the message
-- @message_id Identifier of the message from which the query originated
-- @payload Query payload: Data or Game
function tdbot.getCallbackQueryAnswer(chat_id, message_id, payload, data, game_short_name, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getCallbackQueryAnswer',
    chat_id = chat_id,
    message_id = message_id,
    payload = {
      ["@type"] = 'callbackQueryPayload' .. payload,
      data = data,
      game_short_name = game_short_name
    }
  }, callback or dl_cb, data))
end

-- Sets the result of a callback query; for bots only
-- @callback_query_id Identifier of the callback query
-- @text Text of the answer
-- @show_alert If true, an alert should be shown to the user instead of a toast notification
-- @url URL to be opened
-- @cache_time Time during which the result of the query can be cached, in seconds
function tdbot.answerCallbackQuery(callback_query_id, text, show_alert, url, cache_time, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'answerCallbackQuery',
    callback_query_id = callback_query_id,
    text = tostring(text),
    show_alert = show_alert,
    url = tostring(url),
    cache_time = cache_time
  }, callback or dl_cb, data))
end

-- Sets the result of a shipping query; for bots only
-- @shipping_query_id Identifier of the shipping query
-- @shipping_options Available shipping options
-- @error_message An error message, empty on success
function tdbot.answerShippingQuery(shipping_query_id, shipping_options, error_message, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'answerShippingQuery',
    shipping_query_id = shipping_query_id,
    -- shipping_options = vector<shippingOption>,
    error_message = tostring(error_message)
  }, callback or dl_cb, data))
end

-- Sets the result of a pre-checkout query; for bots only
-- @pre_checkout_query_id Identifier of the pre-checkout query
-- @error_message An error message, empty on success
function tdbot.answerPreCheckoutQuery(pre_checkout_query_id, error_message, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'answerPreCheckoutQuery',
    pre_checkout_query_id = pre_checkout_query_id,
    error_message = tostring(error_message)
  }, callback or dl_cb, data))
end

-- Updates the game score of the specified user in the game; for bots only
-- @chat_id The chat to which the message with the game
-- @message_id Identifier of the message
-- @edit_message True, if the message should be edited
-- @user_id User identifier
-- @score The new score
-- @force Pass true to update the score even if it decreases.
-- If the score is 0, the user will be deleted from the high score table
function tdbot.setGameScore(chat_id, message_id, edit_message, user_id, score, force, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'setGameScore',
    chat_id = chat_id,
    message_id = message_id,
    edit_message = edit_message,
    user_id = user_id,
    score = score,
    force = force
  }, callback or dl_cb, data))
end

-- Updates the game score of the specified user in a game; for bots only
-- @inline_message_id Inline message identifier
-- @edit_message True, if the message should be edited
-- @user_id User identifier
-- @score The new score
-- @force Pass true to update the score even if it decreases.
-- If the score is 0, the user will be deleted from the high score table
function tdbot.setInlineGameScore(inline_message_id, edit_message, user_id, score, force, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'setInlineGameScore',
    inline_message_id = tostring(inline_message_id),
    edit_message = edit_message,
    user_id = user_id,
    score = score,
    force = force
  }, callback or dl_cb, data))
end

-- Returns the high scores for a game and some part of the high score table in the range of the specified user; for bots only
-- @chat_id The chat that contains the message with the game
-- @message_id Identifier of the message
-- @user_id User identifier
function tdbot.getGameHighScores(chat_id, message_id, user_id, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getGameHighScores',
    chat_id = chat_id,
    message_id = message_id,
    user_id = user_id
  }, callback or dl_cb, data))
end

-- Returns game high scores and some part of the high score table in the range of the specified user; for bots only
-- @inline_message_id Inline message identifier
-- @user_id User identifier
function tdbot.getInlineGameHighScores(inline_message_id, user_id, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getInlineGameHighScores',
    inline_message_id = tostring(inline_message_id),
    user_id = user_id
  }, callback or dl_cb, data))
end

-- Deletes the default reply markup from a chat.
-- Must be called after a one-time keyboard or a ForceReply reply markup has been used.
-- UpdateChatReplyMarkup will be sent if the reply markup will be changed
-- @chat_id Chat identifier
-- @message_id The message identifier of the used keyboard
function tdbot.deleteChatReplyMarkup(chat_id, message_id, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'deleteChatReplyMarkup',
    chat_id = chat_id,
    message_id = message_id
  }, callback or dl_cb, data))
end

-- Sends a notification about user activity in a chat
-- @chat_id Chat identifier
-- @action The action description
-- chatAction: Typing|RecordingVideo|UploadingVideo|RecordingVoiceNote|UploadingVoiceNote|UploadingPhoto|UploadingDocument|ChoosingLocation|ChoosingContact|StartPlayingGame|RecordingVideoNote|UploadingVideoNote|Cancel
-- @progress Upload progress, as a percentage
function tdbot.sendChatAction(chat_id, action, progress, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'sendChatAction',
    chat_id = chat_id,
    action = {
      ["@type"] = 'chatAction' .. action,
      progress = progress or 100
    }
  }, callback or dl_cb, data))
end

-- This method should be called if the chat is opened by the user.
-- Many useful activities depend on the chat being opened or closed (e.g., in supergroups and channels all updates are received only for opened chats)
-- @chat_id Chat identifier
function tdbot.openChat(chat_id, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'openChat',
    chat_id = chat_id
  }, callback or dl_cb, data))
end

-- This method should be called if the chat is closed by the user.
-- Many useful activities depend on the chat being opened or closed
-- @chat_id Chat identifier
function tdbot.closeChat(chat_id, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'closeChat',
    chat_id = chat_id
  }, callback or dl_cb, data))
end

-- This method should be called if messages are being viewed by the user.
-- Many useful activities depend on whether the messages are currently being viewed or not (e.g., marking messages as read, incrementing a view counter, updating a view counter, removing deleted messages in supergroups and channels)
-- @chat_id Chat identifier
-- @message_ids The identifiers of the messages being viewed
-- @force_read True, if messages in closed chats should be marked as read
function tdbot.viewMessages(chat_id, message_ids, force_read, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'viewMessages',
    chat_id = chat_id,
    message_ids = vectorize(message_ids),
    force_read = force_read
  }, callback or dl_cb, data))
end

-- This method should be called if the message content has been opened (e.g., the user has opened a photo, video, document, location or venue, or has listened to an audio file or voice note message).
-- An updateMessageContentOpened update will be generated if something has changed
-- @chat_id Chat identifier of the message
-- @message_id Identifier of the message with the opened content
function tdbot.openMessageContent(chat_id, message_id, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'openMessageContent',
    chat_id = chat_id,
    message_id = message_id
  }, callback or dl_cb, data))
end

-- Marks all mentions in a chat as read
-- @chat_id Chat identifier
function tdbot.readAllChatMentions(chat_id, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'readAllChatMentions',
    chat_id = chat_id
  }, callback or dl_cb, data))
end

-- Returns an existing chat corresponding to a given user
-- @user_id User identifier
-- @force If true, the chat will be created without network request.
-- In this case all information about the chat except its type, title and photo can be incorrect
function tdbot.createPrivateChat(user_id, force, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'createPrivateChat',
    user_id = user_id,
    force = force
  }, callback or dl_cb, data))
end

-- Returns an existing chat corresponding to a known basic group
-- @basic_group_id Basic group identifier
-- @force If true, the chat will be created without network request.
-- In this case all information about the chat except its type, title and photo can be incorrect
function tdbot.createBasicGroupChat(basic_group_id, force, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'createBasicGroupChat',
    basic_group_id = getChatId(basic_group_id).id,
    force = force
  }, callback or dl_cb, data))
end

-- Returns an existing chat corresponding to a known supergroup or channel
-- @supergroup_id Supergroup or channel identifier
-- @force If true, the chat will be created without network request.
-- In this case all information about the chat except its type, title and photo can be incorrect
function tdbot.createSupergroupChat(supergroup_id, force, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'createSupergroupChat',
    supergroup_id = getChatId(supergroup_id).id,
    force = force
  }, callback or dl_cb, data))
end

-- Returns an existing chat corresponding to a known secret chat
-- @secret_chat_id Secret chat identifier
function tdbot.createSecretChat(secret_chat_id, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'createSecretChat',
    secret_chat_id = secret_chat_id
  }, callback or dl_cb, data))
end

-- Creates a new basic group and sends a corresponding messageBasicGroupChatCreate.
-- Returns the newly created chat
-- @user_ids Identifiers of users to be added to the basic group
-- @title Title of the new basic group; 1-255 characters
function tdbot.createNewBasicGroupChat(user_ids, title, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'createNewBasicGroupChat',
    user_ids = vectorize(user_ids),
    title = tostring(title)
  }, callback or dl_cb, data))
end

-- Creates a new supergroup or channel and sends a corresponding messageSupergroupChatCreate.
-- Returns the newly created chat
-- @title Title of the new chat; 1-255 characters
-- @is_channel True, if a channel chat should be created
-- @param_description Chat description; 0-255 characters
function tdbot.createNewSupergroupChat(title, is_channel, description, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'createNewSupergroupChat',
    title = tostring(title),
    is_channel = is_channel,
    description = tostring(description)
  }, callback or dl_cb, data))
end

-- Creates a new secret chat.
-- Returns the newly created chat
-- @user_id Identifier of the target user
function tdbot.createNewSecretChat(user_id, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'createNewSecretChat',
    user_id = tonumber(user_id)
  }, callback or dl_cb, data))
end

-- Creates a new supergroup from an existing basic group and sends a corresponding messageChatUpgradeTo and messageChatUpgradeFrom.
-- Deactivates the original basic group
-- @chat_id Identifier of the chat to upgrade
function tdbot.upgradeBasicGroupChatToSupergroupChat(chat_id, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'upgradeBasicGroupChatToSupergroupChat',
    chat_id = chat_id
  }, callback or dl_cb, data))
end

-- Changes the chat title.
-- Supported only for basic groups, supergroups and channels.
-- Requires administrator rights in basic groups and the appropriate administrator rights in supergroups and channels.
-- The title will not be changed until the request to the server has been completed
-- @chat_id Chat identifier
-- @title New title of the chat; 1-255 characters
function tdbot.setChatTitle(chat_id, title, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'setChatTitle',
    chat_id = chat_id,
    title = tostring(title)
  }, callback or dl_cb, data))
end

-- Changes the photo of a chat.
-- Supported only for basic groups, supergroups and channels.
-- Requires administrator rights in basic groups and the appropriate administrator rights in supergroups and channels.
-- The photo will not be changed before request to the server has been completed
-- @chat_id Chat identifier
-- @photo New chat photo.
-- You can use a zero InputFileId to delete the chat photo.
-- Files that are accessible only by HTTP URL are not acceptable
function tdbot.setChatPhoto(chat_id, photo, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'setChatPhoto',
    chat_id = chat_id,
    photo = getInputFile(photo)
  }, callback or dl_cb, data))
end

-- Changes the draft message in a chat
-- @chat_id Chat identifier
-- @draft_message New draft message; may be null
function tdbot.setChatDraftMessage(chat_id, reply_to_message_id, text, parse_mode, disable_web_page_preview, clear_draft, callback, data)
  local tdbody = {
    ["@type"] = 'setChatDraftMessage',
    chat_id = chat_id,
    draft_message = {
      ["@type"] = 'draftMessage',
      reply_to_message_id = reply_to_message_id,
      input_message_text = {
        ["@type"] = 'inputMessageText',
        disable_web_page_preview = disable_web_page_preview,
        text = {text = text},
        clear_draft = clear_draft
      }
    }
  }
  if parse_mode then
    parseTextEntities(text, parse_mode, function(a, d)
      a.tdbody.draft_message.input_message_text.text = d
      assert (tdbot_function (a.tdbody, a.callback or dl_cb, a.data))
    end, {tdbody = tdbody, callback = callback, data = data})
  else
    assert (tdbot_function (tdbody, callback or dl_cb, data))
  end
end

-- Changes the pinned state of a chat.
-- You can pin up to GetOption("pinned_chat_count_max") non-secret chats and the same number of secret chats
-- @chat_id Chat identifier
-- @is_pinned New value of is_pinned
function tdbot.toggleChatIsPinned(chat_id, is_pinned, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'toggleChatIsPinned',
    chat_id = chat_id,
    is_pinned = is_pinned
  }, callback or dl_cb, data))
end

-- Changes client data associated with a chat
-- @chat_id Chat identifier
-- @client_data New value of client_data
function tdbot.setChatClientData(chat_id, client_data, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'setChatClientData',
    chat_id = chat_id,
    client_data = tostring(client_data)
  }, callback or dl_cb, data))
end

-- Adds a new member to a chat.
-- Members can't be added to private or secret chats.
-- Members will not be added until the chat state has been synchronized with the server
-- @chat_id Chat identifier
-- @user_id Identifier of the user
-- @forward_limit The number of earlier messages from the chat to be forwarded to the new member; up to 300.
-- Ignored for supergroups and channels
function tdbot.addChatMember(chat_id, user_id, forward_limit, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'addChatMember',
    chat_id = chat_id,
    user_id = user_id,
    forward_limit = setLimit(300, forward_limit)
  }, callback or dl_cb, data))
end

-- Adds multiple new members to a chat.
-- Currently this option is only available for supergroups and channels.
-- This option can't be used to join a chat.
-- Members can't be added to a channel if it has more than 200 members.
-- Members will not be added until the chat state has been synchronized with the server
-- @chat_id Chat identifier
-- @user_ids Identifiers of the users to be added to the chat
function tdbot.addChatMembers(chat_id, user_ids, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'addChatMembers',
    chat_id = chat_id,
    user_ids = vectorize(user_ids)
  }, callback or dl_cb, data))
end

-- Changes the status of a chat member, needs appropriate privileges.
-- This function is currently not suitable for adding new members to the chat; instead, use addChatMember.
-- The chat member status will not be changed until it has been synchronized with the server
-- @chat_id Chat identifier
-- @user_id User identifier
-- @status The new status of the member in the chat
function tdbot.setChatMemberStatus(chat_id, user_id, status, right, callback, data)
  local chat_member_status = {}
  local right = right and vectorize(right) or {}
  if status == 'Creator' then
    chat_member_status = {
      is_member = right[0] or 1
    }
  elseif status == 'Administrator' then
    chat_member_status = {
      can_be_edited = right[0] or 1,
      can_change_info = right[1] or 1,
      can_post_messages = right[2] or 1,
      can_edit_messages = right[3] or 1,
      can_delete_messages = right[4] or 1,
      can_invite_users = right[5] or 1,
      can_restrict_members = right[6] or 1,
      can_pin_messages = right[7] or 1,
      can_promote_members = right[8] or 0
    }
  elseif status == 'Restricted' then
    chat_member_status = {
      is_member = right[0] or 1,
      restricted_until_date = right[1] or 0,
      can_send_messages = right[2] or 1,
      can_send_media_messages = right[3] or 1,
      can_send_other_messages = right[4] or 1,
      can_add_web_page_previews = right[5] or 1
    }
  elseif status == 'Banned' then
    chat_member_status = {
      banned_until_date = right[0] or 0
    }
  end
  chat_member_status["@type"] = 'chatMemberStatus' .. status
  assert (tdbot_function ({
    ["@type"] = 'setChatMemberStatus',
    chat_id = chat_id,
    user_id = user_id,
    status = chat_member_status
  }, callback or dl_cb, data))
end

-- Returns information about a single member of a chat
-- @chat_id Chat identifier
-- @user_id User identifier
function tdbot.getChatMember(chat_id, user_id, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getChatMember',
    chat_id = chat_id,
    user_id = user_id
  }, callback or dl_cb, data))
end

-- Searches for a specified query in the first name, last name and username of the members of a specified chat.
-- Requires administrator rights in channels
-- @chat_id Chat identifier
-- @query Query to search for
-- @limit The maximum number of users to be returned
function tdbot.searchChatMembers(chat_id, query, limit, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'searchChatMembers',
    chat_id = chat_id,
    query = tostring(query),
    limit = limit
  }, callback or dl_cb, data))
end

-- Returns a list of users who are administrators of the chat
-- @chat_id Chat identifier
function tdbot.getChatAdministrators(chat_id, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getChatAdministrators',
    chat_id = chat_id
  }, callback or dl_cb, data))
end

-- Changes the order of pinned chats
-- @chat_ids The new list of pinned chats
function tdbot.setPinnedChats(chat_ids, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'setPinnedChats',
    chat_ids = vectorize(chat_ids)
  }, callback or dl_cb, data))
end

-- Asynchronously downloads a file from the cloud.
-- updateFile will be used to notify about the download progress and successful completion of the download.
-- Returns file state just after the download has been started
-- @file_id Identifier of the file to download
-- @priority Priority of the download (1-32).
-- The higher the priority, the earlier the file will be downloaded.
-- If the priorities of two files are equal, then the last one for which downloadFile was called will be downloaded first
function tdbot.downloadFile(file_id, priority, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'downloadFile',
    file_id = file_id,
    priority = priority or 32
  }, callback or dl_cb, data))
end

-- Stops the downloading of a file.
-- If a file has already been downloaded, does nothing
-- @file_id Identifier of a file to stop downloading
-- @only_if_pending Pass true to stop downloading only if it hasn't been started, i.e.
-- request hasn't been sent to server
function tdbot.cancelDownloadFile(file_id, only_if_pending, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'cancelDownloadFile',
    file_id = file_id,
    only_if_pending = only_if_pending
  }, callback or dl_cb, data))
end

-- Asynchronously uploads a file to the cloud without sending it in a message.
-- updateFile will be used to notify about upload progress and successful completion of the upload.
-- The file will not have a persistent remote identifier until it will be sent in a message
-- @file File to upload
-- @file_type File type
-- @priority Priority of the upload (1-32).
-- The higher the priority, the earlier the file will be uploaded.
-- If the priorities of two files are equal, then the first one for which uploadFile was called will be uploaded first
-- fileType: None|Animation|Audio|Document|Photo|ProfilePhoto|Secret|Sticker|Thumbnail|Unknown|Video|VideoNote|VoiceNote|Wallpaper|SecretThumbnail
function tdbot.uploadFile(file, file_type, priority, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'uploadFile',
    file = getInputFile(file),
    file_type = {
      ["@type"] = 'fileType' .. file_type
    },
    priority = priority or 32
  }, callback or dl_cb, data))
end

-- Stops the uploading of a file.
-- Supported only for files uploaded by using uploadFile.
-- For other files the behavior is undefined
-- @file_id Identifier of the file to stop uploading
function tdbot.cancelUploadFile(file_id, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'cancelUploadFile',
    file_id = file_id
  }, callback or dl_cb, data))
end

-- The next part of a file was generated
-- @generation_id The identifier of the generation process
-- @expected_size Expected size of the generated file, in bytes; 0 if unknown
-- @local_prefix_size The number of bytes already generated
function tdbot.setFileGenerationProgress(generation_id, expected_size, local_prefix_size, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'setFileGenerationProgress',
    generation_id = generation_id,
    expected_size = expected_size or 0,
    local_prefix_size = local_prefix_size
  }, callback or dl_cb, data))
end

-- Finishes the file generation
-- @generation_id The identifier of the generation process
-- @error If set, means that file generation has failed and should be terminated
function tdbot.finishFileGeneration(generation_id, error, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'finishFileGeneration',
    generation_id = generation_id,
    error = error
  }, callback or dl_cb, data))
end

-- Deletes a file from the TDLib file cache
-- @file_id Identifier of the file to delete
function tdbot.deleteFile(file_id, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'deleteFile',
    file_id = file_id
  }, callback or dl_cb, data))
end

-- Generates a new invite link for a chat; the previously generated link is revoked.
-- Available for basic groups, supergroups, and channels.
-- In basic groups this can be called only by the group's creator; in supergroups and channels this requires appropriate administrator rights
-- @chat_id Chat identifier
function tdbot.generateChatInviteLink(chat_id, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'generateChatInviteLink',
    chat_id = chat_id
  }, callback or dl_cb, data))
end

-- Checks the validity of an invite link for a chat and returns information about the corresponding chat
-- @invite_link Invite link to be checked; should begin with "https://t.me/joinchat/", "https://telegram.me/joinchat/", or "https://telegram.dog/joinchat/"
function tdbot.checkChatInviteLink(invite_link, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'checkChatInviteLink',
    invite_link = tostring(invite_link)
  }, callback or dl_cb, data))
end

-- Uses an invite link to add the current user to the chat if possible.
-- The new member will not be added until the chat state has been synchronized with the server
-- @invite_link Invite link to import; should begin with "https://t.me/joinchat/", "https://telegram.me/joinchat/", or "https://telegram.dog/joinchat/"
function tdbot.joinChatByInviteLink(invite_link, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'joinChatByInviteLink',
    invite_link = tostring(invite_link)
  }, callback or dl_cb, data))
end

-- Creates a new call
-- @user_id Identifier of the user to be called
-- @protocol Description of the call protocols supported by the client
function tdbot.createCall(user_id, udp_p2p, udp_reflector, min_layer, max_layer, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'createCall',
    user_id = user_id,
    protocol = {
      ["@type"] = 'callProtocol',
      udp_p2p = udp_p2p,
      udp_reflector = udp_reflector,
      min_layer = min_layer or 65,
      max_layer = max_layer or 65
    }
  }, callback or dl_cb, data))
end

-- Accepts an incoming call
-- @call_id Call identifier
-- @protocol Description of the call protocols supported by the client
-- @udp_p2p True, if UDP peer-to-peer connections are supported
-- @udp_reflector True, if connection through UDP reflectors is supported
-- @min_layer Minimum supported API layer; use 65
-- @max_layer Maximum supported API layer; use 65
function tdbot.acceptCall(call_id, udp_p2p, udp_reflector, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'acceptCall',
    call_id = call_id,
    protocol = {
      ["@type"] = 'callProtocol',
      udp_p2p = udp_p2p,
      udp_reflector = udp_reflector,
      min_layer = 65,
      max_layer = 65
    }
  }, callback or dl_cb, data))
end

-- Discards a call
-- @call_id Call identifier
-- @is_disconnected True, if the user was disconnected
-- @duration The call duration, in seconds
-- @connection_id Identifier of the connection used during the call
function tdbot.discardCall(call_id, is_disconnected, duration, connection_id, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'discardCall',
    call_id = call_id,
    is_disconnected = is_disconnected,
    duration = duration,
    connection_id = connection_id
  }, callback or dl_cb, data))
end

-- Sends a call rating
-- @call_id Call identifier
-- @rating Call rating; 1-5
-- @comment An optional user comment if the rating is less than 5
function tdbot.sendCallRating(call_id, rating, comment, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'sendCallRating',
    call_id = call_id,
    rating = rating,
    comment = tostring(comment)
  }, callback or dl_cb, data))
end

-- Sends debug information for a call
-- @call_id Call identifier
-- @debug_information Debug information in application-specific format
function tdbot.sendCallDebugInformation(call_id, debug_information, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'sendCallDebugInformation',
    call_id = call_id,
    debug_information = tostring(debug_information)
  }, callback or dl_cb, data))
end

-- Adds a user to the blacklist
-- @user_id User identifier
function tdbot.blockUser(user_id, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'blockUser',
    user_id = user_id
  }, callback or dl_cb, data))
end

-- Removes a user from the blacklist
-- @user_id User identifier
function tdbot.unblockUser(user_id, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'unblockUser',
    user_id = user_id
  }, callback or dl_cb, data))
end

-- Returns users that were blocked by the current user
-- @offset Number of users to skip in the result; must be non-negative
-- @limit Maximum number of users to return; up to 100
function tdbot.getBlockedUsers(offset, limit, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getBlockedUsers',
    offset = offset or 0,
    limit = setLimit(100, limit)
  }, callback or dl_cb, data))
end

-- Adds new contacts or edits existing contacts; contacts' user identifiers are ignored
-- @contacts The list of contacts to import or edit
function tdbot.importContacts(phone_number, first_name, last_name, user_id, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'importContacts',
    contacts = {
      ["@type"] = 'contact',
      phone_number = tostring(phone_number),
      first_name = tostring(first_name),
      last_name = tostring(last_name),
      user_id = user_id or 0
    }
  }, callback or dl_cb, data))
end

-- Searches for the specified query in the first names, last names and usernames of the known user contacts
-- @query Query to search for; can be empty to return all contacts
-- @limit Maximum number of users to be returned
function tdbot.searchContacts(query, limit, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'searchContacts',
    query = tostring(query),
    limit = limit
  }, callback or dl_cb, data))
end

-- Removes users from the contacts list
-- @user_ids Identifiers of users to be deleted
function tdbot.removeContacts(user_ids, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'removeContacts',
    user_ids = vectorize(user_ids)
  }, callback or dl_cb, data))
end

-- Returns the total number of imported contacts
function tdbot.getImportedContactCount(callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getImportedContactCount'
  }, callback or dl_cb, data))
end

-- Changes imported contacts using the list of current user contacts saved on the device.
-- Imports newly added contacts and, if at least the file database is enabled, deletes recently deleted contacts.
-- Query result depends on the result of the previous query, so only one query is possible at the same time
-- @contacts The new list of contacts
function tdbot.changeImportedContacts(phone_number, first_name, last_name, user_id, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'changeImportedContacts',
    contacts = {
      ["@type"] = 'contact',
      phone_number = tostring(phone_number),
      first_name = tostring(first_name),
      last_name = tostring(last_name),
      user_id = user_id or 0
    }
  }, callback or dl_cb, data))
end

-- Clears all imported contacts
function tdbot.clearImportedContacts(callback, data)
  assert (tdbot_function ({
    ["@type"] = 'clearImportedContacts'
  }, callback or dl_cb, data))
end

-- Returns the profile photos of a user.
-- The result of this query may be outdated: some photos might have been deleted already
-- @user_id User identifier
-- @offset The number of photos to skip; must be non-negative
-- @limit Maximum number of photos to be returned; up to 100
function tdbot.getUserProfilePhotos(user_id, offset, limit, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getUserProfilePhotos',
    user_id = user_id,
    offset = offset or 0,
    limit = setLimit(100, limit)
  }, callback or dl_cb, data))
end

-- Returns stickers from the installed sticker sets that correspond to a given emoji.
-- If the emoji is not empty, favorite and recently used stickers may also be returned
-- @emoji String representation of emoji.
-- If empty, returns all known installed stickers
-- @limit Maximum number of stickers to be returned
function tdbot.getStickers(emoji, limit, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getStickers',
    emoji = tostring(emoji),
    limit = setLimit(100, limit)
  }, callback or dl_cb, data))
end

-- Searches for stickers from public sticker sets that correspond to a given emoji
-- @emoji String representation of emoji; must be non-empty
-- @limit Maximum number of stickers to be returned
function tdbot.searchStickers(emoji, limit, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'searchStickers',
    emoji = tostring(emoji),
    limit = limit
  }, callback or dl_cb, data))
end

-- Returns a list of installed sticker sets
-- @is_masks Pass true to return mask sticker sets; pass false to return ordinary sticker sets
function tdbot.getInstalledStickerSets(is_masks, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getInstalledStickerSets',
    is_masks = is_masks
  }, callback or dl_cb, data))
end

-- Returns a list of archived sticker sets
-- @is_masks Pass true to return mask stickers sets; pass false to return ordinary sticker sets
-- @offset_sticker_set_id Identifier of the sticker set from which to return the result
-- @limit Maximum number of sticker sets to return
function tdbot.getArchivedStickerSets(is_masks, offset_sticker_set_id, limit, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getArchivedStickerSets',
    is_masks = is_masks,
    offset_sticker_set_id = offset_sticker_set_id,
    limit = limit
  }, callback or dl_cb, data))
end

-- Returns a list of trending sticker sets
function tdbot.getTrendingStickerSets(callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getTrendingStickerSets'
  }, callback or dl_cb, data))
end

-- Returns a list of sticker sets attached to a file.
-- Currently only photos and videos can have attached sticker sets
-- @file_id File identifier
function tdbot.getAttachedStickerSets(file_id, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getAttachedStickerSets',
    file_id = file_id
  }, callback or dl_cb, data))
end

-- Returns information about a sticker set by its identifier
-- @set_id Identifier of the sticker set
function tdbot.getStickerSet(set_id, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getStickerSet',
    set_id = set_id
  }, callback or dl_cb, data))
end

-- Searches for a sticker set by its name
-- @name Name of the sticker set
function tdbot.searchStickerSet(name, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'searchStickerSet',
    name = tostring(name)
  }, callback or dl_cb, data))
end

-- Searches for installed sticker sets by looking for specified query in their title and name
-- @is_masks Pass true to return mask sticker sets; pass false to return ordinary sticker sets
-- @query Query to search for
-- @limit Maximum number of sticker sets to return
function tdbot.searchInstalledStickerSets(is_masks, query, limit, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'searchInstalledStickerSets',
    is_masks = is_masks,
    query = tostring(query),
    limit = limit
  }, callback or dl_cb, data))
end

-- Searches for ordinary sticker sets by looking for specified query in their title and name.
-- Excludes installed sticker sets from the results
-- @query Query to search for
function tdbot.searchStickerSets(query, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'searchStickerSets',
    query = tostring(query)
  }, callback or dl_cb, data))
end

-- Installs/uninstalls or activates/archives a sticker set
-- @set_id Identifier of the sticker set
-- @is_installed The new value of is_installed
-- @is_archived The new value of is_archived.
-- A sticker set can't be installed and archived simultaneously
function tdbot.changeStickerSet(set_id, is_installed, is_archived, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'changeStickerSet',
    set_id = set_id,
    is_installed = is_installed,
    is_archived = is_archived
  }, callback or dl_cb, data))
end

-- Informs the server that some trending sticker sets have been viewed by the user
-- @sticker_set_ids Identifiers of viewed trending sticker sets
function tdbot.viewTrendingStickerSets(sticker_set_ids, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'viewTrendingStickerSets',
    sticker_set_ids = vectorize(sticker_set_ids)
  }, callback or dl_cb, data))
end

-- Changes the order of installed sticker sets
-- @is_masks Pass true to change the order of mask sticker sets; pass false to change the order of ordinary sticker sets
-- @sticker_set_ids Identifiers of installed sticker sets in the new correct order
function tdbot.reorderInstalledStickerSets(is_masks, sticker_set_ids, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'reorderInstalledStickerSets',
    is_masks = is_masks,
    sticker_set_ids = vectorize(sticker_set_ids)
  }, callback or dl_cb, data))
end

-- Returns a list of recently used stickers
-- @is_attached Pass true to return stickers and masks that were recently attached to photos or video files; pass false to return recently sent stickers
function tdbot.getRecentStickers(is_attached, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getRecentStickers',
    is_attached = is_attached
  }, callback or dl_cb, data))
end

-- Manually adds a new sticker to the list of recently used stickers.
-- The new sticker is added to the top of the list.
-- If the sticker was already in the list, it is removed from the list first.
-- Only stickers belonging to a sticker set can be added to this list
-- @is_attached Pass true to add the sticker to the list of stickers recently attached to photo or video files; pass false to add the sticker to the list of recently sent stickers
-- @sticker Sticker file to add
function tdbot.addRecentSticker(is_attached, sticker, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'addRecentSticker',
    is_attached = is_attached,
    sticker = getInputFile(sticker)
  }, callback or dl_cb, data))
end

-- Removes a sticker from the list of recently used stickers
-- @is_attached Pass true to remove the sticker from the list of stickers recently attached to photo or video files; pass false to remove the sticker from the list of recently sent stickers
-- @sticker Sticker file to delete
function tdbot.removeRecentSticker(is_attached, sticker, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'removeRecentSticker',
    is_attached = is_attached,
    sticker = getInputFile(sticker)
  }, callback or dl_cb, data))
end

-- Clears the list of recently used stickers
-- @is_attached Pass true to clear the list of stickers recently attached to photo or video files; pass false to clear the list of recently sent stickers
function tdbot.clearRecentStickers(is_attached, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'clearRecentStickers',
    is_attached = is_attached
  }, callback or dl_cb, data))
end

-- Returns favorite stickers
function tdbot.getFavoriteStickers(callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getFavoriteStickers'
  }, callback or dl_cb, data))
end

-- Adds a new sticker to the list of favorite stickers.
-- The new sticker is added to the top of the list.
-- If the sticker was already in the list, it is removed from the list first.
-- Only stickers belonging to a sticker set can be added to this list
-- @sticker Sticker file to add
function tdbot.addFavoriteSticker(sticker, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'addFavoriteSticker',
    sticker = getInputFile(sticker)
  }, callback or dl_cb, data))
end

-- Removes a sticker from the list of favorite stickers
-- @sticker Sticker file to delete from the list
function tdbot.removeFavoriteSticker(sticker, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'removeFavoriteSticker',
    sticker = getInputFile(sticker)
  }, callback or dl_cb, data))
end

-- Returns emoji corresponding to a sticker
-- @sticker Sticker file identifier
function tdbot.getStickerEmojis(sticker, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getStickerEmojis',
    sticker = getInputFile(sticker)
  }, callback or dl_cb, data))
end

-- Returns saved animations
function tdbot.getSavedAnimations(callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getSavedAnimations'
  }, callback or dl_cb, data))
end

-- Manually adds a new animation to the list of saved animations.
-- The new animation is added to the beginning of the list.
-- If the animation was already in the list, it is removed first.
-- Only non-secret video animations with MIME type "video/mp4" can be added to the list
-- @animation The animation file to be added.
-- Only animations known to the server (i.e.
-- successfully sent via a message) can be added to the list
function tdbot.addSavedAnimation(animation, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'addSavedAnimation',
    animation = getInputFile(animation)
  }, callback or dl_cb, data))
end

-- Removes an animation from the list of saved animations
-- @animation Animation file to be removed
function tdbot.removeSavedAnimation(animation, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'removeSavedAnimation',
    animation = getInputFile(animation)
  }, callback or dl_cb, data))
end

-- Returns up to 20 recently used inline bots in the order of their last usage
function tdbot.getRecentInlineBots(callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getRecentInlineBots'
  }, callback or dl_cb, data))
end

-- Searches for recently used hashtags by their prefix
-- @prefix Hashtag prefix to search for
-- @limit Maximum number of hashtags to be returned
function tdbot.searchHashtags(prefix, limit, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'searchHashtags',
    prefix = tostring(prefix),
    limit = limit
  }, callback or dl_cb, data))
end

-- Removes a hashtag from the list of recently used hashtags
-- @hashtag Hashtag to delete
function tdbot.removeRecentHashtag(hashtag, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'removeRecentHashtag',
    hashtag = tostring(hashtag)
  }, callback or dl_cb, data))
end

-- Returns a web page preview by the text of the message.
-- Do not call this function too often.
-- Returns a 404 error if the web page has no preview
-- @text Message text with formatting
function tdbot.getWebPagePreview(text, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getWebPagePreview',
    text = formattedText
  }, callback or dl_cb, data))
end

-- Returns an instant view version of a web page if available.
-- Returns a 404 error if the web page has no instant view page
-- @url The web page URL
-- @force_full If true, the full instant view for the web page will be returned
function tdbot.getWebPageInstantView(url, force_full, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getWebPageInstantView',
    url = tostring(url),
    force_full = force_full
  }, callback or dl_cb, data))
end

-- Returns the notification settings for a given scope
-- @scope Scope for which to return the notification settings information
function tdbot.getNotificationSettings(scope, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getNotificationSettings',
    scope = NotificationSettingsScope
  }, callback or dl_cb, data))
end

-- Changes notification settings for a given scope
-- @scope Scope for which to change the notification settings
-- @notification_settings The new notification settings for the given scope
-- Chat|PrivateChats|BasicGroupChats|AllChats
function tdbot.setNotificationSettings(scope, chat_id, mute_for, sound, show_preview, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'setNotificationSettings',
    scope = {
      ["@type"] = 'notificationSettingsScope' .. scope,
      chat_id = chat_id
    },
    notification_settings = {
      ["@type"] = 'notificationSettings',
      mute_for = mute_for,
      sound = tostring(sound),
      show_preview = show_preview
    }
  }, callback or dl_cb, data))
end

-- Changes notification settings for a given scope
-- @scope Scope for which to change the notification settings
-- @notification_settings The new notification settings for the given scope
function tdbot.setNotificationSettings(scope, notification_settings, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'setNotificationSettings',
    scope = NotificationSettingsScope,
    notification_settings = notificationSettings
  }, callback or dl_cb, data))
end

-- Resets all notification settings to their default values.
-- By default, the only muted chats are supergroups, the sound is set to "default" and message previews are shown
function tdbot.resetAllNotificationSettings(callback, data)
  assert (tdbot_function ({
    ["@type"] = 'resetAllNotificationSettings'
  }, callback or dl_cb, data))
end

-- Uploads a new profile photo for the current user.
-- If something changes, updateUser will be sent
-- @photo Profile photo to set.
-- inputFileId and inputFileRemote may still be unsupported
function tdbot.setProfilePhoto(photo, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'setProfilePhoto',
    photo = getInputFile(photo)
  }, callback or dl_cb, data))
end

-- Deletes a profile photo.
-- If something changes, updateUser will be sent
-- @profile_photo_id Identifier of the profile photo to delete
function tdbot.deleteProfilePhoto(profile_photo_id, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'deleteProfilePhoto',
    profile_photo_id = profile_photo_id
  }, callback or dl_cb, data))
end

-- Changes the first and last name of the current user.
-- If something changes, updateUser will be sent
-- @first_name The new value of the first name for the user; 1-255 characters
-- @last_name The new value of the optional last name for the user; 0-255 characters
function tdbot.setName(first_name, last_name, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'setName',
    first_name = tostring(first_name),
    last_name = tostring(last_name)
  }, callback or dl_cb, data))
end

-- Changes the bio of the current user
-- @bio The new value of the user bio; 0-70 characters without line feeds
function tdbot.setBio(bio, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'setBio',
    bio = tostring(bio)
  }, callback or dl_cb, data))
end

-- Changes the username of the current user.
-- If something changes, updateUser will be sent
-- @username The new value of the username.
-- Use an empty string to remove the username
function tdbot.setUsername(username, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'setUsername',
    username = tostring(username)
  }, callback or dl_cb, data))
end

-- Changes the phone number of the user and sends an authentication code to the user's new phone number.
-- On success, returns information about the sent code
-- @phone_number The new phone number of the user in international format
-- @allow_flash_call Pass true if the code can be sent via flash call to the specified phone number
-- @is_current_phone_number Pass true if the phone number is used on the current device.
-- Ignored if allow_flash_call is false
function tdbot.changePhoneNumber(phone_number, allow_flash_call, is_current_phone_number, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'changePhoneNumber',
    phone_number = tostring(phone_number),
    allow_flash_call = allow_flash_call,
    is_current_phone_number = is_current_phone_number
  }, callback or dl_cb, data))
end

-- Re-sends the authentication code sent to confirm a new phone number for the user.
-- Works only if the previously received authenticationCodeInfo next_code_type was not null
function tdbot.resendChangePhoneNumberCode(callback, data)
  assert (tdbot_function ({
    ["@type"] = 'resendChangePhoneNumberCode'
  }, callback or dl_cb, data))
end

-- Checks the authentication code sent to confirm a new phone number of the user
-- @code Verification code received by SMS, phone call or flash call
function tdbot.checkChangePhoneNumberCode(code, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'checkChangePhoneNumberCode',
    code = tostring(code)
  }, callback or dl_cb, data))
end

-- Returns all active sessions of the current user
function tdbot.getActiveSessions(callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getActiveSessions'
  }, callback or dl_cb, data))
end

-- Terminates a session of the current user
-- @session_id Session identifier
function tdbot.terminateSession(session_id, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'terminateSession',
    session_id = session_id
  }, callback or dl_cb, data))
end

-- Terminates all other sessions of the current user
function tdbot.terminateAllOtherSessions(callback, data)
  assert (tdbot_function ({
    ["@type"] = 'terminateAllOtherSessions'
  }, callback or dl_cb, data))
end

-- Returns all website where the current user used Telegram to log in
function tdbot.getConnectedWebsites(callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getConnectedWebsites'
  }, callback or dl_cb, data))
end

-- Disconnects website from the current user's Telegram account
-- @website_id Website identifier
function tdbot.disconnectWebsite(website_id, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'disconnectWebsite',
    website_id = website_id
  }, callback or dl_cb, data))
end

-- Disconnects all websites from the current user's Telegram account
function tdbot.disconnectAllWebsites(callback, data)
  assert (tdbot_function ({
    ["@type"] = 'disconnectAllWebsites'
  }, callback or dl_cb, data))
end

-- Toggles the "All members are admins" setting in basic groups; requires creator privileges in the group
-- @basic_group_id Identifier of the basic group
-- @everyone_is_administrator New value of everyone_is_administrator
function tdbot.toggleBasicGroupAdministrators(basic_group_id, everyone_is_administrator, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'toggleBasicGroupAdministrators',
    basic_group_id = getChatId(basic_group_id).id,
    everyone_is_administrator = everyone_is_administrator
  }, callback or dl_cb, data))
end

-- Changes the username of a supergroup or channel, requires creator privileges in the supergroup or channel
-- @supergroup_id Identifier of the supergroup or channel
-- @username New value of the username.
-- Use an empty string to remove the username
function tdbot.setSupergroupUsername(supergroup_id, username, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'setSupergroupUsername',
    supergroup_id = getChatId(supergroup_id).id,
    username = tostring(username)
  }, callback or dl_cb, data))
end

-- Changes the sticker set of a supergroup; requires appropriate rights in the supergroup
-- @supergroup_id Identifier of the supergroup
-- @sticker_set_id New value of the supergroup sticker set identifier.
-- Use 0 to remove the supergroup sticker set
function tdbot.setSupergroupStickerSet(supergroup_id, sticker_set_id, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'setSupergroupStickerSet',
    supergroup_id = getChatId(supergroup_id).id,
    sticker_set_id = sticker_set_id
  }, callback or dl_cb, data))
end

-- Toggles whether all members of a supergroup can add new members; requires appropriate administrator rights in the supergroup.
-- @supergroup_id Identifier of the supergroup
-- @anyone_can_invite New value of anyone_can_invite
function tdbot.toggleSupergroupInvites(supergroup_id, anyone_can_invite, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'toggleSupergroupInvites',
    supergroup_id = getChatId(supergroup_id).id,
    anyone_can_invite = anyone_can_invite
  }, callback or dl_cb, data))
end

-- Toggles sender signatures messages sent in a channel; requires appropriate administrator rights in the channel.
-- @supergroup_id Identifier of the channel
-- @sign_messages New value of sign_messages
function tdbot.toggleSupergroupSignMessages(supergroup_id, sign_messages, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'toggleSupergroupSignMessages',
    supergroup_id = getChatId(supergroup_id).id,
    sign_messages = sign_messages
  }, callback or dl_cb, data))
end

-- Toggles whether the message history of a supergroup is available to new members; requires appropriate administrator rights in the supergroup.
-- @supergroup_id The identifier of the supergroup
-- @is_all_history_available The new value of is_all_history_available
function tdbot.toggleSupergroupIsAllHistoryAvailable(supergroup_id, is_all_history_available, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'toggleSupergroupIsAllHistoryAvailable',
    supergroup_id = getChatId(supergroup_id).id,
    is_all_history_available = is_all_history_available
  }, callback or dl_cb, data))
end

-- Changes information about a supergroup or channel; requires appropriate administrator rights
-- @supergroup_id Identifier of the supergroup or channel
-- @param_description New supergroup or channel description; 0-255 characters
function tdbot.setSupergroupDescription(supergroup_id, description, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'setSupergroupDescription',
    supergroup_id = getChatId(supergroup_id).id,
    description = tostring(description)
  }, callback or dl_cb, data))
end

-- Pins a message in a supergroup or channel; requires appropriate administrator rights in the supergroup or channel
-- @supergroup_id Identifier of the supergroup or channel
-- @message_id Identifier of the new pinned message
-- @disable_notification True, if there should be no notification about the pinned message
function tdbot.pinSupergroupMessage(supergroup_id, message_id, disable_notification, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'pinSupergroupMessage',
    supergroup_id = getChatId(supergroup_id).id,
    message_id = message_id,
    disable_notification = disable_notification
  }, callback or dl_cb, data))
end

-- Removes the pinned message from a supergroup or channel; requires appropriate administrator rights in the supergroup or channel
-- @supergroup_id Identifier of the supergroup or channel
function tdbot.unpinSupergroupMessage(supergroup_id, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'unpinSupergroupMessage',
    supergroup_id = getChatId(supergroup_id).id
  }, callback or dl_cb, data))
end

-- Reports some messages from a user in a supergroup as spam
-- @supergroup_id Supergroup identifier
-- @user_id User identifier
-- @message_ids Identifiers of messages sent in the supergroup by the user.
-- This list must be non-empty
function tdbot.reportSupergroupSpam(supergroup_id, user_id, message_ids, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'reportSupergroupSpam',
    supergroup_id = getChatId(supergroup_id).id,
    user_id = user_id,
    message_ids = vectorize(message_ids)
  }, callback or dl_cb, data))
end

-- Returns information about members or banned users in a supergroup or channel.
-- Can be used only if SupergroupFullInfo.can_get_members == true; additionally, administrator privileges may be required for some filters
-- @supergroup_id Identifier of the supergroup or channel
-- @filter The type of users to return.
-- By default, supergroupMembersRecent
-- @offset Number of users to skip
-- @limit The maximum number of users be returned; up to 200
-- supergroupMembersFilter = Recent|Administrators|Search|Restricted|Banned|Bots
function tdbot.getSupergroupMembers(supergroup_id, filter, query, offset, limit, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getSupergroupMembers',
    supergroup_id = getChatId(supergroup_id).id,
    filter = {
      ["@type"] = 'supergroupMembersFilter' .. filter,
      query = query
    },
    offset = offset or 0,
    limit = setLimit(200, limit)
  }, callback or dl_cb, data))
end

-- Deletes a supergroup or channel along with all messages in the corresponding chat.
-- This will release the supergroup or channel username and remove all members; requires creator privileges in the supergroup or channel.
-- Chats with more than 1000 members can't be deleted using this method
-- @supergroup_id Identifier of the supergroup or channel
function tdbot.deleteSupergroup(supergroup_id, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'deleteSupergroup',
    supergroup_id = getChatId(supergroup_id).id
  }, callback or dl_cb, data))
end

-- Closes a secret chat, effectively transfering its state to secretChatStateClosed
-- @secret_chat_id Secret chat identifier
function tdbot.closeSecretChat(secret_chat_id, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'closeSecretChat',
    secret_chat_id = secret_chat_id
  }, callback or dl_cb, data))
end

-- Returns a list of service actions taken by chat members and administrators in the last 48 hours.
-- Available only in supergroups and channels.
-- Requires administrator rights.
-- Returns results in reverse chronological order (i.
-- e., in order of decreasing event_id)
-- @chat_id Chat identifier
-- @query Search query by which to filter events
-- @from_event_id Identifier of an event from which to return results.
-- Use 0 to get results from the latest events
-- @limit Maximum number of events to return; up to 100
-- @filters The types of events to return.
-- By default, all types will be returned
-- @user_ids User identifiers by which to filter events.
-- By default, events relating to all users will be returned
function tdbot.getChatEventLog(chat_id, query, from_event_id, limit, filters, user_ids, callback, data)
  local filters = filters or {1,1,1,1,1,1,1,1,1,1}

  assert (tdbot_function ({
    ["@type"] = 'getChatEventLog',
    chat_id = chat_id,
    query = tostring(query) or '',
    from_event_id = from_event_id or 0,
    limit = setLimit(100, limit),
    filters = {
      ["@type"] = 'chatEventLogFilters',
      message_edits = filters[0],
      message_deletions = filters[1],
      message_pins = filters[2],
      member_joins = filters[3],
      member_leaves = filters[4],
      member_invites = filters[5],
      member_promotions = filters[6],
      member_restrictions = filters[7],
      info_changes = filters[8],
      setting_changes = filters[9]
    },
    user_ids = vectorize(user_ids)
  }, callback or dl_cb, data))
end

-- Returns an invoice payment form.
-- This method should be called when the user presses inlineKeyboardButtonBuy
-- @chat_id Chat identifier of the Invoice message
-- @message_id Message identifier
function tdbot.getPaymentForm(chat_id, message_id, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getPaymentForm',
    chat_id = chat_id,
    message_id = message_id
  }, callback or dl_cb, data))
end

-- Validates the order information provided by a user and returns the available shipping options for a flexible invoice
-- @chat_id Chat identifier of the Invoice message
-- @message_id Message identifier
-- @order_info The order information, provided by the user
-- @allow_save True, if the order information can be saved
function tdbot.validateOrderInfo(chat_id, message_id, order_info, allow_save, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'validateOrderInfo',
    chat_id = chat_id,
    message_id = message_id,
    order_info = orderInfo,
    allow_save = allow_save
  }, callback or dl_cb, data))
end

-- Sends a filled-out payment form to the bot for final verification
-- @chat_id Chat identifier of the Invoice message
-- @message_id Message identifier
-- @order_info_id Identifier returned by ValidateOrderInfo, or an empty string
-- @shipping_option_id Identifier of a chosen shipping option, if applicable
-- @credentials The credentials chosen by user for payment
function tdbot.sendPaymentForm(chat_id, message_id, order_info_id, shipping_option_id, credentials, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'sendPaymentForm',
    chat_id = chat_id,
    message_id = message_id,
    order_info_id = tostring(order_info_id),
    shipping_option_id = tostring(shipping_option_id),
    credentials = InputCredentials
  }, callback or dl_cb, data))
end

-- Returns information about a successful payment
-- @chat_id Chat identifier of the PaymentSuccessful message
-- @message_id Message identifier
function tdbot.getPaymentReceipt(chat_id, message_id, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getPaymentReceipt',
    chat_id = chat_id,
    message_id = message_id
  }, callback or dl_cb, data))
end

-- Returns saved order info, if any
function tdbot.getSavedOrderInfo(callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getSavedOrderInfo'
  }, callback or dl_cb, data))
end

-- Deletes saved order info
function tdbot.deleteSavedOrderInfo(callback, data)
  assert (tdbot_function ({
    ["@type"] = 'deleteSavedOrderInfo'
  }, callback or dl_cb, data))
end

-- Deletes saved credentials for all payment provider bots
function tdbot.deleteSavedCredentials(callback, data)
  assert (tdbot_function ({
    ["@type"] = 'deleteSavedCredentials'
  }, callback or dl_cb, data))
end

-- Returns a user that can be contacted to get support
function tdbot.getSupportUser(callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getSupportUser'
  }, callback or dl_cb, data))
end

-- Returns background wallpapers
function tdbot.getWallpapers(callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getWallpapers'
  }, callback or dl_cb, data))
end

-- Registers the currently used device for receiving push notifications
-- @device_token Device token
-- GoogleCloudMessaging|ApplePush|ApplePushVoIP|WindowsPush|MicrosoftPush|MicrosoftPushVoIP|WebPush|SimplePush|UbuntuPush|BlackberryPush|TizenPush
-- @other_user_ids List of at most 100 user identifiers of other users currently using the client
function tdbot.registerDevice(device, token, device_token, is_app_sandbox, access_token, channel_uri, endpoint, p256dh_base64url, auth_base64url, reg_id, other_user_ids, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'registerDevice',
    device_token = {
      ["@type"] = deviceToken .. device,
      device_token = device_token,
      is_app_sandbox = is_app_sandbox,
      access_token = access_token,
      channel_uri = channel_uri,
      endpoint = endpoint,
      p256dh_base64url = p256dh_base64url,
      auth_base64url = auth_base64url,
      token = token,
      reg_id = reg_id
    },
    other_user_ids = vectorize(other_user_ids)
  }, callback or dl_cb, data))
end

-- Returns t.me URLs recently visited by a newly registered user
-- @referrer Google Play referrer to identify the user
function tdbot.getRecentlyVisitedTMeUrls(referrer, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getRecentlyVisitedTMeUrls',
    referrer = tostring(referrer)
  }, callback or dl_cb, data))
end

-- Changes user privacy settings
-- @setting The privacy setting: ShowStatus|AllowChatInvites|AllowCalls
-- @rules The new privacy rules
-- AllowAll|AllowContacts|AllowUsers|RestrictAll|RestrictContacts|RestrictUsers
function tdbot.setUserPrivacySettingRules(setting, rules, allowed_user_ids, restricted_user_ids, callback, data)
  local setting_rules = {
    [0] = {
      ["@type"] = "userPrivacySettingRule" .. rules
    }
  }

  if allowed_user_ids then
    setting_rules[#setting_rules + 1] = {
      {
        ["@type"] = "userPrivacySettingRuleAllowUsers",
        user_ids = vectorize(allowed_user_ids)
      }
    }
  elseif restricted_user_ids then
    setting_rules[#setting_rules + 1] = {
      {
        ["@type"] = "userPrivacySettingRuleRestrictUsers",
        user_ids = vectorize(restricted_user_ids)
      }
    }
  end

  assert (tdbot_function ({
    ["@type"] = 'setUserPrivacySettingRules',
    setting = {
      ["@type"] = "userPrivacySetting" .. setting
    },
    rules = {
      ["@type"] = "userPrivacySettingRules",
      rules = setting_rules
    }
  }, callback or dl_cb, data))
end

-- Returns the current privacy settings
-- @setting The privacy setting
function tdbot.getUserPrivacySettingRules(setting, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getUserPrivacySettingRules',
    setting = {
      ["@type"] = 'userPrivacySetting' .. setting
    }
  }, callback or dl_cb, data))
end

-- Returns the value of an option by its name.
-- (Check the list of available options on https://core.telegram.org/tdlib/options.) Can be called before authorization
-- @name The name of the option
function tdbot.getOption(name, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getOption',
    name = tostring(name)
  }, callback or dl_cb, data))
end

-- Sets the value of an option.
-- (Check the list of available options on https://core.telegram.org/tdlib/options.) Only writable options can be set.
-- Can be called before authorization
-- @name The name of the option
-- @value The new value of the option
function tdbot.setOption(name, value, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'setOption',
    name = tostring(name),
    value = OptionValue
  }, callback or dl_cb, data))
end

-- Changes the period of inactivity after which the account of the current user will automatically be deleted
-- @ttl New account TTL
function tdbot.setAccountTtl(ttl, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'setAccountTtl',
    ttl = {
      ["@type"] = 'accountTtl',
      days = ttl
    }
  }, callback or dl_cb, data))
end

-- Returns the period of inactivity after which the account of the current user will automatically be deleted
function tdbot.getAccountTtl(callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getAccountTtl'
  }, callback or dl_cb, data))
end

-- Deletes the account of the current user, deleting all information associated with the user from the server.
-- The phone number of the account can be used to create a new account
-- @reason The reason why the account was deleted; optional
function tdbot.deleteAccount(reason, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'deleteAccount',
    reason = tostring(reason)
  }, callback or dl_cb, data))
end

-- Returns information on whether the current chat can be reported as spam
-- @chat_id Chat identifier
function tdbot.getChatReportSpamState(chat_id, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getChatReportSpamState',
    chat_id = chat_id
  }, callback or dl_cb, data))
end

-- Used to let the server know whether a chat is spam or not.
-- Can be used only if ChatReportSpamState.can_report_spam is true.
-- After this request, ChatReportSpamState.can_report_spam becomes false forever
-- @chat_id Chat identifier
-- @is_spam_chat If true, the chat will be reported as spam; otherwise it will be marked as not spam
function tdbot.changeChatReportSpamState(chat_id, is_spam_chat, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'changeChatReportSpamState',
    chat_id = chat_id,
    is_spam_chat = is_spam_chat
  }, callback or dl_cb, data))
end

-- Reports a chat to the Telegram moderators.
-- Supported only for supergroups, channels, or private chats with bots, since other chats can't be checked by moderators
-- @chat_id Chat identifier
-- @reason The reason for reporting the chat: Spam|Violence|Pornography|Custom
-- @message_ids Identifiers of reported messages, if any
function tdbot.reportChat(chat_id, reason, text, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'reportChat',
    chat_id = chat_id,
    reason = {
      ["@type"] = 'chatReportReason' .. reason,
      text = text
    }
  }, callback or dl_cb, data))
end

-- Returns storage usage statistics
-- @chat_limit Maximum number of chats with the largest storage usage for which separate statistics should be returned.
-- All other chats will be grouped in entries with chat_id == 0.
-- If the chat info database is not used, the chat_limit is ignored and is always set to 0
function tdbot.getStorageStatistics(chat_limit, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getStorageStatistics',
    chat_limit = chat_limit
  }, callback or dl_cb, data))
end

-- Quickly returns approximate storage usage statistics
function tdbot.getStorageStatisticsFast(callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getStorageStatisticsFast'
  }, callback or dl_cb, data))
end

-- Optimizes storage usage, i.e.
-- deletes some files and returns new storage usage statistics.
-- Secret thumbnails can't be deleted
-- @size Limit on the total size of files after deletion.
-- Pass -1 to use the default limit
-- @ttl Limit on the time that has passed since the last time a file was accessed (or creation time for some filesystems).
-- Pass -1 to use the default limit
-- @count Limit on the total count of files after deletion.
-- Pass -1 to use the default limit
-- @immunity_delay The amount of time after the creation of a file during which it can't be deleted, in seconds.
-- Pass -1 to use the default value
-- @file_types If not empty, only files with the given type(s) are considered.
-- By default, all types except thumbnails, profile photos, stickers and wallpapers are deleted
-- @chat_ids If not empty, only files from the given chats are considered.
-- Use 0 as chat identifier to delete files not belonging to any chat (e.g., profile photos)
-- @exclude_chat_ids If not empty, files from the given chats are excluded.
-- Use 0 as chat identifier to exclude all files not belonging to any chat (e.g., profile photos)
-- @chat_limit Same as in getStorageStatistics.
-- Affects only returned statistics
-- fileType: None|Animation|Audio|Document|Photo|ProfilePhoto|Secret|Sticker|Thumbnail|Unknown|Video|VideoNote|VoiceNote|Wallpaper|SecretThumbnail
function tdbot.optimizeStorage(size, ttl, count, immunity_delay, file_type, chat_ids, exclude_chat_ids, chat_limit, callback, data)
  local file_type = file_type or ''
  assert (tdbot_function ({
    ["@type"] = 'optimizeStorage',
    size = size or -1,
    ttl = ttl or -1,
    count = count or -1,
    immunity_delay = immunity_delay or -1,
    file_type = {
      ["@type"] = 'fileType' .. file_type
    },
    chat_ids = vectorize(chat_ids),
    exclude_chat_ids = vectorize(exclude_chat_ids),
    chat_limit = chat_limit
  }, callback or dl_cb, data))
end

-- Sets the current network type.
-- Can be called before authorization.
-- Calling this method forces all network connections to reopen, mitigating the delay in switching between different networks, so it should be called whenever the network is changed, even if the network type remains the same.
-- Network type is used to check whether the library can use the network at all and also for collecting detailed network data usage statistics
-- @type The new network type.
-- By default, networkTypeOther
-- network: None|Mobile|MobileRoaming|WiFi|Other
function tdbot.setNetworkType(type, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'setNetworkType',
    type = {
      ["@type"] = 'networkType' .. type
    },
  }, callback or dl_cb, data))
end

-- Returns network data usage statistics.
-- Can be called before authorization
-- @only_current If true, returns only data for the current library launch
function tdbot.getNetworkStatistics(only_current, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getNetworkStatistics',
    only_current = only_current
  }, callback or dl_cb, data))
end

-- Adds the specified data to data usage statistics.
-- Can be called before authorization
-- @entry The network statistics entry with the data to be added to statistics
-- entry = File|Call
-- fileType = None|Animation|Audio|Document|Photo|ProfilePhoto|Secret|Sticker|Thumbnail|Unknown|Video|VideoNote|VoiceNote|Wallpaper|SecretThumbnail
-- network = None|Mobile|MobileRoaming|WiFi|Other
function tdbot.addNetworkStatistics(entry, file_type, network, sent_bytes, received_bytes, duration, callback, data)
  local file_type = file_type or 'None'
  assert (tdbot_function ({
    ["@type"] = 'addNetworkStatistics',
    entry = {
      ["@type"] = 'networkStatisticsEntry' .. entry,
      file_type = {
        ["@type"] = 'fileType' .. file_type
      },
      network_type = {
        ["@type"] = 'networkType' .. network
      },
      sent_bytes = sent_bytes,
      received_bytes = received_bytes,
      duration = duration
    }
  }, callback or dl_cb, data))
end

-- Resets all network data usage statistics to zero.
-- Can be called before authorization
function tdbot.resetNetworkStatistics(callback, data)
  assert (tdbot_function ({
    ["@type"] = 'resetNetworkStatistics'
  }, callback or dl_cb, data))
end

-- Informs the server about the number of pending bot updates if they haven't been processed for a long time; for bots only
-- @pending_update_count The number of pending updates
-- @error_message The last error message
function tdbot.setBotUpdatesStatus(pending_update_count, error_message, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'setBotUpdatesStatus',
    pending_update_count = pending_update_count,
    error_message = tostring(error_message)
  }, callback or dl_cb, data))
end

-- Uploads a PNG image with a sticker; for bots only; returns the uploaded file
-- @user_id Sticker file owner
-- @png_sticker PNG image with the sticker; must be up to 512 kB in size and fit in 512x512 square
function tdbot.uploadStickerFile(user_id, png_sticker, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'uploadStickerFile',
    user_id = user_id,
    png_sticker = getInputFile(png_sticker)
  }, callback or dl_cb, data))
end

-- Creates a new sticker set; for bots only.
-- Returns the newly created sticker set
-- @user_id Sticker set owner
-- @title Sticker set title; 1-64 characters
-- @name Sticker set name.
-- Can contain only English letters, digits and underscores.
-- Must end with *"_by_<bot username>"* (*<bot_username>* is case insensitive); 1-64 characters
-- @is_masks True, if stickers are masks
-- @stickers List of stickers to be added to the set
function tdbot.createNewStickerSet(user_id, title, name, is_masks, stickers, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'createNewStickerSet',
    user_id = user_id,
    title = tostring(title),
    name = tostring(name),
    is_masks = is_masks,
    -- stickers = vector<inputSticker>
  }, callback or dl_cb, data))
end

-- Adds a new sticker to a set; for bots only.
-- Returns the sticker set
-- @user_id Sticker set owner
-- @name Sticker set name
-- @sticker Sticker to add to the set
function tdbot.addStickerToSet(user_id, name, sticker, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'addStickerToSet',
    user_id = user_id,
    name = tostring(name),
    sticker = getInputFile(sticker)
  }, callback or dl_cb, data))
end

-- Changes the position of a sticker in the set to which it belongs; for bots only.
-- The sticker set must have been created by the bot
-- @sticker Sticker
-- @position New position of the sticker in the set, zero-based
function tdbot.setStickerPositionInSet(sticker, position, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'setStickerPositionInSet',
    sticker = getInputFile(sticker),
    position = position
  }, callback or dl_cb, data))
end

-- Removes a sticker from the set to which it belongs; for bots only.
-- The sticker set must have been created by the bot
-- @sticker Sticker
function tdbot.removeStickerFromSet(sticker, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'removeStickerFromSet',
    sticker = getInputFile(sticker)
  }, callback or dl_cb, data))
end

-- Sends a custom request; for bots only
-- @method The method name
-- @parameters JSON-serialized method parameters
function tdbot.sendCustomRequest(method, parameters, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'sendCustomRequest',
    method = tostring(method),
    parameters = tostring(parameters)
  }, callback or dl_cb, data))
end

-- Answers a custom query; for bots only
-- @custom_query_id Identifier of a custom query
-- @data JSON-serialized answer to the query
function tdbot.answerCustomQuery(custom_query_id, data, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'answerCustomQuery',
    custom_query_id = custom_query_id,
    data = tostring(data)
  }, callback or dl_cb, data))
end

-- Succeeds after a specified amount of time has passed.
-- Can be called before authorization
-- @seconds Number of seconds before the function returns
function tdbot.setAlarm(seconds, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'setAlarm',
    seconds = seconds
  }, callback or dl_cb, data))
end

-- Uses current user IP to found his country.
-- Returns two-letter ISO 3166-1 alpha-2 country code.
-- Can be called before authorization
function tdbot.getCountryCode(callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getCountryCode'
  }, callback or dl_cb, data))
end

-- Returns the default text for invitation messages to be used as a placeholder when the current user invites friends to Telegram
function tdbot.getInviteText(callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getInviteText'
  }, callback or dl_cb, data))
end

-- Returns the terms of service.
-- Can be called before authorization
function tdbot.getTermsOfService(callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getTermsOfService'
  }, callback or dl_cb, data))
end

-- Sets the proxy server for network requests.
-- Can be called before authorization
-- @proxy Proxy server to use.
-- Specify null to remove the proxy server
-- @server Proxy server IP address
-- @port Proxy server port
-- @username Username for logging in
-- @password Password for logging in
-- proxy = Empty|Socks5
function tdbot.setProxy(proxy, server, port, username, password, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'setProxy',
    proxy = {
      ["@type"] = 'proxy' .. proxy,
      server = server,
      port = port,
      username = username,
      password = password
    }
  }, callback or dl_cb, data))
end

-- Returns the proxy that is currently set up.
-- Can be called before authorization
function tdbot.getProxy(callback, data)
  assert (tdbot_function ({
    ["@type"] = 'getProxy'
  }, callback or dl_cb, data))
end

-- Does nothing; for testing only
function tdbot.testCallEmpty(callback, data)
  assert (tdbot_function ({
    ["@type"] = 'testCallEmpty'
  }, callback or dl_cb, data))
end

-- Returns the received string; for testing only
-- @x String to return
function tdbot.testCallString(x, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'testCallString',
    x = tostring(x)
  }, callback or dl_cb, data))
end

-- Returns the received bytes; for testing only
-- @x Bytes to return
function tdbot.testCallBytes(x, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'testCallBytes',
    x = x
  }, callback or dl_cb, data))
end

-- Returns the received vector of numbers; for testing only
-- @x Vector of numbers to return
function tdbot.testCallVectorInt(x, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'testCallVectorInt',
    x = vectorize(x)
  }, callback or dl_cb, data))
end

-- Returns the received vector of objects containing a number; for testing only
-- @x Vector of objects to return
function tdbot.testCallVectorIntObject(x, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'testCallVectorIntObject',
    x = vectorize(x)
  }, callback or dl_cb, data))
end

-- For testing only request.
-- Returns the received vector of strings; for testing only
-- @x Vector of strings to return
function tdbot.testCallVectorString(x, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'testCallVectorString',
    x = vectorize(x)
  }, callback or dl_cb, data))
end

-- Returns the received vector of objects containing a string; for testing only
-- @x Vector of objects to return
function tdbot.testCallVectorStringObject(x, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'testCallVectorStringObject',
    x = vectorize(x)
  }, callback or dl_cb, data))
end

-- Returns the squared received number; for testing only
-- @x Number to square
function tdbot.testSquareInt(x, callback, data)
  assert (tdbot_function ({
    ["@type"] = 'testSquareInt',
    x = x
  }, callback or dl_cb, data))
end

-- Sends a simple network request to the Telegram servers; for testing only
function tdbot.testNetwork(callback, data)
  assert (tdbot_function ({
    ["@type"] = 'testNetwork'
  }, callback or dl_cb, data))
end

-- Forces an updates.getDifference call to the Telegram servers; for testing only
function tdbot.testGetDifference(callback, data)
  assert (tdbot_function ({
    ["@type"] = 'testGetDifference'
  }, callback or dl_cb, data))
end

-- Does nothing and ensures that the Update object is used; for testing only
function tdbot.testUseUpdate(callback, data)
  assert (tdbot_function ({
    ["@type"] = 'testUseUpdate'
  }, callback or dl_cb, data))
end

-- Does nothing and ensures that the Error object is used; for testing only
function tdbot.testUseError(callback, data)
  assert (tdbot_function ({
    ["@type"] = 'testUseError'
  }, callback or dl_cb, data))
end

-- A text message
-- @text Formatted text to be sent.
-- Only Bold, Italic, Code, Pre, PreCode and TextUrl entities are allowed to be specified manually
-- @disable_web_page_preview True, if rich web page previews for URLs in the message text should be disabled
-- @clear_draft True, if a chat message draft should be deleted
-- textEntityType = Mention|Hashtag|BotCommand|Url|EmailAddress|Bold|Italic|Code|Pre|PreCode|TextUrl|MentionName
function tdbot.sendText(chat_id, reply_to_message_id, text, parse_mode, disable_web_page_preview, clear_draft, disable_notification, from_background, reply_markup, callback, data)
  local input_message_content = {
    ["@type"] = 'inputMessageText',
    disable_web_page_preview = disable_web_page_preview,
    text = {text = text},
    clear_draft = clear_draft
  }
  sendMessage(chat_id, reply_to_message_id, input_message_content, parse_mode, disable_notification, from_background, reply_markup, callback, data)
end

-- An animation message (GIF-style).
-- @animation Animation file to be sent
-- @thumbnail Animation thumbnail, if available
-- @duration Duration of the animation, in seconds
-- @width Width of the animation; may be replaced by the server
-- @height Height of the animation; may be replaced by the server
-- @caption Animation caption; 0-200 characters
function tdbot.sendAnimation(chat_id, reply_to_message_id, animation, caption, parse_mode, duration, width, height, thumbnail, thumb_width, thumb_height, disable_notification, from_background, reply_markup, callback, data)
  local input_message_content = {
    ["@type"] = 'inputMessageAnimation',
    animation = getInputFile(animation),
    thumbnail = {
      ["@type"] = 'inputThumbnail',
      thumbnail = getInputFile(thumbnail),
      width = thumb_width,
      height = thumb_height
    },
    caption = {text = caption},
    duration = duration,
    width = width,
    height = height
  }
  sendMessage(chat_id, reply_to_message_id, input_message_content, parse_mode, disable_notification, from_background, reply_markup, callback, data)
end

-- An audio message
-- @audio Audio file to be sent
-- @album_cover_thumbnail Thumbnail of the cover for the album, if available
-- @duration Duration of the audio, in seconds; may be replaced by the server
-- @title Title of the audio; 0-64 characters; may be replaced by the server
-- @performer Performer of the audio; 0-64 characters, may be replaced by the server
-- @caption Audio caption; 0-200 characters
function tdbot.sendAudio(chat_id, reply_to_message_id, audio, caption, parse_mode, duration, title, performer, thumbnail, thumb_width, thumb_height, disable_notification, from_background, reply_markup, callback, data)
  local input_message_content = {
    ["@type"] = 'inputMessageAudio',
    audio = getInputFile(audio),
    album_cover_thumbnail = {
      ["@type"] = 'inputThumbnail',
      thumbnail = getInputFile(thumbnail),
      width = thumb_width,
      height = thumb_height
    },
    caption = {text = caption},
    duration = duration,
    title = tostring(title),
    performer = tostring(performer)
  }
  sendMessage(chat_id, reply_to_message_id, input_message_content, parse_mode, disable_notification, from_background, reply_markup, callback, data)
end

-- A document message (general file)
-- @document Document to be sent
-- @thumbnail Document thumbnail, if available
-- @caption Document caption; 0-200 characters
function tdbot.sendDocument(chat_id, reply_to_message_id, document, caption, parse_mode, thumbnail, thumb_width, thumb_height, disable_notification, from_background, reply_markup, callback, data)
  local input_message_content = {
    ["@type"] = 'inputMessageDocument',
    document = getInputFile(document),
    thumbnail = {
      ["@type"] = 'inputThumbnail',
      thumbnail = getInputFile(thumbnail),
      width = thumb_width,
      height = thumb_height
    },
    caption = {text = caption}
  }
  sendMessage(chat_id, reply_to_message_id, input_message_content, parse_mode, disable_notification, from_background, reply_markup, callback, data)
end

-- A photo message
-- @photo Photo to send
-- @thumbnail Photo thumbnail to be sent, this is sent to the other party in secret chats only
-- @added_sticker_file_ids File identifiers of the stickers added to the photo, if applicable
-- @width Photo width
-- @height Photo height
-- @caption Photo caption; 0-200 characters
-- @ttl Photo TTL (Time To Live), in seconds (0-60). A non-zero TTL can be specified only in private chats
function tdbot.sendPhoto(chat_id, reply_to_message_id, photo, caption, parse_mode, added_sticker_file_ids, width, height, ttl, thumbnail, thumb_width, thumb_height, disable_notification, from_background, reply_markup, callback, data)
  local input_message_content = {
    ["@type"] = 'inputMessagePhoto',
    photo = getInputFile(photo),
    thumbnail = {
      ["@type"] = 'inputThumbnail',
      thumbnail = getInputFile(thumbnail),
      width = thumb_width,
      height = thumb_height
    },
    caption = {text = caption},
    added_sticker_file_ids = vectorize(added_sticker_file_ids),
    width = width,
    height = height,
    ttl = ttl or 0
  }
  sendMessage(chat_id, reply_to_message_id, input_message_content, parse_mode, disable_notification, from_background, reply_markup, callback, data)
end

-- A sticker message
-- @sticker Sticker to be sent
-- @thumbnail Sticker thumbnail, if available
-- @width Sticker width
-- @height Sticker height
function tdbot.sendSticker(chat_id, reply_to_message_id, sticker, width, height, disable_notification, thumbnail, thumb_width, thumb_height, from_background, reply_markup, callback, data)
  local input_message_content = {
    ["@type"] = 'inputMessageSticker',
    sticker = getInputFile(sticker),
    thumbnail = {
      ["@type"] = 'inputThumbnail',
      thumbnail = getInputFile(thumbnail),
      width = thumb_width,
      height = thumb_height
    },
    width = width,
    height = height
  }
  sendMessage(chat_id, reply_to_message_id, input_message_content, nil, disable_notification, from_background, reply_markup, callback, data)
end

-- A video message
-- @video Video to be sent
-- @thumbnail Video thumbnail, if available
-- @added_sticker_file_ids File identifiers of the stickers added to the video, if applicable
-- @duration Duration of the video, in seconds
-- @width Video width
-- @height Video height
-- @caption Video caption; 0-200 characters
-- @ttl Video TTL (Time To Live), in seconds (0-60). A non-zero TTL can be specified only in private chats
function tdbot.sendVideo(chat_id, reply_to_message_id, video, caption, parse_mode, added_sticker_file_ids, duration, width, height, ttl, thumbnail, thumb_width, thumb_height, disable_notification, from_background, reply_markup, callback, data)
  local input_message_content = {
    ["@type"] = 'inputMessageVideo',
    video = getInputFile(video),
    thumbnail = {
      ["@type"] = 'inputThumbnail',
      thumbnail = getInputFile(thumbnail),
      width = thumb_width,
      height = thumb_height
    },
    caption = {text = caption},
    added_sticker_file_ids = vectorize(added_sticker_file_ids),
    duration = duration,
    width = width,
    height = height,
    ttl = ttl
  }
  sendMessage(chat_id, reply_to_message_id, input_message_content, parse_mode, disable_notification, from_background, reply_markup, callback, data)
end

-- A video note message
-- @video_note Video note to be sent
-- @thumbnail Video thumbnail, if available
-- @duration Duration of the video, in seconds
-- @length Video width and height; must be positive and not greater than 640
function tdbot.sendVideoNote(chat_id, reply_to_message_id, video_note, duration, length, thumbnail, thumb_width, thumb_height, disable_notification, from_background, reply_markup, callback, data)
  local input_message_content = {
    ["@type"] = 'inputMessageVideoNote',
    video_note = getInputFile(video_note),
    thumbnail = {
      ["@type"] = 'inputThumbnail',
      thumbnail = getInputFile(thumbnail),
      width = thumb_width,
      height = thumb_height
    },
    duration = duration,
    length = length
  }
  sendMessage(chat_id, reply_to_message_id, input_message_content, nil, disable_notification, from_background, reply_markup, callback, data)
end

-- A voice note message
-- @voice_note Voice note to be sent
-- @duration Duration of the voice note, in seconds
-- @waveform Waveform representation of the voice note, in 5-bit format
-- @caption Voice note caption; 0-200 characters
function tdbot.sendVoiceNote(chat_id, reply_to_message_id, voice_note, caption, parse_mode, duration, waveform, disable_notification, from_background, reply_markup, callback, data)
  local input_message_content = {
    ["@type"] = 'inputMessageVoiceNote',
    voice_note = getInputFile(voice_note),
    caption = {text = caption},
    duration = duration,
    waveform = waveform
  }
  sendMessage(chat_id, reply_to_message_id, input_message_content, parse_mode, disable_notification, from_background, reply_markup, callback, data)
end

-- A message with a location
-- @location Location to be sent
-- @live_period Period for which the location can be updated, in seconds; should bebetween 60 and 86400 for a live location and 0 otherwise
function tdbot.sendLocation(chat_id, reply_to_message_id, latitude, longitude, disable_notification, from_background, reply_markup, callback, data)
  local input_message_content = {
    ["@type"] = 'inputMessageLocation',
    location = {
      ["@type"] = 'location',
      latitude = latitude,
      longitude = longitude
    },
    live_period = liveperiod
  }
  sendMessage(chat_id, reply_to_message_id, input_message_content, nil, disable_notification, from_background, reply_markup, callback, data)
end

-- A message with information about a venue
-- @venue Venue to send
function tdbot.sendVenue(chat_id, reply_to_message_id, latitude, longitude, title, address, provider, id, disable_notification, from_background, reply_markup, callback, data)
  local input_message_content = {
    ["@type"] = 'inputMessageVenue',
    venue = {
      ["@type"] = 'venue',
      location = {
        ["@type"] = 'location',
        latitude = latitude,
        longitude = longitude
      },
      title = tostring(title),
      address = tostring(address),
      provider = tostring(provider),
      id = tostring(id)
    }
  }
  sendMessage(chat_id, reply_to_message_id, input_message_content, nil, disable_notification, from_background, reply_markup, callback, data)
end

-- A message containing a user contact
-- @contact Contact to send
function tdbot.sendContact(chat_id, reply_to_message_id, phone_number, first_name, last_name, user_id, disable_notification, from_background, reply_markup, callback, data)
  local input_message_content = {
    ["@type"] = 'inputMessageContact',
    contact = {
      ["@type"] = 'contact',
      phone_number = tostring(phone_number),
      first_name = tostring(first_name),
      last_name = tostring(last_name),
      user_id = user_id
    }
  }
  sendMessage(chat_id, reply_to_message_id, input_message_content, nil, disable_notification, from_background, reply_markup, callback, data)
end

-- A message with a game; not supported for channels or secret chats
-- @bot_user_id User identifier of the bot that owns the game
-- @game_short_name Short name of the game
function tdbot.sendGame(chat_id, reply_to_message_id, bot_user_id, gameshortname, disable_notification, from_background, reply_markup, callback, data)
  local input_message_content = {
    ["@type"] = 'inputMessageGame',
    bot_user_id = bot_user_id,
    game_short_name = tostring(gameshortname)
  }
  sendMessage(chat_id, reply_to_message_id, input_message_content, nil, disable_notification, from_background, reply_markup, callback, data)
end

-- A message with an invoice; can be used only by bots and only in private chats
-- @invoice Invoice
-- @title Product title; 1-32 characters
-- @param_description Product description; 0-255 characters
-- @photo_url Product photo URL; optional
-- @photo_size Product photo size
-- @photo_width Product photo width
-- @photo_height Product photo height
-- @payload The invoice payload
-- @provider_token Payment provider token
-- @provider_data JSON-encoded data about the invoice, which will be shared with the payment provider
-- @start_parameter Unique invoice bot start_parameter for the generation of this invoice
function tdbot.sendInvoice(chat_id, reply_to_message_id, invoice, title, description, photo_url, photo_size, photo_width, photo_height, payload, provider_token, provider_data, start_parameter, disable_notification, from_background, reply_markup, callback, data)
  local input_message_content = {
    ["@type"] = 'inputMessageInvoice',
    invoice = invoice,
    title = tostring(title),
    description = tostring(description),
    photo_url = tostring(photo_url),
    photo_size = photo_size,
    photo_width = photo_width,
    photo_height = photo_height,
    payload = payload,
    provider_token = tostring(provider_token),
    provider_data = tostring(provider_data),
    start_parameter = tostring(start_parameter)
  }
  sendMessage(chat_id, reply_to_message_id, input_message_content, nil, disable_notification, from_background, reply_markup, callback, data)
end

-- A forwarded message
-- @from_chat_id Identifier for the chat this forwarded message came from
-- @message_id Identifier of the message to forward
-- @in_game_share True, if a game message should be shared within a launched game; applies only to game messages
function tdbot.sendForwarded(chat_id, reply_to_message_id, from_chat_id, message_id, in_game_share, disable_notification, from_background, reply_markup, callback, data)
  local input_message_content = {
    ["@type"] = 'inputMessageForwarded',
    from_chat_id = from_chat_id,
    message_id = message_id,
    in_game_share = in_game_share
  }
  sendMessage(chat_id, reply_to_message_id, input_message_content, nil, disable_notification, from_background, reply_markup, callback, data)
end

return tdbot
