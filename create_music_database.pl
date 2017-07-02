use warnings;
use strict;
use MP3::Tag;
use Path::Class;
use DBI;



my @files;
dir('.')->recurse(callback => sub {
    my $file = shift;
    if($file =~ /\.mp3/) {
        push @files, $file->absolute->stringify;
    }
});

my $driver   = "SQLite"; 
my $database = "music.db";
my $dsn = "DBI:$driver:dbname=$database";
my $dbh = DBI->connect($dsn, { RaiseError => 1 }) or die $DBI::errstr;
$dbh->do("DROP TABLE IF EXISTS Songs");
$dbh->do("CREATE TABLE Songs (id INT, path TEXT, title TEXT, artist TEXT, year TEXT, album TEXT)");
my $n = 1;
foreach my $file (@files){
	my $mp3 = MP3::Tag->new($file); # create object

	$mp3->get_tags(); # read tags

	if (exists $mp3->{ID3v2}) { # print track information
		my $artist = $mp3->{ID3v2}->artist;
		my $title = $mp3->{ID3v2}->title;
		my $year = $mp3->{ID3v2}->year;
		my $album = $mp3->{ID3v2}->album;
		my $stmt = "INSERT INTO Songs (id,path,title,artist,year,album)
		VALUES (?,?,?,?,?,?)";
		my $sth = $dbh->prepare($stmt);
		$sth->execute($n,$file,$title,$artist,$year,$album);
		$n++;
	}
	else{
		print "No Tags found for $file\n"
	}

	$mp3->close(); # destroy object
}
$dbh->disconnect();