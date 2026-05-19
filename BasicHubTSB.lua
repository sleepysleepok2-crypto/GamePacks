--[[
    ================================================================
    [ SCRIPT INFORMATION ]
    Project: BasicHub - The Strongest Battlegrounds
    Key System: PlatoBoost (lootlabs / linkvertise)

    [ TERMS AND CONDITIONS ]
    - You ARE allowed to use and modify this script for your own games.
    - You ARE NOT allowed to re-upload, redistribute, or claim
      ownership of this script.

    Copyright (c) 2026 BasicHub. All rights reserved.
    ================================================================
]]

local Config = {
    -- [1] PlatoBoost Settings
    ServiceId       = 25252,
    PlatoSecret     = "fbf87ecf-7b6a-4825-af1f-ef465bf7894d",

    -- [2] Anti-Bypass / Global Secret Variable
    Secret          = "TSBCode1234",

    -- [3] Scripts & Links
    MainScriptURL   = "https://raw.githubusercontent.com/sleepysleepok2-crypto/GamePacks2/refs/heads/main/TSB.lua",

    -- [4] File System
    KeyFileName     = "TSBKeys.txt",

    -- [5] Hub Information & UI Text
    HubName         = "BasicHub",
    HubDescription  = "BasicHub | The Strongest Battlegrounds",
}

-------------------------------------------------------------------------------
--! LIBRARIES (JSON & CRYPTOGRAPHY) - DO NOT MODIFY
-------------------------------------------------------------------------------
local a=2^32;local b=a-1;local function c(d,e)local f,g=0,1;while d~=0 or e~=0 do local h,i=d%2,e%2;local j=(h+i)%2;f=f+j*g;d=math.floor(d/2)e=math.floor(e/2)g=g*2 end;return f%a end;local function k(d,e,l,...)local m;if e then d=d%a;e=e%a;m=c(d,e)if l then m=k(m,l,...)end;return m elseif d then return d%a else return 0 end end;local function n(d,e,l,...)local m;if e then d=d%a;e=e%a;m=(d+e-c(d,e))/2;if l then m=n(m,l,...)end;return m elseif d then return d%a else return b end end;local function o(p)return b-p end;local function q(d,r)if r<0 then return lshift(d,-r)end;return math.floor(d%2^32/2^r)end;local function s(p,r)if r>31 or r<-31 then return 0 end;return q(p%a,r)end;local function lshift(d,r)if r<0 then return s(d,-r)end;return d*2^r%2^32 end;local function t(p,r)p=p%a;r=r%32;local u=n(p,2^r-1)return s(p,r)+lshift(u,32-r)end;local v={0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2}local function w(x)return string.gsub(x,".",function(l)return string.format("%02x",string.byte(l))end)end;local function y(z,A)local x=""for B=1,A do local C=z%256;x=string.char(C)..x;z=(z-C)/256 end;return x end;local function D(x,B)local A=0;for B=B,B+3 do A=A*256+string.byte(x,B)end;return A end;local function E(F,G)local H=64-(G+9)%64;G=y(8*G,8)F=F.."\128"..string.rep("\0",H)..G;assert(#F%64==0)return F end;local function I(J)J[1]=0x6a09e667;J[2]=0xbb67ae85;J[3]=0x3c6ef372;J[4]=0xa54ff53a;J[5]=0x510e527f;J[6]=0x9b05688c;J[7]=0x1f83d9ab;J[8]=0x5be0cd19;return J end;local function K(F,B,J)local L={}for M=1,16 do L[M]=D(F,B+(M-1)*4)end;for M=17,64 do local N=L[M-15]local O=k(t(N,7),t(N,18),s(N,3))N=L[M-2]L[M]=(L[M-16]+O+L[M-7]+k(t(N,17),t(N,19),s(N,10)))%a end;local d,e,l,P,Q,R,S,T=J[1],J[2],J[3],J[4],J[5],J[6],J[7],J[8]for B=1,64 do local O=k(t(d,2),t(d,13),t(d,22))local U=k(n(d,e),n(d,l),n(e,l))local V=(O+U)%a;local W=k(t(Q,6),t(Q,11),t(Q,25))local X=k(n(Q,R),n(o(Q),S))local Y=(T+W+X+v[B]+L[B])%a;T=S;S=R;R=Q;Q=(P+Y)%a;P=l;l=e;e=d;d=(Y+V)%a end;J[1]=(J[1]+d)%a;J[2]=(J[2]+e)%a;J[3]=(J[3]+l)%a;J[4]=(J[4]+P)%a;J[5]=(J[5]+Q)%a;J[6]=(J[6]+R)%a;J[7]=(J[7]+S)%a;J[8]=(J[8]+T)%a end;local function Z(F)F=E(F,#F)local J=I({})for B=1,#F,64 do K(F,B,J)end;return w(y(J[1],4)..y(J[2],4)..y(J[3],4)..y(J[4],4)..y(J[5],4)..y(J[6],4)..y(J[7],4)..y(J[8],4))end;local e;local l={["\\"]="\\",["\""]="\"",["\b"]="b",["\f"]="f",["\n"]="n",["\r"]="r",["\t"]="t"}local P={["/"]="/"}for Q,R in pairs(l)do P[R]=Q end;local S=function(T)return"\\"..(l[T]or string.format("u%04x",T:byte()))end;local B=function(M)return"null"end;local v=function(M,z)local _={}z=z or{}if z[M]then error("circular reference")end;z[M]=true;if rawget(M,1)~=nil or next(M)==nil then local A=0;for Q in pairs(M)do if type(Q)~="number"then error("invalid table: mixed or invalid key types")end;A=A+1 end;if A~=#M then error("invalid table: sparse array")end;for a0,R in ipairs(M)do table.insert(_,e(R,z))end;z[M]=nil;return"["..table.concat(_,",").."]"else for Q,R in pairs(M)do if type(Q)~="string"then error("invalid table: mixed or invalid key types")end;table.insert(_,e(Q,z)..":"..e(R,z))end;z[M]=nil;return"{"..table.concat(_,",").."}"end end;local g=function(M)return'"'..M:gsub('[%z\1-\31\\\"]',S)..'"'end;local a1=function(M)if M~=M or M<=-math.huge or M>=math.huge then error("unexpected number value '"..tostring(M).."'")end;return string.format("%.14g",M)end;local j={["nil"]=B,["table"]=v,["string"]=g,["number"]=a1,["boolean"]=tostring}e=function(M,z)local x=type(M)local a2=j[x]if a2 then return a2(M,z)end;error("unexpected type '"..x.."'")end;local a3=function(M)return e(M)end;local a4;local N=function(...)local _={}for a0=1,select("#",...)do _[select(a0,...)]=true end;return _ end;local L=N(" ","\t","\r","\n")local p=N(" ","\t","\r","\n","]","}",",")local a5=N("\\","/",'"',"b","f","n","r","t","u")local m=N("true","false","null")local a6={["true"]=true,["false"]=false,["null"]=nil}local a7=function(a8,a9,aa,ab)for a0=a9,#a8 do if aa[a8:sub(a0,a0)]~=ab then return a0 end end;return#a8+1 end;local ac=function(a8,a9,J)local ad=1;local ae=1;for a0=1,a9-1 do ae=ae+1;if a8:sub(a0,a0)=="\n"then ad=ad+1;ae=1 end end;error(string.format("%s at line %d col %d",J,ad,ae))end;local af=function(A)local a2=math.floor;if A<=0x7f then return string.char(A)elseif A<=0x7ff then return string.char(a2(A/64)+192,A%64+128)elseif A<=0xffff then return string.char(a2(A/4096)+224,a2(A%4096/64)+128,A%64+128)elseif A<=0x10ffff then return string.char(a2(A/262144)+240,a2(A%262144/4096)+128,a2(A%4096/64)+128,A%64+128)end;error(string.format("invalid unicode codepoint '%x'",A))end;local ag=function(ah)local ai=tonumber(ah:sub(1,4),16)local aj=tonumber(ah:sub(7,10),16)if aj then return af((ai-0xd800)*0x400+aj-0xdc00+0x10000)else return af(ai)end end;local ak=function(a8,a0)local _=""local al=a0+1;local Q=al;while al<=#a8 do local am=a8:byte(al)if am<32 then ac(a8,al,"control character in string")elseif am==92 then _=_..a8:sub(Q,al-1)al=al+1;local T=a8:sub(al,al)if T=="u"then local an=a8:match("^[dD][89aAbB]%x%x\\u%x%x%x%x",al+1)or a8:match("^%x%x%x%x",al+1)or ac(a8,al-1,"invalid unicode escape in string")_=_..ag(an)al=al+#an else if not a5[T]then ac(a8,al-1,"invalid escape char '"..T.."' in string")end;_=_..P[T]end;Q=al+1 elseif am==34 then _=_..a8:sub(Q,al-1)return _,al+1 end;al=al+1 end;ac(a8,a0,"expected closing quote for string")end;local ao=function(a8,a0)local am=a7(a8,a0,p)local ah=a8:sub(a0,am-1)local A=tonumber(ah)if not A then ac(a8,a0,"invalid number '"..ah.."'")end;return A,am end;local ap=function(a8,a0)local am=a7(a8,a0,p)local aq=a8:sub(a0,am-1)if not m[aq]then ac(a8,a0,"invalid literal '"..aq.."'")end;return a6[aq],am end;local ar=function(a8,a0)local _={}local A=1;a0=a0+1;while 1 do local am;a0=a7(a8,a0,L,true)if a8:sub(a0,a0)=="]"then a0=a0+1;break end;am,a0=a4(a8,a0)_[A]=am;A=A+1;a0=a7(a8,a0,L,true)local as=a8:sub(a0,a0)a0=a0+1;if as=="]"then break end;if as~=","then ac(a8,a0,"expected ']' or ','")end end;return _,a0 end;local at=function(a8,a0)local _={}a0=a0+1;while 1 do local au,M;a0=a7(a8,a0,L,true)if a8:sub(a0,a0)=="}"then a0=a0+1;break end;if a8:sub(a0,a0)~='"'then ac(a8,a0,"expected string for key")end;au,a0=a4(a8,a0)a0=a7(a8,a0,L,true)if a8:sub(a0,a0)~=":"then ac(a8,a0,"expected ':' after key")end;a0=a7(a8,a0+1,L,true)M,a0=a4(a8,a0)_[au]=M;a0=a7(a8,a0,L,true)local as=a8:sub(a0,a0)a0=a0+1;if as=="}"then break end;if as~=","then ac(a8,a0,"expected '}' or ','")end end;return _,a0 end;local av={['"']=ak,["0"]=ao,["1"]=ao,["2"]=ao,["3"]=ao,["4"]=ao,["5"]=ao,["6"]=ao,["7"]=ao,["8"]=ao,["9"]=ao,["-"]=ao,["t"]=ap,["f"]=ap,["n"]=ap,["["]=ar,["{"]=at}a4=function(a8,a9)local as=a8:sub(a9,a9)local a2=av[as]if a2 then return a2(a8,a9)end;ac(a8,a9,"unexpected character '"..as.."'")end;local aw=function(a8)if type(a8)~="string"then error("expected argument of type string, got "..type(a8))end;local _,a9=a4(a8,a7(a8,1,L,true))a9=a7(a8,a9,L,true)if a9<=#a8 then ac(a8,a9,"trailing garbage")end;return _ end;
local lEncode, lDecode, lDigest = a3, aw, Z

-------------------------------------------------------------------------------
--! CORE FUNCTIONS  (HTTP helper & PlatoBoost API)
-------------------------------------------------------------------------------

local useNonce = true

local function safeRequest(options)
    local req = request or http_request or syn_request or (http and http.request)
    if not req then return nil, "HTTP requests not supported" end
    local success, response = pcall(function() return req(options) end)
    if success and response then return response else return nil, "Connection Error" end
end

local fSetClipboard  = setclipboard or toclipboard or function() end
local fStringChar    = string.char
local fToString      = tostring
local fOsTime        = os.time
local fMathRandom    = math.random
local fMathFloor     = math.floor
local fGetHwid       = gethwid or function()
    return game:GetService("RbxAnalyticsService"):GetClientId()
end

local cachedLink, cachedTime = "", 0
local host = "https://api.platoboost.com"

local function checkConnectivity()
    local response = safeRequest({ Url = host .. "/public/connectivity", Method = "GET" })
    if not response or (response.StatusCode ~= 200 and response.StatusCode ~= 429) then
        host = "https://api.platoboost.net"
    end
end
checkConnectivity()

local function generateNonce()
    local str = ""
    for _ = 1, 16 do
        str = str .. fStringChar(fMathFloor(fMathRandom() * (122 - 97 + 1)) + 97)
    end
    return str
end

-- forceRefresh=true → bypass cache and always fetch a fresh lootlabs link
-- Retries up to 3 times with 1-second delay between attempts
local function cacheLink(forceRefresh)
    if forceRefresh or cachedTime + (10 * 60) < fOsTime() then
        local lastErr = "Server Unreachable"
        for attempt = 1, 3 do
            local response, err = safeRequest({
                Url     = host .. "/public/start",
                Method  = "POST",
                Body    = lEncode({ service = Config.ServiceId, identifier = lDigest(fGetHwid()) }),
                Headers = { ["Content-Type"] = "application/json" },
            })
            if response and response.StatusCode == 200 then
                local decoded = lDecode(response.Body)
                if decoded and decoded.success then
                    cachedLink = decoded.data.url
                    cachedTime = fOsTime()
                    return true, cachedLink
                end
                lastErr = (decoded and decoded.message) or "Bad Response"
            else
                lastErr = err or ("HTTP " .. fToString(response and response.StatusCode or "?"))
            end
            if attempt < 3 then task.wait(1) end
        end
        return false, lastErr
    end
    return true, cachedLink
end

local function redeemKey(key)
    local nonce = generateNonce()
    local body  = { identifier = lDigest(fGetHwid()), key = key }
    if useNonce then body.nonce = nonce end

    local response, err = safeRequest({
        Url     = host .. "/public/redeem/" .. fToString(Config.ServiceId),
        Method  = "POST",
        Body    = lEncode(body),
        Headers = { ["Content-Type"] = "application/json" },
    })

    if response and response.StatusCode == 200 then
        local decoded = lDecode(response.Body)
        if decoded.success and decoded.data.valid then
            if useNonce then
                if decoded.data.hash == lDigest("true" .. "-" .. nonce .. "-" .. Config.PlatoSecret) then
                    if writefile then writefile(Config.KeyFileName, key) end
                    return true, "Success"
                end
                return false, "Integrity Check Failed"
            end
            if writefile then writefile(Config.KeyFileName, key) end
            return true, "Success"
        end
        return false, decoded.message or "Invalid Key"
    end
    return false, err or "Server Error"
end

-------------------------------------------------------------------------------
--! MAIN SCRIPT EXECUTION
-------------------------------------------------------------------------------

local function StartMainScript()
    _G[Config.Secret] = true
    local ok, src = pcall(function() return game:HttpGet(Config.MainScriptURL) end)
    if not ok or not src or #src < 10 then
        warn("[BasicHub] Failed to download TSB.lua: " .. tostring(src))
        return
    end
    local fn, lerr = loadstring(src)
    if not fn then
        warn("[BasicHub] TSB.lua syntax error: " .. tostring(lerr))
        return
    end
    local runOk, runErr = pcall(fn)
    if not runOk then
        warn("[BasicHub] TSB.lua runtime error: " .. tostring(runErr))
    end
end

-------------------------------------------------------------------------------
--! KEY SYSTEM GUI  (custom dark theme, same style as BasicHub main GUI)
-------------------------------------------------------------------------------

local function CreateGUI()
    local coreGui = game:GetService("CoreGui")
    local player  = game:GetService("Players").LocalPlayer
    local UIS     = game:GetService("UserInputService")
    local TS      = game:GetService("TweenService")

    -- ── ScreenGui ─────────────────────────────────────────────────────────────
    local guiRoot
    -- 1) gethui()
    pcall(function()
        if type(gethui) == "function" then
            local sg = Instance.new("ScreenGui")
            sg.Name         = "BasicHub_KeySystem"
            sg.ResetOnSpawn = false
            sg.Parent       = gethui()
            guiRoot         = sg
        end
    end)
    -- 2) CoreGui
    if not guiRoot then
        pcall(function()
            local sg = Instance.new("ScreenGui")
            sg.Name         = "BasicHub_KeySystem"
            sg.ResetOnSpawn = false
            sg.Parent       = coreGui
            guiRoot         = sg
        end)
    end
    -- 3) PlayerGui
    if not guiRoot then
        pcall(function()
            local sg = Instance.new("ScreenGui")
            sg.Name         = "BasicHub_KeySystem"
            sg.ResetOnSpawn = false
            sg.Parent       = player:WaitForChild("PlayerGui")
            guiRoot         = sg
        end)
    end

    -- Colours (matching TSB.lua custom GUI)
    local C_BG      = Color3.fromRGB(18,  18,  22 )
    local C_TOP_BG  = Color3.fromRGB(22,  22,  28 )
    local C_ELEM_BG = Color3.fromRGB(28,  28,  34 )
    local C_INPUT   = Color3.fromRGB(13,  13,  17 )
    local C_TEXT    = Color3.fromRGB(228, 228, 240)
    local C_SUB     = Color3.fromRGB(150, 150, 168)
    local C_ACCENT  = Color3.fromRGB(0,   170, 255)
    local C_BTN_OK  = Color3.fromRGB(0,   140, 255)
    local C_BTN_ALT = Color3.fromRGB(32,  32,  44 )
    local C_RED     = Color3.fromRGB(255, 70,  70 )
    local C_GREEN   = Color3.fromRGB(0,   210, 100)

    -- ── Main frame ────────────────────────────────────────────────────────────
    local Main = Instance.new("Frame", guiRoot)
    Main.Name             = "MainFrame"
    Main.Size             = UDim2.new(0, 340, 0, 246)
    Main.Position         = UDim2.new(0.5, -170, 0.5, -123)
    Main.BackgroundColor3 = C_BG
    Main.BorderSizePixel  = 0
    Main.Active           = true
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

    -- Rainbow border
    local stroke = Instance.new("UIStroke", Main)
    stroke.Thickness       = 2
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.LineJoinMode    = Enum.LineJoinMode.Round
    task.spawn(function()
        local hue = 0
        while Main.Parent do
            hue = (hue + 0.002) % 1
            stroke.Color = Color3.fromHSV(hue, 1, 1)
            task.wait()
        end
    end)

    -- Drag
    local dragging, dragStart, dragBase = false, nil, nil
    Main.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = inp.Position
            dragBase  = Main.Position
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local d = inp.Position - dragStart
            Main.Position = UDim2.new(dragBase.X.Scale, dragBase.X.Offset + d.X,
                                      dragBase.Y.Scale, dragBase.Y.Offset + d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    -- ── Top bar ───────────────────────────────────────────────────────────────
    local TopBar = Instance.new("Frame", Main)
    TopBar.Size             = UDim2.new(1, 0, 0, 42)
    TopBar.BackgroundColor3 = C_TOP_BG
    TopBar.BorderSizePixel  = 0
    Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 12)
    local topPatch = Instance.new("Frame", TopBar)
    topPatch.Size             = UDim2.new(1, 0, 0.5, 0)
    topPatch.Position         = UDim2.new(0, 0, 0.5, 0)
    topPatch.BackgroundColor3 = C_TOP_BG
    topPatch.BorderSizePixel  = 0

    local titleLbl = Instance.new("TextLabel", TopBar)
    titleLbl.Size                   = UDim2.new(1, -44, 1, 0)
    titleLbl.Position               = UDim2.new(0, 12, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text                   = Config.HubName
    titleLbl.TextColor3             = C_ACCENT
    titleLbl.Font                   = Enum.Font.GothamBold
    titleLbl.TextSize               = 15
    titleLbl.TextXAlignment         = Enum.TextXAlignment.Left

    local closeBtn = Instance.new("TextButton", TopBar)
    closeBtn.Size              = UDim2.new(0, 26, 0, 26)
    closeBtn.Position          = UDim2.new(1, -32, 0.5, -13)
    closeBtn.BackgroundColor3  = Color3.fromRGB(180, 40, 40)
    closeBtn.Text              = "✕"
    closeBtn.TextColor3        = Color3.fromRGB(255, 255, 255)
    closeBtn.Font              = Enum.Font.GothamBold
    closeBtn.TextSize          = 11
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
    closeBtn.MouseButton1Click:Connect(function() guiRoot:Destroy() end)

    -- ── Description ───────────────────────────────────────────────────────────
    local descLbl = Instance.new("TextLabel", Main)
    descLbl.Size                   = UDim2.new(1, -20, 0, 22)
    descLbl.Position               = UDim2.new(0, 10, 0, 46)
    descLbl.BackgroundTransparency = 1
    descLbl.Text                   = Config.HubDescription
    descLbl.TextColor3             = C_SUB
    descLbl.Font                   = Enum.Font.Gotham
    descLbl.TextSize               = 12
    descLbl.TextXAlignment         = Enum.TextXAlignment.Center

    -- ── Key input ─────────────────────────────────────────────────────────────
    local inputHolder = Instance.new("Frame", Main)
    inputHolder.Size             = UDim2.new(0.88, 0, 0, 36)
    inputHolder.Position         = UDim2.new(0.06, 0, 0, 76)
    inputHolder.BackgroundColor3 = C_INPUT
    inputHolder.BorderSizePixel  = 0
    Instance.new("UICorner", inputHolder).CornerRadius = UDim.new(0, 7)
    local inputStroke = Instance.new("UIStroke", inputHolder)
    inputStroke.Thickness = 1
    inputStroke.Color     = Color3.fromRGB(46, 46, 62)

    local keyInput = Instance.new("TextBox", inputHolder)
    keyInput.Size                   = UDim2.new(1, -12, 1, 0)
    keyInput.Position               = UDim2.new(0, 6, 0, 0)
    keyInput.BackgroundTransparency = 1
    keyInput.Text                   = ""
    keyInput.PlaceholderText        = "Enter key..."
    keyInput.PlaceholderColor3      = Color3.fromRGB(80, 80, 100)
    keyInput.TextColor3             = C_TEXT
    keyInput.Font                   = Enum.Font.Gotham
    keyInput.TextSize               = 13
    keyInput.ClearTextOnFocus       = false
    keyInput.TextXAlignment         = Enum.TextXAlignment.Left
    keyInput.Focused:Connect(function()
        TS:Create(inputStroke, TweenInfo.new(0.15), { Color = C_ACCENT }):Play()
    end)
    keyInput.FocusLost:Connect(function()
        TS:Create(inputStroke, TweenInfo.new(0.15), { Color = Color3.fromRGB(46, 46, 62) }):Play()
    end)

    -- ── Buttons ───────────────────────────────────────────────────────────────
    local verifyBtn = Instance.new("TextButton", Main)
    verifyBtn.Size             = UDim2.new(0.42, 0, 0, 34)
    verifyBtn.Position         = UDim2.new(0.06, 0, 0, 122)
    verifyBtn.BackgroundColor3 = C_BTN_OK
    verifyBtn.Text             = "VERIFY"
    verifyBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
    verifyBtn.Font             = Enum.Font.GothamBold
    verifyBtn.TextSize         = 13
    Instance.new("UICorner", verifyBtn).CornerRadius = UDim.new(0, 7)

    local getKeyBtn = Instance.new("TextButton", Main)
    getKeyBtn.Size             = UDim2.new(0.42, 0, 0, 34)
    getKeyBtn.Position         = UDim2.new(0.52, 0, 0, 122)
    getKeyBtn.BackgroundColor3 = C_BTN_ALT
    getKeyBtn.Text             = "GET KEY"
    getKeyBtn.TextColor3       = C_TEXT
    getKeyBtn.Font             = Enum.Font.GothamBold
    getKeyBtn.TextSize         = 13
    Instance.new("UICorner", getKeyBtn).CornerRadius = UDim.new(0, 7)

    -- ── Status ────────────────────────────────────────────────────────────────
    local statusLbl = Instance.new("TextLabel", Main)
    statusLbl.Name                   = "StatusLabel"
    statusLbl.Size                   = UDim2.new(1, -20, 0, 24)
    statusLbl.Position               = UDim2.new(0, 10, 0, 165)
    statusLbl.BackgroundTransparency = 1
    statusLbl.Text                   = "Waiting for input..."
    statusLbl.TextColor3             = C_SUB
    statusLbl.Font                   = Enum.Font.Gotham
    statusLbl.TextSize               = 12
    statusLbl.TextXAlignment         = Enum.TextXAlignment.Center

    -- ── Info note ─────────────────────────────────────────────────────────────
    local infoLbl = Instance.new("TextLabel", Main)
    infoLbl.Size                   = UDim2.new(1, -20, 0, 18)
    infoLbl.Position               = UDim2.new(0, 10, 0, 194)
    infoLbl.BackgroundTransparency = 1
    infoLbl.Text                   = "Key is saved locally. Click GET KEY to complete the lootlabs link."
    infoLbl.TextColor3             = Color3.fromRGB(70, 70, 88)
    infoLbl.Font                   = Enum.Font.Gotham
    infoLbl.TextSize               = 10
    infoLbl.TextXAlignment         = Enum.TextXAlignment.Center
    infoLbl.TextWrapped            = true

    -- ── Hover effects ─────────────────────────────────────────────────────────
    verifyBtn.MouseEnter:Connect(function()
        TS:Create(verifyBtn, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(0, 160, 255) }):Play()
    end)
    verifyBtn.MouseLeave:Connect(function()
        TS:Create(verifyBtn, TweenInfo.new(0.1), { BackgroundColor3 = C_BTN_OK }):Play()
    end)
    getKeyBtn.MouseEnter:Connect(function()
        TS:Create(getKeyBtn, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(42, 42, 58) }):Play()
    end)
    getKeyBtn.MouseLeave:Connect(function()
        TS:Create(getKeyBtn, TweenInfo.new(0.1), { BackgroundColor3 = C_BTN_ALT }):Play()
    end)

    -- ── Logic ─────────────────────────────────────────────────────────────────
    local function setStatus(text, color)
        statusLbl.Text       = text
        statusLbl.TextColor3 = color or C_SUB
    end

    local function doVerify(key)
        setStatus("Verifying...", C_SUB)
        verifyBtn.Active  = false
        getKeyBtn.Active  = false
        task.spawn(function()
            local success, msg = redeemKey(key)
            verifyBtn.Active = true
            getKeyBtn.Active = true
            if success then
                setStatus("Key accepted! Loading...", C_GREEN)
                task.wait(0.5)
                guiRoot:Destroy()
                StartMainScript()
            else
                setStatus(tostring(msg), C_RED)
            end
        end)
    end

    verifyBtn.MouseButton1Click:Connect(function()
        local key = keyInput.Text
        if key == "" then
            setStatus("Enter a key first!", Color3.fromRGB(255, 180, 0))
            return
        end
        doVerify(key)
    end)

    getKeyBtn.MouseButton1Click:Connect(function()
        setStatus("Fetching link...", C_SUB)
        getKeyBtn.Active = false
        task.spawn(function()
            local success, link = cacheLink(true)
            getKeyBtn.Active = true
            if success then
                fSetClipboard(link)
                setStatus("Link copied to clipboard!", C_GREEN)
            else
                setStatus("Failed: " .. tostring(link), C_RED)
            end
        end)
    end)

    -- Auto-login from saved key
    if isfile and isfile(Config.KeyFileName) then
        local ok2, savedKey = pcall(readfile, Config.KeyFileName)
        if ok2 and savedKey and savedKey:gsub("%s+", "") ~= "" then
            setStatus("Found saved key, verifying...", C_SUB)
            doVerify(savedKey)
        end
    end
end

-------------------------------------------------------------------------------
-- ENTRY POINT
-------------------------------------------------------------------------------
CreateGUI()
