local _ah = {
  isScanning = false
}

local addonInfo, Internal = ...

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

  _ah.isScanning = true;
  
  local params = {
    type = "search",
    index = 0,
    text = arg1
  }
  
  Command.Auction.Scan(params)
  
end

function _ah.ScanComplete(handle, criteria, auctions)
  
  if( criteria["type"] ~= "search" ) then
    return
  end    
  
  local itemTypes = {}
  
  for auctionID in pairs(auctions) do
      
    local details = Inspect.Auction.Detail(auctionID)
        
    itemTypes[details["itemType"]] = true;
         
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
  
  local result = {
    id = item.id,
    name = item.name,
    history = {}
  }
  
  local i = 1
  
  for k, stat in pairs(data) do
  
    local display = {
      date = os.date("%x", stat.time),
      average = stat.priceAverage,
      volume = stat.volume
    }
    
    result.history[i] = display
    
    i = i + 1
    
  end
  
  AuctionHistory_Prices[result.id] = result;
  
  if( _ah.isScanning == true ) then
    
    print(Utility.Serialize.Inline(result))
  
    _ah.isScanning = false
    
  end
  
end

Command.Console.Display("general", false, string.format("%s v%s loaded...", addonInfo.nameShort, addonInfo.toc.Version), false)

Command.Event.Attach(Command.Slash.Register("ah"), _ah.search, "List all achievements")
Command.Event.Attach(Event.Auction.Scan, _ah.ScanComplete, "Callback function when the auction scan is complete")
Command.Event.Attach(Event.Auction.Statistics, _ah.OnStatsComplete, "Callback function when the auction statistics call is complete")
Command.Event.Attach(Event.Addon.SavedVariables.Load.End, _ah.OnVariablesLoaded, "Callback function when the addon's saved variables have been loaded")