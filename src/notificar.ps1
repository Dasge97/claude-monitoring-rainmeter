# Muestra una notificación de Windows y reproduce el .wav indicado en lugar del sonido de Windows.
# Si el .wav no existe, la notificación suena con el sonido normal de Windows.
# Al pulsarla trae al frente la ventana de VS Code de la sesión
# (protocolo panelclaude://, registrado en HKCU\Software\Classes\panelclaude -> enfocar-vscode.exe).
param([string]$Titulo, [string]$Mensaje, [string]$Carpeta, [string]$Sonido)

[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

function Escapar([string]$t) { [System.Security.SecurityElement]::Escape($t) }

$lanzar = ''
if ($Carpeta) { $lanzar = ' activationType="protocol" launch="' + (Escapar ('panelclaude://' + [Uri]::EscapeDataString($Carpeta))) + '"' }

$hayWav = $Sonido -and (Test-Path $Sonido)
$audio = ''
if ($hayWav) { $audio = '<audio silent="true"/>' }

$xml = @"
<toast$lanzar>
  <visual><binding template="ToastGeneric">
    <text>$(Escapar $Titulo)</text>
    <text>$(Escapar $Mensaje)</text>
  </binding></visual>
  $audio
</toast>
"@

$doc = New-Object Windows.Data.Xml.Dom.XmlDocument
$doc.LoadXml($xml)
$toast = [Windows.UI.Notifications.ToastNotification]::new($doc)
$appId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'

# El sonido (.wav) se carga antes de mostrar la notificación para que empiece sin retraso.
# PlaySync: el script espera a que termine; si el proceso acaba antes, el sonido se corta.
if ($hayWav) {
    $reproductor = New-Object System.Media.SoundPlayer $Sonido
    $reproductor.Load()
    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId).Show($toast)
    $reproductor.PlaySync()
} else {
    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId).Show($toast)
}
