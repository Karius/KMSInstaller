; Script generated by the HM NIS Edit Script Wizard.

; 编译方法，将 kms_files 与 Plugins 目录及 KMSInst.nsi(本脚本) 放在同一个目录中，运行 makensisw.exe，将 KMSInst.nsi 脚本拖到 makensisw.exe 的窗口中即可



; HM NIS Edit Wizard helper defines
!define PRODUCT_NAME "KMS Installer"
!define PRODUCT_VERSION "1.0"
!define PRODUCT_PUBLISHER "Apple company, Inc."
!define PRODUCT_WEB_SITE "http://www.apple.com"

; 程序运行前是否需要检测操作系统版本
;!define CHECK_OS_VER

!addplugindir Plugins

SetCompressor /SOLID lzma

; MUI 1.67 compatible ------
!include "MUI2.nsh"
!include "Sections.nsh"
!include "x64.nsh"
!include "WinVer.nsh"

; MUI Settings
!define MUI_ABORTWARNING
!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\modern-install.ico"

; Pages

; Welcome page
; !insertmacro MUI_PAGE_WELCOME

; License page
; !define MUI_LICENSEPAGE_CHECKBOX
; !insertmacro MUI_PAGE_LICENSE "c:\path\to\licence\YourSoftwareLicence.txt"

; Components Page
!insertmacro MUI_PAGE_COMPONENTS

; Directory page
;!define MUI_PAGE_CUSTOMFUNCTION_PRE DynamicallyShowDirectorySelect
;!insertmacro MUI_PAGE_DIRECTORY

; Instfiles page
!insertmacro MUI_PAGE_INSTFILES

; Finish page
;!define MUI_FINISHPAGE_TEXT_REBOOTNOW "立刻重启！"
;!define MUI_FINISHPAGE_TEXT_REBOOTLATER "稍后重启。"
!insertmacro MUI_PAGE_FINISH


; Language files
!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_LANGUAGE "SimpChinese"

; Reserve files
; !insertmacro MUI_RESERVEFILE_INSTALLOPTIONS

; MUI end ------

Name "${PRODUCT_NAME} ${PRODUCT_VERSION}"
OutFile "KMSInst.exe"
InstallDir "$SYSDIR\spp\store"
ShowInstDetails show
RequestExecutionLevel admin

!define KMSfull_V1 "v1"
!define KMSfull_V2 "v2.01"
!define KMS_SERVICE_NAME "sppsvc"
!define KMS_SERVICE_FILE "$SYSDIR\SppExtComObj.exe"

Section -InitSec
  ; 禁止在32位程序中对注册表与文件系统重定向
  SetRegView 64
  ${DisableX64FSRedirection}

  ; 完成页显示重启选项
  SetRebootFlag true
SectionEnd

; 清除安装时的windows序列号信息
Section -ClearGVLKInfo
    DetailPrint "Clear product key from the registry..."
    ExecWait '"$SYSDIR\wscript.exe" $SYSDIR\slmgr.vbs /cpky'
SectionEnd

; 停止KMS服务
Section -StopKmsSrv
; 最初控制服务使用的是 "services" 插件，这个插件只有 7kb 多，很小巧，但是其创建服务功能好像不好用，所以用了 "SimpleSC" 插件，这个插件体积比较大(54kb)，但是功能比较强
  DetailPrint "KMS Service: ${KMS_SERVICE_NAME} Stoping..."
  SimpleSC::StopService "${KMS_SERVICE_NAME}" 1 10
  Pop $0
  IntCmp $0 0 +5 +1 +1
    Push $0
    SimpleSC::GetErrorMessage
    Pop $0
    ; MessageBox MB_OK|MB_ICONINFORMATION "KMS Service Stopping fails - Reason: $0"
    DetailPrint "KMS Service Stopping fails - Reason: $0"
SectionEnd

; 该段的激活文件取自KMSfull_v1
Section KMS_v1_Files KMS_v1
 ;Push ${KMSfull_V1}
 ;Call ReplaceActivationFiles
  DetailPrint "Replace the KMSfull_v1 activation files in $INSTDIR"
  SetOutPath $INSTDIR
  SetOverwrite try
  File /oname=data.dat "kms_files\v1\data.dat"
  File /oname=tokens.dat "kms_files\v1\tokens.dat"
SectionEnd

; 该段的激活文件取自KMSfull_v2.01
Section /o KMS_v2_Files KMS_v2
 ;Push ${KMSfull_V2}
 ;Call ReplaceActivationFiles
  DetailPrint "Replace the KMSfull_v2.01 activation files in $INSTDIR"
  SetOutPath $INSTDIR
  SetOverwrite try
  File /oname=data.dat "kms_files\v2\data.dat"
  File /oname=tokens.dat "kms_files\v2\tokens.dat"
SectionEnd

; 写入 KMS 的注册表信息
Section -WriteKMSRegInfo
    DetailPrint "Write KMS Reginfo..."
    WriteRegDWORD HKU "S-1-5-20\Software\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform" "KmsHostConfig" 0x1
    WriteRegStr HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform" "KeyManagementServiceVersion" "6.2.9200.16384"
    WriteRegStr HKLM "SOFTWARE\Wow6432Node\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform" "KeyManagementServiceVersion" "6.2.9200.16384"
SectionEnd

; 将KMS服务器在防火墙中放行
Section -AddKMSSrvToWindowsFirewallExcept
  DetailPrint "Add KMS Service To WindowsFirewall Except: ${KMS_SERVICE_FILE}"
  SimpleFC::AddApplication "KMS Service" ${KMS_SERVICE_FILE} 0 2 "" 1
  Pop $0 ; return error(1)/success(0)
  IntCmp $0 0 +2 +1 +1
    MessageBox MB_OK|MB_ICONINFORMATION "windows firewall can't add except!"
  ;Quit
SectionEnd



;--------------------------------
;Descriptions

  ;Language strings
  LangString DESC_KMS_v1 ${LANG_CHINESE} "使用从 KMSfull_v1 中提取的激活文件."
  LangString DESC_KMS_v2 ${LANG_CHINESE} "使用从 KMSfull_v2.01 中提取的激活文件."

  ;Assign language strings to sections
  !insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
    !insertmacro MUI_DESCRIPTION_TEXT ${KMS_v1} $(DESC_KMS_v1)
    !insertmacro MUI_DESCRIPTION_TEXT ${KMS_v2} $(DESC_KMS_v2)
  !insertmacro MUI_FUNCTION_DESCRIPTION_END
 
;--------------------------------

; Functions

; $1 stores the status of group 1
Function .onInit

  !ifdef CHECK_OS_VER
  ; 检查操作系统是否为 Windows Server
  ${Unless} ${IsServerOS}
    MessageBox MB_OK|MB_ICONINFORMATION "本程序只能用在 Windows Server 2012 上."
    Quit
  ${EndIf}
  !endif

  StrCpy $1 ${KMS_v1} ; Group 1 - Option 1 is selected by default
FunctionEnd

Function .onSelChange
  !insertmacro StartRadioButtons $1
    !insertmacro RadioButton ${KMS_v1}
    !insertmacro RadioButton ${KMS_v2}
  !insertmacro EndRadioButtons
FunctionEnd


;Function ReplaceActivationFiles
;  Var /GLOBAL kms_files
;  Pop $0
;  StrCmp $0 "${KMS_V2}" +1 +3
;    StrCpy $kms_files "kms_files\v2\*.dat"
;    Goto +2
;  StrCpy $kms_files "kms_files\v1\*.dat"

;  DetailPrint "Replace the KMSfull_$0 activation files (data.dat, tokens.dat) in \Windows\system32\spp\store"
;  SetOutPath $INSTDIR
;  SetOverwrite try
;  ;File $kms_files
;FunctionEnd
