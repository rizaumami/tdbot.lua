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
]]--

-- Vector form: {[0] = v1, v2, v3}
-- If false or true crashed your telegram-bot, try to change true to 1 and false to 0

-- Main table
local tdbot = {}

-- Does nothing, suppress 'lua: attempt to call a nil value' warning
function dl_cb(arg, data)
end

-- There are three type of chats:
-- @chat_id = user, group, channel, and broadcast
-- @group_id = normal group
-- @channel_id = channel and broadcast
local function getChatId(chat_id)
  local chat = {}
  local chat_id = tostring(chat_id)

  if chat_id:match('^-100') then
    local channel_id = chat_id:gsub('-100', '')
    chat = {id = channel_id, type = 'channel'}
  else
    local group_id = chat_id:gsub('-', '')
    chat = {id = group_id, type = 'group'}
  end

  return chat
end

local function getInputFile(file, conversion_str, expectedsize)
  local input = tostring(file)
  local infile = {}

  if (conversion_str and expectedsize) then
    infile = {
      _ = 'inputFileGenerated',
      original_path = tostring(file),
      conversion = tostring(conversion_str),
      expected_size = expectedsize
    }
  else
    if input:match('/') then
      infile = {_ = 'inputFileLocal', path = file}
    elseif input:match('^%d+$') then
      infile = {_ = 'inputFileId', id = file}
    else
      infile = {_ = 'inputFilePersistentId', persistent_id = file}
    end
  end

  return infile
end

-- User can send bold, italic, and monospace text uses HTML or Markdown format.
local function getParseMode(parse_mode)
  local P = {}
  if parse_mode then
    local mode = parse_mode:lower()

    if mode == 'markdown' or mode == 'md' then
      P._ = 'textParseModeMarkdown'
    elseif mode == 'html' then
      P._ = 'textParseModeHTML'
    end
  end

  return P
end

-- Returns current authorization state, offline request
function tdbot.getAuthState(callback, data)
  assert (tdbot_function ({
    _ = 'getAuthState'
  }, callback or dl_cb, data))
end

-- Sets user's phone number and sends authentication code to the user.
-- Works only when getAuthState returns authStateWaitPhoneNumber.
-- If phone number is not recognized or another error has happened, returns an error. Otherwise returns authStateWaitCode
-- @phone_number User's phone number in any reasonable format
-- @allow_flash_call Pass True, if code can be sent via flash call to the specified phone number
-- @is_current_phone_number Pass true, if the phone number is used on the current device. Ignored if allow_flash_call is False
function tdbot.setAuthPhoneNumber(phonenumber, allowflashcall, iscurrentphonenumber, callback, data)
  assert (tdbot_function ({
    _ = 'setAuthPhoneNumber',
    phone_number = tostring(),
    allow_flash_call = allowflashcall,
    is_current_phone_number = iscurrentphonenumber
  }, callback or dl_cb, data))
end

-- Resends authentication code to the user.
-- Works only when getAuthState returns authStateWaitCode and next_code_type of result is not null.
-- Returns authStateWaitCode on success
function tdbot.resendAuthCode(callback, data)
  assert (tdbot_function ({
    _ = 'resendAuthCode'
  }, callback or dl_cb, data))
end

-- Checks authentication code.
-- Works only when getAuthState returns authStateWaitCode.
-- Returns authStateWaitPassword or authStateOk on success
-- @code Verification code from SMS, Telegram message, phone call or flash call
-- @first_name User first name, if user is yet not registered, 1-255 characters
-- @last_name Optional user last name, if user is yet not registered, 0-255 characters
function tdbot.checkAuthCode(cod, firstname, lastname, callback, data)
  assert (tdbot_function ({
    _ = 'checkAuthCode',
    code = tostring(cod),
    first_name = tostring(firstname),
    last_name = tostring(lastname)
  }, callback or dl_cb, data))
end

-- Checks password for correctness.
-- Works only when getAuthState returns authStateWaitPassword.
-- Returns authStateOk on success
-- @password Password to check
function tdbot.checkAuthPassword(passwd, callback, data)
  assert (tdbot_function ({
    _ = 'checkAuthPassword',
    password = tostring(passwd)
  }, callback or dl_cb, data))
end

-- Requests to send password recovery code to email.
-- Works only when getAuthState returns authStateWaitPassword.
-- Returns authStateWaitPassword on success
function tdbot.requestAuthPasswordRecovery(callback, data)
  assert (tdbot_function ({
    _ = 'requestAuthPasswordRecovery'
  }, callback or dl_cb, data))
end

-- Recovers password with recovery code sent to email.
-- Works only when getAuthState returns authStateWaitPassword.
-- Returns authStateOk on success
-- @recovery_code Recovery code to check
function tdbot.recoverAuthPassword(recoverycode, callback, data)
  assert (tdbot_function ({
    _ = 'recoverAuthPassword',
    recovery_code = tostring(recoverycode)
  }, callback or dl_cb, data))
end

-- Logs out user.
-- If force == false, begins to perform soft log out, returns authStateLoggingOut after completion.
-- If force == true then succeeds almost immediately without cleaning anything at the server, but returns error with code 401 and description 'Unauthorized'
-- @force If true, just delete all local data.
-- Session will remain in list of active sessions
function tdbot.resetAuth(force, callback, data)
  assert (tdbot_function ({
    _ = 'resetAuth',
    force = force
  }, callback or dl_cb, data))
end

-- Check bot's authentication token to log in as a bot.
-- Works only when getAuthState returns authStateWaitPhoneNumber.
-- Can be used instead of setAuthPhoneNumber and checkAuthCode to log in.
-- Returns authStateOk on success
-- @token Bot token
function tdbot.checkAuthBotToken(token, callback, data)
  assert (tdbot_function ({
    _ = 'checkAuthBotToken',
    token = tostring(token)
  }, callback or dl_cb, data))
end

-- Returns current state of two-step verification
function tdbot.getPasswordState(callback, data)
  assert (tdbot_function ({
    _ = 'getPasswordState'
  }, callback or dl_cb, data))
end

-- Changes user password.
-- If new recovery email is specified, then error EMAIL_UNCONFIRMED is returned and password change will not be applied until email confirmation.
-- Application should call getPasswordState from time to time to check if email is already confirmed
-- @old_password Old user password
-- @new_password New user password, may be empty to remove the password
-- @new_hint New password hint, can be empty
-- @set_recovery_email Pass True, if recovery email should be changed
-- @new_recovery_email New recovery email, may be empty
function tdbot.setPassword(oldpassword, newpassword, newhint, setrecoveryemail, newrecoveryemail, callback, data)
  assert (tdbot_function ({
    _ = 'setPassword',
    old_password = tostring(oldpassword),
    new_password = tostring(newpassword),
    new_hint = tostring(newhint),
    set_recovery_email = setrecoveryemail,
    new_recovery_email = tostring(newrecoveryemail)
  }, callback or dl_cb, data))
end

-- Returns set up recovery email.
-- This method can be used to verify a password provided by the user
-- @password Current user password
function tdbot.getRecoveryEmail(passwd, callback, data)
  assert (tdbot_function ({
    _ = 'getRecoveryEmail',
    password = tostring(passwd)
  }, callback or dl_cb, data))
end

-- Changes user recovery email.
-- If new recovery email is specified, then error EMAIL_UNCONFIRMED is returned and email will not be changed until email confirmation.
-- Application should call getPasswordState from time to time to check if email is already confirmed.
-- If new_recovery_email coincides with the current set up email succeeds immediately and aborts all other requests waiting for email confirmation
-- @password Current user password
-- @new_recovery_email New recovery email
function tdbot.setRecoveryEmail(passwd, newrecoveryemail, callback, data)
  assert (tdbot_function ({
    _ = 'setRecoveryEmail',
    password = tostring(passwd),
    new_recovery_email = tostring(newrecoveryemail)
  }, callback or dl_cb, data))
end

-- Requests to send password recovery code to email
function tdbot.requestPasswordRecovery(callback, data)
  assert (tdbot_function ({
    _ = 'requestPasswordRecovery'
  }, callback or dl_cb, data))
end

-- Recovers password with recovery code sent to email
-- @recovery_code Recovery code to check
function tdbot.recoverPassword(recoverycode, callback, data)
  assert (tdbot_function ({
    _ = 'recoverPassword',
    recovery_code = tostring(recoverycode)
  }, callback or dl_cb, data))
end

-- Creates new temporary password for payments processing
-- @password Persistent user password
-- @valid_for Time before temporary password will expire, seconds. Should be between 60 and 86400
function tdbot.createTemporaryPassword(passwd, validfor, callback, data)
  assert (tdbot_function ({
    _ = 'createTemporaryPassword',
    password = tostring(passwd),
    valid_for = validfor
  }, callback or dl_cb, data))
end

-- Returns information about current temporary password
function tdbot.getTemporaryPasswordState(callback, data)
  assert (tdbot_function ({
    _ = 'getTemporaryPasswordState'
  }, callback or dl_cb, data))
end

-- Handles DC_UPDATE push service notification.
-- Can be called before authorization
-- @dc Value of 'dc' paramater of the notification
-- @addr Value of 'addr' parameter of the notification
function tdbot.processDcUpdate(dc, addr, callback, data)
  assert (tdbot_function ({
    _ = 'processDcUpdate',
    dc = tostring(dc),
    addr = tostring(addr)
  }, callback or dl_cb, data))
end

-- Returns current logged in user
function tdbot.getMe(callback, data)
  assert (tdbot_function ({
    _ = 'getMe'
  }, callback or dl_cb, data))
end

-- Returns information about a user by its identifier, offline request if current user is not a bot
-- @user_id User identifier
function tdbot.getUser(userid, callback, data)
  assert (tdbot_function ({
    _ = 'getUser',
    user_id = userid
  }, callback or dl_cb, data))
end

-- Returns full information about a user by its identifier
-- @user_id User identifier
function tdbot.getUserFull(userid, callback, data)
  assert (tdbot_function ({
    _ = 'getUserFull',
    user_id = userid
  }, callback or dl_cb, data))
end

-- Returns information about a group by its identifier, offline request if current user is not a bot
-- @group_id Group identifier
function tdbot.getGroup(groupid, callback, data)
  assert (tdbot_function ({
    _ = 'getGroup',
    group_id = getChatId(groupid).id
  }, callback or dl_cb, data))
end

-- Returns full information about a group by its identifier
-- @group_id Group identifier
function tdbot.getGroupFull(groupid, callback, data)
  assert (tdbot_function ({
    _ = 'getGroupFull',
    group_id = getChatId(groupid).id
  }, callback or dl_cb, data))
end

-- Returns information about a channel by its identifier, offline request if current user is not a bot
-- @channel_id Channel identifier
function tdbot.getChannel(channelid, callback, data)
  assert (tdbot_function ({
    _ = 'getChannel',
    channel_id = getChatId(channelid).id
  }, callback or dl_cb, data))
end

-- Returns full information about a channel by its identifier, cached for at most 1 minute
-- @channel_id Channel identifier
function tdbot.getChannelFull(channelid, callback, data)
  assert (tdbot_function ({
    _ = 'getChannelFull',
    channel_id = getChatId(channelid).id
  }, callback or dl_cb, data))
end

-- Returns information about a secret chat by its identifier, offline request
-- @secret_chat_id Secret chat identifier
function tdbot.getSecretChat(secretchatid, callback, data)
  assert (tdbot_function ({
    _ = 'getSecretChat',
    secret_chat_id = secretchatid
  }, callback or dl_cb, data))
end

-- Returns information about a chat by its identifier, offline request if current user is not a bot
-- @chat_id Chat identifier
function tdbot.getChat(chatid, callback, data)
  assert (tdbot_function ({
    _ = 'getChat',
    chat_id = chatid
  }, callback or dl_cb, data))
end

-- Returns information about a message
-- @chat_id Identifier of the chat, message belongs to
-- @message_id Identifier of the message to get
function tdbot.getMessage(chatid, messageid, callback, data)
  assert (tdbot_function ({
    _ = 'getMessage',
    chat_id = chatid,
    message_id = messageid
  }, callback or dl_cb, data))
end

-- Returns information about messages.
-- If message is not found, returns null on the corresponding position of the result
-- @chat_id Identifier of the chat, messages belongs to
-- @message_ids Identifiers of the messages to get
function tdbot.getMessages(chatid, messageids, callback, data)
  assert (tdbot_function ({
    _ = 'getMessages',
    chat_id = chatid,
    message_ids = messageids
  }, callback or dl_cb, data))
end

-- Returns information about a file, offline request
-- @file_id Identifier of the file to get
function tdbot.getFile(fileid, callback, data)
  assert (tdbot_function ({
    _ = 'getFile',
    file_id = fileid
  }, callback or dl_cb, data))
end

-- Returns information about a file by its persistent id, offline request.
-- May be used to register a URL as a file for further uploading or sending as message
-- @persistent_file_id Persistent identifier of the file to get
-- @file_type File type, if known
function tdbot.getFilePersistent(persistentfileid, filetype, callback, data)
  assert (tdbot_function ({
    _ = 'getFilePersistent',
    persistent_file_id = tostring(persistentfileid),
    file_type = FileType
  }, callback or dl_cb, data))
end

-- Returns list of chats in the right order, chats are sorted by (order, chat_id) in decreasing order.
-- For example, to get list of chats from the beginning, the offset_order should be equal 2^63 - 1
-- @offset_order Chat order to return chats from
-- @offset_chat_id Chat identifier to return chats from
-- @limit Maximum number of chats to be returned. There may be less than limit chats returned even the end of the list is not reached
function tdbot.getChats(offsetorder, offsetchatid, lim, callback, data)
  assert (tdbot_function ({
    _ = 'getChats',
    offset_order = offsetorder,
    offset_chat_id = offsetchatid,
    limit = lim
  }, callback or dl_cb, data))
end

-- Searches public chat by its username.
-- Currently only private and channel chats can be public.
-- Returns chat if found, otherwise some error is returned
-- @username Username to be resolved
function tdbot.searchPublicChat(username, callback, data)
  assert (tdbot_function ({
    _ = 'searchPublicChat',
    username = tostring(username)
  }, callback or dl_cb, data))
end

-- Searches public chats by prefix of their username.
-- Currently only private and channel (including supergroup) chats can be public.
-- Returns meaningful number of results.
-- Returns nothing if length of the searched username prefix is less than 5.
-- Excludes private chats with contacts from the results
-- @username_prefix Prefix of the username to search
function tdbot.searchPublicChats(usernameprefix, callback, data)
  assert (tdbot_function ({
    _ = 'searchPublicChats',
    username_prefix = tostring(usernameprefix)
  }, callback or dl_cb, data))
end

-- Searches for specified query in the title and username of known chats, offline request.
-- Returns chats in the order of them in the chat list
-- @query Query to search for, if query is empty, returns up to 20 recently found chats
-- @limit Maximum number of chats to be returned
function tdbot.searchChats(query, lim, callback, data)
  assert (tdbot_function ({
    _ = 'searchChats',
    query = tostring(query),
    limit = lim
  }, callback or dl_cb, data))
end

-- Returns a list of frequently used chats.
-- Supported only if chat info database is enabled
-- @category Category of chats to return
-- @limit Maximum number of chats to be returned, at most 30
-- category: Users | Bots | Groups | Channels | InlineBots | Calls
function tdbot.getTopChats(cat, lim, callback, data)
  assert (tdbot_function ({
    _ = 'getTopChats',
    category = {
      _ = 'topChatCategory' .. cat
    },
    limit = lim
  }, callback or dl_cb, data))
end

-- Delete a chat from a list of frequently used chats.
-- Supported only if chat info database is enabled
-- @category Category of frequently used chats
-- @chat_id Chat identifier
function tdbot.deleteTopChat(cat, chatid, callback, data)
  assert (tdbot_function ({
    _ = 'deleteTopChat',
    category = {
      _ = 'topChatCategory' .. cat
    },
    chat_id = chatid
  }, callback or dl_cb, data))
end

-- Adds chat to the list of recently found chats.
-- The chat is added to the beginning of the list.
-- If the chat is already in the list, at first it is removed from the list
-- @chat_id Identifier of the chat to add
function tdbot.addRecentlyFoundChat(chatid, callback, data)
  assert (tdbot_function ({
    _ = 'addRecentlyFoundChat',
    chat_id = chatid
  }, callback or dl_cb, data))
end

-- Deletes chat from the list of recently found chats
-- @chat_id Identifier of the chat to delete
function tdbot.deleteRecentlyFoundChat(chatid, callback, data)
  assert (tdbot_function ({
    _ = 'deleteRecentlyFoundChat',
    chat_id = chatid
  }, callback or dl_cb, data))
end

-- Clears list of recently found chats
function tdbot.deleteRecentlyFoundChats(callback, data)
  assert (tdbot_function ({
    _ = 'deleteRecentlyFoundChats'
  }, callback or dl_cb, data))
end

-- Returns list of common chats with an other given user.
-- Chats are sorted by their type and creation date
-- @user_id User identifier
-- @offset_chat_id Chat identifier to return chats from, use 0 for the first request
-- @limit Maximum number of chats to be returned, up to 100
function tdbot.getCommonChats(userid, offsetchatid, lim, callback, data)
  assert (tdbot_function ({
    _ = 'getCommonChats',
    user_id = userid,
    offset_chat_id = offsetchatid,
    limit = lim
  }, callback or dl_cb, data))
end

-- Returns list of created public chats
function tdbot.getCreatedPublicChats(callback, data)
  assert (tdbot_function ({
    _ = 'getCreatedPublicChats'
  }, callback or dl_cb, data))
end

-- Returns messages in a chat.
-- Returns result in reverse chronological order, i.e. in order of decreasing message.message_id. Offline request if only_local is true
-- @chat_id Chat identifier
-- @from_message_id Identifier of the message near which we need a history, you can use 0 to get results from the beginning, i.e. from oldest to newest
-- @offset Specify 0 to get results exactly from from_message_id or negative offset to get specified message and some newer messages
-- @limit Maximum number of messages to be returned, should be positive and can't be greater than 100.
-- If offset is negative, limit must be greater than -offset.
-- There may be less than limit messages returned even the end of the history is not reached
-- @only_local Return only locally available messages without sending network requests
function tdbot.getChatHistory(chatid, frommessageid, off, lim, onlylocal, callback, data)
  assert (tdbot_function ({
    _ = 'getChatHistory',
    chat_id = chatid,
    from_message_id = frommessageid,
    offset = off,
    limit = lim,
    only_local = onlylocal
  }, callback or dl_cb, data))
end

-- Deletes all messages in the chat.
-- Can't be used for channel chats
-- @chat_id Chat identifier
-- @remove_from_chat_list Pass true, if chat should be removed from the chat list
function tdbot.deleteChatHistory(chatid, removefromchatlist, callback, data)
  assert (tdbot_function ({
    _ = 'deleteChatHistory',
    chat_id = chatid,
    remove_from_chat_list = removefromchatlist
  }, callback or dl_cb, data))
end

-- Searches for messages with given words in the chat.
-- Returns result in reverse chronological order, i. e. in order of decreasing message_id.
-- Doesn't work in secret chats with non-empty query (searchSecretMessages should be used instead) or without enabled message database
-- @chat_id Chat identifier to search messages in
-- @query Query to search for
-- @sender_user_id If not 0, only messages sent by the specified user will be returned. Doesn't supported in secret chats
-- @from_message_id Identifier of the message from which we need a history, you can use 0 to get results from the beginning
-- @offset Specify 0 to get results exactly from from_message_id or negative offset to get specified message and some newer messages
-- @limit Maximum number of messages to be returned, should be positive and can't be greater than 100. If offset is negative, limit must be greater than -offset. There may be less than limit messages returned even the end of the history is not reached
-- @filter Filter for content of the searched messages
---
-- searchMessagesFilter Represents filter for content of searched messages
-- searchMessagesFilter: Empty | Animation | Audio | Document | Photo | Video | Voice | PhotoAndVideo | Url | ChatPhoto | Call | MissedCall | VideoNote | VoiceAndVideoNote
function tdbot.searchChatMessages(chatid, query, senderuserid, frommessageid, off, lim, searchmessagesfilter, callback, data)
  assert (tdbot_function ({
    _ = 'searchChatMessages',
    chat_id = chatid,
    query = tostring(query),
    sender_user_id = senderuserid,
    from_message_id = frommessageid,
    offset = off,
    limit = lim,
    filter = {
      _ = 'searchMessagesFilter' .. searchmessagesfilter,
    },
  }, callback or dl_cb, data))
end

-- Searches for messages in all chats except secret chats.
-- Returns result in reverse chronological order, i.e. in order of decreasing (date, chat_id, message_id)
-- @query Query to search for
-- @offset_date Date of the message to search from, you can use 0 or any date in the future to get results from the beginning
-- @offset_chat_id Chat identifier of the last found message or 0 for the first request
-- @offset_message_id Message identifier of the last found message or 0 for the first request
-- @limit Maximum number of messages to be returned, at most 100
function tdbot.searchMessages(query, offsetdate, offsetchatid, offsetmessageid, lim, callback, data)
  assert (tdbot_function ({
    _ = 'searchMessages',
    query = tostring(query),
    offset_date = offsetdate,
    offset_chat_id = offsetchatid,
    offset_message_id = offsetmessageid,
    limit = lim
  }, callback or dl_cb, data))
end

-- Searches for messages in secret chats.
-- Returns result in reverse chronological order
-- @chat_id Identifier of a chat to search in.
-- Specify 0 to search in all secret chats
-- @query Query to search for. If empty, searchChatMessages should be used instead
-- @from_search_id Identifier from the result of previous request, use 0 to get results from the beginning
-- @limit Maximum number of messages to be returned, can't be greater than 100
-- @filter Filter for content of searched messages
---
-- searchMessagesFilter Represents filter for content of searched messages
-- searchMessagesFilter: Empty | Animation | Audio | Document | Photo | Video | Voice | PhotoAndVideo | Url | ChatPhoto | Call | MissedCall | VideoNote | VoiceAndVideoNote
function tdbot.searchSecretMessages(chatid, query, fromsearchid, lim, searchmessagesfilter, callback, data)
  assert (tdbot_function ({
    _ = 'searchSecretMessages',
    chat_id = chatid,
    query = tostring(query),
    from_search_id = fromsearchid,
    limit = lim,
    filter = {
      _ = 'searchMessagesFilter' .. searchmessagesfilter,
    },
  }, callback or dl_cb, data))
end

-- Searches for call messages.
-- Returns result in reverse chronological order, i.e. in order of decreasing message_id
-- @from_message_id Identifier of the message from which to search, you can use 0 to get results from beginning
-- @limit Maximum number of messages to be returned, can't be greater than 100.
-- There may be less than limit messages returned even the end of the history is not reached filter
-- @only_missed If true, return only messages with missed calls
function tdbot.searchCallMessages(frommessageid, lim, onlymissed, callback, data)
  assert (tdbot_function ({
    _ = 'searchCallMessages',
    from_message_id = frommessageid,
    limit = lim,
    only_missed = onlymissed
  }, callback or dl_cb, data))
end

-- Returns public HTTPS link to a message.
-- Available only for messages in public channels
-- @chat_id Identifier of the chat, message belongs to
-- @message_id Identifier of the message
function tdbot.getPublicMessageLink(chatid, messageid, callback, data)
  assert (tdbot_function ({
    _ = 'getPublicMessageLink',
    chat_id = chatid,
    message_id = messageid
  }, callback or dl_cb, data))
end

-- Sends a message.
-- Returns sent message
-- @chat_id Chat to send message
-- @reply_to_message_id Identifier of a message to reply to or 0
-- @disable_notification Pass true, to disable notification about the message, doesn't works in secret chats
-- @from_background Pass true, if the message is sent from background
-- @reply_markup Bots only. Markup for replying to message
-- @input_message_content Content of a message to send
local function sendMessage(chatid, replytomessageid, InputMessageContent, disablenotification, frombackground, replymarkup, callback, data)
  assert (tdbot_function ({
    _ = 'sendMessage',
    chat_id = chatid,
    reply_to_message_id = replytomessageid,
    disable_notification = disablenotification or 0,
    from_background = frombackground or 1,
    reply_markup = replymarkup,
    input_message_content = InputMessageContent
  }, callback or dl_cb, data))
end

tdbot.sendMessage = sendMessage

-- Invites bot to a chat (if it is not in the chat) and send /start to it.
-- Bot can't be invited to a private chat other than chat with the bot.
-- Bots can't be invited to broadcast channel chats and secret chats.
-- Returns sent message
-- @bot_user_id Identifier of the bot
-- @chat_id Identifier of the chat
-- @parameter Hidden parameter sent to bot for deep linking (https://api.telegram.org/bots#deep-linking)
function tdbot.sendBotStartMessage(botuserid, chatid, parameter, callback, data)
  assert (tdbot_function ({
    _ = 'sendBotStartMessage',
    bot_user_id = botuserid,
    chat_id = chatid,
    parameter = tostring(parameter)
  }, callback or dl_cb, data))
end

-- Sends result of the inline query as a message.
-- Returns sent message.
-- Always clears chat draft message
-- @chat_id Chat to send message
-- @reply_to_message_id Identifier of a message to reply to or 0
-- @disable_notification Pass true, to disable notification about the message, doesn't works in secret chats
-- @from_background Pass true, if the message is sent from background
-- @query_id Identifier of the inline query
-- @result_id Identifier of the inline result
function tdbot.sendInlineQueryResultMessage(chatid, replytomessageid, disablenotification, frombackground, queryid, resultid, callback, data)
  assert (tdbot_function ({
    _ = 'sendInlineQueryResultMessage',
    chat_id = chatid,
    reply_to_message_id = replytomessageid,
    disable_notification = disablenotification,
    from_background = frombackground,
    query_id = queryid,
    result_id = tostring(resultid)
  }, callback or dl_cb, data))
end

-- Forwards previously sent messages.
-- Returns forwarded messages in the same order as message identifiers passed in message_ids.
-- If message can't be forwarded, null will be returned instead of the message
-- @chat_id Identifier of a chat to forward messages
-- @from_chat_id Identifier of a chat to forward from
-- @message_ids Identifiers of messages to forward
-- @disable_notification Pass true, to disable notification about the message, doesn't works if messages are forwarded to secret chat
-- @from_background Pass true, if the message is sent from background
function tdbot.forwardMessages(chatid, fromchatid, messageids, disablenotification, frombackground, callback, data)
  assert (tdbot_function ({
    _ = 'forwardMessages',
    chat_id = chatid,
    from_chat_id = fromchatid,
    message_ids = messageids,
    disable_notification = disablenotification,
    from_background = frombackground
  }, callback or dl_cb, data))
end

-- Changes current ttl setting in a secret chat and sends corresponding message
-- @chat_id Chat identifier
-- @ttl New value of ttl in seconds
function tdbot.sendChatSetTtlMessage(chatid, seconds, callback, data)
  assert (tdbot_function ({
    _ = 'sendChatSetTtlMessage',
    chat_id = chatid,
    ttl = seconds
  }, callback or dl_cb, data))
end

-- Bots only.
-- Edits message reply markup.
-- Returns edited message after edit is complete server side
-- @chat_id Chat the message belongs to
-- @message_id Identifier of the message
-- @reply_markup New message reply markup
function tdbot.editMessageReplyMarkup(chatid, messageid, replymarkup, callback, data)
  assert (tdbot_function ({
    _ = 'editMessageReplyMarkup',
    chat_id = chatid,
    message_id = messageid,
    reply_markup = replymarkup
  }, callback or dl_cb, data))
end

-- Bots only.
-- Edits text of an inline text or game message sent via bot
-- @inline_message_id Inline message identifier
-- @reply_markup New message reply markup
-- @input_message_content New text content of the message. Should be of type InputMessageText
function tdbot.editInlineMessageText(inlinemessageid, replymarkup, inputmessagecontent, callback, data)
  assert (tdbot_function ({
    _ = 'editInlineMessageText',
    inline_message_id = tostring(inlinemessageid),
    reply_markup = replymarkup,
    input_message_content = InputMessageContent
  }, callback or dl_cb, data))
end

-- Bots only.
-- Edits caption of an inline message content sent via bot
-- @inline_message_id Inline message identifier
-- @reply_markup New message reply markup
-- @caption New message content caption, 0-200 characters
function tdbot.editInlineMessageCaption(inlinemessageid, replymarkup, caption, callback, data)
  assert (tdbot_function ({
    _ = 'editInlineMessageCaption',
    inline_message_id = tostring(inlinemessageid),
    reply_markup = replymarkup,
    caption = tostring(caption)
  }, callback or dl_cb, data))
end

-- Bots only.
-- Edits reply markup of an inline message sent via bot
-- @inline_message_id Inline message identifier
-- @reply_markup New message reply markup
function tdbot.editInlineMessageReplyMarkup(inlinemessageid, replymarkup, callback, data)
  assert (tdbot_function ({
    _ = 'editInlineMessageReplyMarkup',
    inline_message_id = tostring(inlinemessageid),
    reply_markup = replymarkup
  }, callback or dl_cb, data))
end

-- Bots only.
-- Sets result of an inline query
-- @inline_query_id Identifier of the inline query
-- @is_personal Does result of the query can be cached only for specified user
-- @results Results of the query
-- @cache_time Allowed time to cache results of the query in seconds
-- @next_offset Offset for the next inline query, pass empty string if there is no more results
-- @switch_pm_text If non-empty, this text should be shown on the button, which opens private chat with the bot and sends bot start message with parameter switch_pm_parameter
-- @switch_pm_parameter Parameter for the bot start message
function tdbot.answerInlineQuery(inlinequeryid, ispersonal, results, cachetime, nextoffset, switchpmtext, switchpmparameter, callback, data)
  assert (tdbot_function ({
    _ = 'answerInlineQuery',
    inline_query_id = inlinequeryid,
    is_personal = ispersonal,
    results = results, -- vector<InputInlineQueryResult>
    cache_time = cachetime,
    next_offset = tostring(nextoffset),
    switch_pm_text = tostring(switchpmtext),
    switch_pm_parameter = tostring(switchpmparameter)
  }, callback or dl_cb, data))
end

-- Sends notification about screenshot taken in a chat.
-- Works only in private and secret chats
-- @chat_id Chat identifier
function tdbot.sendChatScreenshotTakenNotification(chatid, callback, data)
  assert (tdbot_function ({
    _ = 'sendChatScreenshotTakenNotification',
    chat_id = chatid
  }, callback or dl_cb, data))
end

-- Deletes messages
-- @chat_id Chat identifier
-- @message_ids Identifiers of messages to delete
-- @revoke Pass true to try to delete sent messages for all chat members (may fail if messages are too old).
-- Is always true for Channels and SecretChats
function tdbot.deleteMessages(chatid, messageids, revok, callback, data)
  assert (tdbot_function ({
    _ = 'deleteMessages',
    chat_id = chatid,
    message_ids = messageids,
    revoke = revok
  }, callback or dl_cb, data))
end

-- Deletes all messages in the chat sent by the specified user.
-- Works only in supergroup channel chats, needs can_delete_messages administrator privileges
-- @chat_id Chat identifier
-- @user_id User identifier
function tdbot.deleteMessagesFromUser(chatid, userid, callback, data)
  assert (tdbot_function ({
    _ = 'deleteMessagesFromUser',
    chat_id = chatid,
    user_id = userid
  }, callback or dl_cb, data))
end

-- Edits text of text or game message.
-- Non-bots can edit message in a limited period of time.
-- Returns edited message after edit is complete server side
-- @chat_id Chat the message belongs to
-- @message_id Identifier of the message
-- @reply_markup Bots only. New message reply markup
-- @input_message_content New text content of the message. Should be of type InputMessageText
-- @text Text to send
-- @disable_web_page_preview Pass true to disable rich preview for link in the message text
-- @clear_draft Pass true if chat draft message should be deleted
function tdbot.editMessageText(chatid, messageid, replymarkup, teks, disablewebpagepreview, cleardraft, entity, textparsemode, callback, data)
  assert (tdbot_function ({
    _ = 'editMessageText',
    chat_id = chatid,
    message_id = messageid,
    reply_markup = replymarkup,
    input_message_content = {
      _ = 'inputMessageText',
      text = tostring(teks),
      disable_web_page_preview = disablewebpagepreview,
      clear_draft = cleardraft,
      entities = entity, -- vector<textEntity>
      parse_mode = getParseMode(textparsemode)
    },
  }, callback or dl_cb, data))
end

-- Edits message content caption.
-- Non-bots can edit message in a limited period of time.
-- Returns edited message after edit is complete server side
-- @chat_id Chat the message belongs to
-- @message_id Identifier of the message
-- @reply_markup Bots only. New message reply markup
-- @caption New message content caption, 0-200 characters
function tdbot.editMessageCaption(chatid, messageid, replymarkup, capt, callback, data)
  assert (tdbot_function ({
    _ = 'editMessageCaption',
    chat_id = chatid,
    message_id = messageid,
    reply_markup = replymarkup,
    caption = tostring(capt)
  }, callback or dl_cb, data))
end

-- Returns all mentions, hashtags, bot commands, URLs and emails contained in the text.
-- Offline method.
-- Can be called before authorization.
-- Can be called synchronously
-- @text Text to find entites in
function tdbot.getTextEntities(text, callback, data)
  assert (tdbot_function ({
    _ = 'getTextEntities',
    text = tostring(text)
  }, callback or dl_cb, data))
end

-- Returns file's mime type guessing only by its extension.
-- Returns empty string on failure.
-- Offline method.
-- Can be called before authorization.
-- Can be called synchronously
-- @file_name Name of the file or path to the file
function tdbot.getFileMimeType(filename, callback, data)
  assert (tdbot_function ({
    _ = 'getFileMimeType',
    file_name = tostring(filename)
  }, callback or dl_cb, data))
end

-- Returns file's extension guessing only by its mime type.
-- Returns empty string on failure.
-- Offline method.
-- Can be called before authorization.
-- Can be called synchronously
-- @mime_type Mime type of the file
function tdbot.getFileExtension(mimetype, callback, data)
  assert (tdbot_function ({
    _ = 'getFileExtension',
    mime_type = tostring(mimetype)
  }, callback or dl_cb, data))
end

-- Sends inline query to a bot and returns its results.
-- Returns error with code 502 if bot fails to answer the query before query timeout expires.
-- Unavailable for bots
-- @bot_user_id Identifier of the bot send query to
-- @chat_id Identifier of the chat, where the query is sent
-- @user_location User location, only if needed
-- @query Text of the query
-- @offset Offset of the first entry to return
---
-- location on Earth
-- @latitude Latitude of location in degrees as defined by sender
-- @longitude Longitude of location in degrees as defined by sender
function tdbot.getInlineQueryResults(botuserid, chatid, lat, lon, query, off, callback, data)
  assert (tdbot_function ({
    _ = 'getInlineQueryResults',
    bot_user_id = botuserid,
    chat_id = chatid,
    user_location = {
      _ = 'location',
      latitude = lat,
      longitude = lon
    },
    query = tostring(query),
    offset = tostring(off)
  }, callback or dl_cb, data))
end

-- Sends callback query to a bot and returns answer to it.
-- Returns error with code 502 if bot fails to answer the query before query timeout expires.
-- Unavailable for bots
-- @chat_id Identifier of the chat with a message
-- @message_id Identifier of the message, from which the query is originated
-- @payload Query payload
---
-- callbackQueryPayload Represents payload of a callback query
-- @data Data that was attached to the callback button
-- @game_short_name Short name of the game that was attached to the callback button
function tdbot.getCallbackQueryAnswer(chatid, messageid, query_payload, cb_query_payload, callback, data)
  local callback_query_payload = {}

  if query_payload == 'Data' then
    callback_query_payload.data = cb_query_payload
  elseif query_payload == 'Game' then
    callback_query_payload.game_short_name = cb_query_payload
  end

  callback_query_payload._ = 'callbackQueryPayload' .. query_payload,

  assert (tdbot_function ({
    _ = 'getCallbackQueryAnswer',
    chat_id = chatid,
    message_id = messageid,
    payload = callback_query_payload
  }, callback or dl_cb, data))
end

-- Bots only.
-- Sets result of a callback query
-- @callback_query_id Identifier of the callback query
-- @text Text of the answer
-- @show_alert If true, an alert should be shown to the user instead of a toast
-- @url Url to be opened
-- @cache_time Allowed time to cache result of the query in seconds
function tdbot.answerCallbackQuery(callbackqueryid, text, showalert, url, cachetime, callback, data)
  assert (tdbot_function ({
    _ = 'answerCallbackQuery',
    callback_query_id = callbackqueryid,
    text = tostring(text),
    show_alert = showalert,
    url = tostring(url),
    cache_time = cachetime
  }, callback or dl_cb, data))
end

-- Bots only.
-- Sets result of a shipping query
-- @shipping_query_id Identifier of the shipping query
-- @shipping_options Available shipping options
-- @error_message Error message, empty on success
function tdbot.answerShippingQuery(shippingqueryid, shippingoptions, errormessage, callback, data)
  assert (tdbot_function ({
    _ = 'answerShippingQuery',
    shipping_query_id = shippingqueryid,
    shipping_options = shippingoptions, -- vector<shippingOption>
    error_message = tostring(errormessage)
  }, callback or dl_cb, data))
end

-- Bots only.
-- Sets result of a pre checkout query
-- @pre_checkout_query_id Identifier of the pre-checkout query
-- @error_message Error message, empty on success
function tdbot.answerPreCheckoutQuery(precheckoutqueryid, errormessage, callback, data)
  assert (tdbot_function ({
    _ = 'answerPreCheckoutQuery',
    pre_checkout_query_id = precheckoutqueryid,
    error_message = tostring(errormessage)
  }, callback or dl_cb, data))
end

-- Bots only.
-- Updates game score of the specified user in the game
-- @chat_id Chat a message with the game belongs to
-- @message_id Identifier of the message
-- @edit_message True, if message should be edited
-- @user_id User identifier
-- @score New score
-- @force Pass True to update the score even if it decreases.
-- If score is 0, user will be deleted from the high scores table
function tdbot.setGameScore(chatid, messageid, editmessage, userid, score, force, callback, data)
  assert (tdbot_function ({
    _ = 'setGameScore',
    chat_id = chatid,
    message_id = messageid,
    edit_message = editmessage,
    user_id = userid,
    score = score,
    force = force
  }, callback or dl_cb, data))
end

-- Bots only.
-- Updates game score of the specified user in the game
-- @inline_message_id Inline message identifier
-- @edit_message True, if message should be edited
-- @user_id User identifier
-- @score New score
-- @force Pass True to update the score even if it decreases.
-- If score is 0, user will be deleted from the high scores table
function tdbot.setInlineGameScore(inlinemessageid, editmessage, userid, score, force, callback, data)
  assert (tdbot_function ({
    _ = 'setInlineGameScore',
    inline_message_id = tostring(inlinemessageid),
    edit_message = editmessage,
    user_id = userid,
    score = score,
    force = force
  }, callback or dl_cb, data))
end

-- Bots only.
-- Returns game high scores and some part of the score table around of the specified user in the game
-- @chat_id Chat a message with the game belongs to
-- @message_id Identifier of the message
-- @user_id User identifie
function tdbot.getGameHighScores(chatid, messageid, userid, callback, data)
  assert (tdbot_function ({
    _ = 'getGameHighScores',
    chat_id = chatid,
    message_id = messageid,
    user_id = userid
  }, callback or dl_cb, data))
end

-- Bots only.
-- Returns game high scores and some part of the score table around of the specified user in the game
-- @inline_message_id Inline message identifier
-- @user_id User identifier
function tdbot.getInlineGameHighScores(inlinemessageid, userid, callback, data)
  assert (tdbot_function ({
    _ = 'getInlineGameHighScores',
    inline_message_id = tostring(inlinemessageid),
    user_id = userid
  }, callback or dl_cb, data))
end

-- Deletes default reply markup from chat.
-- This method needs to be called after one-time keyboard or ForceReply reply markup has been used.
-- UpdateChatReplyMarkup will be send if reply markup will be changed
-- @chat_id Chat identifier
-- @message_id Message identifier of used keyboard
function tdbot.deleteChatReplyMarkup(chatid, messageid, callback, data)
  assert (tdbot_function ({
    _ = 'deleteChatReplyMarkup',
    chat_id = chatid,
    message_id = messageid
  }, callback or dl_cb, data))
end

-- Sends notification about user activity in a chat
-- @chat_id Chat identifier
-- @action Action description
---
-- chatAction Describes different types of activity in a chat
-- @progress Upload progress in percents
-- chatAction: Typing | RecordingVideo | UploadingVideo | RecordingVoice | UploadingVoice | UploadingPhoto | UploadingDocument | ChoosingLocation | ChoosingContact | StartPlayingGame | RecordingVideoNote | UploadingVideoNote | Cancel
function tdbot.sendChatAction(chatid, act, uploadprogress, callback, data)
  assert (tdbot_function ({
    _ = 'sendChatAction',
    chat_id = chatid,
    action = {
      _ = 'chatAction' .. act,
      progress = uploadprogress
    },
  }, callback or dl_cb, data))
end

-- Chat is opened by the user.
-- Many useful activities depends on chat being opened or closed.
-- For example, in channels all updates are received only for opened chats
-- @chat_id Chat identifier
function tdbot.openChat(chatid, callback, data)
  assert (tdbot_function ({
    _ = 'openChat',
    chat_id = chatid
  }, callback or dl_cb, data))
end

-- Chat is closed by the user.
-- Many useful activities depends on chat being opened or closed.
-- @chat_id Chat identifier
function tdbot.closeChat(chatid, callback, data)
  assert (tdbot_function ({
    _ = 'closeChat',
    chat_id = chatid
  }, callback or dl_cb, data))
end

-- Messages are viewed by the user.
-- Many useful activities depends on message being viewed.
-- For example, marking messages as read, incrementing of view counter, updating of view counter, removing of deleted messages in channels
-- @chat_id Chat identifier
-- @message_ids Identifiers of viewed messages
function tdbot.viewMessages(chatid, messageids, callback, data)
  assert (tdbot_function ({
    _ = 'viewMessages',
    chat_id = chatid,
    message_ids = messageids
  }, callback or dl_cb, data))
end

-- Message content is opened, for example the user has opened a photo, a video, a document, a location or a venue or have listened to an audio or a voice message.
-- You will receive updateOpenMessageContent if something has changed
-- @chat_id Chat identifier of the message
-- @message_id Identifier of the message with opened content
function tdbot.openMessageContent(chatid, messageid, callback, data)
  assert (tdbot_function ({
    _ = 'openMessageContent',
    chat_id = chatid,
    message_id = messageid
  }, callback or dl_cb, data))
end

-- Returns existing chat corresponding to the given user
-- @user_id User identifier
function tdbot.createPrivateChat(userid, callback, data)
  assert (tdbot_function ({
    _ = 'createPrivateChat',
    user_id = userid
  }, callback or dl_cb, data))
end

-- Returns existing chat corresponding to the known group
-- @group_id Group identifier
function tdbot.createGroupChat(groupid, callback, data)
  assert (tdbot_function ({
    _ = 'createGroupChat',
    group_id = getChatId(groupid).id
  }, callback or dl_cb, data))
end

-- Returns existing chat corresponding to the known channel
-- @channel_id Channel identifier
function tdbot.createChannelChat(channelid, callback, data)
  assert (tdbot_function ({
    _ = 'createChannelChat',
    channel_id = getChatId(channelid).id
  }, callback or dl_cb, data))
end

-- Returns existing chat corresponding to the known secret chat
-- @secret_chat_id SecretChat identifier
function tdbot.createSecretChat(secretchatid, callback, data)
  assert (tdbot_function ({
    _ = 'createSecretChat',
    secret_chat_id = secretchatid
  }, callback or dl_cb, data))
end

-- Creates new group chat and send corresponding messageGroupChatCreate, returns created chat
-- @user_ids Identifiers of users to add to the group
-- @title Title of new group chat, 1-255 characters
function tdbot.createNewGroupChat(userids, chattitle, callback, data)
  assert (tdbot_function ({
    _ = 'createNewGroupChat',
    user_ids = userids,
    title = tostring(chattitle)
  }, callback or dl_cb, data))
end

-- Creates new channel chat and send corresponding messageChannelChatCreate, returns created chat
-- @title Title of new channel chat, 1-255 characters
-- @is_supergroup True, if supergroup chat should be created
-- @description Channel description, 0-255 characters
function tdbot.createNewChannelChat(title, issupergroup, channelldescription, callback, data)
  assert (tdbot_function ({
    _ = 'createNewChannelChat',
    title = tostring(title),
    is_supergroup = issupergroup,
    description = tostring(channelldescription)
  }, callback or dl_cb, data))
end

-- Creates new secret chat, returns created chat
-- @user_id Identifier of a user to create secret chat with
function tdbot.createNewSecretChat(userid, callback, data)
  assert (tdbot_function ({
    _ = 'createNewSecretChat',
    user_id = userid
  }, callback or dl_cb, data))
end

-- Creates new channel supergroup chat from existing group chat and send corresponding messageChatMigrateTo and messageChatMigrateFrom.
-- Deactivates group
-- @chat_id Group chat identifier
function tdbot.migrateGroupChatToChannelChat(chatid, callback, data)
  assert (tdbot_function ({
    _ = 'migrateGroupChatToChannelChat',
    chat_id = chatid
  }, callback or dl_cb, data))
end

-- Changes chat title.
-- Works only for group and channel chats.
-- Requires administrator rights in groups and appropriate administrator right in channels.
-- Title will not change before request to the server completes
-- @chat_id Chat identifier
-- @title New title of the chat, 1-255 characters
function tdbot.changeChatTitle(chatid, title, callback, data)
  assert (tdbot_function ({
    _ = 'changeChatTitle',
    chat_id = chatid,
    title = tostring(title)
  }, callback or dl_cb, data))
end

-- Changes chat photo.
-- Works only for group and channel chats.
-- Requires administrator rights in groups and appropriate administrator right in channels.
-- Photo will not change before request to the server completes
-- @chat_id Chat identifier
-- @photo New chat photo.
-- You can use zero InputFileId to delete chat photo.
-- Files accessible only by HTTP URL are not acceptable
function tdbot.changeChatPhoto(chatid, foto, callback, data)
  assert (tdbot_function ({
    _ = 'changeChatPhoto',
    chat_id = chatid,
    photo = getInputFile(foto)
  }, callback or dl_cb, data))
end

-- Changes chat draft message
-- @chat_id Chat identifier
-- @draft_message New draft message, nullable
function tdbot.changeChatDraftMessage(chatid, replytomessageid, teks, disablewebpagepreview, cleardraft, entity, parsemode, callback, data)
  assert (tdbot_function ({
    _ = 'changeChatDraftMessage',
    chat_id = chatid,
    draft_message = {
      _ = 'draftMessage',
      reply_to_message_id = replytomessageid,
      input_message_text = {
        _ = 'inputMessageText',
        text = tostring(teks),
        disable_web_page_preview = disablewebpagepreview,
        clear_draft = cleardraft,
        entities = entity, -- vector<textEntity>
        parse_mode = getParseMode(parsemode)
      },
    },
  }, callback or dl_cb, data))
end

-- Changes chat pinned state.
-- You can pin up to getOption('pinned_chat_count_max') non-secret chats and the same number of secret chats
-- @chat_id Chat identifier
-- @is_pinned New value of is_pinned
function tdbot.toggleChatIsPinned(chatid, ispinned, callback, data)
  assert (tdbot_function ({
    _ = 'toggleChatIsPinned',
    chat_id = chatid,
    is_pinned = ispinned
  }, callback or dl_cb, data))
end

-- Changes client data associated with a chat
-- @chat_id Chat identifier
-- @client_data New value of client_data
function tdbot.setChatClientData(chatid, clientdata, callback, data)
  assert (tdbot_function ({
    _ = 'setChatClientData',
    chat_id = chatid,
    client_data = tostring(clientdata)
  }, callback or dl_cb, data))
end

-- Adds new member to chat.
-- Members can't be added to private or secret chats.
-- Member will not be added until chat state will be synchronized with the server
-- @chat_id Chat identifier
-- @user_id Identifier of the user to add
-- @forward_limit Number of previous messages from chat to forward to new member, ignored for channel chats. Can't be greater than 300
function tdbot.addChatMember(chatid, userid, forwardlimit, callback, data)
  assert (tdbot_function ({
    _ = 'addChatMember',
    chat_id = chatid,
    user_id = userid,
    forward_limit = forwardlimit
  }, callback or dl_cb, data))
end

-- Adds many new members to the chat.
-- Currently, available only for channels.
-- Can't be used to join the channel.
-- Members can't be added to broadcast channel if it has more than 200 members.
-- Members will not be added until chat state will be synchronized with the server
-- @chat_id Chat identifier
-- @user_ids Identifiers of the users to add
function tdbot.addChatMembers(chatid, userids, callback, data)
  assert (tdbot_function ({
    _ = 'addChatMembers',
    chat_id = chatid,
    user_ids = userids,
  }, callback or dl_cb, data))
end

-- Changes status of the chat member, need appropriate privileges.
-- This function is currently not suitable for adding new members to the chat, use addChatMember instead.
-- Status will not be changed until chat state will be synchronized with the server
-- @chat_id Chat identifier
-- @user_id Identifier of the user to edit status
-- @status New status of the member in the chat
-- rank = Creator | Administrator | Member | Restricted | Left | Banned
function tdbot.changeChatMemberStatus(chatid, userid, rank, right, callback, data)
  local chat_member_status = {}

-- User is a chat member with some additional priviledges.
-- In groups, administrators can edit and delete other messages, add new members and ban unpriviledged members
-- @can_be_edited True, if current user has rights to edit administrator privileges of that user
-- @can_change_info True, if the administrator can change chat title, photo and other settings
-- @can_post_messages True, if the administrator can create channel posts, broadcast channels only
-- @can_edit_messages True, if the administrator can edit messages of other users, broadcast channels only
-- @can_delete_messages True, if the administrator can delete messages of other users
-- @can_invite_users True, if the administrator can invite new users to the chat
-- @can_restrict_members True, if the administrator can restrict, ban or unban chat members
-- @can_pin_messages True, if the administrator can pin messages, supergroup channels only
-- @can_promote_members True, if the administrator can add new administrators with a subset of his own privileges or demote administrators directly or indirectly promoted by him
  if rank == 'Administrator' then
    chat_member_status = {
      can_be_edited = right[1] or 1,
      can_change_info = right[2] or 1,
      can_post_messages = right[3] or 1,
      can_edit_messages = right[4] or 1,
      can_delete_messages = right[5] or 1,
      can_invite_users = right[6] or 1,
      can_restrict_members = right[7] or 1,
      can_pin_messages = right[8] or 1,
      can_promote_members = right[9] or 1
    }
-- User has some additional restrictions in the chat.
-- Unsupported in group chats and broadcast channels
-- @is_member True, if user is chat member
-- @restricted_until_date Date when the user will be unrestricted, 0 if never. Unix time.
-- If user is restricted for more than 366 days or less than 30 seconds from the current time it considered to be restricted forever
-- @can_send_messages True, if the user can send text messages, contacts, locations and venues
-- @can_send_media_messages True, if the user can send audios, documents, photos, videos, video notes and voice notes, implies can_send_messages
-- @can_send_other_messages True, if the user can send animations, games, stickers and use inline bots, implies can_send_media_messages
-- @can_add_web_page_previews True, if user may add web page preview to his messages, implies can_send_messages
  elseif rank == 'Restricted' then
    chat_member_status = {
      is_member = right[1] or 1,
      restricted_until_date = right[2] or 0,
      can_send_messages = right[3] or 1,
      can_send_media_messages = right[4] or 1,
      can_send_other_messages = right[5] or 1,
      can_add_web_page_previews = right[6] or 1
    }
-- User was banned (and obviously is not a chat member) and can't return to the chat or view messages
-- @banned_until_date Date when the user will be unbanned, 0 if never. Unix time.
-- If user is banned for more than 366 days or less than 30 seconds from the current time it considered to be banned forever
  elseif rank == 'Banned' then
    chat_member_status = {
      banned_until_date = right[1] or 0
    }
  end

  chat_member_status._ = 'chatMemberStatus' .. rank

  assert (tdbot_function ({
    _ = 'changeChatMemberStatus',
    chat_id = chatid,
    user_id = userid,
    status = chat_member_status
  }, callback or dl_cb, data))
end

-- Returns information about one participant of the chat
-- @chat_id Chat identifier
-- @user_id User identifier
function tdbot.getChatMember(chatid, userid, callback, data)
  assert (tdbot_function ({
    _ = 'getChatMember',
    chat_id = chatid,
    user_id = userid
  }, callback or dl_cb, data))
end

-- Searches for the specified query in the first name, last name and username among members of the specified chat.
-- Requires administrator rights in broadcast channels
-- @chat_id Chat identifier
-- @query Query to search for
-- @limit Maximum number of users to be returned
function tdbot.searchChatMembers(chatid, query, lim, callback, data)
  assert (tdbot_function ({
    _ = 'searchChatMembers',
    chat_id = chatid,
    query = tostring(query),
    limit = lim
  }, callback or dl_cb, data))
end

-- Changes list or order of pinned chats
-- @chat_ids New list of pinned chats
function tdbot.setPinnedChats(chatids, callback, data)
  assert (tdbot_function ({
    _ = 'setPinnedChats',
    chat_ids = chatids
  }, callback or dl_cb, data))
end

-- Asynchronously downloads file from cloud.
-- Updates updateFile will notify about download progress and successful download
-- @file_id Identifier of file to download
-- @priority Priority of download, 1-32. The higher priority, the earlier file will be downloaded.
-- If priorities of two files are equal then the last one for which downloadFile is called will be downloaded first
function tdbot.downloadFile(fileid, priorities, callback, data)
  assert (tdbot_function ({
    _ = 'downloadFile',
    file_id = fileid,
    priority = priorities
  }, callback or dl_cb, data))
end

-- Stops file downloading.
-- If file is already downloaded, does nothing
-- @file_id Identifier of file to cancel download
function tdbot.cancelDownloadFile(fileid, callback, data)
  assert (tdbot_function ({
    _ = 'cancelDownloadFile',
    file_id = fileid
  }, callback or dl_cb, data))
end

-- Asynchronously uploads file to the cloud without sending it in a message.
-- Updates updateFile will notify about upload progress and successful upload.
-- The file will not have persistent identifier until it will be sent in a message
-- @file File to upload
-- @file_type File type
-- @priority Priority of upload, 1-32. The higher priority, the earlier file will be uploaded.
-- If priorities of two files are equal then the first one for which uploadFile is called will be uploaded first
---
-- fileType Represents type of a file
-- fileType: None | Animation | Audio | Document | Photo | ProfilePhoto | Secret | Sticker | Thumb | Unknown | Video | VideoNote | Voice | Wallpaper | SecretThumb
function tdbot.uploadFile(filetoupload, filetype, prior, callback, data)
  assert (tdbot_function ({
    _ = 'uploadFile',
    file = getInputFile(filetoupload),
    file_type = {
      _ = 'fileType' .. filetype,
    },
    priority = prior
  }, callback or dl_cb, data))
end

-- Stops file uploading.
-- Works only for files uploaded using uploadFile.
-- For other files the behavior is undefined
-- @file_id Identifier of file to cancel upload
function tdbot.cancelUploadFile(fileid, callback, data)
  assert (tdbot_function ({
    _ = 'cancelUploadFile',
    file_id = fileid
  }, callback or dl_cb, data))
end

-- Next part of a file was generated
-- @generation_id Identifier of the generation process
-- @size Full size of file in bytes, 0 if unknown.
-- @local_size Number of bytes already generated. Negative number means that generation has failed and should be terminated
function tdbot.setFileGenerationProgress(generationid, size, localsize, callback, data)
  assert (tdbot_function ({
    _ = 'setFileGenerationProgress',
    generation_id = generationid,
    size = size,
    local_size = localsize
  }, callback or dl_cb, data))
end

-- Finishes file generation
-- @generation_id Identifier of the generation process
function tdbot.finishFileGeneration(generationid, callback, data)
  assert (tdbot_function ({
    _ = 'finishFileGeneration',
    generation_id = generationid
  }, callback or dl_cb, data))
end

-- Deletes a file from TDLib file cache
-- @file_id Identifier of the file to delete
function tdbot.deleteFile(fileid, callback, data)
  assert (tdbot_function ({
    _ = 'deleteFile',
    file_id = fileid
  }, callback or dl_cb, data))
end

-- Generates new chat invite link, previously generated link is revoked.
-- Available for group and channel chats.
-- In groups can be called only by creator, in channels requires appropriate rights
-- @chat_id Chat identifier
function tdbot.exportChatInviteLink(chatid, callback, data)
  assert (tdbot_function ({
    _ = 'exportChatInviteLink',
    chat_id = chatid
  }, callback or dl_cb, data))
end

-- Checks chat invite link for validness and returns information about the corresponding chat
-- @invite_link Invite link to check.
-- Should begin with 'https://t.me/joinchat/', 'https://telegram.me/joinchat/' or 'https://telegram.dog/joinchat/'
function tdbot.checkChatInviteLink(invitelink, callback, data)
  assert (tdbot_function ({
    _ = 'checkChatInviteLink',
    invite_link = tostring(invitelink)
  }, callback or dl_cb, data))
end

-- Imports chat invite link, adds current user to a chat if possible.
-- Member will not be added until chat state will be synchronized with the server
-- @invite_link Invite link to import. Should begin with "https://t.me/joinchat/", "https://telegram.me/joinchat/" or "https://telegram.dog/joinchat/"
function tdbot.importChatInviteLink(invitelink, callback, data)
  assert (tdbot_function ({
    _ = 'importChatInviteLink',
    invite_link = tostring(invitelink)
  }, callback or dl_cb, data))
end

-- Creates new call
-- @user_id Identifier of user to call
-- @protocol Description of supported by the client call protocols
---
-- callProtocol Specifies supported call protocols
-- @udp_p2p True, if UDP peer to peer connections are supported
-- @udp_reflector True, if connection through UDP reflectors are supported
-- @min_layer Minimum supported layer, use 65
-- @max_layer Maximum supported layer, use 65
function tdbot.createCall(userid, udpp2p, udpreflector, minlayer, maxlayer, callback, data)
  assert (tdbot_function ({
    _ = 'createCall',
    user_id = userid,
    protocol = {
      _ = 'callProtocol',
      udp_p2p = udpp2p,
      udp_reflector = udpreflector,
      min_layer = minlayer,
      max_layer = maxlayer or 65
    },
  }, callback or dl_cb, data))
end

-- Accepts incoming call
-- @call_id Call identifier
-- @protocol Specifies supported call protocols
-- @udp_p2p True, if UDP peer to peer connections are supported
-- @udp_reflector True, if connection through UDP reflectors are supported
-- @min_layer Minimum supported layer, use 65
-- @max_layer Maximum supported layer, use 65
function tdbot.acceptCall(callid, udpp2p, udpreflector, minlayer, maxlayer, callback, data)
  assert (tdbot_function ({
    _ = 'acceptCall',
    call_id = callid,
    protocol = {
      _ = 'callProtocol',
      udp_p2p = udpp2p,
      udp_reflector = udpreflector,
      min_layer = minlayer,
      max_layer = maxlayer
    },
  }, callback or dl_cb, data))
end

-- Discards a call
-- @call_id Call identifier
-- @is_disconnected True, if users was disconnected
-- @duration Call duration in seconds
-- @connection_id Identifier of a connection used during the call
function tdbot.discardCall(callid, isdisconnected, callduration, connectionid, callback, data)
  assert (tdbot_function ({
    _ = 'discardCall',
    call_id = callid,
    is_disconnected = isdisconnected,
    duration = callduration,
    connection_id = connectionid
  }, callback or dl_cb, data))
end

-- Sends call rating
-- @call_id Call identifier
-- @rating Call rating, 1-5
-- @comment Optional user comment if rating is less than 5
function tdbot.rateCall(callid, rating, usercomment, callback, data)
  assert (tdbot_function ({
    _ = 'rateCall',
    call_id = callid,
    rating = rating,
    comment = tostring(usercomment)
  }, callback or dl_cb, data))
end

-- Sends call debug information
-- @call_id Call identifier
-- @debug Debug information in application specific format
function tdbot.debugCall(callid, debg, callback, data)
  assert (tdbot_function ({
    _ = 'debugCall',
    call_id = callid,
    debug = tostring(debg)
  }, callback or dl_cb, data))
end

-- Adds user to black list
-- @user_id User identifier
function tdbot.blockUser(userid, callback, data)
  assert (tdbot_function ({
    _ = 'blockUser',
    user_id = userid
  }, callback or dl_cb, data))
end

-- Removes user from black list
-- @user_id User identifier
function tdbot.unblockUser(userid, callback, data)
  assert (tdbot_function ({
    _ = 'unblockUser',
    user_id = userid
  }, callback or dl_cb, data))
end

-- Returns users blocked by the current user
-- @offset Number of users to skip in result, must be non-negative
-- @limit Maximum number of users to return, can't be greater than 100
function tdbot.getBlockedUsers(off, lim, callback, data)
  assert (tdbot_function ({
    _ = 'getBlockedUsers',
    offset = off,
    limit = lim
  }, callback or dl_cb, data))
end

-- Adds new contacts/edits existing contacts, contacts user identifiers are ignored
-- @contacts List of contacts to import/edit
-- @phone_number User's phone number
-- @first_name User first name, 1-255 characters
-- @last_name User last name
-- @user_id User identifier if known, 0 otherwise
function tdbot.importContacts(phonenumber, firstname, lastname, userid, callback, data)
  assert (tdbot_function ({
    _ = 'importContacts',
    contacts = {
      [0] = {
        _ = 'contact',
        phone_number_ = tostring(phonenumber),
        first_name_ = tostring(firstname),
        last_name_ = tostring(lastname),
        user_id_ = userid
      }
    },
  }, callback or dl_cb, data))
end

-- Searches for specified query in the first name, last name and username of the known user contacts
-- @query Query to search for, can be empty to return all contacts
-- @limit Maximum number of users to be returned
function tdbot.searchContacts(que, lim, callback, data)
  assert (tdbot_function ({
    _ = 'searchContacts',
    query = tostring(que),
    limit = lim
  }, callback or dl_cb, data))
end

-- Deletes users from contacts list
-- @user_ids Identifiers of users to be deleted
function tdbot.deleteContacts(userids, callback, data)
  assert (tdbot_function ({
    _ = 'deleteContacts',
    user_ids = userids,
  }, callback or dl_cb, data))
end

-- Returns total number of imported contacts
function tdbot.getImportedContactCount(callback, data)
  assert (tdbot_function ({
    _ = 'getImportedContactCount'
  }, callback or dl_cb, data))
end

-- Deletes all imported contacts
function tdbot.deleteImportedContacts(callback, data)
  assert (tdbot_function ({
    _ = 'deleteImportedContacts'
  }, callback or dl_cb, data))
end

-- Returns profile photos of the user.
-- Result of this query may be outdated: some photos may be already deleted
-- @user_id User identifier
-- @offset Photos to skip, must be non-negative
-- @limit Maximum number of photos to be returned, can't be greater than 100
function tdbot.getUserProfilePhotos(userid, off, lim, callback, data)
  assert (tdbot_function ({
    _ = 'getUserProfilePhotos',
    user_id = userid,
    offset = off,
    limit = lim
  }, callback or dl_cb, data))
end

-- Returns stickers from installed ordinary sticker sets corresponding to the given emoji.
-- If emoji is not empty, elso favorite and recently used stickers may be returned
-- @emoji String representation of emoji. If empty, returns all known stickers
-- @limit Maximum number of stickers to return
function tdbot.getStickers(emo, lim, callback, data)
  assert (tdbot_function ({
    _ = 'getStickers',
    emoji = tostring(emo),
    limit = lim
  }, callback or dl_cb, data))
end

-- Returns list of installed sticker sets
-- @is_masks Pass true to return mask sticker sets, pass false to return ordinary sticker sets
function tdbot.getInstalledStickerSets(ismasks, callback, data)
  assert (tdbot_function ({
    _ = 'getInstalledStickerSets',
    is_masks = ismasks
  }, callback or dl_cb, data))
end

-- Returns list of archived sticker sets
-- @is_masks Pass true to return mask stickers sets, pass false to return ordinary sticker sets
-- @offset_sticker_set_id Identifier of the sticker set from which return the result
-- @limit Maximum number of sticker sets to return
function tdbot.getArchivedStickerSets(ismasks, offsetstickersetid, lim, callback, data)
  assert (tdbot_function ({
    _ = 'getArchivedStickerSets',
    is_masks = ismasks,
    offset_sticker_set_id = offsetstickersetid,
    limit = lim
  }, callback or dl_cb, data))
end

-- Returns list of trending sticker sets
function tdbot.getTrendingStickerSets(callback, data)
  assert (tdbot_function ({
    _ = 'getTrendingStickerSets'
  }, callback or dl_cb, data))
end

-- Returns list of sticker sets attached to a file, currently only photos and videos can have attached sticker sets
-- @file_id File identifier
function tdbot.getAttachedStickerSets(fileid, callback, data)
  assert (tdbot_function ({
    _ = 'getAttachedStickerSets',
    file_id = fileid
  }, callback or dl_cb, data))
end

-- Returns information about sticker set by its identifier
-- @set_id Identifier of the sticker set
function tdbot.getStickerSet(setid, callback, data)
  assert (tdbot_function ({
    _ = 'getStickerSet',
    set_id = setid
  }, callback or dl_cb, data))
end

-- Searches sticker set by its short name
-- @name Name of the sticker set
function tdbot.searchStickerSet(sticker_name, callback, data)
  assert (tdbot_function ({
    _ = 'searchStickerSet',
    name = tostring(sticker_name)
  }, callback or dl_cb, data))
end

-- Installs/uninstalls or enables/archives sticker set
-- @set_id Identifier of the sticker set
-- @is_installed New value of is_installed
-- @is_archived New value of is_archived.
-- A sticker set can't be installed and archived simultaneously
function tdbot.changeStickerSet(setid, isinstalled, isarchived, callback, data)
  assert (tdbot_function ({
    _ = 'changeStickerSet',
    set_id = setid,
    is_installed = isinstalled,
    is_archived = isarchived
  }, callback or dl_cb, data))
end

-- Informs that some trending sticker sets are viewed by the user
-- @sticker_set_ids Identifiers of viewed trending sticker sets
function tdbot.viewTrendingStickerSets(stickersetids, callback, data)
  assert (tdbot_function ({
    _ = 'viewTrendingStickerSets',
    sticker_set_ids = stickersetids
  }, callback or dl_cb, data))
end

-- Changes the order of installed sticker sets
-- @is_masks Pass true to change mask sticker sets order, pass false to change ordinary sticker sets order
-- @sticker_set_ids Identifiers of installed sticker sets in the new right order
function tdbot.reorderInstalledStickerSets(ismasks, stickersetids, callback, data)
  assert (tdbot_function ({
    _ = 'reorderInstalledStickerSets',
    is_masks = ismasks,
    sticker_set_ids = stickersetids
  }, callback or dl_cb, data))
end

-- Returns list of recently used stickers
-- @is_attached Pass true to return stickers and masks recently attached to photo or video files, pass false to return recently sent stickers
function tdbot.getRecentStickers(isattached, callback, data)
  assert (tdbot_function ({
    _ = 'getRecentStickers',
    is_attached = isattached
  }, callback or dl_cb, data))
end

-- Manually adds new sticker to the list of recently used stickers.
-- New sticker is added to the beginning of the list.
-- If the sticker is already in the list, at first it is removed from the list.
-- Only stickers belonging to a sticker set can be added to the list
-- @is_attached Pass true to add the sticker to the list of stickers recently attached to photo or video files, pass false to add the sticker to the list of recently sent stickers
-- @sticker Sticker file to add
function tdbot.addRecentSticker(isattached, sticker_path, callback, data)
  assert (tdbot_function ({
    _ = 'addRecentSticker',
    is_attached = isattached,
    sticker = getInputFile(sticker_path)
  }, callback or dl_cb, data))
end

-- Removes a sticker from the list of recently used stickers
-- @is_attached Pass true to remove the sticker from the list of stickers recently attached to photo or video files, pass false to remove the sticker from the list of recently sent stickers
-- @sticker Sticker file to delete
function tdbot.deleteRecentSticker(isattached, sticker_path, callback, data)
  assert (tdbot_function ({
    _ = 'deleteRecentSticker',
    is_attached = isattached,
    sticker = getInputFile(sticker_path)
  }, callback or dl_cb, data))
end

-- Clears list of recently used stickers
-- @is_attached Pass true to clear list of stickers recently attached to photo or video files, pass false to clear the list of recently sent stickers
function tdbot.clearRecentStickers(isattached, callback, data)
  assert (tdbot_function ({
    _ = 'clearRecentStickers',
    is_attached = isattached
  }, callback or dl_cb, data))
end

-- Returns favorite stickers
function tdbot.getFavoriteStickers(callback, data)
  assert (tdbot_function ({
    _ = 'getFavoriteStickers'
  }, callback or dl_cb, data))
end

-- Adds new sticker to the list of favorite stickers. New sticker is added to the beginning of the list. If the sticker is already in the list, at first it is removed from the list. Only stickers belonging to a sticker set can be added to the list
-- @sticker Sticker file to add
function tdbot.addFavoriteSticker(sticker_file, callback, data)
  assert (tdbot_function ({
    _ = 'addFavoriteSticker',
    sticker = getInputFile(sticker_file)
  }, callback or dl_cb, data))
end

-- Removes a sticker from the list of favorite stickers
-- @sticker Sticker file to delete from the list
function tdbot.deleteFavoriteSticker(sticker_file, callback, data)
  assert (tdbot_function ({
    _ = 'deleteFavoriteSticker',
    sticker = getInputFile(sticker_file)
  }, callback or dl_cb, data))
end

-- Returns emojis corresponding to a sticker
-- @sticker Sticker file identifier
function tdbot.getStickerEmojis(sticker_path, callback, data)
  assert (tdbot_function ({
    _ = 'getStickerEmojis',
    sticker = getInputFile(sticker_path)
  }, callback or dl_cb, data))
end

-- Returns saved animations
function tdbot.getSavedAnimations(callback, data)
  assert (tdbot_function ({
    _ = 'getSavedAnimations'
  }, callback or dl_cb, data))
end

-- Manually adds new animation to the list of saved animations.
-- New animation is added to the beginning of the list.
-- If the animation is already in the list, at first it is removed from the list.
-- Only non-secret video animations with MIME type 'video/mp4' can be added to the list
-- @animation Animation file to add. Only known to server animations (i.e. successfully sent via message) can be added to the list
function tdbot.addSavedAnimation(animation_path, callback, data)
  assert (tdbot_function ({
    _ = 'addSavedAnimation',
    animation = getInputFile(animation_path)
  }, callback or dl_cb, data))
end

-- Removes an animation from the list of saved animations
-- @animation Animation file to delete
function tdbot.deleteSavedAnimation(animation_path, callback, data)
  assert (tdbot_function ({
    _ = 'deleteSavedAnimation',
    animation = getInputFile(animation_path)
  }, callback or dl_cb, data))
end

-- Returns up to 20 recently used inline bots in the order of the last usage
function tdbot.getRecentInlineBots(callback, data)
  assert (tdbot_function ({
    _ = 'getRecentInlineBots'
  }, callback or dl_cb, data))
end

-- Searches for recently used hashtags by their prefix
-- @prefix Hashtag prefix to search for
-- @limit Maximum number of hashtags to return
function tdbot.searchHashtags(prefix, lim, callback, data)
  assert (tdbot_function ({
    _ = 'searchHashtags',
    prefix = tostring(prefix),
    limit = lim
  }, callback or dl_cb, data))
end

-- Deletes a hashtag from the list of recently used hashtags
-- @hashtag The hashtag to delete
function tdbot.deleteRecentHashtag(hash, callback, data)
  assert (tdbot_function ({
    _ = 'deleteRecentHashtag',
    hashtag = tostring(hash)
  }, callback or dl_cb, data))
end

-- Returns web page preview by text of the message.
-- Do not call this function to often.
-- Returns error 404 if web page has no preview
-- @message_text Message text
function tdbot.getWebPagePreview(messagetext, callback, data)
  assert (tdbot_function ({
    _ = 'getWebPagePreview',
    message_text = tostring(messagetext)
  }, callback or dl_cb, data))
end

-- Returns web page instant view if available.
-- Returns error 404 if web page has no instant view
-- @url Web page URL
-- @force_full If true, full web page instant view will be returned
function tdbot.getWebPageInstantView(uri, forcefull, callback, data)
  assert (tdbot_function ({
    _ = 'getWebPageInstantView',
    url = tostring(uri),
    force_full = forcefull
  }, callback or dl_cb, data))
end

-- Returns notification settings for a given scope
-- @scope Scope to return information about notification settings
---
-- NotificationSettingsScope @description Describes kinds of chat for which notification settings are applied
-- @chat_id Chat identifier
-- notificationSettingsScope: Chat | PrivateChats | GroupChats | AllChats
function tdbot.getNotificationSettings(scop, chatid, callback, data)
  assert (tdbot_function ({
    _ = 'getNotificationSettings',
    scope = {
      _ = 'notificationSettingsScope' .. scop,
      chat_id = chatid
    },
  }, callback or dl_cb, data))
end

-- Changes notification settings for a given scope
-- @scope Scope to change notification settings
-- @notification_settings New notification settings for given scope
-- @mute_for Time left before notifications will be unmuted, seconds
-- @sound Audio file name for notifications, iPhone apps only
-- @show_preview Display message text/media in notification
function tdbot.setNotificationSettings(scop, chatid, mutefor, isound, showpreview, callback, data)
  assert (tdbot_function ({
    _ = 'setNotificationSettings',
    scope = {
      _ = 'notificationSettingsScope' .. scop,
      chat_id = chatid
    },
    notification_settings = {
      _ = 'notificationSettings',
      mute_for = mutefor,
      sound = tostring(isound),
      show_preview = showpreview
    },
  }, callback or dl_cb, data))
end

-- Resets all notification settings to the default value.
-- By default the only muted chats are supergroups, sound is set to 'default' and message previews are showed
function tdbot.resetAllNotificationSettings(callback, data)
  assert (tdbot_function ({
    _ = 'resetAllNotificationSettings'
  }, callback or dl_cb, data))
end

-- Uploads new profile photo for logged in user.
-- If something changes, updateUser will be sent
-- @photo Profile photo to set. inputFileId and inputFilePersistentId may be unsupported
function tdbot.setProfilePhoto(photo_path, callback, data)
  assert (tdbot_function ({
    _ = 'setProfilePhoto',
    photo = getInputFile(photo_path)
  }, callback or dl_cb, data))
end

-- Deletes profile photo.
-- If something changes, updateUser will be sent
-- @profile_photo_id Identifier of profile photo to delete
function tdbot.deleteProfilePhoto(profilephotoid, callback, data)
  assert (tdbot_function ({
    _ = 'deleteProfilePhoto',
    profile_photo_id = profilephotoid
  }, callback or dl_cb, data))
end

-- Changes first and last names of logged in user.
-- If something changes, updateUser will be sent
-- @first_name New value of user first name, 1-255 characters
-- @last_name New value of optional user last name, 0-255 characters
function tdbot.changeName(firstname, lastname, callback, data)
  assert (tdbot_function ({
    _ = 'changeName',
    first_name = tostring(firstname),
    last_name = tostring(lastname)
  }, callback or dl_cb, data))
end

-- Changes about information of logged in user
-- @about New value of userFull.about, 0-70 characters without line feeds
function tdbot.changeAbout(abo, callback, data)
  assert (tdbot_function ({
    _ = 'changeAbout',
    about = tostring(abo)
  }, callback or dl_cb, data))
end

-- Changes username of logged in user.
-- If something changes, updateUser will be sent
-- @username New value of username. Use empty string to remove username
function tdbot.changeUsername(uname, callback, data)
  assert (tdbot_function ({
    _ = 'changeUsername',
    username = tostring(uname)
  }, callback or dl_cb, data))
end

-- Changes user's phone number and sends authentication code to the new user's phone number.
-- Returns authStateWaitCode with information about sent code on success
-- @phone_number New user's phone number in any reasonable format
-- @allow_flash_call Pass True, if code can be sent via flash call to the specified phone number
-- @is_current_phone_number Pass true, if the phone number is used on the current device. Ignored if allow_flash_call is False
function tdbot.changePhoneNumber(phonenumber, allowflashcall, iscurrentphonenumber, callback, data)
  assert (tdbot_function ({
    _ = 'changePhoneNumber',
    phone_number = tostring(phonenumber),
    allow_flash_call = allowflashcall,
    is_current_phone_number = iscurrentphonenumber
  }, callback or dl_cb, data))
end

-- Resends authentication code sent to change user's phone number.
-- Wotks only if in previously received authStateWaitCode next_code_type was not null.
-- Returns authStateWaitCode on success
function tdbot.resendChangePhoneNumberCode(callback, data)
  assert (tdbot_function ({
    _ = 'resendChangePhoneNumberCode'
  }, callback or dl_cb, data))
end

-- Checks authentication code sent to change user's phone number.
-- Returns authStateOk on success
-- @code Verification code from SMS, phone call or flash call
function tdbot.checkChangePhoneNumberCode(cod, callback, data)
  assert (tdbot_function ({
    _ = 'checkChangePhoneNumberCode',
    code = tostring(cod)
  }, callback or dl_cb, data))
end

-- Returns all active sessions of logged in user
function tdbot.getActiveSessions(callback, data)
  assert (tdbot_function ({
    _ = 'getActiveSessions'
  }, callback or dl_cb, data))
end

-- Terminates another session of logged in user
-- @session_id Session identifier
function tdbot.terminateSession(sessionid, callback, data)
  assert (tdbot_function ({
    _ = 'terminateSession',
    session_id = sessionid
  }, callback or dl_cb, data))
end

-- Terminates all other sessions of logged in user
function tdbot.terminateAllOtherSessions(callback, data)
  assert (tdbot_function ({
    _ = 'terminateAllOtherSessions'
  }, callback or dl_cb, data))
end

-- Gives or revokes all members of the group administrator rights.
-- Needs creator privileges in the group
-- @group_id Identifier of the group
-- @everyone_is_administrator New value of everyone_is_administrator
function tdbot.toggleGroupAdministrators(groupid, everyoneisadministrator, callback, data)
  assert (tdbot_function ({
    _ = 'toggleGroupAdministrators',
    group_id = getChatId(groupid).id,
    everyone_is_administrator = everyoneisadministrator
  }, callback or dl_cb, data))
end

-- Changes username of the channel.
-- Needs creator privileges in the channel
-- @channel_id Identifier of the channel
-- @username New value of username. Use empty string to remove username
function tdbot.changeChannelUsername(channelid, uname, callback, data)
  assert (tdbot_function ({
    _ = 'changeChannelUsername',
    channel_id = getChatId(channelid).id,
    username = tostring(uname)
  }, callback or dl_cb, data))
end

-- Changes sticker set of the channel.
-- Needs appropriate rights in the channel
-- @channel_id Identifier of the channel
-- @sticker_set_id New value of channel sticker set identifier. Use 0 to remove channel sticker set
function tdbot.setChannelStickerSet(channelid, stickersetid, callback, data)
  assert (tdbot_function ({
    _ = 'setChannelStickerSet',
    channel_id = getChatId(channelid).id,
    sticker_set_id = stickersetid
  }, callback or dl_cb, data))
end

-- Gives or revokes right to invite new members to all current members of the channel.
-- Needs appropriate rights in the channel.
-- Available only for supergroups
-- @channel_id Identifier of the channel
-- @anyone_can_invite New value of anyone_can_invite
function tdbot.toggleChannelInvites(channelid, anyonecaninvite, callback, data)
  assert (tdbot_function ({
    _ = 'toggleChannelInvites',
    channel_id = getChatId(channelid).id,
    anyone_can_invite = anyonecaninvite
  }, callback or dl_cb, data))
end

-- Enables or disables sender signature on sent messages in the channel.
-- Needs appropriate rights in the channel.
-- Not available for supergroups
-- @channel_id Identifier of the channel
-- @sign_messages New value of sign_messages
function tdbot.toggleChannelSignMessages(channelid, signmessages, callback, data)
  assert (tdbot_function ({
    _ = 'toggleChannelSignMessages',
    channel_id = getChatId(channelid).id,
    sign_messages = signmessages
  }, callback or dl_cb, data))
end

-- Changes information about the channel.
-- Needs appropriate rights in the channel
-- @channel_id Identifier of the channel
-- @description New channel description, 0-255 characters
function tdbot.changeChannelDescription(channelid, descript, callback, data)
  assert (tdbot_function ({
    _ = 'changeChannelDescription',
    channel_id = getChatId(channelid).id,
    description = tostring(descript)
  }, callback or dl_cb, data))
end

-- Pins a message in a supergroup channel chat.
-- Needs appropriate rights in the channel
-- @channel_id Identifier of the channel
-- @message_id Identifier of the new pinned message
-- @disable_notification True, if there should be no notification about the pinned message
function tdbot.pinChannelMessage(channelid, messageid, disablenotification, callback, data)
  assert (tdbot_function ({
    _ = 'pinChannelMessage',
    channel_id = getChatId(channelid).id,
    message_id = messageid,
    disable_notification = disablenotification
  }, callback or dl_cb, data))
end

-- Removes pinned message in the supergroup channel.
-- Needs appropriate rights in the channel
-- @channel_id Identifier of the channel
function tdbot.unpinChannelMessage(channelid, callback, data)
  assert (tdbot_function ({
    _ = 'unpinChannelMessage',
    channel_id = getChatId(channelid).id
  }, callback or dl_cb, data))
end

-- Reports some supergroup channel messages from a user as spam messages
-- @channel_id Channel identifier
-- @user_id User identifier
-- @message_ids Identifiers of messages sent in the supergroup by the user, the list should be non-empty
function tdbot.reportChannelSpam(channelid, userid, messageids, callback, data)
  assert (tdbot_function ({
    _ = 'reportChannelSpam',
    channel_id = getChatId(channelid).id,
    user_id = userid,
    message_ids = messageids
  }, callback or dl_cb, data))
end

-- Returns information about channel members or banned users.
-- Can be used only if channel_full->can_get_members == true.
-- Administrator privileges may be additionally needed for some filters
-- @channel_id Identifier of the channel
-- @filter Kind of channel users to return, defaults to channelMembersRecent
-- @offset Number of channel users to skip
-- @limit Maximum number of users be returned, can't be greater than 200
---
-- channelMembersFilter Specifies kind of chat users to return in getChannelMembers
-- @query Query to search for
-- channelMembersFilter: Recent | Administrators | Search | Restricted | Banned | Bots
function tdbot.getChannelMembers(channelid, off, lim, mbrfilter, searchquery, callback, data)
  local lim = lim or 200
  lim = lim > 200 and 200 or lim

  assert (tdbot_function ({
    _ = 'getChannelMembers',
    channel_id = getChatId(channelid).id,
    filter = {
      _ = 'channelMembersFilter' .. mbrfilter,
      query = tostring(searchquery)
    },
    offset = off,
    limit = lim
  }, callback or dl_cb, data))
end

-- Deletes channel along with all messages in corresponding chat.
-- Releases channel username and removes all members.
-- Needs creator privileges in the channel.
-- Channels with more than 1000 members can't be deleted
-- @channel_id Identifier of the channel
function tdbot.deleteChannel(channelid, callback, data)
  assert (tdbot_function ({
    _ = 'deleteChannel',
    channel_id = getChatId(channelid).id
  }, callback or dl_cb, data))
end

-- Closes secret chat, effectively transfering its state to 'Closed'
-- @secret_chat_id Secret chat identifier
function tdbot.closeSecretChat(secretchatid, callback, data)
  assert (tdbot_function ({
    _ = 'closeSecretChat',
    secret_chat_id = secretchatid
  }, callback or dl_cb, data))
end

-- Returns list of service actions taken by chat members and administrators in the last 48 hours, available only in channels.
-- Requires administrator rights.
-- Returns result in reverse chronological order, i.e. in order of decreasing event_id
-- @chat_id Chat identifier
-- @query Search query to filter events
-- @from_event_id Identifier of an event from which to return result, you can use 0 to get results from the latest events
-- @limit Maximum number of events to return, can't be greater than 100
-- @filters Types of events to return, defaults to all
-- @user_ids User identifiers, which events to return, defaults to all users
---
-- chatEventLogFilters Represents a set of filters used to obtain a chat event log
-- @message_edits True, if message edits should be returned
-- @message_deletions True, if message deletions should be returned
-- @message_pins True, if message pins should be returned
-- @member_joins True, if chat member joins should be returned
-- @member_leaves True, if chat member leaves should be returned
-- @member_invites True, if chat member invites should be returned
-- @member_promotions True, if chat member promotions/demotions should be returned
-- @member_restrictions True, if chat member restrictions/unrestrictions including bans/unbans should be returned
-- @info_changes True, if changes of chat information should be returned
-- @setting_changes True, if changes of chat settings should be returned
function tdbot.getChatEventLog(chatid, searchquery, fromeventid, lim, userids, msgedits, msgdeletions, msgpins, mbrjoins, mbrleaves, mbrinvites, mbrpromotions, mbrrestrictions, infochanges, settingchanges, callback, data)
  assert (tdbot_function ({
    _ = 'getChatEventLog',
    chat_id = chatid,
    query = tostring(searchquery),
    from_event_id = fromeventid,
    limit = lim,
    filters = {
      _ = 'chatEventLogFilters',
      message_edits = msgedits or 1,
      message_deletions = msgdeletions or 1,
      message_pins = msgpins or 1,
      member_joins = mbrjoins or 1,
      member_leaves = mbrleaves or 1,
      member_invites = mbrinvites or 1,
      member_promotions = mbrpromotions or 1,
      member_restrictions = mbrrestrictions or 1,
      info_changes = infochanges or 1,
      setting_changes = settingchanges or 1
    },
    user_ids = userids
  }, callback or dl_cb, data))
end

-- Returns invoice payment form.
-- The method should be called when user presses inlineKeyboardButtonBuy
-- @chat_id Chat identifier of the Invoice message
-- @message_id Message identifier
function tdbot.getPaymentForm(chatid, messageid, callback, data)
  assert (tdbot_function ({
    _ = 'getPaymentForm',
    chat_id = chatid,
    message_id = messageid
  }, callback or dl_cb, data))
end

-- Validates order information provided by the user and returns available shipping options for flexible invoice
-- @chat_id Chat identifier of the Invoice message
-- @message_id Message identifier
-- @order_info Order information, provided by the user
-- @allow_save True, if order information can be saved
function tdbot.validateOrderInfo(chatid, messageid, orderinfo, allowsave, callback, data)
  assert (tdbot_function ({
    _ = 'validateOrderInfo',
    chat_id = chatid,
    message_id = messageid,
    order_info = orderInfo,
    allow_save = allowsave
  }, callback or dl_cb, data))
end

-- Sends filled payment form to the bot for the final verification
-- @chat_id Chat identifier of the Invoice message
-- @message_id Message identifier
-- @order_info_id Identifier returned by ValidateOrderInfo or empty string
-- @shipping_option_id Identifier of a chosen shipping option, if applicable
-- @credentials Credentials choosed by user for payment
-- @saved_credentials_id Identifier of saved credentials
-- @data JSON-encoded data with credentials identifier from the payment provider
-- @allow_save True, if credentials identifier can be saved server-side
function tdbot.sendPaymentForm(chatid, messageid, orderinfoid, shippingoptionid, credent, input_credentials, callback, data)
  local input_credentials = input_credentials or {}

  if credent == 'Saved' then
    input_credentials = {
      saved_credentials_id = tostring(input_credentials[1])
    }
  elseif credent == 'New' then
    input_credentials = {
      data = tostring(input_credentials[1]),
      allow_save = input_credentials[2]
    }
  end

  input_credentials._ = 'inputCredentials' .. credent

  assert (tdbot_function ({
    _ = 'sendPaymentForm',
    chat_id = chatid,
    message_id = messageid,
    order_info_id = tostring(orderinfoid),
    shipping_option_id = tostring(shippingoptionid),
    credentials = input_credentials
  }, callback or dl_cb, data))
end

-- Returns information about successful payment
-- @chat_id Chat identifier of the PaymentSuccessful message
-- @message_id Message identifier
function tdbot.getPaymentReceipt(chatid, messageid, callback, data)
  assert (tdbot_function ({
    _ = 'getPaymentReceipt',
    chat_id = chatid,
    message_id = messageid
  }, callback or dl_cb, data))
end

-- Returns saved order info if any
function tdbot.getSavedOrderInfo(callback, data)
  assert (tdbot_function ({
    _ = 'getSavedOrderInfo'
  }, callback or dl_cb, data))
end

-- Deletes saved order info
function tdbot.deleteSavedOrderInfo(callback, data)
  assert (tdbot_function ({
    _ = 'deleteSavedOrderInfo'
  }, callback or dl_cb, data))
end

-- Deletes saved credentials for all payments provider bots
function tdbot.deleteSavedCredentials(callback, data)
  assert (tdbot_function ({
    _ = 'deleteSavedCredentials'
  }, callback or dl_cb, data))
end

-- Returns user that can be contacted to get support
function tdbot.getSupportUser(callback, data)
  assert (tdbot_function ({
    _ = 'getSupportUser'
  }, callback or dl_cb, data))
end

-- Returns background wallpapers
function tdbot.getWallpapers(callback, data)
  assert (tdbot_function ({
    _ = 'getWallpapers'
  }, callback or dl_cb, data))
end

-- Registers current used device for receiving push notifications
-- @device_token Device token
-- @token The token, may be empty to unregister device
-- deviceToken: Apns | Gcm | SimplePush | UbuntuPhone | Blackberry
function tdbot.registerDevice(devicetoken, tokn, callback, data)
  assert (tdbot_function ({
    _ = 'registerDevice',
    device_token = {
      _ = 'deviceToken' .. devicetoken,
      token = tokn
    },
  }, callback or dl_cb, data))
end

-- Changes privacy settings
-- @key Privacy key
-- @rules New privacy rules
-- privacyKey: UserStatus | ChatInvite | Call
-- rule: AllowAll | AllowContacts | AllowUsers | DisallowAll | DisallowContacts | DisallowUsers
function tdbot.setPrivacy(privacy_key, rule, allowed_user_ids, disallowed_user_ids, callback, data)
  local privacy_rules = {[0] = {_ = 'privacyRule' .. rule}}

  if allowed_user_ids then
    privacy_rules = {
      {
        _ = 'privacyRule' .. rule
      },
      [0] = {
        _ = 'privacyRuleAllowUsers',
        user_ids = allowed_user_ids
      },
    }
  end
  if disallowed_user_ids then
    privacy_rules = {
      {
        _ = 'privacyRule' .. rule
      },
      [0] = {
        _ = 'privacyRuleDisallowUsers',
        user_ids = disallowed_user_ids
      },
    }
  end
  if allowed_user_ids and disallowed_user_ids then
    privacy_rules = {
      {
        _ = 'privacyRule' .. rule
      },
      {
        _ = 'privacyRuleAllowUsers',
        user_ids = allowed_user_ids
      },
      [0] = {
        _ = 'privacyRuleDisallowUsers',
        user_ids = disallowed_user_ids
      },
    }
  end
  assert (tdbot_function ({
    _ = 'setPrivacy',
    key = {
      _ = 'privacyKey' .. privacy_key
    },
    rules = {
      _ = 'privacyRules',
      rules = privacy_rules, -- vector<PrivacyRule>
    },
  }, callback or dl_cb, data))
end

-- Returns current privacy settings
-- @key Privacy key
-- privacyKey: UserStatus | ChatInvite | Call
function tdbot.getPrivacy(pkey, callback, data)
  assert (tdbot_function ({
    _ = 'getPrivacy',
    key = {
      _ = 'privacyKey' .. pkey
    },
  }, callback or dl_cb, data))
end

-- Returns value of an option by its name.
-- See list of available options on https://core.telegram.org/tdlib/options.
-- Can be called before authorization
-- @name Name of the option
function tdbot.getOption(optionname, callback, data)
  assert (tdbot_function ({
    _ = 'getOption',
    name = tostring(optionname)
  }, callback or dl_cb, data))
end

-- Sets value of an option.
-- See list of available options on https://core.telegram.org/tdlib/options.
-- Only writable options can be set.
-- Can be called before authorization
-- @name Name of the option
-- @value New value of the option
-- optionValue: Boolean | Empty | Integer | String
function tdbot.setOption(optionname, option, optionvalue, callback, data)
  assert (tdbot_function ({
    _ = 'setOption',
    name = tostring(optionname),
    value = {
      _ = 'optionValue' .. option,
      value = optionvalue
    },
  }, callback or dl_cb, data))
end

-- Changes period of inactivity, after which the account of currently logged in user will be automatically deleted
-- @ttl New account TTL
-- @days Number of days of inactivity before account deletion, should be from 30 and up to 366
function tdbot.changeAccountTtl(day, callback, data)
  assert (tdbot_function ({
    _ = 'changeAccountTtl',
    ttl = {
      _ = 'accountTtl',
      days = day
    },
  }, callback or dl_cb, data))
end

-- Returns period of inactivity, after which the account of currently logged in user will be automatically deleted
function tdbot.getAccountTtl(callback, data)
  assert (tdbot_function ({
    _ = 'getAccountTtl'
  }, callback or dl_cb, data))
end

-- Deletes the account of currently logged in user, deleting from the server all information associated with it.
-- Account's phone number can be used to create new account, but only once in two weeks
-- @reason Optional reason of account deletion
function tdbot.deleteAccount(rea, callback, data)
  assert (tdbot_function ({
    _ = 'deleteAccount',
    reason = tostring(rea)
  }, callback or dl_cb, data))
end

-- Returns current chat report spam state
-- @chat_id Chat identifier
function tdbot.getChatReportSpamState(chatid, callback, data)
  assert (tdbot_function ({
    _ = 'getChatReportSpamState',
    chat_id = chatid
  }, callback or dl_cb, data))
end

-- Reports chat as a spam chat or as not a spam chat.
-- Can be used only if ChatReportSpamState.can_report_spam is true.
-- After this request ChatReportSpamState.can_report_spam became false forever
-- @chat_id Chat identifier
-- @is_spam_chat If true, chat will be reported as a spam chat, otherwise it will be marked as not a spam chat
function tdbot.changeChatReportSpamState(chatid, isspamchat, callback, data)
  assert (tdbot_function ({
    _ = 'changeChatReportSpamState',
    chat_id = chatid,
    is_spam_chat = isspamchat
  }, callback or dl_cb, data))
end

-- Reports chat to Telegram moderators.
-- Can be used only for a channel chat or a private chat with a bot, because all other chats can't be checked by moderators
-- @chat_id Chat identifier
-- @reason Reason, the chat is reported
-- @text Report text
-- reason: Spam | Violence | Pornography | Other
function tdbot.reportChat(chatid, reasn, teks, callback, data)
  assert (tdbot_function ({
    _ = 'reportChat',
    chat_id = chatid,
    reason = {
      _ = 'chatReportReason' .. reasn,
      text = teks
    },
  }, callback or dl_cb, data))
end

-- Returns storage usage statistics
-- @chat_limit Maximum number of chats with biggest storage usage for which separate statistics should be returned.
-- All other chats will be grouped in entries with chat_id == 0.
-- If chat info database is not used, chat_limit is ignored and is always set to 0
function tdbot.getStorageStatistics(chatlimit, callback, data)
  assert (tdbot_function ({
    _ = 'getStorageStatistics',
    chat_limit = chatlimit
  }, callback or dl_cb, data))
end

-- Quickly returns approximate storage usage statistics
function tdbot.getStorageStatisticsFast(callback, data)
  assert (tdbot_function ({
    _ = 'getStorageStatisticsFast'
  }, callback or dl_cb, data))
end

-- Optimizes storage usage, i.e. deletes some files and return new storage usage statistics.
-- Secret thumbnails can't be deleted
-- @size Limit on total size of files after deletion. Pass -1 to use default limit
-- @ttl Limit on time passed since last access time (or creation time on some filesystems) to a file. Pass -1 to use default limit
-- @count Limit on total count of files after deletion. Pass -1 to use default limit
-- @immunity_delay Number of seconds after creation of a file, it can't be delited. Pass -1 to use default value
-- @file_types If not empty, only files with given types are considered. By default, all types except thumbnails, profile photos, stickers and wallpapers are deleted
-- @file_types: None | Animation | Audio | Document | Photo | ProfilePhoto | Secret | Sticker | Thumb | Unknown | Video | VideoNote | Voice | Wallpaper | SecretThumb
-- @chat_ids If not empty, only files from the given chats are considered. Use 0 as chat identifier to delete files not belonging to any chat, for example profile photos
-- @exclude_chat_ids If not empty, files from the given chats are exluded. Use 0 as chat identifier to exclude all files not belonging to any chat, for example profile photos
-- @chat_limit Same as in getStorageStatistics. Affects only returned statistics
function tdbot.optimizeStorage(siz, tt, cnt, immunitydelay, filetypes, chatids, excludechatids, chatlimit, callback, data)
  assert (tdbot_function ({
    _ = 'optimizeStorage',
    size = siz or -1,
    ttl = tt or -1,
    count = cnt or -1,
    immunity_delay = immunitydelay or -1,
    file_types = {
      _ = 'fileType' .. filetypes
    },
    chat_ids = chatids,
    exclude_chat_ids = excludechatids,
    chat_limit = chatlimit
  }, callback or dl_cb, data))
end

-- Sets current network type.
-- Can be called before authorization.
-- Call to this method forces reopening of all network connections mitigating delay in switching between different networks, so it should be called whenever network is changed even network type remains the same.
-- Network type is used to check if library can use network at all and for collecting detailed network data usage statistics
-- @type New network type, defaults to networkTypeNone
-- networkType: None | Mobile | MobileRoaming | WiFi | Other
function tdbot.setNetworkType(network_type, callback, data)
  assert (tdbot_function ({
    _ = 'setNetworkType',
    type = {
      _ = 'networkType' .. network_type
    },
  }, callback or dl_cb, data))
end

-- Returns network data usage statistics.
-- Can be called before authorization
-- @only_current If true, returns only data for the current library launch
function tdbot.getNetworkStatistics(onlycurrent, callback, data)
  assert (tdbot_function ({
    _ = 'getNetworkStatistics',
    only_current = onlycurrent
  }, callback or dl_cb, data))
end

-- Adds specified data to data usage statistics.
-- Can be called before authorization
-- @entry Network statistics entry with a data to add to statistics
-- entry: File | Call
-- @sent_bytes Total number of sent bytes
-- @received_bytes Total number of received bytes
-- @file_type Type of a file the data is part of
-- fileType: None | Animation | Audio | Document | Photo | ProfilePhoto | Secret | Sticker | Thumb | Unknown | Video | VideoNote | Voice | Wallpaper | SecretThumb
-- @network_type Type of a network the data was sent through. Call setNetworkType to maintain actual network type
-- networkType: None | Mobile | MobileRoaming | WiFi | Other
-- @sent_bytes Total number of sent bytes
-- @received_bytes Total number of received bytes
function tdbot.addNetworkStatistics(entri, filetype, networktype, sentbytes, receivedbytes, durasi, callback, data)
  assert (tdbot_function ({
    _ = 'addNetworkStatistics',
    entry = {
      _ = 'networkStatisticsEntry' .. entri,
      file_type = {
        _ = 'fileType' .. filetype
      },
      network_type = {
        _ = 'networkType' .. networktype
      },
      sent_bytes = sentbytes,
      received_bytes = receivedbytes,
      duration = durasi
    },
  }, callback or dl_cb, data))
end

-- Resets all network data usage statistics to zero.
-- Can be called before authorization
function tdbot.resetNetworkStatistics(callback, data)
  assert (tdbot_function ({
    _ = 'resetNetworkStatistics'
  }, callback or dl_cb, data))
end

-- Bots only.
-- Informs server about number of pending bot updates if they aren't processed for a long time
-- @pending_update_count Number of pending updates
-- @error_message Last error's message
function tdbot.setBotUpdatesStatus(pendingupdatecount, errormessage, callback, data)
  assert (tdbot_function ({
    _ = 'setBotUpdatesStatus',
    pending_update_count = pendingupdatecount,
    error_message = tostring(errormessage)
  }, callback or dl_cb, data))
end

-- Bots only.
-- Uploads a png image with a sticker.
-- Returns uploaded file
-- @user_id Sticker file owner
-- @png_sticker Png image with the sticker, must be up to 512 kilobytes in size and fit in 512x512 square
function tdbot.uploadStickerFile(userid, pngsticker, callback, data)
  assert (tdbot_function ({
    _ = 'uploadStickerFile',
    user_id = userid,
    png_sticker = getInputFile(pngsticker)
  }, callback or dl_cb, data))
end

-- Bots only.
-- Creates new sticker set.
-- Returns created sticker set
-- @user_id Sticker set owner
-- @title Sticker set title, 1-64 characters
-- @name Sticker set name. Can contain only english letters, digits and underscores. Should end on *'_by_<bot username>'*. *<bot_username>* is case insensitive, 1-64 characters
-- @is_masks True, is stickers are masks
-- @stickers Description of a sticker which should be added to a sticker set
-- @png_sticker Png image with the sticker, must be up to 512 kilobytes in size and fit in 512x512 square
-- @emojis Emojis corresponding to the sticker
-- @mask_position Position where the mask should be placed, nullable
-- @point Part of a face relative to which the mask should be placed. 0 - forehead, 1 - eyes, 2 - mouth, 3 - chin
-- @x_shift Shift by X-axis measured in widths of the mask scaled to the face size, from left to right. For example, choosing -1.0 will place mask just to the left of the default mask position
-- @y_shift Shift by Y-axis measured in heights of the mask scaled to the face size, from top to bottom. For example, 1.0 will place the mask just below the default mask position.
-- @scale Mask scaling coefficient. For example, 2.0 means double size
function tdbot.createNewStickerSet(userid, title, name, ismasks, pngsticker, emoji, points, x_shifts, y_shifts, scales, callback, data)
  assert (tdbot_function ({
    _ = 'createNewStickerSet',
    user_id = userid,
    title = tostring(title),
    name = tostring(name),
    is_masks = ismasks,
    stickers = {
      _ = 'inputSticker',
      png_sticker = getInputFile(pngsticker),
      emojis = tostring(emoji),
      mask_position = {
        _ = 'maskPosition',
        point = points,
        x_shift = x_shifts,
        y_shift = y_shifts,
        scale = scales
      },
    },
  }, callback or dl_cb, data))
end

-- Bots only.
-- Adds new sticker to a set.
-- Returns the sticker set
-- @user_id Sticker set owner
-- @name Sticker set name
-- @sticker Sticker to add to the set
-- @png_sticker Png image with the sticker, must be up to 512 kilobytes in size and fit in 512x512 square
-- @emojis Emojis corresponding to the sticker
-- @mask_position Position where the mask should be placed, nullable
-- @point Part of a face relative to which the mask should be placed. 0 - forehead, 1 - eyes, 2 - mouth, 3 - chin
-- @x_shift Shift by X-axis measured in widths of the mask scaled to the face size, from left to right. For example, choosing -1.0 will place mask just to the left of the default mask position
-- @y_shift Shift by Y-axis measured in heights of the mask scaled to the face size, from top to bottom. For example, 1.0 will place the mask just below the default mask position.
-- @scale Mask scaling coefficient. For example, 2.0 means double size
function tdbot.addStickerToSet(userid, name, pngsticker, mpoint, xshift, yshift, mscale, callback, data)
  assert (tdbot_function ({
    _ = 'addStickerToSet',
    user_id = userid,
    name = tostring(name),
    sticker = {
      _ = 'inputSticker',
      png_sticker = getInputFile(pngsticker),
      emojis = tostring(emoji),
      mask_position = {
        _ = 'maskPosition',
        point = mpoint,
        x_shift = xshift,
        y_shift = yshift,
        scale = mscale
      },
    },
  }, callback or dl_cb, data))
end

-- Bots only.
-- Changes position of a sticker in the set it belongs to.
-- Sticker set should be created by the bot
-- @sticker The sticker
-- @position New sticker position in the set, zero-based
function tdbot.setStickerPositionInSet(sticker, position, callback, data)
  assert (tdbot_function ({
    _ = 'setStickerPositionInSet',
    sticker = getInputFile(sticker),
    position = position
  }, callback or dl_cb, data))
end

-- Bots only.
-- Deletes a sticker from the set it belongs to.
-- Sticker set should be created by the bot
-- @sticker The sticker
function tdbot.deleteStickerFromSet(sticker, callback, data)
  assert (tdbot_function ({
    _ = 'deleteStickerFromSet',
    sticker = getInputFile(sticker)
  }, callback or dl_cb, data))
end

-- Bots only.
-- Sends custom request
-- @method Method name
-- @parameters JSON-serialized method parameters
function tdbot.sendCustomRequest(method, parameters, callback, data)
  assert (tdbot_function ({
    _ = 'sendCustomRequest',
    method = tostring(method),
    parameters = tostring(parameters)
  }, callback or dl_cb, data))
end

-- Bots only.
-- Answers a custom query
-- @custom_query_id Identifier of a custom query
-- @data JSON-serialized answer to the query
function tdbot.answerCustomQuery(customqueryid, data, callback, data)
  assert (tdbot_function ({
    _ = 'answerCustomQuery',
    custom_query_id = customqueryid,
    data = tostring(data)
  }, callback or dl_cb, data))
end

-- Returns Ok after specified amount of the time passed.
-- Can be called before authorization
-- @seconds Number of seconds before that function returns
function tdbot.setAlarm(sec, callback, data)
  assert (tdbot_function ({
    _ = 'setAlarm',
    seconds = sec
  }, callback or dl_cb, data))
end

-- Returns invite text for invitation of new users
function tdbot.getInviteText(callback, data)
  assert (tdbot_function ({
    _ = 'getInviteText'
  }, callback or dl_cb, data))
end

-- Returns terms of service.
-- Can be called before authorization
function tdbot.getTermsOfService(callback, data)
  assert (tdbot_function ({
    _ = 'getTermsOfService'
  }, callback or dl_cb, data))
end

-- Sets proxy server for network requests.
-- Can be called before authorization
-- @proxy The proxy to use. You can specify null to remove proxy server
-- @server Proxy server ip address
-- @port Proxy server port
-- @username Username to log in
-- @password Password to log in
-- proxy: Empty | Socks5
function tdbot.setProxy(proksi, serv, pport, uname, passwd, callback, data)
  assert (tdbot_function ({
    _ = 'setProxy',
    proxy = {
      _ = 'proxy' .. proksi,
      server = tostring(serv),
      port = pport,
      username = tostring(uname),
      password = tostring(passwd),
    },
  }, callback or dl_cb, data))
end

-- Returns current set up proxy.
-- Can be called before authorization
function tdbot.getProxy(callback, data)
  assert (tdbot_function ({
    _ = 'getProxy'
  }, callback or dl_cb, data))
end

-- Text message
-- @text Text to send
-- @disable_web_page_preview Pass true to disable rich preview for link in the message text
-- @clear_draft Pass true if chat draft message should be deleted
-- @entities Bold, Italic, Code, Pre, PreCode and TextUrl entities contained in the text. Non-bot users can't use TextUrl entities. Can't be used with non-null parse_mode
-- @parse_mode Text parse mode, nullable. Can't be used along with enitities
function tdbot.sendText(chat_id, reply_to_message_id, text, disable_notification, from_background, reply_markup, disablewebpagepreview, parsemode, cleardraft, entity, callback, data)
  local input_message_content = {
    _ = 'inputMessageText',
    text = tostring(text),
    disable_web_page_preview = disablewebpagepreview,
    parse_mode = getParseMode(parsemode),
    clear_draft = cleardraft,
    entities = entity
  }
  sendMessage(chat_id, reply_to_message_id, input_message_content, disable_notification, from_background, reply_markup, callback, data)
end

-- Animation message
-- @animation Animation file to send
-- @thumb Animation thumb, if available
-- @duration Duration of the animation in seconds
-- @width Width of the animation, may be replaced by the server
-- @height Height of the animation, may be replaced by the server
-- @caption Animation caption, 0-200 characters
function tdbot.sendAnimation(chat_id, reply_to_message_id, animation_file, aniwidth, aniheight, anicaption, disable_notification, from_background, reply_markup, callback, data)
  local input_message_content = {
    _ = 'inputMessageAnimation',
    animation = getInputFile(animation_file),
    thumb = inputThumb,
    duration = duration,
    width = aniwidth,
    height = aniheight,
    caption = tostring(anicaption)
  }
  sendMessage(chat_id, reply_to_message_id, input_message_content, disable_notification, from_background, reply_markup, callback, data)
end
-- Audio message
-- @audio Audio file to send
-- @album_cover_thumb Thumb of the album's cover, if available
-- @duration Duration of the audio in seconds, may be replaced by the server
-- @title Title of the audio, 0-64 characters, may be replaced by the server
-- @performer Performer of the audio, 0-64 characters, may be replaced by the server
-- @caption Audio caption, 0-200 characters
function tdbot.sendAudio(chat_id, reply_to_message_id, audio, duration, title, performer, caption, disable_notification, from_background, reply_markup, callback, data)
  local input_message_content = {
    _ = 'inputMessageAudio',
    audio = getInputFile(audio),
    album_cover_thumb = inputThumb,
    duration = duration or 0,
    title = tostring(title) or 0,
    performer = tostring(performer),
    caption = tostring(caption)
  }
  sendMessage(chat_id, reply_to_message_id, input_message_content, disable_notification, from_background, reply_markup, callback, data)
end

-- Document message
-- @document Document to send
-- @thumb Document thumb, if available
-- @caption Document caption, 0-200 characters
function tdbot.sendDocument(chat_id, document, caption, doc_thumb, reply_to_message_id, disable_notification, from_background, reply_markup, callback, data)
  local input_message_content = {
    _ = 'inputMessageDocument',
    document = getInputFile(document),
    thumb = doc_thumb, -- inputThumb
    caption = tostring(caption)
  }
  sendMessage(chat_id, reply_to_message_id, input_message_content, disable_notification, from_background, reply_markup, callback, data)
end

-- Photo message
-- @photo Photo to send
-- @thumb Photo thumb to send, is sent to the other party in secret chats only
-- @added_sticker_file_ids File identifiers of stickers added onto the photo
-- @width Photo width
-- @height Photo height
-- @caption Photo caption, 0-200 characters
-- @ttl Photo TTL in seconds, 0-60. Non-zero TTL can be only specified in private chats
function tdbot.sendPhoto(chat_id, reply_to_message_id, photo_file, photo_thumb, addedstickerfileids, photo_width, photo_height, photo_caption, photo_ttl, disable_notification, from_background, reply_markup, callback, data)
  local input_message_content = {
    _ = 'inputMessagePhoto',
    photo = getInputFile(photo_file),
    thumb = photo_thumb, -- inputThumb
    added_sticker_file_ids = addedstickerfileids,
    width = photo_width,
    height = photo_height,
    caption = tostring(photo_caption),
    ttl = photo_ttl
  }
  sendMessage(chat_id, reply_to_message_id, input_message_content, disable_notification, from_background, reply_markup, callback, data)
end

-- Sticker message
-- @sticker Sticker to send
-- @thumb Sticker thumb, if available
-- @width Sticker width
-- @height Sticker height
function tdbot.sendSticker(chat_id, reply_to_message_id, sticker_file, sticker_width, sticker_height, disable_notification, from_background, reply_markup, callback, data)
  local input_message_content = {
    _ = 'inputMessageSticker',
    sticker = getInputFile(sticker_file),
    thumb = sticker_thumb, -- inputThumb
    width = sticker_width,
    height = sticker_height
  }
  sendMessage(chat_id, reply_to_message_id, input_message_content, disable_notification, from_background, reply_markup, callback, data)
end

-- Video message
-- @video Video to send
-- @thumb Video thumb, if available
-- @added_sticker_file_ids File identifiers of stickers added onto the video
-- @duration Duration of the video in seconds
-- @width Video width @height Video height
-- @caption Video caption, 0-200 characters
-- @ttl Video TTL in seconds, 0-60. Non-zero TTL can be only specified in private chats
function tdbot.sendVideo(chat_id, reply_to_message_id, video_file, vid_thumb, addedstickerfileids, vid_duration, vid_width, vid_height, vid_caption, vid_ttl, disable_notification, from_background, reply_markup, callback, data)
  local input_message_content = {
    _ = 'inputMessageVideo',
    video = getInputFile(video_file),
    thumb = vid_thumb, -- inputThumb
    added_sticker_file_ids = addedstickerfileids,
    duration = vid_duration or 0,
    width = vid_width or 0,
    height = vid_height or 0,
    caption = tostring(vid_caption),
    ttl = vid_ttl
  }
  sendMessage(chat_id, reply_to_message_id, input_message_content, disable_notification, from_background, reply_markup, callback, data)
end

-- Video note message
-- @video_note Video note to send
-- @thumb Video thumb, if available
-- @duration Duration of the video in seconds
-- @length Video width and height, should be positive and not greater than 640
function tdbot.sendVideoNote(chat_id, reply_to_message_id, videonote, vnote_thumb, vnote_duration, vnote_length, disable_notification, from_background, reply_markup, callback, data)
  local input_message_content = {
    _ = 'inputMessageVideoNote',
    video_note = getInputFile(videonote),
    thumb = vidnote_thumb, -- inputThumb
    duration = vnote_duration,
    length = vnote_length
  }
  sendMessage(chat_id, reply_to_message_id, input_message_content, disable_notification, from_background, reply_markup, callback, data)
end

-- Voice message
-- @voice Voice file to send
-- @duration Duration of the voice in seconds
-- @waveform Waveform representation of the voice in 5-bit format
-- @caption Voice caption, 0-200 characters
function tdbot.sendVoice(chat_id, reply_to_message_id, voice_file, voi_duration, voi_waveform, voi_caption, disable_notification, from_background, reply_markup, callback, data)
  local input_message_content = {
    _ = 'inputMessageVoice',
    voice = getInputFile(voice_file),
    duration = voi_duration or 0,
    waveform = voi_waveform,
    caption = tostring(voi_caption)
  }
  sendMessage(chat_id, reply_to_message_id, input_message_content, disable_notification, from_background, reply_markup, callback, data)
end

-- Message with location
-- @location Location to send
-- @latitude Latitude of location in degrees as defined by sender
-- @longitude Longitude of location in degrees as defined by sender
function tdbot.sendLocation(chat_id, reply_to_message_id, lat, lon, disable_notification, from_background, reply_markup, callback, data)
  local input_message_content = {
    _ = 'inputMessageLocation',
    location = {
      _ = 'location',
      latitude = lat,
      longitude = lon
    },
  }
  sendMessage(chat_id, reply_to_message_id, input_message_content, disable_notification, from_background, reply_markup, callback, data)
end

-- Message with information about venue
-- @venue Venue to send
-- @location Venue location as defined by sender
-- @title Venue name as defined by sender
-- @address Venue address as defined by sender
-- @provider Provider of venue database as defined by sender. Only 'foursquare' need to be supported currently
function tdbot.sendVenue(chat_id, reply_to_message_id, lat, lon, ven_title, ven_address, ven_provider, ven_id, disable_notification, from_background, reply_markup, callback, data)
  local input_message_content = {
    _ = 'inputMessageVenue',
    venue = {
      _ = 'venue',
      location = {
        _ = 'location',
        latitude = lat,
        longitude = lon
      },
      title = tostring(ven_title),
      address = tostring(ven_address),
      provider = tostring(ven_provider) or 'foursquare',
      id = tostring(ven_id)
    },
  }
  sendMessage(chat_id, reply_to_message_id, input_message_content, disable_notification, from_background, reply_markup, callback, data)
end

-- User contact message
-- @contact Contact to send
-- @phone_number User's phone number
-- @first_name User first name, 1-255 characters
-- @last_name User last name
-- @user_id User identifier if known, 0 otherwise
function tdbot.sendContact(chat_id, reply_to_message_id, phonenumber, firstname, lastname, userid, disable_notification, from_background, reply_markup, callback, data)
  local input_message_content = {
    _ = 'inputMessageContact',
    contact = {
      _ = 'contact',
      phone_number = tostring(phonenumber),
      first_name = tostring(firstname),
      last_name = tostring(lastname),
      user_id = userid
    },
  }
  sendMessage(chat_id, reply_to_message_id, input_message_content, disable_notification, from_background, reply_markup, callback, data)
end

-- @bot_user_id User identifier of a bot owned the game
-- @game_short_name Game short name
function tdbot.sendGame(chat_id, reply_to_message_id, botuserid, gameshortname, disable_notification, from_background, reply_markup, callback, data)
  local input_message_content = {
    _ = 'inputMessageGame',
    bot_user_id = botuserid,
    game_short_name = tostring(gameshortname)
  }
  sendMessage(chat_id, reply_to_message_id, input_message_content, disable_notification, from_background, reply_markup, callback, data)
end

-- Message with an invoice, can be used only by bots and in private chats only
-- @invoice The invoice
-- @title Product title, 1-32 characters
-- @param_description Product description, 0-255 characters
-- @photo_url Goods photo URL, optional
-- @photo_size Goods photo size
-- @photo_width Goods photo width
-- @photo_height Goods photo height
-- @payload Invoice payload
-- @provider_token Payments provider token
-- @start_parameter Unique invoice bot start_parameter for generation of this invoice
function tdbot.sendInvoice(chat_id, reply_to_message_id, the_invoice, inv_title, inv_desc, photourl, photosize, photowidth, photoheight, inv_payload, providertoken, startparameter, disable_notification, from_background, reply_markup, callback, data)
  local input_message_content = {
    _ = 'inputMessageInvoice',
    invoice = the_invoice,
    -- invoice = {
      -- _ = 'invoice',
      -- currency = tostring(currency),
      -- prices = prices, -- vector<labeledPrice>
      -- is_test = is_test,
      -- need_name = need_name,
      -- need_phone_number = need_phone_number,
      -- need_email = need_email,
      -- need_shipping_address = need_shipping_address,
      -- is_flexible = is_flexible
    -- },
    title = tostring(inv_title),
    description = tostring(inv_desc),
    photo_url = tostring(photourl),
    photo_size = photosize,
    photo_width = photowidth,
    photo_height = photoheight,
    payload = inv_payload,
    provider_token = tostring(providertoken),
    start_parameter = tostring(startparameter)
  }
  sendMessage(chat_id, reply_to_message_id, input_message_content, disable_notification, from_background, reply_markup, callback, data)
end

-- Forwarded message
-- @from_chat_id Chat identifier of the message to forward
-- @message_id Identifier of the message to forward
-- @in_game_share Pass true to share a game message within a launched game, for Game messages only
function tdbot.sendForwarded(chat_id, reply_to_message_id, fromchatid, messageid, ingameshare, disable_notification, from_background, reply_markup, callback, data)
  local input_message_content = {
    _ = 'inputMessageForwarded',
    from_chat_id = fromchatid,
    message_id = messageid,
    in_game_share = ingameshare
  }
  sendMessage(chat_id, reply_to_message_id, input_message_content, disable_notification, from_background, reply_markup, callback, data)
end

return tdbot
