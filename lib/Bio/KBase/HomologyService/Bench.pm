#
# Little class for wrapping up call benchmarking (execution time & network use)
#

package Bio::KBase::HomologyService::Bench;

use strict;
use Time::HiRes 'gettimeofday';

sub new
{
    my($class, $netif) = @_;

    if (!$netif)
    {
	if (open(my $fh, "<", "/proc/net/route"))
	{
	    while (<$fh>)
	    {
		chomp;
		my($if, $dest, $gw) = split(/\t/);
		if ($dest =~ /^0+$/)
		{
		    $netif = $if;
		    print STDERR "Chose network $if\n";
		    last;
		}
	    }
	    close($fh);
	}
    }

    my $self = {
	netif => $netif,
    };

    bless $self, $class;

    $self->start();

    return $self;
}

sub start
{
    my($self) = @_;

    $self->{start_time} = gettimeofday;

    my $ns = $self->get_netstats();

    $self->{start_stats} = $ns;
}

sub finish
{
    my($self) = @_;

    $self->{finish_time} = gettimeofday;

    my $ns = $self->get_netstats();

    $self->{finish_stats} = $ns;
}

sub stats
{
    my($self) = @_;
    my $dur = $self->{finish_time} - $self->{start_time};
    my $rcvd = $self->{finish_stats}->[0] - $self->{start_stats}->[0];
    my $sent = $self->{finish_stats}->[1] - $self->{start_stats}->[1];
    my $in_rate = $rcvd / $dur;
    my $out_rate = $sent / $dur;
    return { dur => $dur, bytes_received => $rcvd, bytes_sent => $sent,  in_rate => $in_rate, out_rate => $out_rate };
}

sub stats_text
{
    my($self) = @_;
    my $stats = $self->stats;

    return join(" ", map { "$_=$stats->{$_}" } keys %$stats);
}


sub get_netstats
{
    my($self) = @_;
    return undef unless $self->{netif};
    if (open(my $fh, "<", "/proc/net/dev"))
    {
	while (<$fh>)
	{
	    if (/^\s*$self->{netif}:\s*(.*)/)
	    {
		my @vals = split(/\s+/, $1);
		close($fh);
		return [@vals[0,8] ];
	    }
	}
	close($fh);
    }
    return undef;
}

1;
