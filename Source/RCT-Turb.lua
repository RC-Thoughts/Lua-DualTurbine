--[[
	---------------------------------------------------------
    RCT-Turbine is a app working with RPM-difference when two
    engines are used.
    
    Possible to use alarms for left and right turbine. Alarm
    is played as audiofile if one turbine's rpm is lower than
    the other with more than user-definied limit allows.
    
    Alarm-function enabled with a switch, good example is
    flight mode so alarms are active only in air.
    
    RCT-Turbines works in DC/DS-24 and requires 
    firmware 4.22 or up.   
	---------------------------------------------------------
	Localisation-file has to be as /Apps/Lang/RCT-Turb.jsn
	---------------------------------------------------------
	RCT-Turbine is part of RC-Thoughts Jeti Tools.
	---------------------------------------------------------
	Released under MIT-license by Tero @ RC-Thoughts.com 2017
	---------------------------------------------------------
--]]
collectgarbage()
--------------------------------------------------------------------------------
-- Locals for application
local sensRpmIdL, sensRpmId12, sensRpmPaL, sensRpmPaR, enableAlarm = 0, 0
local curRpmL, curRpmR, curDiff, diffTriggered, multi = 0, 0, 0, false, 1
local curTime, playTime, playDone, alarmFileL, alarmFileR = 0, 0, false
local maxDiff, maxDiffTrue, idleRpm, maxRpm, almSwitch = 0, 0, 0, 0
local sensorsAvailable, runL, runR, checkIndex = {"..."}, false, false
--------------------------------------------------------------------------------
local function dispTurbine()
    -- Set display colors based on display colors
    local txtr,txtg,txtb
    local bgr,bgg,bgb = lcd.getBgColor()
    if (bgr+bgg+bgb)/3 >128 then
        txtr,txtg,txtb = 0,0,0
        else
        txtr,txtg,txtb = 255,255,255
    end
    -- Draw bargraphs frames
    lcd.drawRectangle(1,2,148,9)
    lcd.drawRectangle(1,12,148,9)
    -- Draw bargraph frames based on range
    -- Left turbine
    -- If alarm is active and left rpm is lower set left bar color to red
    if(diffTriggered and curRpmL < curRpmR) then
        lcd.setColor(240,0,0)
        else
        lcd.setColor(0,196,0)
    end
    if(runL) then
        local leftBar = string.format("%.0f", 146 / 100 * (((curRpmL / 1000) - idleRpm) / (maxRpm - idleRpm) * 100))
        -- If left rpm is over max stop bar at 100%
        if (tonumber(leftBar) > 146) then
            leftBar = 146
        end
        lcd.drawFilledRectangle(2, 3, leftBar, 7) 
    end
    -- Right turbine
    -- If alarm is active and right rpm is lower set right bar color to red
    if(diffTriggered and curRpmL > curRpmR) then
        lcd.setColor(240,0,0)
        else
        lcd.setColor(0,196,0)
    end
    if(runR) then
        rightBar = string.format("%.0f", 146 / 100 * (((curRpmR / 1000) - idleRpm) / (maxRpm - idleRpm) * 100))
        -- If right rpm is over max stop bar at 100%
        if (tonumber(rightBar) > 146) then
            rightBar = 146
        end
        lcd.drawFilledRectangle(2, 13, rightBar, 7)
    end
    lcd.setColor(txtr,txtg,txtb)
    -- Draw names "Left" and "Right"
    lcd.drawText(40 - lcd.getTextWidth(FONT_MINI,string.format("Left")),22,string.format("Left"),FONT_MINI)
    lcd.drawText(133 - lcd.getTextWidth(FONT_MINI,string.format("Right")),22,string.format("Right"),FONT_MINI)
    -- Draw arrow pointing to turbine with lower rpm if alarm is active
    if(diffTriggered) then
        lcd.setColor(240,0,0)
        if(curRpmL > curRpmR) then
            lcd.drawText(83 - lcd.getTextWidth(FONT_MAXI,">"),30,">",FONT_MAXI)
        end
        if(curRpmL < curRpmR) then
            lcd.drawText(83 - lcd.getTextWidth(FONT_MAXI,"<"),30,"<",FONT_MAXI)
        end
        lcd.setColor(txtr,txtg,txtb)
    end
    -- Draw rpm-value as thousands - if alarm is active set rpm-display to red on turbine with lower rpm
    if(runL) then
        if(diffTriggered and curRpmL < curRpmR) then
            lcd.setColor(240,0,0)
        end
        -- Left Turbine value
        if((curRpmL / 1000) > 99) then
            lcd.drawText(58 - lcd.getTextWidth(FONT_MAXI,string.format("%.0f",(curRpmL / 1000))),30,string.format("%.0f",(curRpmL / 1000)),FONT_MAXI)
            else if((curRpmL / 1000) > 9 and (curRpmL / 1000) < 100) then
                lcd.drawText(48 - lcd.getTextWidth(FONT_MAXI,string.format("%.0f",(curRpmL / 1000))),30,string.format("%.0f",(curRpmL / 1000)),FONT_MAXI)
                else
                lcd.drawText(40 - lcd.getTextWidth(FONT_MAXI,string.format("%.0f",(curRpmL / 1000))),30,string.format("%.0f",(curRpmL / 1000)),FONT_MAXI)
            end
        end
        lcd.setColor(txtr,txtg,txtb)
        else
        -- Show N/A instead of blinking zero as rpm if no sensorvalue
        lcd.drawText(48 - lcd.getTextWidth(FONT_BIG,trans17.noTurbine),38,trans17.noTurbine,FONT_BIG)
        -- Clear bargraph
        if(txtr == 0) then
            lcd.setColor(255,255,255)
            lcd.drawFilledRectangle(2, 3, 146, 7)
            lcd.setColor(txtr,txtg,txtb)
            else
            lcd.setColor(0,0,0)
            lcd.drawFilledRectangle(2, 3, 146, 7)
            lcd.setColor(txtr,txtg,txtb)
        end
    end
    --- Right turbine
    if(runR) then
        if(diffTriggered and curRpmL > curRpmR) then
            lcd.setColor(240,0,0)
        end
        if((curRpmR / 1000) > 99) then
            lcd.drawText(145 - lcd.getTextWidth(FONT_MAXI,string.format("%.0f",(curRpmR / 1000))),30,string.format("%.0f",(curRpmR / 1000)),FONT_MAXI)
            else if((curRpmR / 1000) > 9 and (curRpmR / 1000) < 100) then
                lcd.drawText(137 - lcd.getTextWidth(FONT_MAXI,string.format("%.0f",(curRpmR / 1000))),30,string.format("%.0f",(curRpmR / 1000)),FONT_MAXI)
                else
                lcd.drawText(130 - lcd.getTextWidth(FONT_MAXI,string.format("%.0f",(curRpmR / 1000))),30,string.format("%.0f",(curRpmR / 1000)),FONT_MAXI)
            end
        end
        lcd.setColor(txtr,txtg,txtb)
        else
        -- Show N/A instead of blinking zero as rpm if no sensorvalue
        lcd.drawText(137 - lcd.getTextWidth(FONT_BIG,trans17.noTurbine),38,trans17.noTurbine,FONT_BIG)
        -- Clear bargraph
        if(txtr == 0) then
            lcd.setColor(255,255,255)
            lcd.drawFilledRectangle(2, 13, 146, 7)
            lcd.setColor(txtr,txtg,txtb)
            else
            lcd.setColor(0,0,0)
            lcd.drawFilledRectangle(2, 13, 146, 7)
            lcd.setColor(txtr,txtg,txtb)
        end
    end
end
--------------------------------------------------------------------------------
-- Read translations
local function setLanguage()
    local lng = system.getLocale()
    local file = io.readall("Apps/Lang/RCT-Turb.jsn")
    local obj = json.decode(file)
    if(obj) then
        trans17 = obj[lng] or obj[obj.default]
    end
    collectgarbage()
end
--------------------------------------------------------------------------------
-- Take care of user's settings-changes
local function sensor1Changed(value)
	sensRpmIdL  = sensorsAvailable[value].id
	sensRpmPaL  = sensorsAvailable[value].param
	system.pSave("sensRpmIdL", sensRpmIdL)
	system.pSave("sensRpmPaL", sensRpmPaL)
end

local function sensor2Changed(value)
	sensRpmIdR  = sensorsAvailable[value].id
    sensRpmPaR  = sensorsAvailable[value].param
	system.pSave("sensRpmIdR", sensRpmIdR)
    system.pSave("sensRpmPaR", sensRpmPaR)
end

local function multiChanged(value)
    multi = value
    system.pSave("multi", multi)
end

local function idleRpmChanged(value)
    idleRpm = value
    system.pSave("idleRpm", idleRpm)
end

local function maxRpmChanged(value)
    maxRpm = value
    system.pSave("maxRpm", maxRpm)
end

local function almSwitchChanged(value)
    almSwitch = value
    system.pSave("almSwitch", almSwitch)
end

local function maxDiffChanged(value)
    maxDiff = value
    system.pSave("maxDiff", maxDiff)
end

local function alarmFileLChanged(value)
    alarmFileL = value
    system.pSave("alarmFileL", alarmFileL)
end

local function alarmFileRChanged(value)
    alarmFileR = value
    system.pSave("alarmFileR", alarmFileR)
end
--------------------------------------------------------------------------------
-- Draw the main form (Application inteface)
local function initForm(formID)
    -- List sensors only if menu is active to preserve memory at runtime 
    -- (measured up to 25% save if menu is not opened)
    sensorsAvailable = {}
    local sensors = system.getSensors();
    local list={}
    local curIndex1, curIndex2 = -1, -1
    local descr = ""
    for index,sensor in ipairs(sensors) do 
        if(sensor.param == 0) then
            descr = sensor.label
            else
            list[#list + 1] = string.format("%s - %s", descr, sensor.label)
            sensorsAvailable[#sensorsAvailable + 1] = sensor
           	if(sensor.id == sensRpmIdL and sensor.param == sensRpmPaL ) then
                curIndex1 =# sensorsAvailable
            end
            if(sensor.id == sensRpmIdR  and sensor.param == sensRpmPaR) then
                curIndex2 =# sensorsAvailable
            end
        end
    end
    
    local form, addRow, addLabel = form, form.addRow ,form.addLabel
    local addIntbox, addSelectbox = form.addIntbox, form.addSelectbox
    local addInputbox, addCheckbox = form.addInputbox, form.addCheckbox
    local addAudioFilebox, setButton = form.addAudioFilebox, form.setButton
    
	addRow(1)
	addLabel({label="---    RC-Thoughts Jeti Tools     ---", font=FONT_BIG})
    
    addRow(1)
    addLabel({label=trans17.labelSensor,font=FONT_BOLD})
    
    addRow(2)
    addLabel({label=trans17.selSens1, width=200})
    addSelectbox(list, curIndex1, true, sensor1Changed)
    
    addRow(2)
    addLabel({label=trans17.selSens2, width=200})
    addSelectbox(list, curIndex2, true, sensor2Changed)
    
    addRow(2)
    addLabel({label=trans17.multi, width=200})
    addIntbox(multi, 1, 1000, 0, 0, 1000, multiChanged)
    
    addRow(2)
    addLabel({label=trans17.idleRPM, width=200})
    addIntbox(idleRpm, 0, 100, 0, 0, 1, idleRpmChanged)
    
    addRow(2)
    addLabel({label=trans17.maxRPM, width=200})
    addIntbox(maxRpm, 0, 500, 0, 0, 1, maxRpmChanged)
    
    addRow(1)
    addLabel({label=trans17.labelAlarm,font=FONT_BOLD})
    
    addRow(2)
    addLabel({label=trans17.useSwitch,width=220})
    addInputbox(almSwitch, true, almSwitchChanged)
    
    addRow(2)
    addLabel({label=trans17.alarmDiff, width=230})
    addIntbox(maxDiff, 0, 100, 0, 0, 1, maxDiffChanged)
    
    form.addRow(2)
    addLabel({label=trans17.alarmFileL})
    addAudioFilebox(alarmFileL, alarmFileLChanged)
    
    form.addRow(2)
    addLabel({label=trans17.alarmFileR})
    addAudioFilebox(alarmFileR, alarmFileRChanged)
	
	addRow(1)
	addLabel({label="Powered by RC-Thoughts.com - v."..turbVersion.." ", font=FONT_MINI, alignRight=true})
    
    collectgarbage()
end
--------------------------------------------------------------------------------
local function loop()
    curTime = system.getTimeCounter()
    maxDiffTrue = maxDiff * 100
    local turbineL = system.getSensorByID(sensRpmIdL, sensRpmPaL)
    local turbineR = system.getSensorByID(sensRpmIdR, sensRpmPaR)
    if(turbineL and turbineL.valid) then
        runL = true
        else
        runL = false
    end
    if(turbineR and turbineR.valid) then
        runR = true
        else
        runR = false
    end
    if (runL and runR) then
        -- Get rpm-values and use multiplicator for those telemetry-units giving just thousands
        curRpmL = turbineL.value * multi
        curRpmR = turbineR.value * multi
        -- Calculate difference in rpm if one of turbines is over idle-rpm
        if(curRpmL > curRpmR) then
            curDiff = curRpmL - curRpmR
        end
        if(curRpmL < curRpmR) then
            curDiff = curRpmR - curRpmL
        end
        -- Check if difference is over alarmlimit and alarms are enabled
        enableAlarm = system.getInputsVal(almSwitch)
        if(maxDiff > 0 and curDiff > maxDiffTrue and enableAlarm == 1) then
            diffTriggered = true
            else
            diffTriggered = false
        end
        -- If difference in rpm's is more than allowed and left is lower play left audiofile
        if(not playDone and diffTriggered and playTime < curTime and alarmFileL ~= "..." and curRpmL < curRpmR) then
            system.playFile(alarmFileL,AUDIO_QUEUE)
            playTime = curTime + 10000
            playDone = true
        end
        -- If difference in rpm's is more than allowed and right is lower play right audiofile
        if(not playDone and diffTriggered and playTime < curTime and alarmFileR ~= "..." and curRpmL > curRpmR) then
            system.playFile(alarmFileR,AUDIO_QUEUE)
            playTime = curTime + 10000
            playDone = true
        end
        -- Reset playtimer
        if(not diffTriggered and playDone) then
            playDone = false
            playTime = 0
        end
    end
    collectgarbage()
end
--------------------------------------------------------------------------------
local function init()
    local pLoad, registerForm, registerTelemetry = system.pLoad, system.registerForm, system.registerTelemetry
    sensRpmIdL = pLoad("sensRpmIdL", 0)
    sensRpmPaL = pLoad("sensRpmPaL", 0)
    sensRpmIdR = pLoad("sensRpmIdR", 0)
    sensRpmPaR = pLoad("sensRpmPaR", 0)
    multi = pLoad("multi", 1)
    idleRpm = pLoad("idleRpm", 0)
    maxRpm = pLoad("maxRpm", 0)
    maxDiff = pLoad("maxDiff", 0)
    almSwitch = pLoad("almSwitch")
    alarmFileL = pLoad("alarmFileL", "...")
    alarmFileR = pLoad("alarmFileR", "...")
    registerForm(1, MENU_APPS, trans17.appName, initForm, keyPressed)
    registerTelemetry(1,"RCT-DualTurbine",2,dispTurbine)
    collectgarbage()
end
--------------------------------------------------------------------------------
turbVersion = "1.0"
setLanguage()
collectgarbage()
return {init=init, loop=loop, author="RC-Thoughts", version=turbVersion, name=trans17.appName}