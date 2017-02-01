#!/usr/bin/perl

use strict;
use JSON;
use Data::Dumper;
use Date::Calc qw(Today Add_Delta_Days);


my $debug = 0;
my $final_ref;

#List of shipID's as defined by zkillboard.
my @ship_types = (20183, 20185, 20187, 20189, 34328, 28848, 28850, 28846, 28844, 28606);

#Start year/mm/dd
my $start = get_date(1);
print "Start date: $start\n" if ($debug);

#End year/mm/dd
my $end = get_date(0);
print "End date: $end\n" if ($debug);

#Unless you know what you are doing you shouldn't mess with anything past this line.
for (@ship_types) {
  my $json = `curl -s https://zkillboard.com/api/losses/shipID/$_/startTime/${start}0000/endTime/${end}0000/`;
  my @test = decode_json($json);
  for my $first (@test) {
    for my $second (@$first) {
      my $kill_id = $second->{'killID'};
      my $hash = $second->{'zkb'}->{'hash'};
      for my $key (keys %$second) {
        for my $player (@{$second->{'attackers'}}) {
          my $pname = $player->{'characterName'};
          my $aname = $player->{'allianceName'};
          #This is a list of player names/alliances that if found causes the kill to be tagged as a miniluv kill. A little lame, but it should work.
          if ($pname eq 'Darnoth' || $pname eq 'Logical Fatality' || $pname eq 'BoneyTooth Thompkins ISK-Chip' || $pname eq 'BAE B BLUE' || $pname eq 'Jack Fizzleblade' || $pname eq 'Unfit ForDoody' || $aname eq 'Gimme Da Loot') {
            $final_ref->{$kill_id} = $hash;
            print "Found kill $kill_id with hash $hash. pname is $pname, aname is $aname\n" if ($debug == 2);
          }
        }
      }
    }
  }
  print "Finished $_\n" if ($debug);
  sleep 5;
}

#This posts the kills to our KB. Will only output if a kill was missing.
for my $key (keys %$final_ref) {
  my $hash = $final_ref->{$key};
  my $out = `curl -s --data "submit_crest=Process+%21&crest_url=https://crest-tq.eveonline.com/killmails/$key/$hash/" http://kb.miniluv.co/?a=post`;
  if ($out !~ /That killmail has already been posted/) {
     print "$key was missing\n" if ($debug);
  } else {
     print "$key was already posted\n" if ($debug);
  }
}

sub get_date {
  my $subtract = shift;
  my ($year,$month,$day) = Add_Delta_Days(Today(1), - $subtract);
  $month = sprintf('%02d', $month);
  $day = sprintf('%02d', $day);
  return "$year$month$day";
}
