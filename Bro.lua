local httpService=game:GetService('HttpService')

local SaveManager={} do
SaveManager.Folder='LinoriaLibSettings'
SaveManager.Ignore={}
SaveManager.Parser={
Toggle={
Save=function(idx, object) 
return { type='Toggle', idx=idx, value=object.Value } 
end,
Load=function(idx, data)
if Toggles[idx] then 
Toggles[idx]:SetValue(data.value)
end
end,
},
Slider={
Save=function(idx, object)
return { type='Slider', idx=idx, value=tostring(object.Value) }
end,
Load=function(idx, data)
if Options[idx] then 
Options[idx]:SetValue(data.value)
end
end,
},
Dropdown={
Save=function(idx, object)
return { type='Dropdown', idx=idx, value=object.Value, mutli=object.Multi }
end,
Load=function(idx, data)
if Options[idx] then 
Options[idx]:SetValue(data.value)
end
end,
},
ColorPicker={
Save=function(idx, object)
return { type='ColorPicker', idx=idx, value=object.Value:ToHex() }
end,
Load=function(idx, data)
if Options[idx] then 
Options[idx]:SetValueRGB(Color3.fromHex(data.value))
end
end,
},
KeyPicker={
Save=function(idx, object)
return { type='KeyPicker', idx=idx, mode=object.Mode, key=object.Value }
end,
Load=function(idx, data)
if Options[idx] then 
Options[idx]:SetValue({ data.key, data.mode })
end
end,
},

Input={
Save=function(idx, object)
return { type='Input', idx=idx, text=object.Value }
end,
Load=function(idx, data)
if Options[idx] and type(data.text) == 'string' then
Options[idx]:SetValue(data.text)
end
end,
},
}

function SaveManager:SetIgnoreIndexes(list)
for _, key in next, list do
self.Ignore[key]=true
end
end

function SaveManager:SetFolder(folder)
self.Folder=folder;
self:BuildFolderTree()
end

function SaveManager:Save(name)
local fullPath=self.Folder .. '/settings/' .. name .. '.json'

local data={
objects={}
}

for idx, toggle in next, Toggles do
if self.Ignore[idx] then continue end

table.insert(data.objects, self.Parser[toggle.Type].Save(idx, toggle))
end

for idx, option in next, Options do
if not self.Parser[option.Type] then continue end
if self.Ignore[idx] then continue end

table.insert(data.objects, self.Parser[option.Type].Save(idx, option))
end	

local success, encoded=pcall(httpService.JSONEncode, httpService, data)
if not success then
return false, 'failed to encode data'
end

writefile(fullPath, encoded)
return true
end

function SaveManager:Load(name)
local file=self.Folder .. '/settings/' .. name .. '.json'
if not isfile(file) then return false, 'invalid file' end

local success, decoded=pcall(httpService.JSONDecode, httpService, readfile(file))
if not success then return false, 'decode error' end

for _, option in next, decoded.objects do
if self.Parser[option.type] then
self.Parser[option.type].Load(option.idx, option)
end
end

return true
end

function SaveManager:IgnoreThemeSettings()
self:SetIgnoreIndexes({ 
"BackgroundColor", "MainColor", "AccentColor", "OutlineColor", "FontColor", -- themes
"ThemeManager_ThemeList", 'ThemeManager_CustomThemeList', 'ThemeManager_CustomThemeName', -- themes
})
end

function SaveManager:BuildFolderTree()
local paths={
self.Folder,
self.Folder .. '/themes',
self.Folder .. '/settings'
}

for i=1, #paths do
local str=paths[i]
if not isfolder(str) then
makefolder(str)
end
end
end

function SaveManager:RefreshConfigList()
local list=listfiles(self.Folder .. '/settings')

local out={}
for i=1, #list do
local file=list[i]
if file:sub(-5) == '.json' then
-- i hate this but it has to be done ...

local pos=file:find('.json', 1, true)
local start=pos

local char=file:sub(pos, pos)
while char~='/' and char ~= '\\' and char ~= '' do
pos=pos - 1
char=file:sub(pos, pos)
end

if char=='/' or char == '\\' then
table.insert(out, file:sub(pos + 1, start - 1))
end
end
end
		
return out
end

function SaveManager:SetLibrary(library)
self.Library=library
end

function SaveManager:LoadAutoloadConfig()
if isfile(self.Folder .. '/settings/autoload.txt') then
local name=readfile(self.Folder .. '/settings/autoload.txt')

local success, err=self:Load(name)
if not success then
return self.Library:Notify('Failed to load autoload config: ' .. err)
end

self.Library:Notify(string.format('Auto loaded config %q', name))
end
end


function SaveManager:BuildConfigSection(tab)
assert(self.Library, 'Must set SaveManager.Library')

local ServerandJob=tab:AddRightTabbox()
local Server=ServerandJob:AddTab('Server')
local Job=ServerandJob:AddTab('Server Job')

local xxx=Server:AddButton('Rejoin', function()
game:GetService("TeleportService"):Teleport(game.PlaceId, game:GetService("Players").LocalPlayer)
end)

local cxx1=xxx:AddButton('Hop Server', function()
Library:Notify('Hopping...')				
local PlaceID=game.PlaceId
local AllIDs={}
local foundAnything=""
local actualHour=os.date("!*t").hour
local Deleted=false
function tPO()
local Site;
if foundAnything=="" then
Site=game.HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. PlaceID .. '/servers/Public?sortOrder=Asc&limit=100'))
else
Site=game.HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. PlaceID .. '/servers/Public?sortOrder=Asc&limit=100&cursor=' .. foundAnything))
end
local ID=""
if Site.nextPageCursor and Site.nextPageCursor ~= "null" and Site.nextPageCursor ~= nil then
foundAnything=Site.nextPageCursor
end
local num=0;
for i,v in pairs(Site.data) do
local Possible=true
ID=tostring(v.id)
if tonumber(v.maxPlayers)>tonumber(v.playing) then
for _,Existing in pairs(AllIDs) do
if num~=0 then
if ID==tostring(Existing) then
Possible=false
end
else
if tonumber(actualHour) ~= tonumber(Existing) then
local delFile=pcall(function()
AllIDs={}
table.insert(AllIDs, actualHour)
end)
end
end
num=num + 1
end
if Possible==true then
table.insert(AllIDs, ID)
wait()
pcall(function()
wait()
game:GetService("TeleportService"):TeleportToPlaceInstance(PlaceID, ID, game.Players.LocalPlayer)
end)
wait(1)
end
end
end
end
function hOP() 
while wait() do
pcall(function()
tPO()
if foundAnything ~= "" then
tPO()
end
end)
end
end
hOP()
end)

Job:AddInput('IdJob', {
Text = 'Join Job',
Callback=function(v)
textjob = v
end
})
Options.IdJob:OnChanged(function(v)
textjob = v
end)
local joinjob1=Job:AddButton('Join Job', function()
game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, textjob, game.Players.LocalPlayer);
end)
local joinjob2=joinjob1:AddButton('Copy Job', function()
setclipboard(game.JobId)
end)

SaveManager:SetIgnoreIndexes({ 'SaveManager_ConfigList', 'SaveManager_ConfigName' })
end

SaveManager:BuildFolderTree()
end

return SaveManager
