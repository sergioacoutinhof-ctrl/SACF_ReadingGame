# Runs in a separate Windows PowerShell process. No audio-device playback or
# engine TTS calls: only local PCM files, atomically published after synthesis.
$ErrorActionPreference = 'Stop'
$RequestPath = '__REQUEST_PATH__'
$request = Get-Content -LiteralPath $RequestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$cacheRoot = [IO.Path]::GetFullPath([string]$request.cache_dir)
$statusPath = [string]$request.status_path
$synth = $null
try {
    Add-Type -AssemblyName System.Speech
    $synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
    $voices = @($synth.GetInstalledVoices() | Where-Object { $_.Enabled -and $_.VoiceInfo.Culture.Name -eq 'pt-BR' })
    if ($voices.Count -eq 0) {
        $voices = @($synth.GetInstalledVoices() | Where-Object { $_.Enabled -and $_.VoiceInfo.Culture.TwoLetterISOLanguageName -eq 'pt' })
    }
    if ($voices.Count -eq 0) { throw 'No Portuguese speech voice installed.' }
    $synth.SelectVoice($voices[0].VoiceInfo.Name)
    $synth.Rate = -1
    $synth.Volume = 100
    $format = [System.Speech.AudioFormat.SpeechAudioFormatInfo]::new(22050, [System.Speech.AudioFormat.AudioBitsPerSample]::Sixteen, [System.Speech.AudioFormat.AudioChannel]::Mono)
    $sha = [Security.Cryptography.SHA256]::Create()
    $count = 0
    try {
        foreach ($text in $request.texts) {
            $text = [string]$text
            $key = ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($text)))).Replace('-', '').ToLowerInvariant()
            $target = Join-Path $cacheRoot ($key + '.wav')
            if ((Test-Path -LiteralPath $target) -and (Get-Item -LiteralPath $target).Length -gt 44) { continue }
            $partial = $target + '.' + $PID + '.part'
            $synth.SetOutputToWaveFile($partial, $format)
            $synth.Speak($text)
            $synth.SetOutputToNull()
            Move-Item -LiteralPath $partial -Destination $target -Force
            $count += 1
        }
    } finally { $sha.Dispose() }
    $status = @{state='ready';language=$voices[0].VoiceInfo.Culture.Name;generated=$count}
    [IO.File]::WriteAllText($statusPath, ($status | ConvertTo-Json -Compress), [Text.UTF8Encoding]::new($false))
} catch {
    $status = @{state='unavailable';reason='speech_generation_failed'}
    [IO.File]::WriteAllText($statusPath, ($status | ConvertTo-Json -Compress), [Text.UTF8Encoding]::new($false))
    exit 1
} finally {
    if ($null -ne $synth) { $synth.Dispose() }
}
