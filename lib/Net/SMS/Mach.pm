package Net::SMS::Mach;

# ABSTRACT: Send SMS messages via the Mach HTTP API

use strict;
use warnings;

use Carp;
use HTTP::Request::Common;
use LWP::UserAgent;

use constant {
    PROVIDER1 => "http://gw1.promessaging.com/sms.php",
    PROVIDER2 => "http://gw2.promessaging.com/sms.php",
    TIMEOUT  => 10
};

sub new {
    my ($class, %args) = @_;

    if (! exists $args{userid} || ! exists $args{password}) {
        Carp::croak("${class}->new() requires username and password as parameters\n");
    }

    my $self = \%args;
    bless $self, $class;
}

sub send_sms {
    my ($self, %args) = @_;

    my $ua = LWP::UserAgent->new();
    $ua->timeout(TIMEOUT);
    $ua->agent("Net::SMS::Mach/$Net::SMS::Mach::VERSION");

    $args{number} =~ s{\D}{}g;
    $args{number} = "+$args{number}";

    my $snr = "Opera Verification";
    my $enc = "ucs";

    my $hash = {
        dnr => $args{number},
        srn => $snr,
        msg => $args{message},
        enc => $enc,
    };

    my $url  = PROVIDER1;
    my $resp = $ua->request(POST $url, [ id => $self->{userid}, pass => $self->{password}, $hash ]);
    my $as_string = $resp->as_string;

    if (! $resp->is_success) {
        my $status = $resp->status_line;
        warn "HTTP request failed: $status\n$as_string\n";
        return 0;
    }

    my $res = $resp->content;
    chomp($res);

    my $return = 1;
    unless ($res =~ /^\+OK/) {
        warn "Failed: $res\n";
        $return = 0;
    }

    return wantarray ? ($return, $res) : $return;
}

1;

__END__

=pod

=head1 SYNOPSIS

  # Create a testing sender
  my $sms = Net::SMS::Mach->new(
      username => 'testuser', password => 'testpass'
  );

  # Send a message
  my ($sent, $status) = $sms->send_sms(
      message => "All your base are belong to us",
      number  => '1234567890',
  );

  $sent will contain a true / false if the sending worked,
  $status will contain the status message from the provider.

  # If you just want a true / false if it workes, use :
  my $sent = $sms->send_sms(
      message => "All your base are belong to us",
      number  => '1234567890',
  );

  # If you want a better description of the status message, use the
  # long_status parameter
  my ($sent, $status, $desc) = $sms->send_sms(
      message => "All your base are belong to us",
      number  => '1234567890',
      long_status => 1,
  );

  if ($sent) {
      # Success, message sent
  }
  else {
      # Something failed
      warn("Failed : $status");
  }

=head1 DESCRIPTION

Perl module to send SMS messages through the HTTP API provided by Mach
(Mach.com).

=head1 METHODS

=head2 new

new( username => 'testuser', password => 'testpass' )

Nothing fancy. You need to supply your username and password
in the constructor, or it will complain loudly.

=head2 send_sms

send_sms(number => $phone_number, message => $message)

Uses the API to send a message given in C<$message> to
the phone number given in C<$phone_number>.

Phone number should be given with only digits. No "+" or spaces, like this:

=over 4

=item C<1234567890>

=back

Returns a true / false value and a status message. The message is "success" if the server has accepted your query. It does not mean that the message has been delivered.
If the long_status argument is set, then it also returns a long description as the third value.

=head1 SEE ALSO

Mach website, http://www.Mach.com/
