-- This module implements a subset of the Adobe RTMP protocol as specified by:
--  http://www.adobe.com/devnet/rtmp/pdf/rtmp_specification_1.0.pdf
--
-- It provides direct streaming for rtmp in conjunction with the RTMP.pm server protocol handler
-- which is contained with the BBCiPlayer plugin.  It is intended for use with BBC live and listen
-- again streams as supported by the BBCiPlayer plugin.
--
-- (c) Triode, 2009, triode1@btinternet.com
--
-- The implementation here contains just the low level state machine for processing the rtmp protocol.
-- It relies on the server module to create serialised amf0 objects necessary to establish the stream and
-- returns amf0 response packets to the server for decoding.  It makes the following assumptions:
--
-- 1) streams use a streamingId of 1 (it ignores the streamingId inside the amf0 _result reponse to a createStream message)
-- 2) only implements single byte chunk headers (chunk id < 63)
-- 3) does not implement timestamps - a value of 0 is sent in any timestamp field sent to the rtmp server
--
-- Due to the way the stream object is created it is necessary to switch methods in the stream object's meta table
-- so that the Rtmp read and write methods here are used (this is done in Playback.lua)

local string, table, math = string, table, math

local Stream   = require("squeezeplay.stream")

local mime     = require("mime")

local debug    = require("jive.utils.debug")
local log      = require("jive.utils.log").logger("audio.decode")

module(...)


-- session params (can't be stored in the object as we reuse the streambuf object)
local inBuf, outBuf, state, token, inCaches, rtmpMessages
local ackWindow, nextAck, receivedBytes
local sendChunkSize, recvChunkSize
local adts1, adts2, adts3, adts4, adts5, adts6, adts7

local slimproto


function init(self, slimprotoObj)
	slimproto = slimprotoObj
	slimproto:capability("Rtmp", 1)
end


local function unpackNumber(str, pos, len, le)
	local v = 0
	if le then
		for i = pos + len - 1, pos, - 1 do
			v = (v << 8) | (string.byte(str, i) or 0)
		end
	else
		for i = pos, pos + len - 1 do
			v = (v << 8) | (string.byte(str, i) or 0)
		end
	end
	return v
end


local function changeState(newstate)
	log:info(state, " -> ", newstate)
	state = newstate
end


function sendRtmp(stream, rtmp)
	-- send rtmp packets fragmenting if neccessary
	-- assume all packets have a t0 header (no header compression)
	local header = string.sub(rtmp, 1, 12)
	local body   = string.sub(rtmp, 13)

	stream:_streamWrite(nil, header)
	
	len = string.len(body)

	while len > 0 do
		if len > sendChunkSize then
			len = sendChunkSize
		end
		local chunk = string.sub(body, 1, len)
		body = string.sub(body, len + 1)

		stream:_streamWrite(nil, chunk)
		len = string.len(body)

		if len > 0 then
			stream:_streamWrite(nil, string.char( string.byte(header, 1) | 0xc0 ) )
		end
	end
end


function write(stream, playback, header)
	-- initialise
	inBuf, outBuf, token, inCaches, rtmpMessages, sendChunkSize, recvChunkSize = "", "", "", {}, {}, 128, 128
	ackWindow, nextAck, receivedBytes = 10240, 10240, 0
	state = "reset"

	-- extract the pre built rtmp packets within the header
	for k, v in string.gmatch(header, "(%w+)=([a-zA-Z0-9%/%+]+%=*)&") do
		rtmpMessages[k] = mime.unb64("", v)
	end

	-- create the handshake token
	for i = 1, 1528 do
		token = token .. string.char(math.random(0,255))
	end

	-- send RTMP handshake
	-- c0
	local c0 = string.char(0x03)

	-- c1 [ assume timestamp of 0 ]
	local c1 = string.char(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00) .. token

	changeState("hsAwaitS0")

	return stream:_streamWrite(nil, c0 .. c1)
end


local hsHanders = {

	hsAwaitS0 = { 1,
				  function(stream, s0)
					  if string.byte(s0, 1) == 0x03 then
						  return 'hsAwaitS1'
					  else
						  log:warn("did not get S0 response")
						  return nil
					  end
				  end
	},

	hsAwaitS1 = { 1536,
				  function(stream, s1)
					  local time1 = string.sub(s1, 1, 4)
					  local mytime = string.char(0x00, 0x00, 0x00, 0x00)
					  local c2 = time1 .. mytime .. string.sub(s1, 9)
					  stream:_streamWrite(nil, c2)
					  return 'hsAwaitS2'
				  end
	},

	hsAwaitS2 = { 1536,
				  function(stream, s2)
					  local rand = string.sub(s2, 9)
					  if rand == token then
						  sendRtmp(stream, rtmpMessages["connect"])
						  return 'sentConnect'
					  else
						  return nil
					  end
				  end
	},
}

local rtmpHandlers = {

	[1]  = function(stream, rtmp)
			   recvChunkSize = unpackNumber(rtmp["body"], 1, 4)
			   log:info("message type 1 - set recv chunk size to ", recvChunkSize)
		   end,

	[2]  = function(stream, rtmp)
			   log:info("message type 2 - abort for chunk channel ", rtmp["chan"])
			   inCaches[ rtmp["chan"] ] = {}
		   end,

	[3]  = function(stream, rtmp)
			   log:info("ack received")
		   end,

	[4]  = function(stream, rtmp)
			   local event = unpackNumber(rtmp["body"], 1, 2)
			   local data  = string.sub(rtmp["body"], 3)

			   if event == 0 then
				   log:info("message type 4 - user control message ", event, ": Stream Begin")
			   elseif event == 1 then
				   log:info("message type 4 - user control message ", event, ": EOF - exiting")
				   return "EOF"
			   elseif event == 2 then
				   log:info("message type 4 - user control message ", event, ": Stream Dry")
			   elseif event == 4 then
				   log:info("message type 4 - user control message ", event, ": Stream Is Recorded")
			   elseif event == 6 then
				   log:info("message type 4 - user control message ", event, ": Ping Request - sending response")
				   sendRtmp(stream, 
							string.char(0x02,                  -- chan 2, format 0
										0x00, 0x00, 0x00,      -- timestamp (not implemented)
										0x00, 0x00, 0x06,      -- length [data should be 4 bytes]
										0x04,                  -- type 0x04
										0x00, 0x00, 0x00, 0x00,-- streamId 0
										0x00, 0x07) ..         -- event type 7
							data)                              -- return data

			   else
				   log:debug("message type 4 - user control message ", event, ": ignored")
			   end
		   end,

	[5]  = function(stream, rtmp)
			   local window = unpackNumber(rtmp["body"], 1, 4)
			   log:info("message type 5 - window ack size: ", window, " - ignored")
		   end,

	[6]  = function(stream, rtmp)
			   local window = unpackNumber(rtmp["body"], 1, 4)
			   local limit  = unpackNumber(rtmp["body"], 5, 1)

			   log:info("message type 5 - set peer BW: ", window, " limit type ", limit, " - sending response")
			   ackWindow = window
			   sendRtmp(stream, 
						string.char(0x02,                       -- chan 2, format 0
									0x00, 0x00, 0x00,           -- timestamp (not implemented)
									0x00, 0x00, 0x04,           -- length
									0x05,                       -- type 0x05
									0x00, 0x00, 0x00, 0x00,     -- streamId 0
									(window & 0xFF000000) >> 24,-- window as u32 be
									(window & 0x00FF0000) >> 16,
									(window & 0x0000FF00) >>  8,
									(window & 0x000000FF)
							))
		   end,

	[8]  = function(stream, rtmp)
			   local byte1, byte2 = string.byte(rtmp["body"], 1, 2)
			   if not byte1 then
				   return 0
			   end

			   if byte1 == 0xAF and byte2 == 0x01 then
				   -- AAC
				   --log:debug("message type 8 - AAC audiodata, len:", rtmp["length"])
				   local framesize = rtmp["length"] - 2 + 7
				   local header = string.char(adts1, adts2, adts3, 
											  adts4 | ((framesize >> 11) & 0x03),
											  adts5 | ((framesize >>  3) & 0xFF),
											  adts6 | ((framesize <<  5) & 0xE0),
											  adts7)

				   outBuf = outBuf .. header .. string.sub(rtmp["body"], 3)

			   elseif byte1 == 0xAF and byte2 == 0x00 then
				   -- AAC Config
				   local firstword = unpackNumber(rtmp["body"], 1, 4)
				   local profile   = 1
				   local sr_index  = (firstword & 0x00000780) >> 7
				   local channels  = (firstword & 0x00000078) >> 3

				   log:info("message type 8 - AAC config, profile: ", profile, " sr_index: ", sr_index, " channels: ", channels)

				   adts1 = 0xFF
				   adts2 = 0xF9
				   adts3 = ((profile << 6) & 0xC0) | ((sr_index << 2) & 0x3C) | ((channels >> 2) & 0x1)
				   adts4 = ((channels << 6) & 0xC0)
				   adts5 = 0x00
				   adts6 = ((0x7FF >> 6) & 0x1F)
				   adts7 = ((0x7FF << 2) & 0xFC)

			   elseif (byte1 & 0xF0) == 0x20 then
				   -- MP3
				   --log:debug("message type 8 - MP3 audiodata, len:", rtmp["length"])

				   outBuf = outBuf .. string.sub(rtmp["body"], 2)
			   end

			   local n = stream:feedFromLua(outBuf)
			   if n > 0 then
				   outBuf = string.sub(outBuf, n + 1)
			   end

			   return n
		   end,

	[18] = function(stream, rtmp)
			   log:info("message type 18 - metadata")
			   slimproto:send({ opcode = "META", data = rtmp["body"] })
		   end,

	[20] = function(stream, rtmp)
			   log:info("message type 20")

			   slimproto:send({ opcode = "META", data = rtmp["body"] })

			   if string.match(rtmp["body"], "_result") then

				   if state == "sentConnect" then

					   log:info("sending createStream")
					   sendRtmp(stream, rtmpMessages["create"])
					   changeState("sentCreateStream")

				   elseif state == "sentCreateStream" then

					   if rtmpMessages["subscribe"] then
						   log:info("sending FCSubscribe")
						   sendRtmp(stream, rtmpMessages["subscribe"])
						   changeState("sentFCSubscribe")
					   else
						   log:info("sending play")
						   sendRtmp(stream, rtmpMessages["play"])
						   changeState("sentPlay")
					   end
				   end

			   elseif string.match(rtmp["body"], "_error") then

				   log:warn("stream error")
				   return nil, true

			   elseif string.match(rtmp["body"], "onFCSubscribe") then

				   log:info("sending play")
				   sendRtmp(stream, rtmpMessages["play"])
				   changeState("sentPlay")

			   elseif string.match(rtmp["body"], "onStatus") then

				   log:info("onStatus")

				   local error =
					   string.match(rtmp["body"], "NetStream%.Failed") or
					   string.match(rtmp["body"], "NetStream%.Play%.Failed") or
					   string.match(rtmp["body"], "NetStream%.Play%.StreamNotFound") or
					   string.match(rtmp["body"], "NetConnection%.Connect%.InvalidApp") or
					   string.match(rtmp["body"], "NetStream%.Play%.Complete") or
					   string.match(rtmp["body"], "NetStream%.Play%.Stop")

				   if error then
					   return nil, true
				   end

			   end

		   end,
}


function read(stream)

	local readmore = true
	local n = 0

	while readmore do

		local new, error = stream:readToLua()
		if error then
			return
		end
		if new then
			inBuf = inBuf .. new
			receivedBytes = receivedBytes + string.len(new)
		end

		readmore = false

		local len = string.len(inBuf)
		
		-- handshake phase
		if (state == 'hsAwaitS0' or state == 'hsAwaitS1' or state == 'hsAwaitS2') then
			
			local expect  = hsHanders[state][1]
			local handler = hsHanders[state][2]
			
			if len >= expect then

				local packet = string.sub(inBuf, 1, expect)
				inBuf = string.sub(inBuf, expect + 1)

				local newstate = handler(stream, packet)
				if not newstate then
					return
				end

				changeState(newstate)

				readmore = true

			end

		-- rtmp parsing phase	
		elseif len > 0 then
		
			local header0 = string.byte(inBuf, 1)
			local chan    = header0 & 0x3f
			local fmt     = (header0 & 0xc0) >> 6
			local info, body

			if not inCaches[chan] then
				inCaches[chan] = {}
			end
			local inCache = inCaches[chan]

			if (chan == 0 or chan == 1) then
				log:error("rtmp chan > 63 - not supported")
				return
			end

			if fmt == 0 and len >= 12 then

				local t0len = unpackNumber(inBuf, 5, 3)
				local read = math.min(t0len, recvChunkSize) + 12

				if len >= read then

					info = {
						chunkChan = chan,
						type      = string.byte(inBuf, 8),
						--timestamp = unpackNumber(inBuf, 2, 3),
						length    = t0len,
						streamId  = unpackNumber(inBuf, 9, 4, true)
					}

					local frag = string.sub(inBuf, 13, read)
					inBuf = string.sub(inBuf, read + 1)

					if read == t0len + 12 then
						body = frag
					else
						inCaches[chan] = {
							info   = info,
							body   = frag,
							remain = t0len + 12 - read
						}
						inCache = inCache[chan]
					end

					readmore = true
				end

			elseif fmt == 1 and len >= 8 and inCache["info"] then

				local t1len = unpackNumber(inBuf, 5, 3)
				local read = math.min(t1len, recvChunkSize) + 8

				if len >= read then

					local delta = unpackNumber(inBuf, 2, 3)

					info = inCache["info"]
					info["type"] = string.byte(inBuf, 8)
					--info["timestamp"] = info["timestamp"] + delta
					info["length"] = t1len
					-- streamId is cached
					--info["delta"] = delta

					local frag = string.sub(inBuf, 9, read)
					inBuf = string.sub(inBuf, read + 1)

					if read == t1len + 8 then
						body = frag
					else
						inCache["body"] = frag
						inCache["remain"] = t1len + 8 - read
					end

					readmore = true
				end

			elseif fmt == 2 and inCache["info"] then

				local t2len = inCache["info"]["length"]
				local read = math.min(t2len, recvChunkSize) + 4

				if len >= read then

					--local delta = unpackNumber(inBuf, 2, 3)

					info = inCache["info"]
					--info["timestamp"] = info["timestamp"] + delta
					-- type, length, streamId is cached
					--info["delta"] = delta

					local frag = string.sub(inBuf, 5, read)
					inBuf = string.sub(inBuf, read + 1)

					if read == t2len + 4 then
						body = frag
					else
						inCache["body"] = frag
						inCache["remain"] = t2len + 4 - read
					end

					readmore = true
				end

			elseif fmt == 3 and inCache["remain"] and inCache["remain"] > 0 then

				local read = math.min(inCache["remain"], recvChunkSize) + 1

				if len >= read then

					local frag = string.sub(inBuf, 2, read)
					inBuf = string.sub(inBuf, read + 1)

					inCache["body"] = inCache["body"] .. frag
					inCache["remain"] = inCache["remain"] - (read - 1)

					if inCache["remain"] == 0 then
						info = inCache["info"]
						body = inCache["body"]
					end

					readmore = true
				end

			elseif fmt == 3 and inCache["info"] then

				local t3len = inCache["info"]["length"]
				local read = math.min(t3len, recvChunkSize) + 1

				if len >= read then
				
					info = inCache["info"]
					--info["timestamp"] = info["timestamp"] + info["delta"]
					-- type, length, streamId is cached

					local frag = string.sub(inBuf, 2, read)
					inBuf = string.sub(inBuf, read + 1)

					if read == t3len + 1 then
						body = frag
					else
						inCache["body"] = frag
						inCache["remain"] = t3len + 1 - read
					end

					readmore = true
				end

			end

			if body then
				local rtmp = info
				inCache["info"] = info
				rtmp["body"] = body

				local handler = rtmpHandlers[ rtmp["type"] ]
				if handler then
					local ret, error = handler(stream, rtmp)
					if error then
						return
					end
					if ret then
						n = n + ret
					end
				else
					log:warn("unhandled rtmp packet, type: ", info["type"])
				end
			end

		end

		if receivedBytes > nextAck then
			log:info("sending ack")
			sendRtmp(stream, 
					 string.char(0x02,                       -- chan 2, format 0
								 0x00, 0x00, 0x00,           -- timestamp (not implemented)
								 0x00, 0x00, 0x04,           -- length
								 0x03,                       -- type 0x03
								 0x00, 0x00, 0x00, 0x00,     -- streamId 0
								 (receivedBytes & 0xFF000000) >> 24,
								 (receivedBytes & 0x00FF0000) >> 16,
								 (receivedBytes & 0x0000FF00) >>  8,
								 (receivedBytes & 0x000000FF)
						 ))
			nextAck = nextAck + ackWindow
		end
		
	end

	return n

end


