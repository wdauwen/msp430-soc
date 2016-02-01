#!/usr/bin/perl
while (<>)
  {
   print $1 if $_=~/VERSION \"(.*)\"/;
  }
