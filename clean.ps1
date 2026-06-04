# windows 11 cleaner
# автор: арсений щеглов
# запускать от имени администратора

write-host "windows 11 очистка" -foregroundcolor cyan
write-host "удаление мусора, телеметрии и рекламы..." -foregroundcolor yellow

# 1. удаление встроенного мусора
$bloatware = @(
    "microsoft.copilot"
    "microsoft.windows.outlook"
    "microsoft.microsofttodo"
    "microsoft.microsoftsolitairecollection"
    "microsoft.microsoft365"
    "microsoft.bingweather"
    "microsoft.bingnews"
    "microsoft.getstarted"
    "microsoft.xboxgamingoverlay"
    "microsoft.xboxapp"
    "microsoft.xboxidentityprovider"
    "microsoft.xboxspeechtotextoverlay"
    "microsoft.gamingservices"
    "microsoft.yourphone"
    "microsoft.people"
    "microsoft.mixedreality.portal"
    "microsoft.windowsalarms"
    "microsoft.windowscamera"
    "microsoft.windowsSoundRecorder"
    "microsoft.mspaint"
    "microsoft.office.onenote"
    "microsoft.skypeapp"
    "microsoft.zunemusic"
    "microsoft.zunevideo"
    "microsoft.storepurchaseapp"
    "microsoft.todos"
    "microsoft.windowsfeedbackhub"
    "microsoft.windowsmaps"
    "microsoft.advertising.xaml"
    "microsoft.wallet"
    "microsoft.windows.photos"
    # "microsoft.windowsstore"
)

foreach ($app in $bloatware) {
    write-host "удаление: $app" -foregroundcolor darkgray
    get-appxpackage -name $app -allusers | remove-appxpackage -allusers -erroraction silentlycontinue
    get-appxprovisionedpackage -online | where-object { $_.displayname -eq $app } | remove-appxprovisionedpackage -online -erroraction silentlycontinue
}

# 2. удаление onedrive
write-host "удаление onedrive..." -foregroundcolor yellow
stop-process -name onedrive -force -erroraction silentlycontinue
start-sleep -seconds 2
$onedrive = "$env:systemroot\syswow64\onedrivesetup.exe"
if (test-path $onedrive) { & $onedrive /uninstall }
start-sleep -seconds 2
remove-item -path "$env:localappdata\microsoft\onedrive" -recurse -force -erroraction silentlycontinue
remove-item -path "$env:programdata\microsoft onedrive" -recurse -force -erroraction silentlycontinue
remove-item -path "$env:userprofile\onedrive" -recurse -force -erroraction silentlycontinue

# 3. отключение телеметрии
write-host "отключение телеметрии..." -foregroundcolor yellow
new-item -path "hklm:\software\policies\microsoft\windows\datacollection" -force | out-null
set-itemproperty -path "hklm:\software\policies\microsoft\windows\datacollection" -name "allowtelemetry" -type dword -value 0
set-itemproperty -path "hklm:\software\policies\microsoft\windows\datacollection" -name "donotshowfeedbacknotifications" -type dword -value 1

# 4. отключение рекламного id и предложений
write-host "отключение рекламы и предложений..." -foregroundcolor yellow
new-item -path "hkcu:\software\microsoft\windows\currentversion\advertisinginfo" -force | out-null
set-itemproperty -path "hkcu:\software\microsoft\windows\currentversion\advertisinginfo" -name "enabled" -type dword -value 0

new-item -path "hkcu:\software\microsoft\windows\currentversion\contentdeliverymanager" -force | out-null
set-itemproperty -path "hkcu:\software\microsoft\windows\currentversion\contentdeliverymanager" -name "contentdeliveryallowed" -type dword -value 0
set-itemproperty -path "hkcu:\software\microsoft\windows\currentversion\contentdeliverymanager" -name "oempreinstalledappsenabled" -type dword -value 0
set-itemproperty -path "hkcu:\software\microsoft\windows\currentversion\contentdeliverymanager" -name "preinstalledappsenabled" -type dword -value 0
set-itemproperty -path "hkcu:\software\microsoft\windows\currentversion\contentdeliverymanager" -name "silentinstalledappsenabled" -type dword -value 0
set-itemproperty -path "hkcu:\software\microsoft\windows\currentversion\contentdeliverymanager" -name "softlandingenabled" -type dword -value 0
set-itemproperty -path "hkcu:\software\microsoft\windows\currentversion\contentdeliverymanager" -name "subscribedcontent-338387enabled" -type dword -value 0
set-itemproperty -path "hkcu:\software\microsoft\windows\currentversion\contentdeliverymanager" -name "subscribedcontent-338388enabled" -type dword -value 0
set-itemproperty -path "hkcu:\software\microsoft\windows\currentversion\contentdeliverymanager" -name "subscribedcontent-338389enabled" -type dword -value 0
set-itemproperty -path "hkcu:\software\microsoft\windows\currentversion\contentdeliverymanager" -name "subscribedcontent-353698enabled" -type dword -value 0

# 5. отключение copilot в панели задач
write-host "отключение copilot..." -foregroundcolor yellow
set-itemproperty -path "hkcu:\software\microsoft\windows\currentversion\explorer\advanced" -name "showcopilotbutton" -type dword -value 0

# 6. отключение виджетов новости и погода
write-host "отключение виджетов..." -foregroundcolor yellow
set-itemproperty -path "hklm:\software\policies\microsoft\dsh" -name "allownewsandinterests" -type dword -value 0

# 7. отключение игровой панели
write-host "отключение игровой панели..." -foregroundcolor yellow
set-itemproperty -path "hkcu:\software\microsoft\windows\currentversion\gamebar" -name "usegamebar" -type dword -value 0
set-itemproperty -path "hklm:\software\microsoft\policymanager\default\applicationmanagement\allowgamedvr" -name "value" -type dword -value 0

# 8. отключение служб xbox
write-host "отключение xbox..." -foregroundcolor yellow
$services = @(
    "xblauthmanager",
    "xblgamesave",
    "xboxnetapisvc",
    "xboxgipsvc"
)
foreach ($service in $services) {
    stop-service -name $service -force -erroraction silentlycontinue
    set-service -name $service -startuptype disabled -erroraction silentlycontinue
}

# 9. отключение заданий телеметрии
write-host "удаление заданий телеметрии..." -foregroundcolor yellow
get-scheduledtask -taskpath "\microsoft\windows\application experience\" -erroraction silentlycontinue | where-object { 
    $_.taskname -match "microsoft compatibility appraiser|programdataupdater|startupapptask" 
} | disable-scheduledtask -erroraction silentlycontinue

# 10. блокировка серверов телеметрии
write-host "блокировка серверов телеметрии..." -foregroundcolor yellow
$hostspath = "$env:windir\system32\drivers\etc\hosts"
$telemetryhosts = @(
    "0.0.0.0 v10.vortex-win.data.microsoft.com",
    "0.0.0.0 vortex.data.microsoft.com",
    "0.0.0.0 vortex-win.data.microsoft.com",
    "0.0.0.0 telemetry.microsoft.com",
    "0.0.0.0 telemetry.remote.microsoft.com",
    "0.0.0.0 watson.telemetry.microsoft.com"
)

add-content -path $hostspath -value "`n# windows 11 cleaner - заблокированные серверы" -erroraction silentlycontinue
foreach ($entry in $telemetryhosts) {
    add-content -path $hostspath -value $entry -erroraction silentlycontinue
}

write-host "очистка завершена" -foregroundcolor green
write-host "пожалуйста, перезагрузите компьютер" -foregroundcolor yellow
read-host "нажмите enter для выхода"
