#!/usr/bin/perl

use strict;
use LWP;
use Data::Dumper;
use utf8;

my @ns_headers = (
   'User-Agent' => 'Mozilla/5.0 (IE 11.0; Windows NT 6.3; TopolM/7.0; .NET4.0E; .NET4.0C; rv:11.0) like Gecko',
   'Accept' => 'image/gif, image/x-xbitmap, image/jpeg,
        image/pjpeg, image/png, */*',
   'Accept-Charset' => 'iso-8859-1,*,utf-8',
   'Accept-Language' => 'en-US',
);


my @urllist;
my $counter;
my $curdir;
my $output = 'out.txt';

my $browser = LWP::UserAgent->new;


open OUT, ">$output";
for my $pagenum (1..140) {
	print "$pagenum\n";
	my $url = "https://www.defense.gov/Newsroom/Contracts/?Page=" . $pagenum;
	my $page = getpage($url);

	# Парсим ссылки на ежедневные странички с контрактами 
	# <a class="title" href='http://www.defense.gov/Newsroom/Contracts/Contract/Article/605969/' >

	while ($page =~ /<a class="title" href='(http:\/\/www.defense.gov\/Newsroom\/Contracts\/Contract\/Article\/\d+\/)' >Contracts For ([^<]+)<\/a>/) {
		my $url2 = $1; 
		my $date = $2;
		# Качаем ежедневную страничку с контрактами
		my $page2 = getpage( $url2 );
		
		# Парсим теперь её
		my @strings = split(/\n/, $page2);
		my $customer;
		for (@strings) {
			if (/<p style="text-align: center;"><b>([^<]+)<\/b><\/p>/) {
				$customer = $1;
			} elsif ($_ =~ /^<p>([^<]+)<\/p>/) {
				my $str = $1;
				my ($supplier) = $str =~ /^([^,]+),/; # Название подрядчика это всё, что до первоой запятой в строке
				my ($sum) = $str =~ /\$([,\d]+)/; # Сумма контракта - это цифры и запятые после символа доллара.
				print OUT "$date\t$customer\t$supplier\t$sum\t$str\n";
			}

		}
		$page = $';
	}
}
close OUT;

sub getpage($) {
	my $url = shift;
	my $response = $browser->get($url, @ns_headers);
	
	return $response -> content if ($response -> is_success);
	print $response -> status_line unless ($response -> is_success);
}
	
