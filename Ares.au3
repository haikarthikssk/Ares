#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.12.0
 Author:         Karthik K

 Script Function:
	Template AutoIt script.

#ce ----------------------------------------------------------------------------
#pragma compile(ProductVersion, 1.2)
#pragma compile(ProductName, Ares)
#pragma compile(FileVersion, 1.1.0.0)
#NoTrayIcon
#include <TrayConstants.au3>
#include <Timers.au3>
#include<MsgBoxConstants.au3>
#include <Misc.au3>

Opt("TrayMenuMode",3);Tell autoit not to pause our script while we click on it.
$EXIT=0
$ROUTER_LIST_FILE="routerlist.txt"
local $MENU_CONTROLS[30]
$INDEX=0

;Check whether Only One Instance in running
if _Singleton("Ares",1)=0 Then
   msgbox(16,"Ares Conflict Detected!!","Another Instance is Already Running!!  Please Close it from the Systemtray")
   exit
EndIf

changeDir()
addtoStartup()
resolveToIP()

;Change the Current Dir to the Another Direcotry ; Passed as Command-Line Option
func changeDir()
   if $CmdLine[0]>0 Then
	  FileChangeDir($CmdLine[1])
   EndIf
EndFunc

;Read file

func readFile()
   return FileReadToArray($ROUTER_LIST_FILE)
   EndFunc

;Resolve Hostname to IP Address

func resolveToIP()
$array=readFile()
TCPStartup()
for $i=0 to UBound($array) -1
  ; ConsoleWrite(TCPNameToIP($array[$i]))
   $IP=TCPNameToIP($array[$i])
   if $IP<>"" then
   createTrayItem($array[$i]&"-"&$IP)
   EndIf
Next
$EXIT=TrayCreateItem("exit")
TCPShutdown()
EndFunc

;Show the Tray Icon. Don't Hide

TraySetState($TRAY_ICONSTATE_SHOW)

;Create the Tray Items ;
func createTrayItem($value)

   $MENU_CONTROLS[$INDEX]=TrayCreateItem($value)
   $INDEX+=1
EndFunc
func clearTrayItems()
   for $i=0 to $INDEX
	  TrayItemDelete($MENU_CONTROLS[$i])
   Next
   TrayItemDelete($EXIT)
   $INDEX=0
   EndFunc


$Timer=_Timer_Init()
while 1
   $msg=TrayGetMsg()
   if $msg=$EXIT Then	;Exit when user clicks exit
	  Exit
   EndIf
  for $i=0 to $INDEX
	 if $msg==$MENU_CONTROLS[$i] then
		$data=StringSplit(TrayItemGetText($MENU_CONTROLS[$i]),"-")
		ClipPut($data[$data[0]]) ; when clicked copy the IP to the clipboard
		tooltip("IP Copied!!") 
		sleep(800)
		tooltip("") ;clear the tooltip
		EndIf
	 Next
  if _Timer_Diff($Timer)>600000 then; Reload the list every hour
	 clearTrayItems()
	 resolveToIP()
	 $Timer=_Timer_Init() ; Reset the Time
	 EndIf
  WEnd

;Adds our exe to the windows startup
;You may wonder why i have added the current directory to the registry.
;The answer is ,we are installed at say XYZ dir and all our files are present under dir XYZ
; when the Windows boots up , it will execute the exe with the 'system32' as base dir.
;We don't know where our files are present , so we make ourself to get notified about our installed path by writing it to registry and passing it to ourself.

     func addtoStartup()
  local  $key=RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\run","Ares")
   if not @error and $key <>"" Then
	  if StringCompare($key,'"'&@autoitExe&'" "'& @WorkingDir&'"',0)<>0 Then
		 msgbox(48,"Caution!!.","Ares Configured With Invalid Startup Path ")
	  Else
		 return
		 EndIf
	  EndIf
	  local $option=msgbox(4,"Configure Ares","Would you like to add Ares to Startup")
	  if $option<>$IDYes Then
		 Return
		 EndIf
	  if RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\run","Ares","REG_SZ",'"'&@AutoItExe&'" "'& @WorkingDir&'"')==0 Then
		 msgbox(16,"Error","Adding to Startup Failed !!")
	  Else
		 msgbox(64,"Success!!","Added To Startup Succesfully")
		 EndIf
	  EndFunc
