#!/usr/bin/perl

use strict;
use JSON;
use Data::Dumper;

my $final_ref;

#List of shipID's as defined by zkillboard.
my @ship_types = (20183, 20185, 20187, 20189, 34328, 28848, 28850, 28846, 28844);

#Start year/mm/dd
my $start = '20170101';

#End year/mm/dd
my $end = '20170201';

#Unless you know what you are doing you shouldn't mess with anything past this line.
for (@ship_types) {
  my $json = `curl https://zkillboard.com/api/losses/shipID/$_/startTime/${start}0000/endTime/${end}0000/`;
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
          }
        }
      }
    }
  }
  print "Finished $_\n";
  sleep 5;
}

#This posts the kills to our KB. Will only output if a kill was missing.
for my $key (keys %$final_ref) {
  my $hash = $final_ref->{$key};
  my $out = `curl -s --data "submit_crest=Process+%21&crest_url=https://crest-tq.eveonline.com/killmails/$key/$hash/" http://kb.miniluv.co/?a=post`;
  if ($out !~ /That killmail has already been posted/) {
     print "$key was missing\n";
  }
}
