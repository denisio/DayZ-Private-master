#!/usr/bin/perl -w
# Reality build utility 
# forked from Bliss by ayan4m1, updated by Thevisad

use Config::IniFiles;
use Getopt::Long qw(:config pass_through);

use File::Copy;
use File::Path qw(make_path remove_tree);
use File::Slurp;
use File::Basename;
use File::DirCompare;

use Text::Diff qw(diff);
use Text::Patch;

use Digest::SHA qw(sha1_hex);
use Time::HiRes qw(time);
use List::Util qw(max min);
use JSON;

our %args;
GetOptions(
	\%args,
	'rcon|password|pass|p=s',
	'world|w|map|mission|m=s',
	'instance|id|i=s',
	'channels|chat=s',
	'serverpassword|spass=s',
	'serveradminpassword|admpass=s',
	'servername|sname=s',
	'locationid|lid=s',
	'serverbuild|sbuild=s',
	'hostedby|host=s',
	'battleyepassword|bepass=s',
	'serverdifficulty|diff=s',
	'dayzversion|dz=s',
	'hivehost|hhost=s',
	'hiveport|hport=s',
	'hivedatabase|hdb=s',
	'hiveusername|huser=s',
	'hivepassword|hpass=s',
	'hiveloglevel|hll=s',
	'hiveconsolelevel|hcl=s',
	'hiveconsole|hc=s',
	'serverversion|sver=s',
	'datetype=s',
	'year=s',
	'month=s',
	'date=s',
	'timetype=s',
	'timeoffset=s',
	'hour=s',
	'minbandwidth=s',
	'maxbandwidth=s',
	'maxmsgsend=s',
	'maxsizeguaranteed=s',
	'maxsizenonguaranteed=s',
	'minerrortosendnear=s',
	'minerrortosend=s',
	'maxcustomfilesize=s',
	'windowed=s',
	'adapter=s',
	'3D_performance=s',
	'resolution_bpp=s',
	'maxpacketsize=s',
	'hiveversion=s',
	'list',
	'clean',
	'help'
);

# Set defaults if options are not specified
# Config File Settings
$args{'serverpassword'} = ($args{'serverpassword'}) ? ($args{'serverpassword'}) : '';
$args{'serveradminpassword'} = ($args{'serveradminpassword'}) ? ($args{'serveradminpassword'}) : '';
$args{'servername'} = ($args{'servername'}) ? ($args{'servername'}) : 'CHANGEME';
$args{'locationid'} = ($args{'locationid'}) ? ($args{'locationid'}) : '';
$args{'serverbuild'} = ($args{'serverbuild'}) ? ($args{'serverbuild'}) : 'CHANGEME';
$args{'hostedby'} = ($args{'hostedby'}) ? ($args{'hostedby'}) : 'CHANGEME';
$args{'battleyepassword'} = ($args{'battleyepassword'}) ? ($args{'battleyepassword'}) : 'CHANGEME';
$args{'serverdifficulty'} = ($args{'serverdifficulty'}) ? ($args{'serverdifficulty'}) : 'CHANGEME';
$args{'dayzversion'} = ($args{'dayzversion'}) ? ($args{'dayzversion'}) : 'CHANGEME';
$args{'hiveversion'} = ($args{'hiveversion'}) ? ($args{'hiveversion'}) : 'oldversion';

# Hive settings
$args{'hivehost'} = ($args{'hivehost'}) ? ($args{'hivehost'}) : '127.0.0.1';
$args{'hiveport'} = ($args{'hiveport'}) ? ($args{'hiveport'}) : '3306';
$args{'hivedatabase'} = ($args{'hivedatabase'}) ? ($args{'hivedatabase'}) : 'dayz';
$args{'hiveusername'} = ($args{'hiveusername'}) ? ($args{'hiveusername'}) : 'CHANGEME';
$args{'hivepassword'} = ($args{'hivepassword'}) ? ($args{'hivepassword'}) : 'CHANGEME';
$args{'hiveconsole'} = ($args{'hiveconsole'}) ? ($args{'hiveconsole'}) : 'true';
$args{'hiveconsolelevel'} = ($args{'hiveconsolelevel'}) ? ($args{'hiveconsolelevel'}) : 'warning';
$args{'hiveloglevel'} = ($args{'hiveloglevel'}) ? ($args{'hiveloglevel'}) : 'warning';

$args{'datetype'} = ($args{'datetype'}) ? lc($args{'datetype'}) : 'local';
$args{'year'} = ($args{'year'}) ? ($args{'year'}) : ';Year = 2012';
$args{'month'} = ($args{'month'}) ? ($args{'month'}) : ';Month = 1';
$args{'date'} = ($args{'date'}) ? ($args{'date'}) : ';Date = 1';
$args{'timetype'} = ($args{'timetype'}) ? lc($args{'timetype'}) : 'local';
$args{'timeoffset'} = ($args{'timeoffset'}) ? ($args{'timeoffset'}) : ';Offset = 0';
$args{'hour'} = ($args{'hour'}) ? ($args{'hour'}) : ';Hour = 8';

# Basic.cfg settings
$args{'minbandwidth'} = ($args{'minbandwidth'}) ? ($args{'minbandwidth'}) : '104857600';
$args{'maxbandwidth'} = ($args{'maxbandwidth'}) ? ($args{'maxbandwidth'}) : '1073741824';
$args{'maxmsgsend'} = ($args{'maxmsgsend'}) ? ($args{'maxmsgsend'}) : '256';
$args{'maxsizeguaranteed'} = ($args{'maxsizeguaranteed'}) ? ($args{'maxsizeguaranteed'}) : '128';
$args{'maxsizenonguaranteed'} = ($args{'maxsizenonguaranteed'}) ? ($args{'maxsizenonguaranteed'}) : '256';
$args{'minerrortosendnear'} = ($args{'minerrortosendnear'}) ? ($args{'minerrortosendnear'}) : '0.03';
$args{'minerrortosend'} = ($args{'minerrortosend'}) ? ($args{'minerrortosend'}) : '0.003';
$args{'maxcustomfilesize'} = ($args{'maxcustomfilesize'}) ? ($args{'maxcustomfilesize'}) : '0';
$args{'windowed'} = ($args{'windowed'}) ? ($args{'windowed'}) : '0';
$args{'adapter'} = ($args{'adapter'}) ? ($args{'adapter'}) : '-1';
$args{'3D_performance'} = ($args{'3D_performance'}) ? ($args{'3D_performance'}) : '1';
$args{'resolution_bpp'} = ($args{'resolution_bpp'}) ? ($args{'resolution_bpp'}) : '32';
$args{'maxpacketsize'} = ($args{'maxpacketsize'}) ? ($args{'maxpacketsize'}) : '1400';

# Generic Settings for build purposes
$args{'world'} = ($args{'world'}) ? lc($args{'world'}) : 'chernarus';
$args{'instance'} = '1' unless $args{'instance'};
$args{'serverversion'} = '18' unless $args{'serverversion'};

# Initialize paths
our $base_dir = dirname(__FILE__);
our $tmp_dir  = "$base_dir/tmp";
our $wld_dir  = "$base_dir/pkgs/pkg". $args{'serverversion'} ."/world";
our $bls_dir  = "$base_dir/pkgs/pkg". $args{'serverversion'} ."/reality";
our $msn_dir  = "$base_dir/missions/mission". $args{'serverversion'};
our $src_dir  = "$base_dir/util/dayz_server_" . $args{'serverversion'};
our $dst_dir  = "$base_dir/deploy";
our $flt_dir  = "$base_dir/filter";
our $build_dir     = "$tmp_dir/dayz_server";
our $msn_build_dir = "$tmp_dir/mission_tmp";
our $pkg_build_dir = "$tmp_dir/package_tmp";

if ($args{'help'}) {
	print "usage: build.pl [--world <world>] [--instance <id>] [--with-<option>] [--clean] [--channels <channels>] [--rcon <password>] [--list]\n";
	print "    --world <world>: build an instance for the specified map/world\n";
	print "    --serverpassword <>";
	print "    --serveradminpassword <>";
	print "    --servername <>";
	print "    --locationid <>";
	print "    --serverbuild <>";
	print "    --hostedby <>";
	print "    --battleyepassword <>";
	print "    --instance <id>: build an instance with the specified integer instance id\n";
	print "\n";
	print "    --with-<package>: merge in changes from ./pkg/<package>/ during build\n";
	print "    --clean: remove all files in ./tmp/ and perform no further action\n";
	print "    --channels: set comma-separated list of channel ids to disable\n";
	print "    --rcon: set rcon/admin password\n";
	print "    --serverversion: set which server version to work with\n";
	print "    --list: lists all available worlds and packages\n";
	exit;
} elsif ($args{'list'}) {
	opendir (my $dh, "$msn_dir/world");
	my @missions = readdir $dh;
	closedir $dh;

	print "Available worlds:\n";
	foreach my $world (@missions) {
		print "    $world\n" unless ($world =~ m/^\./);
	}
	print "\n";

	opendir $dh, "$base_dir/pkgs/pkg" . $args{'serverversion'};
	my @pkgs = readdir $dh;
	closedir $dh;

	print "Available options for server version " . $args{'serverversion'} . "\n";
	foreach my $pkg (@pkgs) {
		print "    --with-$pkg\n" unless ($pkg =~ m/(^\.|world|reality)/);
	}
	exit;
} elsif ($args{'clean'}) {
	print "INFO: Removing $dst_dir\n";
	remove_tree($dst_dir);
	print "INFO: Removing $tmp_dir\n";
	remove_tree($tmp_dir);
	exit;
}

die "FATAL: Source dir $src_dir does not exist\n" unless (-d $src_dir);
die "FATAL: Mission dir $msn_dir/world/$args{'world'} does not exist\n" unless (-d "$msn_dir/world/$args{'world'}");

# Create deploy directory and get build paths ready
if ($args{'hiveversion'} eq "oldversion" ) { copy_dir("$base_dir/util/deploy", $dst_dir) unless (-d $dst_dir);}
if ($args{'hiveversion'} eq "genderversion" ) { copy_dir("$base_dir/util/deploy", $dst_dir) unless (-d $dst_dir);}
if ($args{'hiveversion'} eq "newversion" ) { copy_dir("$base_dir/util/newdeploy", $dst_dir) unless (-d $dst_dir);}
#copy_dir("$base_dir/util/deploy", $dst_dir) unless (-d $dst_dir);
make_path($tmp_dir) unless (-d $tmp_dir);



	
# Make all modifications to deploy directory
my $profile  = "dayz_$args{'instance'}.$args{'world'}";
my $src      = "$base_dir/util/dayz_config";
my $conf_dir = "$dst_dir/$profile";

# Only create config directory if it does not exist
if (-d $src && !-d $conf_dir) {
	# Copy base config directory to the instance-specific path
	print "INFO: Creating configuration $profile\n";
	copy_dir($src, $conf_dir);

	# Ensure proper mission name is specified in config.cfg
	replace_text("s/template\\s=\\sdayz_[0-9]+.[a-z]+/template = $profile/", "$conf_dir/config.cfg");

	my $mods = {
		'chernarus'           => '@dayz;expansion\beta;expansion\beta\expansion;Expansion\beta\expansion\addons',
		'lingor'              => '@DayZHuntingGrounds',
		'takistan'            => '@dayztakistan',
		'fallujah'            => '@dayzfallujah',
		'zargabad'            => '@dayzzargabad',
		'panthera2'           => '@dayzpanthera',
		'namalsk'             => '@DayZ_Namalsk;@DayZ_Namalsk_@DayZ',
		'mbg_celle2'          => '@Dayz_Conflicts;@dayz_celle;@mbg_celle',
		'tavi'                => '@Taviana',
		'i44.chernarus'       => 'expansion\beta;expansion\beta\expansion;Expansion\beta\expansion\addons;@DayZ_i44;@I44;@CBA;@CBA_A2;@CBA_OA;@CBA_CO',
		'dayz2017.chernarus'  => '@DayZ2017'
	};
	my $mod = ((defined $mods->{$args{'world'}}) ? "$mods->{$args{'world'}}" : '@dayz') . ";\@reality_$args{'instance'}.$args{'world'}";

	my $dst_ini  = "$dst_dir/Restarter.ini";
	die "FATAL: Could not find $dst_ini, try running build.pl --clean\n" unless (-f $dst_ini);

	$ini = Config::IniFiles->new(-file => $dst_ini);
	my $profile_sect = $profile;
	$profile_sect =~ s/\./_/g;
	if (!$ini->SectionExists($profile_sect)) {
		$ini->AddSection($profile_sect);
		$ini->newval($profile_sect, 'name', 'Reality');
		$ini->newval($profile_sect, 'profiles', $profile);
		$ini->newval($profile_sect, 'config', "$profile\\config_deadbeef.cfg");
		$ini->newval($profile_sect, 'mod', $mod);
		$ini->newval($profile_sect, 'world', $args{'world'});
	}

	# Obfuscate the configuration/password if not already performed
	if (-f "$conf_dir/config.cfg") {
		my $start = int(rand(32));
		my $hash = ($args{'rcon'}) ? $args{'rcon'} : substr(sha1_hex(time()), $start, 8);
		print "INFO: RCon password will be set to $hash\n";

		# Copy config.cfg to secured path and substitute values
		rename("$conf_dir/config.cfg", "$conf_dir/config_$hash.cfg");
		# Config file edits
		replace_text("s/passwordAdmin\\s=\\s\\\"\\\"/passwordAdmin = \\\"$args{'serveradminpassword'}\\\"/", "$conf_dir/config_$hash.cfg");
		replace_text("s/password\\s=\\s\\\"\\\"/password = \\\"$args{'serverpassword'}\\\"/", "$conf_dir/config_$hash.cfg");
		
		replace_text("s/AAAAAA/$args{'servername'}/", "$conf_dir/config_$hash.cfg");
		replace_text("s/BBBBBB/$args{'locationid'}/", "$conf_dir/config_$hash.cfg");
		replace_text("s/CCCCCC/$args{'dayzversion'}/", "$conf_dir/config_$hash.cfg");
		replace_text("s/DDDDDD/$args{'serverbuild'}/", "$conf_dir/config_$hash.cfg");
		replace_text("s/EEEEEE/$args{'hostedby'}/", "$conf_dir/config_$hash.cfg");
		replace_text("s/FFFFFF/$args{'serverdifficulty'}/", "$conf_dir/config_$hash.cfg");

		# Hive Edits
		replace_text("s/HHHHHH/$args{'hivehost'}/", "$conf_dir/HiveExt.ini");
		replace_text("s/IIIIII/$args{'hiveport'}/", "$conf_dir/HiveExt.ini");
		replace_text("s/JJJJJJ/$args{'hivedatabase'}/", "$conf_dir/HiveExt.ini");
		replace_text("s/KKKKKK/$args{'hiveusername'}/", "$conf_dir/HiveExt.ini");
		replace_text("s/LLLLLL/$args{'hivepassword'}/", "$conf_dir/HiveExt.ini");
		replace_text("s/MMMMMM/$args{'hiveloglevel'}/", "$conf_dir/HiveExt.ini");
		replace_text("s/NNNNNN/$args{'hiveconsolelevel'}/", "$conf_dir/HiveExt.ini");
		replace_text("s/OOOOOO/$args{'hiveconsole'}/", "$conf_dir/HiveExt.ini");
		
		
		if ($args{'datetype'} eq "local"){
			replace_text("s/FGHJGFJ/type = $args{'datetype'}/", "$conf_dir/HiveExt.ini");
			replace_text("s/JSDFHGXCCBNX/$args{'year'}/", "$conf_dir/HiveExt.ini");
			replace_text("s/FHKDFJHDFJ/$args{'month'}/", "$conf_dir/HiveExt.ini");
			replace_text("s/DJDHZZ/$args{'date'}/", "$conf_dir/HiveExt.ini");
		}
		else 
		{
			replace_text("s/FGHJGFJ/type = $args{'datetype'}/", "$conf_dir/HiveExt.ini");
			replace_text("s/JSDFHGXCCBNX/year = $args{'year'}/", "$conf_dir/HiveExt.ini");
			replace_text("s/FHKDFJHDFJ/month = $args{'month'}/", "$conf_dir/HiveExt.ini");
			replace_text("s/DJDHZZ/date = $args{'date'}/", "$conf_dir/HiveExt.ini");
		}
		if ($args{'datetype'} eq "local"){
			replace_text("s/TYLTJU/type = $args{'timetype'}/", "$conf_dir/HiveExt.ini");
			replace_text("s/OSNDDRTR/$args{'timeoffset'}/", "$conf_dir/HiveExt.ini");
			replace_text("s/WEMSHWQ/$args{'hour'}/", "$conf_dir/HiveExt.ini");
		}
		else 
		{
			replace_text("s/TYLTJU/type = $args{'timetype'}/", "$conf_dir/HiveExt.ini");
			replace_text("s/OSNDDRTR/offset = $args{'timeoffset'}/", "$conf_dir/HiveExt.ini");
			replace_text("s/WEMSHWQ/hour = $args{'hour'}/", "$conf_dir/HiveExt.ini");
		}
		
		
		# Basic.cfg edits
		replace_text("s/KLJKJJ/$args{'minbandwidth'}/", "$conf_dir/basic.cfg");
		replace_text("s/JHLJKHG/$args{'maxbandwidth'}/", "$conf_dir/basic.cfg");
		replace_text("s/UFIYCDY/$args{'maxmsgsend'}/", "$conf_dir/basic.cfg");
		replace_text("s/IHGKHB/$args{'maxsizeguaranteed'}/", "$conf_dir/basic.cfg");
		replace_text("s/IBGKHVCV/$args{'maxsizenonguaranteed'}/", "$conf_dir/basic.cfg");
		replace_text("s/CUCCGS/$args{'minerrortosendnear'}/", "$conf_dir/basic.cfg");
		replace_text("s/JGCJFXC/$args{'minerrortosend'}/", "$conf_dir/basic.cfg");
		replace_text("s/IHHVSS/$args{'maxcustomfilesize'}/", "$conf_dir/basic.cfg");
		replace_text("s/ILJHGIF/$args{'windowed'}/", "$conf_dir/basic.cfg");
		replace_text("s/YYDYSS/$args{'adapter'}/", "$conf_dir/basic.cfg");
		replace_text("s/YTFIYF/$args{'3D_performance'}/", "$conf_dir/basic.cfg");
		replace_text("s/LVHKLJ/$args{'resolution_bpp'}/", "$conf_dir/basic.cfg");
		replace_text("s/IHGUIDG/$args{'maxpacketsize'}/", "$conf_dir/basic.cfg");
		
		# BE Edits
		replace_text("s/RConPassword\\s[0-9a-fA-F]{8}/RConPassword $args{'battleyepassword'}/", "$conf_dir/BattlEye/BEServer.cfg");

		# Change config path in Restarter.ini
		$ini->newval($profile_sect, 'config', "dayz_$args{'instance'}.$args{'world'}\\config_$hash.cfg");
	}

	$ini->WriteConfig($dst_ini);
}

# Clean up existing temp directories before starting work
remove_tree($build_dir) if (-d $build_dir);
remove_tree($pkg_build_dir) if (-d $pkg_build_dir);
remove_tree($msn_build_dir) if (-d $msn_build_dir);

# Apply core Reality changes to build directory
print "INFO: Merging Reality code into official server\n";
copy_dir($src_dir, $build_dir);
simple_merge($bls_dir, $build_dir);

# Optionally merge in world-specific modifications
if (-d "$wld_dir/$args{'world'}") {
	print "INFO: Merging changes for world $args{'world'}\n";
	simple_merge("$wld_dir/$args{'world'}", $build_dir);
}

# For each --with-<package> option, attempt to merge in its changes
my @pkgs = ();
my @msn_pkgs = ();
my @flt_lookups = ();
while (my $option = shift(@ARGV)) {
	next unless ($option =~ m/with-([-\w]+)/);
	my $pkg_dir = "$base_dir/pkgs/pkg".$args{'serverversion'}."/$1";
	if (!-d $pkg_dir && !-d "$msn_dir/$1" && !-f "$flt_dir/$1") {
		print "ERROR: Package $1 does not exist\n";
		next;
	}

	push(@pkgs, $pkg_dir) if (-d $pkg_dir);
	push(@msn_pkgs, "$msn_dir/$1") if (-d "$msn_dir/$1");
	
	# Check if there are BattlEye filter exceptions for the package
	next unless (-f "$flt_dir/$1");
	my $json = read_file("$flt_dir/$1");
	my $json_data = decode_json($json);
	push(@flt_lookups, $json_data);
}

# Check if there are BattlEye filter exceptions for the world
if(-f "$flt_dir/$args{'world'}") {
	my $json = read_file("$flt_dir/$args{'world'}");
	my $json_data = decode_json($json);
	push(@flt_lookups, $json_data);
}



# Create the dayz_server PBO
if (scalar(@pkgs) > 0) {
	merge_packages(\@pkgs, $build_dir, $pkg_build_dir, 0);
}

pack_world();

# Create the mission PBO
copy_dir("$msn_dir/world/$args{'world'}", $msn_build_dir);
if (scalar(@msn_pkgs) > 0) {
	merge_packages(\@msn_pkgs, $msn_build_dir, $msn_build_dir, 1);
}

pack_mission();

remove_tree($tmp_dir);
print "INFO: Build completed successfully!\n";
exit;

#==================================================================================================
# SUBROUTINE DEFINITIONS BELOW
#==================================================================================================

# Merge helpers
sub simple_merge {
	my ($src, $dst) = @_;

	die "FATAL: Source path $src does not exist\n" unless (-d $src);
	die "FATAL: Destination path $dst does not exist\n" unless (-d $dst);

	File::DirCompare->compare($src, $dst, sub {
		my ($srcPath, $dstPath) = @_;

		if (!$dstPath) {
			return unless (-f $srcPath);

			# New file, copy it from $srcPath
			my @dstSplit = File::Spec->splitdir($dst);
			my @srcSplit = File::Spec->splitdir(dirname($srcPath));
			my $dstLast = pop(@dstSplit);
			my $srcLast = pop(@srcSplit);
			$dstPath = "$dst/" . (($srcLast ne $dstLast) ? "$srcLast/" : '') . basename($srcPath);

			#print "SRC $srcPath -> $dstPath\n";
			make_path(dirname($dstPath)) unless (-d dirname($dstPath));
			copy($srcPath, $dstPath) unless (-d $dstPath);
		} elsif ($srcPath) {
			my $diff = diff($dstPath, $srcPath, { STYLE => 'Unified' });
			my $srcData = read_file($dstPath);
			my $dstData = patch($srcData, $diff, { STYLE => 'Unified' });

			my @dstSplit = File::Spec->splitdir($dst);
			my @srcSplit = File::Spec->splitdir(dirname($srcPath));
			my $dstLast = pop(@dstSplit);
			my $srcLast = pop(@srcSplit);
			$dstPath = "$dst/" . (($srcLast ne $dstLast) ? "$srcLast/" : '') . basename($srcPath);

			#print "MRG $srcPath -> $dstPath\n";
			make_path(dirname($dstPath));
			write_file($dstPath, $dstData);
		}
	});
}

sub complex_merge {
	my ($orig, $src, $dst) = @_;

	die "FATAL: Origin path $orig does not exist\n" unless (-d $orig);
	die "FATAL: Source path $src does not exist\n" unless (-d $src);
	die "FATAL: Destination path $dst does not exist\n" unless (-d $dst);

	File::DirCompare->compare($orig, $dst, sub {
		my ($origPath, $dstPath) = @_;

		if ($origPath && $dstPath) {
			#print "MRG $origPath -> $dstPath\n";

			# Perform a three-way merge of the files 
			my @origSplit = File::Spec->splitdir(dirname($origPath));
			my $origLast = pop(@origSplit);
			my $srcPath = "$src/$origLast/" . basename($origPath);

			$srcPath = "$src/" . basename($origPath) if (!-f $srcPath);
			return unless (-f $srcPath);

			my $cmd = (($^O =~ m/MSWin32/) ? 'util\\diff3.exe --diff-program=util\\diff.exe -m' : 'diff3 -m');
			my $diffOutput = `$cmd $srcPath $origPath $dstPath`;

			$diffOutput =~ s/^[<=>\|]{7}.*//mg;
			#$diffOutput =~ s/<{7,}.*={7,}(.*)>{7,}.*/$1/mg;
			#$diffOutput =~ s/<<<<<<<[^>]*=======//mg;
			#$diffOutput =~ s/<<<<<<<[^>>>>>>>>]*=======|>>>>>>>.*|<<<<<<<.*|=======.*//mg;
			#$diffOutput =~ s/>>>>>>>[^>].*//mg;
			$diffOutput =~ s/(\n){2,}/\n/sg;

			make_path(dirname($dstPath)) unless (-d dirname($dstPath));
			write_file($dstPath, $diffOutput);
		}
	});
}

# Perform merge of package changes into output dir
sub merge_packages {
	my ($ref_pkgs, $dst, $tmp, $mission) = @_;
	my @pkgs = @{$ref_pkgs};

	die "FATAL: Destination path $dst does not exist\n" unless (-d $dst);

	foreach my $i (0 .. $#pkgs) {
		my $src = $pkgs[$i];

		if (-d "$wld_dir/$args{'world'}") {
			print "Merging world changes into $src\n";
			my $src_tmp = "$tmp_dir/" . basename($src) . (($mission) ? '_msn' : '') . "_tmp";
                        remove_tree($src_tmp) if (-d $src_tmp);
                        copy_dir($src, $src_tmp);

			if ($mission) {
				complex_merge("$msn_dir/world/$args{'world'}", $src, $src_tmp);
			} else {
				complex_merge($bls_dir, "$wld_dir/$args{'world'}", $src_tmp);
			}
			$src = $src_tmp;
		}

		print "Merging changes for package $src\n";
		if ($i > 0) {
			my @pkg_slice = @pkgs[0 .. ($i - 1)];
			if (!$mission) {
				remove_tree($tmp) if (-d $tmp);
				copy_dir($src, $tmp);
			}
			foreach my $replay_pkg (@pkg_slice) {
				if (-d "$wld_dir/$args{'world'}") {
					my $replay_pkg_tmp = "$tmp_dir/" . basename($replay_pkg) . "_replay" . (($mission) ? '_msn' : '') . "_tmp";
					remove_tree($replay_pkg_tmp) if (-d $replay_pkg_tmp);
					copy_dir($replay_pkg, $replay_pkg_tmp);
					if ($mission) {
						complex_merge("$msn_dir/world/$args{'world'}", $replay_pkg, $replay_pkg_tmp);
					} else {
						complex_merge($bls_dir, "$wld_dir/$args{'world'}", $replay_pkg_tmp);
					}
					$replay_pkg = $replay_pkg_tmp;
				}
				

				complex_merge($replay_pkg, $src, $tmp);
			}
			$src = $tmp;
		}
	

		File::DirCompare->compare($src, $dst, sub {
			my ($srcPath, $dstPath) = @_;

			if (!$dstPath) {
				return unless (-f $srcPath);

				# New file, copy it from $srcPath
				my @dstSplit = File::Spec->splitdir($dst);
				my @srcSplit = File::Spec->splitdir(dirname($srcPath));
				my $dstLast = pop(@dstSplit);
				my $srcLast = pop(@srcSplit);
				$dstPath = "$dst/" . (($srcLast eq $dstLast || !$mission) ? "$srcLast/" : '') . basename($srcPath);

				#print "SRC $srcPath -> $dstPath\n";
				make_path(dirname($dstPath)) unless (-d dirname($dstPath));
				copy($srcPath, $dstPath) unless (-d $dstPath);
			} elsif ($srcPath) {
				#print "MRG $srcPath -> $dstPath\n";

				my $diff = diff($dstPath, $srcPath, { STYLE => 'Unified' });
				my $srcData = read_file($dstPath);
				my $dstData = patch($srcData, $diff, { STYLE => 'Unified' });

				my @srcSplit = File::Spec->splitdir(dirname($srcPath));
				my @dstSplit = File::Spec->splitdir(dirname($dstPath));
				my $srcLast = pop(@srcSplit);
				my $dstLast = pop(@dstSplit);

				$dstPath = "$dst/" . (($srcLast eq $dstLast && -f $srcPath) ? "$srcLast/" : '') . basename($srcPath);

				make_path(dirname($dstPath)) unless (-d dirname($dstPath));
				write_file($dstPath, $dstData);
			}
		});
	}
}


# .pbo packing helpers
sub pack_pbo {
	my ($dir, $pbo) = @_;
	die "FATAL: PBO directory $dir does not exist\n" unless (-d $dir);

	my $cmd = (($^O =~ m/MSWin32/) ? '' : 'wine ') . 'util/cpbo.exe -y -p';
	#system("$cmd \"$dir\" \"$pbo\" > " . (($^O =~ m/MSWin32/) ? 'NUL' : '/dev/null')); # This line was in the last commit from ayan4m1, but it does not seem to work properly on windows
	system("$cmd \"$dir\" \"$pbo\"");
}

sub pack_world {
	my $src = $build_dir;
	my $dst = "$dst_dir/\@reality_$args{'instance'}.$args{'world'}/addons";

	print "INFO: Creating dayz_server.pbo\n";
	make_path($dst) unless (-d $dst);
	pack_pbo($src, "$dst/dayz_server.pbo");
	
	if($args{'world'} eq "lingor") {
		copy("$base_dir/util/genderselection/HiveExt.dll", "$dst_dir/\@reality_$args{'instance'}.$args{'world'}/HiveExt.dll");
	} else {
	if ($args{'hiveversion'} eq "oldversion" ) { copy("$base_dir/util/HiveExt.dll", "$dst_dir/\@reality_$args{'instance'}.$args{'world'}/HiveExt.dll");};
	if ($args{'hiveversion'} eq "genderversion" ) { copy("$base_dir/util/genderselection/HiveExt.dll", "$dst_dir/\@reality_$args{'instance'}.$args{'world'}/HiveExt.dll");};
	if ($args{'hiveversion'} eq "newversion" ) { copy("$base_dir/util/newhive/HiveExt.dll", "$dst_dir/\@reality_$args{'instance'}.$args{'world'}/HiveExt.dll");};
		
	}
	
	if($args{'world'} eq "dayz2017.chernarus") {
		copy("$base_dir/util/HiveExt_2017.dll", "$dst_dir/\@reality_$args{'instance'}.$args{'world'}/HiveExt.dll");
	} else {
	if ($args{'hiveversion'} eq "oldversion" ) { copy("$base_dir/util/HiveExt.dll", "$dst_dir/\@reality_$args{'instance'}.$args{'world'}/HiveExt.dll");};
	if ($args{'hiveversion'} eq "genderversion" ) { copy("$base_dir/util/genderselection/HiveExt.dll", "$dst_dir/\@reality_$args{'instance'}.$args{'world'}/HiveExt.dll");};
	if ($args{'hiveversion'} eq "newversion" ) { copy("$base_dir/util/newhive/HiveExt.dll", "$dst_dir/\@reality_$args{'instance'}.$args{'world'}/HiveExt.dll");};
	}
}

sub pack_mission {
	my $src  = "$tmp_dir/mission_tmp";
	my $dst  = "$dst_dir/MPMissions";
	my $name = "dayz_$args{'instance'}.$args{'world'}";

	# Substitute the instance ID into init.sqf
	replace_text("s/dayZ_instance\\s=\\s[0-9]*/dayZ_instance = $args{'instance'}/", "$src/init.sqf");

	# Set the chat channels in description.ext
	if ($args{'channels'}) {
		replace_text("s/disableChannels\\[\\]=\\{([0-9],*)+\\}/disableChannels\\[\\]={$args{'channels'}}/", "$msn_build_dir/description.ext");
	}

	print "INFO: Creating $name.pbo\n";
	make_path($dst) unless (-d $dst);
	pack_pbo($src, "$dst/$name.pbo");

	# Reset the instance ID in init.sqf
	replace_text("s/dayZ_instance\\s=\\s[0-9]*/dayZ_instance = 1/", "$src/init.sqf");
}


# Cross-platform system() helpers 
sub replace_text {
	system("perl -pi" . (($^O eq "MSWin32") ? '.bak' : '') . " -e \"$_[0]\" $_[1]");
	# Clean up .bak file in Windows only
	if ($^O eq "MSWin32") {
		(my $bakPath = $_[1]) =~ s/\//\\/g;
		system("del \"$bakPath.bak\"");
	}
}

sub copy_dir {
	my ($src, $dst) = @_;
	my $cmd = (($^O =~ m/MSWin32/) ? 'xcopy /s /q /y' : 'cp -r');
	my $path = "\"$src\" \"$dst\/\"";
	$path =~ s/\//\\/g if ($^O =~ m/MSWin32/);
	system("$cmd $path");
}
