# Parity with GEDR JobKernelProcessPoll: wevtutil sample of Kernel-Process operational log.
$AgentsAvBin = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\Bin'))
. (Join-Path $AgentsAvBin '_JobLog.ps1')

function Invoke-KernelProcessPoll {
    $wv = Join-Path $env:SystemRoot 'System32\wevtutil.exe'
    if (-not (Test-Path -LiteralPath $wv)) {
        Write-JobLog '[KernelProcessPoll] wevtutil.exe not found; skipping.' 'INFO' 'kernel_process_poll.log'
        return
    }
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $wv
        $psi.Arguments = 'qe Microsoft-Windows-Kernel-Process/Operational /c:25 /f:text /rd:true'
        $psi.UseShellExecute = $false
        $psi.RedirectStandardOutput = $true
        $psi.CreateNoWindow = $true
        $p = [System.Diagnostics.Process]::Start($psi)
        if (-not $p.WaitForExit(65000)) { try { $p.Kill() } catch { }; return }
        $o = $p.StandardOutput.ReadToEnd()
        if ($o -and $o.Length -gt 0 -and $o.Length -lt 120000) {
            $snippet = if ($o.Length -gt 800) { $o.Substring(0, 800) + '...' } else { $o }
            Write-JobLog "[KernelProcessPoll] Sample ($($o.Length) chars): $snippet" 'INFO' 'kernel_process_poll.log'
        }
    } catch {
        Write-JobLog "[KernelProcessPoll] $_" 'ERROR' 'kernel_process_poll.log'
    }
}

if ($MyInvocation.InvocationName -ne '.') { Invoke-KernelProcessPoll }
