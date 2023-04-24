addon.name = 'hgather';
addon.description = 'Simple dig tracker.';
addon.author = 'Hastega';
addon.version = '1.0.0';
addon.commands = {'/hgather'};

----------------------------------------------------------------------------------------------------
-- Variables
----------------------------------------------------------------------------------------------------
local common = require('common');
local imgui = require('imgui');
local settings = require('settings');
local ffi = require('ffi');
local d3d = require 'd3d8';
local d3d8dev   = d3d.get_device();

local ashitaResourceManager = AshitaCore:GetResourceManager();
local ashitaChatManager     = AshitaCore:GetChatManager();
local ashitaDataManager     = AshitaCore:GetMemoryManager();
local ashitaParty           = ashitaDataManager:GetParty();
local ashitaPlayer          = ashitaDataManager:GetPlayer();
local ashitaInventory       = ashitaDataManager:GetInventory();
local ashitaTarget          = ashitaDataManager:GetTarget();
local ashitaEntity          = ashitaDataManager:GetEntity();

hgather = T{
    open = false,
    isAttempt = false,
    numDigs = 0,
    numItems = 0,
    skillUp = 0.0,
    lastDig = os.time(),
    diggingRewards = { },
    pricing = { }
};

----------------------------------------------------------------------------------------------------
-- Helper Functions
----------------------------------------------------------------------------------------------------
function file_exists(file)
    local f = io.open(file, "rb")
    if f then f:close() end
    return f ~= nil
end
  
function lines_from(file)
    if not file_exists(file) then return {} end
    local lines = {}
    for line in io.lines(file) do 
      lines[#lines + 1] = line
    end
    return lines
end

function mysplit (inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

function updatePricing() 
    -- Grab Pricing
    local path = ('%saddons\\hgather\\%s.txt'):fmt(AshitaCore:GetInstallPath(), 'itempricing');
    local file = path
    local lines = lines_from(file)

    -- print all line numbers and their contents
    for k,v in pairs(lines) do
        for k2, v2 in pairs(mysplit(v, ':')) do
            if (k2 == 1) then
                itemname = v2
            end
            if (k2 == 2) then
                itemvalue = v2
            end
        end

        hgather.pricing[itemname] = itemvalue
    end
end

function reportSession()
    totalworth = 0
    accuracy = 0
    totalprofit = 0

    if (hgather.numDigs ~= 0) then
        accuracy = (hgather.numItems / hgather.numDigs) * 100
    end

    print('~~ Digging Session ~~')
    print("Attempted Digs: " + hgather.numDigs)
    print('Items Dug: ' + hgather.numItems)
    print('Dig Accuracy: ' + string.format('%.2f', accuracy) + '%%')
        
    print('~~ Digging Session ~~')
    print("Attempted Digs: " + hgather.numDigs)
    print('Items Dug: ' + hgather.numItems)
    --Only show skillup line if one was seen during session
    if (hgather.skillUp ~= 0.0) then
        print('Skillups: ' + string.format('%.1f', hgather.skillUp))
    end
    print('----------')

    for k,v in pairs(hgather.diggingRewards) do
        itemTotal = 0
        if (hgather.pricing[k] ~= nil) then
            totalworth = totalworth + hgather.pricing[k] * v
            itemTotal = v * hgather.pricing[k]
        end

        if (string.sub(k,1,9) == "chunk of ") then
            k = string.sub(k,10,-1)
        elseif (string.sub(k,1,11) == "handful of ") then
            k = string.sub(k,12,-1)
        end

        k = k:gsub("^%l", string.upper)
                
        print(k + ": " + "x" + v + " (" + itemTotal + "g)")
    end

    print('----------')
    print("Gil Made: " + totalworth + 'g')

    totalprofit = totalworth - hgather.numDigs*62

    print("Total Profit: " + totalprofit + "g")
end


----------------------------------------------------------------------------------------------------
-- Load Event
----------------------------------------------------------------------------------------------------
ashita.events.register('load', 'load_cb', function()
    updatePricing()
end)

----------------------------------------------------------------------------------------------------
-- Commands
----------------------------------------------------------------------------------------------------
ashita.events.register('text_out', 'text_out_callback1', function (e)
    if (not e.injected) then
        if (string.match(e.message, '/hgather reset')) then
            hgather.diggingRewards = { }
            hgather.isAttempt = 0
            hgather.numItems = 0
            hgather.skillUp = 0.0
            hgather.numDigs = 0
            print('HGather: Digging session has been reset')
        end
    end

    if (not e.injected) then
        if (string.match(e.message, '/hgather open')) then
            hgather.open = true;
            hgather.lastDig = os.time();
        end
    end

    if (not e.injected) then
        if (string.match(e.message, '/hgather close')) then
            hgather.open = false;
        end
    end

    if (not e.injected) then
        if (string.match(e.message, '/hgather update')) then
            updatePricing()
            print('HGather: Pricing has been Updated.')
        end
    end

    if (not e.injected) then
        if (string.match(e.message, '/hgather report')) then
            print('HGather: Reporting current session')
            reportSession()
        end
    end

    if (not e.injected) then
        if (string.match(e.message, '/hgather help')) then
            print('HGather: Commands are Open, Close, Reset, Update, Report, Help')
        end
    end
end);

----------------------------------------------------------------------------------------------------
-- Parse Digging Items + Main Logic
----------------------------------------------------------------------------------------------------
ashita.events.register('text_in', 'text_in_cb', function (e)
    lasttime = os.difftime(os.time(), hgather.lastDig);
    message = e.message;
    message = string.lower(message);
    message = string.strip_colors(message);

    success = string.match(message, "obtained: (.*).") or successBreak
    unable = string.contains(message, "you dig and you dig");
    skillUp = string.match(message, "skill increases by (.*) raising");
	
    -- only set isAttempt if we dug within last 15 seconds
    if ((success or unable) and lasttime < 15) then
        hgather.isAttempt = true
    else
        hgather.isAttempt = false
    end
   
    --skillup count
    if (skillUp) then
        hgather.skillUp = hgather.skillUp + skillUp;
    end

    if hgather.isAttempt then 
        successBreak = false;
        success = string.match(message, "obtained: (.*).") or successBreak
        unable = string.contains(message, "you dig and you dig");
        broken = false;
        lost = false;

        --keep window open
        if (unable or success) then
            hgather.open = true;
        end

        --count attempt
        if (unable) then 
            hgather.numDigs = hgather.numDigs + 1;
        end
        
        if success then
            --local of = string.match(success, "of (.*)");
            --if of then success = of; txt = of end;
            hgather.numItems = hgather.numItems + 1;
            hgather.numDigs = hgather.numDigs + 1;

            if (success ~= nil) then
                if (hgather.diggingRewards[success] == nil) then
                    hgather.diggingRewards[success] = 1
                elseif (hgather.diggingRewards[success] ~= nil) then
                    hgather.diggingRewards[success] = hgather.diggingRewards[success] + 1
                end
            end
        end
    end
end)

----------------------------------------------------------------------------------------------------
-- Digging Event
----------------------------------------------------------------------------------------------------
ashita.events.register('packet_out', 'packet_out_callback1', function (e)
    if e.id == 0x01A then -- digging
        if struct.unpack("H", e.data_modified, 0x0A) == 0x1104 then -- digging
            hgather.isAttempt = true;
            hgather.lastDig = os.time();
        end
    end
end)

----------------------------------------------------------------------------------------------------
-- GUI
----------------------------------------------------------------------------------------------------
ashita.events.register('d3d_present', 'present_cb', function () 
    lasttime = os.difftime(os.time(), hgather.lastDig);
    if (hgather.open == false) then
        return;
    end

    imgui.SetNextWindowBgAlpha(0.8);
    imgui.SetNextWindowSize({ 250, -1, }, ImGuiCond_Always);

    if (imgui.Begin('HasteGather', hgather.open, bit.bor(ImGuiWindowFlags_NoDecoration, ImGuiWindowFlags_AlwaysAutoResize, ImGuiWindowFlags_NoSavedSettings, ImGuiWindowFlags_NoFocusOnAppearing, ImGuiWindowFlags_NoNav))) then
        totalworth = 0
        accuracy = 0

        if (hgather.numDigs ~= 0) then
            accuracy = (hgather.numItems / hgather.numDigs) * 100
        end
        
        imgui.Text('~~ Digging Session ~~')
        imgui.Text("Attempted Digs: " + hgather.numDigs)
        imgui.Text('Items Dug: ' + hgather.numItems)
        imgui.Text('Dig Accuracy: ' + string.format('%.2f', accuracy) + '%%')
        --Only show skillup line if one was seen during session
        if (hgather.skillUp ~= 0.0) then
            imgui.Text('Skillups: ' + string.format('%.1f', hgather.skillUp))
        end
        imgui.Separator();

        for k,v in pairs(hgather.diggingRewards) do
            itemTotal = 0
            if (hgather.pricing[k] ~= nil) then
                totalworth = totalworth + hgather.pricing[k] * v
                itemTotal = v * hgather.pricing[k]
            end

            if (string.sub(k,1,9) == "chunk of ") then
                k = string.sub(k,10,-1)
            elseif (string.sub(k,1,11) == "handful of ") then
                k = string.sub(k,12,-1)
            end

            k = k:gsub("^%l", string.upper)

            imgui.Text(k + ": " + "x" + v + " (" + itemTotal + "g)")
        end

        imgui.Separator();
        imgui.Text("Gil Made: " + totalworth + 'g')

        totalprofit = totalworth - hgather.numDigs*62

        imgui.Text("Total Profit: " + totalprofit + "g")

        --List things gotten for digging session
    end

    --end session
    if (lasttime > 300) then
        imgui.End()
        hgather.open = false;
    end
end)
