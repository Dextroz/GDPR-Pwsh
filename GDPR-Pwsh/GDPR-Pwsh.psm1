function Send-GdprEmail {
    <#
    .SYNOPSIS
        Sends a GDPR email. 
    
    .DESCRIPTION
        Sends a GDPR right to erasure email to the recipient requesting they delete all data associated with the senders email account. 

    .PARAMETER SmtpServer
        The Smtp server used to send the email.

    .PARAMETER EmailPassword
        The password used to authenticate with the Smtp server. Defaults to: "smtp.google.com".

    .PARAMETER Recipient
        The recipient address for the email.

    .PARAMETER From
        The email address you are sending the email from.

    .PARAMETER Cc
        The email address(es) to send a carbon copy.

    .PARAMETER Bcc
        The email address(es) to send a blind carbon copy.
    
    .EXAMPLE
        $EmailPassword = "<Password Here>" | ConvertTo-SecureString -AsPlainText -Force
        Send-GdprEmail -EmailPassword $EmailPassword -Recipient "foobar@email.com" -From "foobar@email.com" -Verbose

    .EXAMPLE
        $EmailPassword = "<Password Here>" | ConvertTo-SecureString -AsPlainText -Force
        Send-GdprEmail -SmtpServer "smtp.office365.com" -EmailPassword $EmailPassword -Recipient "foo@email.com","bar@email.com" -From "foobar@outlook.com" -$Cc "foo@email.com","bar@email.com" -$Bcc "bar@email.com" -Verbose

    .NOTES
        If there are multiple recipients Cc, Bcc, separate their addresses with a comma (,).
        If using Gmail and your Google account is MFA enabled, generate an app password and pass this to $EmailPassword.
        https://support.google.com/accounts/answer/185833
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]
        $SmtpServer = "smtp.gmail.com", # Using Google's gmail SMTP server by default as Gmail is so popular.

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [SecureString]
        $EmailPassword,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $Recipient,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $From,

        [Parameter(Mandatory = $false)]
        [String[]]
        $Cc,

        [Parameter(Mandatory = $false)]
        [String[]]
        $Bcc
    )
    
    begin {
        # Declare variables.
        $Date = Get-Date
        $Subject = "General Data Protection Regulation (GDPR): Right to Erasure request"
        # Create email PSCredential object for SMTP server authentication.
        Write-Verbose -Message "Creating PSCredential object with email credentials"
        $EmailCreds = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList ($From, $EmailPassword)
    }
    process {
        
        $Body = @"
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <style>
        body,
        html {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        }

        h2 {
            color: red;
            font-weight: bold;
        }

        p {
            font-size: 1.0em;
            padding-top: 0.4em;
        }
    </style>
</head>

<body>
    <h2>Attention!</h2>
    <p>To whom this may concern,</p>
    <p>Under the General Data Protection Regulation (GDPR), I hereby revoke consent for my data to be processed and
        excercise my right to erasure <a href="https://gdpr-info.eu/art-17-gdpr/">(GDPR Chapter 3 Art. 17).</a><br>
        I instruct your organisation, without undue delay, to delete/remove/purge all data associated with the account
        at this email address.</p>
    <p>Failure to comply with this request in a timely manner will result in a complaint being filed with my country's
        data protection authority.</p>
    <p>This email was generated using GDPR-Pwsh - $Date</p>
</body>

</html>
"@
        Write-Verbose -Message "Sending email to: $Recipient"
        try {
            if ($Cc -and $Bcc) {
                Write-Verbose -Message "Cc(s): $Cc Bcc(s): $Bcc"
                # Send email.
                Send-MailMessage -To $Recipient -Subject $Subject -Body $Body -SmtpServer $SmtpServer -From $From -Cc $Cc -Bcc $Bcc -BodyAsHtml -UseSsl -Credential $EmailCreds -Verbose:($PSBoundParameters["Verbose"] -eq $true) -ErrorAction "Stop"
            }
            elseif ($Cc) {
                Write-Verbose -Message "Cc(s): $Cc"
                # Send email.
                Send-MailMessage -To $Recipient -Subject $Subject -Body $Body -SmtpServer $SmtpServer -From $From -Cc $Cc -BodyAsHtml -UseSsl -Credential $EmailCreds -Verbose:($PSBoundParameters["Verbose"] -eq $true) -ErrorAction "Stop"
            }
            elseif ($Bcc) {
                Write-Verbose -Message "Bcc(s): $Bcc"
                # Send email.
                Send-MailMessage -To $Recipient -Subject $Subject -Body $Body -SmtpServer $SmtpServer -From $From -Bcc $Bcc -BodyAsHtml -UseSsl -Credential $EmailCreds -Verbose:($PSBoundParameters["Verbose"] -eq $true) -ErrorAction "Stop"
            }
            else {
                Write-Verbose -Message "Recipient(s): $Recipient"
                # Send email.
                Send-MailMessage -To $Recipient -Subject $Subject -Body $Body -SmtpServer $SmtpServer -From $From -BodyAsHtml -UseSsl -Credential $EmailCreds -Verbose:($PSBoundParameters["Verbose"] -eq $true) -ErrorAction "Stop"
            }
        }
        catch {
            Write-Error -Message "Failed to send email with the following error: $($_.Exception.Message)"
            break
        }
        Write-Verbose -Message "Email sent successfully at $(Get-Date)"
    }
}

function Show-GdprPwsh {
    # Check that AnyBox is installed, if not, install it.
    if (Get-Module -ListAvailable -Name "AnyBox") {
        Import-Module -Name "AnyBox"
    }
    else {
        Write-Error -Message "AnyBox isn't installed, attempting to install..."
        try {
            Install-Module -Name "AnyBox" -Force -AllowClobber -Verbose -ErrorAction "Stop"
            Import-Module -Name "AnyBox" -ErrorAction "Stop"
        }
        catch {
            Write-Error -Message "Failed to install the AnyBox module. Terminating..."
            break
        }
    }

    # Start AnyBox GUI.
    $AnyBox = New-Object -TypeName "AnyBox.AnyBox"
    $AnyBox.Title = "GDPR-Pwsh"
    $AnyBox.Prompts = @(
        New-AnyBoxPrompt -InputType "Text" -Message "Specify a SMTP server: " -DefaultValue "smtp.gmail.com"
        New-AnyBoxPrompt -InputType "Password" -Message "Email password: " -ValidateNotEmpty
        New-AnyBoxPrompt -InputType "Text" -Message "Email recipient (Specify multiple using a ',' delimiter): " -ValidateScript {
            # Check if it is an empty string.
            if ($_ -eq "") {
                break
            } 
            else {
                $Recipients = $_ -split ","
                foreach ($Recipient in $Recipients) {
                    try {
                        [MailAddress]$Recipient
                    }
                    catch {
                        Write-Error -Message "The email string: $Recipient is not a valid email address" -ErrorAction "Stop"
                        break
                    }
                }
            }
        } -ValidateNotEmpty
        New-AnyBoxPrompt -InputType "Text" -Message "Email origin (From): " -ValidateScript { try { [MailAddress]$_ } catch { Write-Error -Message "The email string: $_ is not a valid email address" -ErrorAction "Stop" break } } -ValidateNotEmpty
        New-AnyBoxPrompt -InputType "Text" -Message "Carbon copy addresses (Specify multiple using a ',' delimiter): " -ValidateScript {
            # Check if it is an empty string.
            if ($_ -eq "") {
                break
            }
            else {
                $CarbonCopys = $_ -split "," 
                foreach ($CarbonCopy in $CarbonCopys) {
                    try {
                        [MailAddress]$CarbonCopy
                    }
                    catch {
                        Write-Error -Message "The email string: $CarbonCopy is not a valid email address" -ErrorAction "Stop"
                        break
                    }
                }
            }
        }
        New-AnyBoxPrompt -InputType "Text" -Message "Blind carbon copy addresses (Specify multiple using a ',' delimiter): " -ValidateScript {
            # Check if it is an empty string.
            if ($_ -eq "") {
                break
            } 
            else {
                $BlindCarbonCopys = $_ -split "," 
                foreach ($BlindCarbonCopy in $BlindCarbonCopys) {
                    try {
                        [MailAddress]$BlindCarbonCopy
                    }
                    catch {
                        Write-Error -Message "The email string: $BlindCarbonCopy is not a valid email address" -ErrorAction "Stop"
                        break
                    }
                }
            }
        }
    )
    $AnyBox.Buttons = @(
        New-AnyBoxButton -Text "Close" -IsCancel
        New-AnyBoxButton -Text "Send email" -IsDefault
    )

    # Show AnyBox GUI and collect responses.
    $Response = $AnyBox | Show-AnyBox

    # Act on response.
    if ($Response["Send email"] -eq $true) {
        Write-Output -InputObject "Sending email..."
        # Get Input_2 value. Recipient.
        $Recipient = $Response.GetEnumerator() | Where-Object -FilterScript { $_.Name -eq "Input_2" } | Select-Object -Property "Value" -ExpandProperty "Value"
        # Split because PowerShell cannot work out how to convert a comma seperated string (example: "test,test") to String[].
        $Recipient = $Recipient -split ","
        # Get Input_4 value. CC.
        $Cc = $Response.GetEnumerator() | Where-Object -FilterScript { $_.Name -eq "Input_4" } | Select-Object -Property "Value" -ExpandProperty "Value"
        $Cc = $Cc -split ","
        # Get Input_5 value. Bcc.
        $Bcc = $Response.GetEnumerator() | Where-Object -FilterScript { $_.Name -eq "Input_5" } | Select-Object -Property "Value" -ExpandProperty "Value"
        $Bcc = $Bcc -split ","
        if ($Cc -and $Bcc) {
            # Cc and Bcc are present.
            Write-Output -InputObject "Sending email with Cc: $Cc and Bcc: $Bcc"
            Send-GdprEmail -SmtpServer $Response.Input_0 -EmailPassword $Response.Input_1 -Recipient $Recipient -From $Response.Input_3 -Cc $Cc -Bcc $Bcc -Verbose
        }
        elseif ($Cc) {
            # Only Cc is present.
            Write-Output -InputObject "Sending email with Cc: $Cc only"
            Send-GdprEmail -SmtpServer $Response.Input_0 -EmailPassword $Response.Input_1 -Recipient $Recipient -From $Response.Input_3 -Cc $Cc -Verbose
        }
        elseif ($Bcc) {
            # Only Bcc is present.
            Write-Output -InputObject "Sending email with Bcc: $Bcc only"
            Send-GdprEmail -SmtpServer $Response.Input_0 -EmailPassword $Response.Input_1 -Recipient $Recipient -From $Response.Input_3 -Bcc $Bcc -Verbose
        }
        else {
            # Neither are present.
            Write-Output -InputObject "Sending email without Cc and Bcc"
            Send-GdprEmail -SmtpServer $Response.Input_0 -EmailPassword $Response.Input_1 -Recipient $Recipient -From $Response.Input_3 -Verbose
        }
    }
}
