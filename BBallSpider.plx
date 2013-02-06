#!/usr/bin/perl
use strict;
use warnings;
use HTML::TokeParser;
use WWW::Mechanize;
use DBI;

my $dbh;
$dbh = DBI->connect("DBI:mysql:database=bball;host=localhost", "user", "pass")
or die $DBI::errstr;

my @date = (20121109 .. 20121199);
my $date;
foreach $date (@date) {
	
	my $gameagent = WWW::Mechanize->new();
	$gameagent->get("http://espn.go.com/mens-college-basketball/schedule?date=$date");
	my $p = HTML::TokeParser->new(\$gameagent->{content});

	my $token;
	my $gamelink;
	my @gamelinks;


	while($token = $p->get_tag("a")) {					#get gameids for each game played on this date
		# print "test\n";
		if ($token->[1]{href} and $token->[1]{href} =~ m/boxscore/) {
			# print "test2\n";
			$gamelink = $token->[1]{href};
			# print "$gamelink\n";
			push (@gamelinks, $gamelink);
		}
		
	}
	
	foreach $gamelink (@gamelinks) {
		my $agent = WWW::Mechanize->new();
		$agent->get("$gamelink");
		my $p = HTML::TokeParser->new(\$agent->{content});
		my $check = 116969;
		my $token;
		my $teamToken;
		my $data;
		my $team;
		my $fgm;
		my $fga;
		my $threesm;
		my $threesa;
		my $ftm;
		my $fta;
		my $oreb;
		my $reb;
		my $ast;
		my $stl;
		my $blk;
		my $to;
		my $pf;
		my $pts;
		my $test = 6969;
		my $home;
		my $away;
		my $awayid;
		my $homeid;
		my $num=0;
		my $homeflag=0;
		my $gameid;
		my ($hfgm, $hfga, $afgm, $afga, $hthreesm, $hthreesa, $athreesm, $athreesa, $hftm, $hfta, $aftm, $afta, $horeb, $aoreb, $hdreb, $adreb, $hreb, $areb, $hast, $aast, $hstl, $astl, $hblk, $ablk, $hto, $ato, $hpf, $apf, $hpts, $apts);
		$p = HTML::TokeParser->new(\$agent->{content});
		$gamelink =~ m/id=(\d*)/;
		$gameid = $1;

		#get team names
		while ($teamToken = $p->get_tag("thead")) {
			while($team = $p->get_tag("div")) {	#team names are after a <div> in a <thead>
				if ($team->[1]{class} and $team->[1]{class} =~ /teamId-(\d*)/) { 	#the <div> right before the team name contains the teamId in a class statement
					my $teamid = $1;
					$team = $p->get_trimmed_text("/th");				#the team name is the only text in the <th> so the </th> immediately follows the name
					if ($homeflag eq 0) {
						$away = $team;
						$awayid = $teamid;
					} else {$home = $team; $homeid = $teamid;}
					$homeflag = $homeflag +1;
				}
			}
			# print "$test\n";
		}
		print "Home: $home ($homeid), Away: $away ($awayid)\n";
		$home = $dbh->quote($home);
		$away = $dbh->quote($away);
		$p = HTML::TokeParser->new(\$agent->{content});
		$num=0;
		#get totals for each team
		while ($token = $p->get_tag("tr")) {
			if ($token->[1]{class} and $token->[1]{class} eq "even bi") {	#the totals are in a <tr> with a class="even bi" statement
				$data = $p->get_trimmed_text("/tr");			#this returns all the totals
				# print "$data\n";
				my @splitdata = split(/ /, $data);
				print "split: @splitdata\n";
				my $fieldgoals = $splitdata[0];
				my @fieldgoalssplit = split(/-/, $fieldgoals);
				$fgm = $fieldgoalssplit[0];
				$fga = $fieldgoalssplit[1];
				print "$fgm = fgm\n";
				my $threes = $splitdata[1];
				my @threessplit = split(/-/, $threes);
				$threesm = $threessplit[0];
				$threesa = $threessplit[1];
				my $frees = $splitdata[2];
				my @freessplit = split(/-/, $frees);
				$ftm = $freessplit[0];
				$fta = $freessplit[1];
				my $dreb = $splitdata[4] - $splitdata[3];
				if ($num eq 0) {
					print "@splitdata\n";
					$afgm = $fgm;
					$afga = $fga;
					$athreesm = $threesm;
					$athreesa = $threesa;
					$aftm = $ftm;
					$afta = $fta;
					$aoreb = $splitdata[3];
					$adreb = $dreb;
					$areb = $splitdata[4];
					$aast = $splitdata[5];
					$astl = $splitdata[6];
					$ablk = $splitdata[7];
					$ato = $splitdata[8];
					$apf = $splitdata[9];
					$apts = $splitdata[10];
				} else {
					print "@splitdata\n";
					$hfgm = $fgm;
					$hfga = $fga;
					$hthreesm = $threesm;
					$hthreesa = $threesa;
					$hftm = $ftm;
					$hfta = $fta;
					$horeb = $splitdata[3];
					$hdreb = $dreb;
					$hreb = $splitdata[4];
					$hast = $splitdata[5];
					$hstl = $splitdata[6];
					$hblk = $splitdata[7];
					$hto = $splitdata[8];
					$hpf = $splitdata[9];
					$hpts = $splitdata[10];
				}
				$num = $num+1;
				print "$num\n";
				
				# foreach $stats (@stats) {
					# print "$dta\n";
					# @stats = shift($dta);
				# }
				# print "$FG\n";
				# print "stats: @stats";
			}
		}

		my $sth;
				my $statsquery = 'insert into stats (gameid, home, homeid, away, awayid, hfgm, hfga, h3pm, h3pa, hftm, hfta, horeb, hdreb, hreb, hast, hstl, hblk, hto, hpf, hpts, afgm, afga, a3pm, a3pa, aftm, afta, aoreb, adreb, areb, aast, astl, ablk, ato, apf, apts) values ('
				. $gameid . ', ' . $home . ', ' . $homeid . ', ' . $away . ', ' . $awayid . ', '
				. $hfgm . ', ' . $hfga . ', ' . $hthreesm . ', ' . $hthreesa . ', ' . $hftm . ', ' . $hfta . ', '
				. $horeb . ', ' . $hdreb . ', ' . $hreb . ', ' . $hast . ', ' . $hstl . ', '
				. $hblk . ', ' . $hto . ', ' . $hpf . ', ' . $hpts . ', '
				. $afgm . ', ' . $afga . ', ' . $athreesm . ', ' . $athreesa . ', ' . $aftm . ', ' . $afta . ', '
				. $aoreb . ', ' . $adreb . ', ' . $areb . ', ' . $aast . ', ' . $astl . ', '
				. $ablk . ', ' . $ato . ', ' . $apf . ', ' . $apts . ');';
				$sth= $dbh->prepare($statsquery) or die $DBI::errstr;
				
				$sth->execute();
				$sth->finish();
		

	}
}
