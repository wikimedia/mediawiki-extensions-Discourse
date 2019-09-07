local discourse = {}
local php

function discourse.setupInterface( options )
	-- Remove setup function.
	discourse.setupInterface = nil

	-- Copy the PHP callbacks to a local variable, and remove the global.
	php = mw_interface
	mw_interface = nil

	-- Install into the mw global.
	mw = mw or {}
	mw.ext = mw.ext or {}
	mw.ext.discourse = discourse

	-- Indicate that we're loaded.
	package.loaded['mw.ext.discourse'] = discourse
end

-- --
-- Get data from a Discourse site.
-- @param string site Site name, from $wgDiscourseSites.
-- @param string urlPath The URL path of a JSON endpoint.
-- @return table Whatever is returned by the Discourse API.
-- --
function discourse.getData( site, urlPath )
	return php.getData( site, urlPath );
end

-- --
-- Get the base URL of a given Discourse site.
-- @param string site Site name, from $wgDiscourseSites.
-- @return table With 'result' key.
-- --
function discourse.getBaseUrl( site )
	return php.getBaseUrl( site );
end

-- --
-- Basic list of recent posts, optionally filtered by tags or category.
-- @return string Wikitext.
-- --
function discourse.news( frame )
	local args = frame.args

	-- Construct the URL path.
	local urlPath = 'latest.json'
	local tags = {}
	if args.tags ~= nil then
		tags = mw.text.split( args.tags, ',', true )
	end
	if args.category then
		urlPath = '/c/' .. args.category .. '.json'
		if args.tags then
			urlPath = urlPath .. '?tags=' .. args.tags
		end
	elseif args.category == nil and #tags == 1 then
		urlPath = '/tags/' .. table.concat( tags ) .. '.json'
	elseif args.category == nil and #tags > 1 then
		urlPath = '/tags/intersection/' .. table.concat( tags, '/' ) .. '.json'
	end

	-- Get the data.
	local baseUrl = discourse.getBaseUrl( frame.args.site )
	local data = discourse.getData( frame.args.site, urlPath )

	-- Construct the output wikitext.
	local outHtml = mw.html.create( 'ol' )
	outHtml:addClass( 'ext-discourse' )
	for _, topic in pairs( data.topic_list.topics ) do
		local li = mw.html.create( 'li' )
		-- Make an external link, escaping right square brackets in the title because these end the link.
		li:wikitext( '[' .. baseUrl .. '/t/' .. topic.id .. ' ' .. string.gsub( topic.title, ']', '&#93;' ) .. ']' )
		outHtml:node( li )
	end
	return outHtml
end

-- --
-- List coming events, optionally filtered by tag.
-- --
function discourse.events( frame )
	local args = frame.args
	local lang = mw.getContentLanguage()
	local urlPath = 'c/events/l/calendar.json?start=' .. lang:formatDate( 'Y-m-d' )
	if args.tags ~= nil and args.tags ~= '' then
		urlPath = urlPath .. '&tags=' .. args.tags
	end

	-- Get the data.
	local baseUrl = discourse.getBaseUrl( frame.args.site )
	local data = discourse.getData( frame.args.site, urlPath )
	if not baseUrl or not data.topic_list then
		return mw.html.create( 'p' )
			:addClass( 'error' )
			:wikitext( 'Unable to get data for site "' .. frame.args.site .. '" with URL path: <code>' .. urlPath .. '</code>' )
	end

	-- Rearrange data and discard past events.
	local topics = {}
	local topicKeys = {}
	for _, topic in pairs( data.topic_list.topics ) do
		-- @TODO The API shouldn't be returning things outside our requested range, but it is.
		local startTimestamp = lang:formatDate( 'U', topic.event['start'] )
		local endTimestamp = lang:formatDate( 'U', topic.event['end'] )
		local today = lang:formatDate( 'U' )
		if startTimestamp >= today or ( topic.event['end'] and endTimestamp >= today ) then
			-- Only include ongoing or future events.
			local sortKey = topic.event.start .. topic.id
			topics[ sortKey ] = topic
			table.insert( topicKeys, sortKey )
		end
	end
	table.sort( topicKeys )

	-- Construct the output wikitext.
	local outHtml = mw.html.create( 'ol' )
	outHtml:addClass( 'ext-discourse ' )
	for _, sortKey in pairs( topicKeys ) do
		local topic = topics[ sortKey ]
		local startDate =  lang:formatDate( 'F j H:i', topic.event.start )
		local endTime = ''
		if topic.event['end'] then
			endTime = ' &ndash; ' .. lang:formatDate( 'H:i', topic.event['end'] )
		end
		local going = ''
		if topic.event.going ~= nil and #topic.event.going > 0 then
			going = mw.message.new( 'discourse-going-count' ):params( #topic.event.going ):plain()
		end

		local li = mw.html.create( 'li' )
		li:wikitext( startDate .. endTime .. ' [' .. baseUrl .. '/t/' .. topic.id .. ' ' .. topic.title .. '] ' .. going )
		outHtml:node( li )
	end
	return outHtml
end

return discourse
