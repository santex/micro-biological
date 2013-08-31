#!/usr/bin/perl -w

$|++;
use strict;
use File::Basename;
use File::Copy;
use File::Find;
use File::Path;
use IO::File;
use Digest::MD5 qw(md5_hex);
use Data::Dumper;
use Data::Printer;
use Digest::MD5 qw(md5_hex);
use AI::MicroStructure;
use AI::MicroStructure::ObjectSet;
use Env qw(PWD);
use Storable qw(lock_store lock_retrieve);
use Getopt::Long;
use Text::Autoformat;
our $curSysDate = `date +"%F"`;
    $curSysDate=~ s/\n//g;

our $files={};
our $out = "";
our $meta = AI::MicroStructure->new();
our @t = $meta->structures;


my $TOP = "/home/santex/data-hub";
my $TOP_URL = "http://www.stonehenge.com/merlyn/WebTechniques";
my $OUT = "/home/santex/";


our %opts = (cache_file => sprintf("%s/%s_micro.cache","/tmp",$curSysDate),
             dir        => "/home/santex",
             match      => "",
             mime       => "json",
             level=>1,
             scope=>1);

GetOptions (\%opts, "cache_file=s", "mime=s","match=s","dir=s","level=i","scope=i");

our $cache = {};



sub WITHIN {

}


## "use MyParser;" ##
BEGIN {
  our $found = 0;

  die() unless(@ARGV);
  
  package MyContent;

  use Data::Dumper;
  use Storable qw(lock_store lock_retrieve freeze thaw dclone);

  sub new {

    my $package = shift;
    my $self = bless {}, $package;
    my $cache={};
    eval {
        local $^W = 0;  # because otherwhise doesn't pass errors

        $cache = lock_retrieve($opts{cache_file});

        if($@){
          lock_strore($cache,$opts{cache_file});
        }
        $cache = {} unless $cache;

        warn "New cache!\n" unless defined $cache;



    };


    $self->{cache} = $cache;
    $self->{data} = @_;
    return $self;
  }

  sub DESTROY {

  my $self = shift;

  $self->{cache} = $cache;

  lock_store($self->{cache},$opts{cache_file});

#  print Dumper [$self->{cache}];



  }
  sub start {
    my $self = shift;
  }

  sub sxe {

  my ( @res ) = @_;
  my ($i, $t, $_);

  for ( @res ) { tr/a-zA-Z//cd; tr/a-zA-Z/A-ZA-Z/s;
      ($i,$t) = /(.)(.*)/;
      $i = "" unless($i);
      $t = "" unless($t);

     $t =~ tr/BFPVCGJKQSXZDTLMNRAEHIOUWY/111122222222334556/sd;
     $_ = substr(($i||'Z').$t.'000', 0, 4);

  }
  wantarray ? @res : $res[0];
}

  sub  decruft  {
    my($file)  =  @_;
    my($cruftSet)  =  q{%§&|#[^+*(  ]),'";  };

    my  $clean  =  $file;
    $clean =~ s/\.$opts{mime}//g;
    $clean=~s/\Q$_//g  for  split("",$cruftSet);

    return  $clean;
  }






sub translate {


  return unless -f;
  (my $rel_name = $File::Find::name) =~ s{.*/}{}xs;

  my $xname = $rel_name;

  
  if (/\.$opts{mime}$/ && $xname =~ m/$opts{match}/i) {

  $xname = MyContent::decruft($xname);
  
  my @words = split("(_| - | |,)",$xname);

  my @sy = MyContent::sxe(@words);



  @sy = grep{!/(00|A530|A500|0100)/}@sy;
  @sy = @sy[0..$opts{level}] unless($#sy<$opts{level});
    my $name=sprintf("%40s%s%s%4s%s",join("_",@sy)," ","|","\t"x1,$xname);
   # my $name=sprintf("%s",$xname);

    if($found % 250==1) {
#      printf "\n%3s\t",$found;
    }
    if($found % 10==1) {
 #     printf ".";
    }


    $found++;
    $files->{pdf}->{$name} = $xname;
    if($sy[0]){
    push @{$cache->{$sy[0]}},$xname;
    @{$cache->{$sy[0]}}=sort @{$cache->{$sy[0]}};
    }
 #   @{$cache->{$_}->{$words[0]}} = sort @{$cache->{$_}->{$words[0]}} for @sy;
  }
}

}


find(\&MyContent::translate, "$opts{dir}");


my @out = ();
my $app = new MyContent(@ARGV);
my $i = 1;
foreach(sort{$a cmp $b} keys %{$files->{pdf}}){
  my $row = $_;
     $row =~ s/ //g;

 $app->{last} = "" unless( $app->{last});

if(substr($app->{last},0,$opts{scope}*4) ne substr($row,0,$opts{scope}*4)){
  $out .= sprintf("...............................\n");
  @out = sort @out;
  $out .= sprintf(join("",@out));
  @out = ();
  $i=1;
}else{
  $i++;
}

push @out, sprintf autoformat { all => 1, ignore => sub { tr/\n/\n/ < 3
               } }, $_;
$app->{last} = $row;



};


END{
print $out;
}
1;
