use Test::Simple 'no_plan';
use strict;
use lib './lib';
use HTML::Template::Default 'get_tmpl';
use Cwd;

$HTML::Template::Default::DEBUG = 1;

$ENV{TMPL_PATH} = cwd().'/t/templates';

my $default = '
   <html>
   <head>
   <title><TMPL_VAR TITLE></title>
   </head>
   <body>
   <h1><TMPL_VAR TITLE></h1>
   <p><TMPL_VAR CONTENT></p>   
   </body>
   </html>
';

my $tmpl;
ok( $tmpl= get_tmpl('super.tmpl',\$default), 'got default because none on disk'); 

$tmpl->param( TITLE => 'Great Title' );
$tmpl->param( CONTENT => 'Super cool content is here.' );

my $out =  $tmpl->output;
print $out;
ok($out,'output');



# try from disk



ok($tmpl = get_tmpl('duper.html', \$default),'get tmpl from disk instead'  );

$out = $tmpl->output;

ok( $out=~/FROM DISK XYZ/,'correct, is from disk' );







