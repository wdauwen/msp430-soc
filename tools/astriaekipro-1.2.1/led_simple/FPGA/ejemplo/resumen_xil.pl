#!/usr/bin/perl
$version="0.1.0";

$argc=scalar(@ARGV);
ShowProgram();
if ($argc!=3)
  {
   ShowUsage();
   exit(1);
  }

$project=@ARGV[0];
$dir_xilinx=@ARGV[1];
$changelog=@ARGV[2];

print FIL "Entity: $top | Part: $part | Optimized for: $optt | Constrained: $const\n\n";
$a=cat("$project.xst");
$top=$1  if $a=~/-top\s+(\S*)/;
$part=$1 if $a=~/-p\s+(\S*)/;
$optt=$1 if $a=~/-opt_mode\s+(\S*)/;
$const='no';
$const=$1 if $a=~/-uc\s+(\S*)/;
$a='';

ParseResults();
1;

sub ShowProgram
{
 print "resumen_xil v$version Copyright (c) 2006-2007 Salvador E. Tropea/INTI\n";
}

sub ShowUsage
{
 print "Usage:\n";
 print "resumen_xil.pl project dir_xilinx changelog\n";
}

sub replace
{
 my $b=$_[1];

 open(FIL,">$_[0]") || return 0;
 print FIL ($b);
 close(FIL);
}

sub cat
{
 local $/;
 my $b;

 open(FIL,$_[0]) || return 0;
 $b=<FIL>;
 close(FIL);

 $b;
}

sub MakeSep
{
 my ($ch)=@_;
 my ($i);

 for ($i=0; $i<80; $i++)
    {
     print FIL $ch;
    }
 print FIL "\n";
}

sub ParseResults()
{
 my ($in,$ff,$fft,$ffp,$lut,$lutt,$lutp,$lutl,$lutlp,$sl,$slt,$slp);
 my ($br,$brt,$brp,$per,$freq,$rev);

 # Map report
 $in=cat("$dir_xilinx/$project".'_map.mrp');
 $in=~/Number of Slice Flip Flops:\s+([\d,]+) out of\s+([\d,]+)/ or die "FFs";
 $ff=$1;
 $fft=$2;
 $ff=~s/,//g;
 $fft=~s/,//g;
 $ffp=$ff/$fft*100;
 $in=~/Total Number (of )?4 input LUTs:\s+([\d,]+) out of\s+([\d,]+)/ or die "LUTs tot";
 $lut=$2;
 $lutt=$3;
 $lut=~s/,//g;
 $lutt=~s/,//g;
 $lutp=$lut/$lutt*100;
 $in=~/Number of 4 input LUTs:\s+([\d,]+) out of\s+([\d,]+)/ or die "LUTs log";
 $lutl=$1;
 $lutl=~s/,//g;
 $lutlp=$lutl/$lut*100;
 $in=~/Number of occupied Slices:\s+([\d,]+) out of\s+([\d,]+)/ or die "Slices";
 $sl=$1;
 $slt=$2;
 $sl=~s/,//g;
 $slt=~s/,//g;
 $slp=$sl/$slt*100;
 $in=~/Number of Block RAMs:\s+([\d,]+) out of\s+([\d,]+)/;
 $br=$1;
 $brt=$2;
 $br=~s/,//g;
 $brt=~s/,//g;
 $brp=$br/$brt*100 if $brt;

 # Time report
 $in=cat("$dir_xilinx/$project".'.twr');
 $in=~/Minimum period:\s+([\d\.]+)ns/ or die "Time";
 $per=$1;
 $freq=1/$per*1000;

 # Changelog
 $in=cat($changelog);
 $in=~/Revision ([\d\.]+)/ or die "Changelog\n";
 $rev=$1;

 open(FIL,">>$project.txt") or die;
 print FIL "Revision: $rev - ".`date`."\n";
 print FIL "Entity: $top | Part: $part | Optimized for: $optt | Constrained: $const\n\n";
 printf FIL "Flip Flops: %5d/%d %5.2f %%\n",$ff,$fft,$ffp;
 printf FIL "LUTs:       %5d/%d %5.2f %% (%d/%d logic/route %5.2f %%)\n",
        $lut,$lutt,$lutp,$lutl,$lut-$lutl,$lutlp;
 printf FIL "Slices:     %5d/%d %5.2f %%\n",$sl,$slt,$slp;
 MakeSep('-');
 printf FIL "BRAMs:      %5d/%d %5.2f %%\n",$br,$brt,$brp if $br;
 MakeSep('-');
 printf FIL "Max. Clock:  %5.2f MHz (%5.2f ns)\n",$freq,$per;
 MakeSep('*');
 print FIL "\n\n";
 close(FIL);
}
