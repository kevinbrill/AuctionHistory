local _ah = {
  totalScans = 0,
  addonInitiated = false,
  shard = ''
}

local addonInfo, Internal = ...

function getPriceHistory( item )
  
  local result = AuctionHistory_Prices[item.id]
  
  if( result == nil ) then
    
    result = {
      id = item.id,
      name = item.name,
      category = item.category,
      rarity = item.rarity,
      shards = {}
    }
      
  end
  
  if(result.shards[_ah.shard] == nil) then
    
    result.shards[_ah.shard] = {
      time = Inspect.Time.Server(),
      history = {}
    }
    
  end    
  
  return result
  
end

function _ah.OnVariablesLoaded(identifier)
    
  if(AuctionHistory_Prices == nil) then 
    AuctionHistory_Prices = {}
  end
  
end

function _ah.search(handle, args)
  
  args = string.trim(args)
  local arg1 = unpack(string.split(args, "%s+", true))
    
  if(#args <= 0) then
    Command.Console.Display("v0000000000000000", true, "Usage: /ah <search text>", false)
    return
  end
    
  local status = Inspect.Interaction("auction")
  
  if( status ~= true ) then
    Command.Console.Display("v0000000000000000", true, "Need to be at the auction", true)
    return
  end

  local params = {
    type = "search",
    index = 0,
    text = args
  }
  
  -- Pull the shard that the search was initially kicked off from
  _ah.shard = Inspect.Shard().name
  
  -- The addon initiated the scan.  Toggle the flag
  _ah.addonInitiated = true;
  
  Command.Auction.Scan(params)
  
end

function _ah.ScanComplete(handle, criteria, auctions)
  
  if( ( criteria["type"] ~= "search" ) or ( _ah.addonInitiated == false ) ) then
    return
  end    
  
  local itemTypes = {}
  
  _ah.totalScans = 0
  
  for auctionID in pairs(auctions) do
      
    -- Get the item detail for the current auction ID
    local details = Inspect.Auction.Detail(auctionID)
        
    -- Check to see if we've encountered this item type before
    if( itemTypes[details["itemType"]] == nil ) then
    
      -- We haven't.  Flag it for search and increment the number
      --  of items on which we're going to search
      itemTypes[details["itemType"]] = true;
    
      -- Increment the total number of stat calls to be made
      _ah.totalScans = _ah.totalScans + 1
    
    end
  
  end

  local now = Inspect.Time.Server()
  local lastWeek = now - 604800
          
  for key, value in pairs(itemTypes) do
    
    Command.Auction.Analyze(key, lastWeek, now)
    
  end
  
end

function _ah.OnStatsComplete(handle, itemType, data)
  
  -- Inspect the item to pull some useful information
  local item = Inspect.Item.Detail(itemType)
  
  local result = getPriceHistory(item)
  
  local i = 1
  
  for k, stat in pairs(data) do
  
    local display = {
      date = os.date("%x", stat.time),
      average = stat.priceAverage,
      volume = stat.volume
    }
    
    result.shards[_ah.shard].time = Inspect.Time.Server()
    result.shards[_ah.shard].history[i] = display
    
    i = i + 1
    
  end
  
  AuctionHistory_Prices[result.id] = result;
  
  if( _ah.totalScans <= 0 ) then
    return
  end
  
  Command.Console.Display("general", false, string.format("Collected price history for %s", result.name), false)
    
  _ah.totalScans = _ah.totalScans - 1
  
  -- Reset the addon initiated scan flag
  if( _ah.totalScans == 0 ) then
    
    _ah.addonInitiated = false
    
  end
  
end

Command.Console.Display("general", false, string.format("%s v%s loaded...", addonInfo.nameShort, addonInfo.toc.Version), false)

Command.Event.Attach(Command.Slash.Register("ah"), _ah.search, "List all achievements")
Command.Event.Attach(Event.Auction.Scan, _ah.ScanComplete, "Callback function when the auction scan is complete")
Command.Event.Attach(Event.Auction.Statistics, _ah.OnStatsComplete, "Callback function when the auction statistics call is complete")
Command.Event.Attach(Event.Addon.SavedVariables.Load.End, _ah.OnVariablesLoaded, "Callback function when the addon's saved variables have been loaded")