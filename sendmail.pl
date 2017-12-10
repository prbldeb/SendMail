#!/usr/bin/env perl
# ---------------------------------------------------------------------------
#
# --------------------------------PURPOSE------------------------------------
#
# sendmail.pl: For sending HTML based mail, can be used in CI system
#
# -------------------------HISTORY OF DEVELOPMENT----------------------------
#
# Current Version 1.0.0
#
# v1.0.0 (07/12/2015, prbldeb)
#  original implementation
#
# ---------------------------------------------------------------------------

# Add modules directory to @INC
BEGIN {
    my $cpanModulepath = ( $0 =~ m/^(.*)\// )[0] . "/modules/CPAN";
	push(@INC, $cpanModulepath);
}

# Module Usage
use strict;
use MIME::QuotedPrint;
use MIME::Base64;
use Mail::Sendmail;

# Module Version
my $version = "1.0.0";

# Predeclarations of subroutines
sub CISendMail(%);

# Options and default values
my $mailServer = "localhost" # Mandatory parameter to be pre-configured
my $subject = "";
my $bodytext = "";
my $to = "";
my $cc = "";
my $attachment = "";
my $debug = 0;
my $showUsage = 0;

# Check command line options
if ( @ARGV != 0 ) {
	while (( @ARGV != 0 ) and ( $ARGV[0] =~ m/^-/ )) {
		if ( $ARGV[0] =~ m/s/ ) {
            $subject = $ARGV[1];
			shift(@ARGV);
			shift(@ARGV);
			next;
	    } elsif ( $ARGV[0] =~ m/b/ ) {
            $bodytext = $ARGV[1];
			shift(@ARGV);
			shift(@ARGV);
			next;
        } elsif ( $ARGV[0] =~ m/t/ ) {
            $to = $ARGV[1];
			shift(@ARGV);
			shift(@ARGV);
			next;
        } elsif ( $ARGV[0] =~ m/c/ ) {
            $cc = $ARGV[1];
			shift(@ARGV);
			shift(@ARGV);
			next;
        } elsif ( $ARGV[0] =~ m/a/ ) {
            $attachment = $ARGV[1];
			shift(@ARGV);
			shift(@ARGV);
			next;
        } elsif ( $ARGV[0] =~ m/d/ ) {
            $debug = 1;
			shift(@ARGV);
			next;
        } else {
			print "WARNING: Invalid Option " . $ARGV[0] . "\n";
			shift(@ARGV);
			$showUsage = 1;
			next;
		}
	}
}

# Validate Inputs
$showUsage = 1 if ($subject eq "");
$showUsage = 1 if ($bodytext eq "");
$showUsage = 1 if ($to eq "");

if ($showUsage) {
	print "ERROR: Invalid command line options - Check below Usage\n\n";
	print "USAGE:   $0 -s [Subject] -b [Body(HTML)] -t [To Adresses (,) separated] -c [CC Adresses] -a [Attachment] -d\n\n\n";
	print "            -s   :   Mail Subject (Mandatory)\n\n";
	print "            -b   :   Mail Body Text (Mandatory)\n\n";
	print "            -t   :   Mention To mail addresses (,) seprtaed (Mandatory)\n\n";
	print "            -c   :   Mention CC mail addresses (,) seprtaed (Optional)\n\n";
	print "            -a   :   Mention Attachment File (Optional)\n\n";
	print "            -d   :   If specified it will print the send message logs (Optional)\n\n";
	exit (1);
}

# Create Message HTML body
my $body;
$bodytext =~ s/\n/<br>/g;
$body .= "<html>\n";
$body .= "<head><style type=\"text/css\">\n";
$body .= "<!--\n";
$body .= " .fontheading\n {\n  font-family: Arial;\n  font-size: 18px;\n font-weight: bold;\n}\n";
$body .= " .fontnormal\n {\n  font-family: Arial;\n  font-size: 15px;\n font-weight: normal;\n}\n";
$body .= "-->\n";
$body .= "</style></head>\n";
$body .= "<body bgcolor=\"#ffffff\" text=\"#000000\">\n";
$body .= "<font class=\"fontnormal\">" . $bodytext . "</font><br><br>";
$body .= "</body>\n";
$body .= "</html>\n";

# Setup Mail and Send
my %mail = (
		From	=> "CI Mail<nomail\@nobody.com>",
		To	=> $to,
		Cc	=> $cc,
		Subject => $subject,
		Message => $body,
		'Content-Type' => "text/html",
		Attachment => $attachment
	);
my $result = CISendMail(%mail);
print ("$result\n") if ($debug);
exit (0);

# Subroutine send
sub CISendMail(%)
{
	# Backup values of $/ and $\ as the Mail::Sendmail module changes them
	my $slashbackup = $/;
	my $backslashbackup = $\;

	# Mail server configuration
	unshift @{$Mail::Sendmail::mailcfg{'smtp'}} , $mailServer;
	
	# Input parameters
	my %input = @_;
	
	# Make sure that we have all input prameters
	unless (( defined($input{'From'}) ) and ( defined($input{'To'}) ) and ( defined($input{'Subject'}) ) and ( defined($input{'Message'}) ))
	{
		return(1);
	}

	# Get sender UID
	my $senderuid = $input{'From'};
	my $sender = "";
	$sender = $senderuid;

	# Get target UIDs
	my $targetuids = $input{'To'};
	my $target = "";
	if ( $targetuids =~ m/,/ )
	{
		my @targets = split(",", $targetuids);
		foreach my $targetuid (@targets)
		{
			$target .= $targetuid . ", ";
		}
		$target =~ s/, $//;
	}
	else
	{
		$target = $targetuids;
	}
	
	# Check CC
	my $cc = "";
	if ( defined $input{'Cc'} )
	{
		my $ccuids = $input{'Cc'};
		if ( $ccuids =~ m/,/ )
		{
			my @ccs = split(",", $ccuids);
			foreach my $ccuid (@ccs)
			{
				$cc .= $ccuid . ", ";
			}
			$cc =~ s/, $//;
		}
		else
		{
			$cc = $ccuids;
		}
	}
	
	# Check BCC
	my $bcc = "";
	if ( defined $input{'Bcc'} )
	{
		my $bccuids = $input{'Bcc'};
		if ( $bccuids =~ m/,/ )
		{
			my @bccs = split(",", $bccuids);
			foreach my $bccuid (@bccs)
			{
				$bcc = $bccuid . ", ";
			}
			$bcc =~ s/, $//;
		}
		else
		{
			$bcc = $bccuids;
		}
	}

	# Check Content-Type
	my $ct = "text/plain";
	if ( defined $input{'Content-Type'} )
	{
		$ct = $input{'Content-Type'};
	}

	# Setup mail hash
	my %mail = (
			From	=> $sender,
			To	=> $target,
			Cc	=> $cc,
			Bcc	=> $bcc,
			Subject => $input{'Subject'},
			'X-Mailer' => "CISendMail version " . $version . " using Mail::Sendmail version " . $Mail::Sendmail::VERSION
		);
		
	# Check priority
	if ( defined $input{'Priority'} )
	{
		if ( $input{'Priority'} == 1 )
		{
			%mail = (
				From	=> $sender,
				To	=> $target,
				Cc	=> $cc,
				Bcc	=> $bcc,
				Subject => $input{'Subject'},
				'X-Mailer' => "CISendMail version " . $version . " using Mail::Sendmail version " . $Mail::Sendmail::VERSION,
				'X-Priority' => "1",
				'Priority' => "Urgent",
				'Importance' => "high"
			);
		}
	}
	
	# Message body
	my $boundary = "====" . time() . "====";
	$mail{'Content-Type'} = "multipart/mixed; boundary=\"" . $boundary . "\"";
	$boundary = "--" . $boundary;
	my $body = "";
	my $message = encode_qp($input{'Message'});
	$body .= $boundary . "\n";
	$body .= "Content-Type: " . $ct . "; charset=\"iso-8859-1\"\n";
	$body .= "Content-Transfer-Encoding: quoted-printable\n\n";
	$body .= $message . "\n\n";
	
	# Check Attachments
	if ( defined $input{'Attachment'} )
	{
		my $attachment = $input{'Attachment'};
		if ( $attachment =~ m/,/ )
		{
			my @attachments = split(",", $attachment);
			foreach my $attachment (@attachments)
			{
				if (( -f $attachment ) and ( -r $attachment ))
				{
					my $attachmentname = $attachment;
					if ( $attachmentname =~ m/\// )
					{
						my @tmp = split("/", $attachmentname);
						$attachmentname = pop(@tmp);
					}
					
					if ( open(ATTACHMENT, "<$attachment") )
					{
						$body .= $boundary . "\n";
						$body .= "Content-Type: application/octet-stream; name=\"" . $attachmentname . "\"\n";
						$body .= "Content-Transfer-Encoding: base64\n";
						$body .= "Content-Disposition: attachment; filename=\"" . $attachmentname . "\"\n\n";
						
						binmode ATTACHMENT;
						undef $/;
						$body .= encode_base64(<ATTACHMENT>);
						close(ATTACHMENT);
					}
				}
				
			}
		}
		else
		{
			if (( -f $attachment ) and ( -r $attachment ))
			{
				my $attachmentname = $attachment;
				if ( $attachmentname =~ m/\// )
				{
					my @tmp = split("/", $attachmentname);
					$attachmentname = pop(@tmp);
				}

				if ( open(ATTACHMENT, "<$attachment") )
				{
					$body .= $boundary . "\n";
					$body .= "Content-Type: application/octet-stream; name=\"" . $attachmentname . "\"\n";
					$body .= "Content-Transfer-Encoding: base64\n";
					$body .= "Content-Disposition: attachment; filename=\"" . $attachmentname . "\"\n\n";

					binmode ATTACHMENT;
					undef $/;
					$body .= encode_base64(<ATTACHMENT>);
					close(ATTACHMENT);
				}
			}
		}
	}
	
	# End mail body
	$body .= $boundary . "--";
	
	# Set mail body
	$mail{'Body'} = $body;

	# Send mail and return	
	if ( Mail::Sendmail::sendmail(%mail) )
	{
		return ($Mail::Sendmail::log);
	}
	else
	{
		return($Mail::Sendmail::log);
	}
	
	# Restore values of $/ and $\
	$/ = $slashbackup;
	$\ = $backslashbackup;
	
	return(0);
}
