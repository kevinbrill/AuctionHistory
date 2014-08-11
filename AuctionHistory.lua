local _ah = {
}

function _ah.search(handle, args)
  
  args = string.trim(args)
  local arg1 = unpack(string.split(args, "%s+", true))
    
  if(#args <= 0) then
    Command.Console.Display("v0000000000000000", true, "Incorrect usage", true)
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
    text = arg1
  }
  
  _ah.searching = true
  
  Command.Auction.Scan(params)
  
end

function _ah.ScanComplete(handle, criteria, auctions)
  
  if( criteria["type"] ~= "search" ) then
    return
  end    
  
  local now = Inspect.Time.Server()
  local lastWeek = now - 604800  
  
  for auctionID in pairs(auctions) do
      
    local details = Inspect.Auction.Detail(auctionID)
        
    print(Utility.Serialize.Inline(details["itemType"]))
      
    local now = Inspect.Time.Server()
    local lastWeek = now - 604800
    
    Command.Auction.Analyze(details["itemType"], lastWeek, now)
    
  end

end

function _ah.OnStatsComplete(handle, itemType, data)
  
  --print(Utility.Serialize.Inline(data))
  
end

Command.Event.Attach(Command.Slash.Register("ah"), _ah.search, "List all achievements")
Command.Event.Attach(Event.Auction.Scan, _ah.ScanComplete, "Callback function when the auction scan is complete")
Command.Event.Attach(Event.Auction.Statistics, _ah.OnStatsComplete, "Callback function when the auction statistics call is complete")