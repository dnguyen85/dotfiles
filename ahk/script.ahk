!w::    appGvim("nvim-qt.exe")
!r::    appGvim("chrome.exe")
;!e::    titleMatch("X Window")
!d::    appGvim("javaw.exe")
!e::    appGvim("etxc.exe")
;!e::    appGvim("ExceedonDemand.exe")
!o::    appGvim("Outlook.exe")
!y::    appGvim("Teams.exe")
!m::    appGvim("MendeleyDesktop.exe")
!i::    appGvim("WINWORD.exe")
!x::    appGvim("EXCEL.exe")
!p::    appGvim("POWERPNT.exe")
!v::    appGvim("vlc.exe")
!t::    appGvim("mintty.exe")
!Space::WinMinimize, A

appGvim(exe) {
    IfWinExist, ahk_exe %exe%
        IfWinActive
            Send !{Esc} 
        else
            WinActivate
              }
return

titleMatch(win) {
    IfWinExist, %win%
        IfWinActive
            Send !{Esc}
        else
            WinActivate
}
return

NumLock::Send {F11}
PrintScreen::Send {F12}
