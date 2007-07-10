package HTML::Template::Default;
use strict;
use warnings;
use Carp;
use HTML::Template;
require Exporter;
use vars qw(@EXPORT_OK @ISA %EXPORT_TAGS);
@ISA = qw(Exporter);
@EXPORT_OK = qw(get_tmpl);
%EXPORT_TAGS = ( 
	all => \@EXPORT_OK,
);
our $VERSION = sprintf "%d.%02d", q$Revision: 1.1.1.1 $ =~ /(\d+)/g;

=pod

=head1 NAME

HTML::Template::Default - unless template file is on disk, use default hard coded

=head1 DESCRIPTION

I sometimes code implementations of CGI::Application for multiple client installations.
I want to provide and use a default template for runmodes, and also allow the site admin to change the templates.
This module allows me to do this, without requiring that tmpl files be in place, and if they are, those override the defaults.

Of course you don't have to use CGI::Application to find this module useful.

The files are sought in ENV TMPL_PATH

=head1 SYNOPSIS

   use HTML::Template::Default 'get_tmpl';
   $ENV{TMPL_PATH} = '/home/myself/public_html/templates';

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

   # if super.tmpl exists, use it, if not, use my default

   my $tmpl = get_tmpl('super.tmpl',\$default); 

   $tmpl->param( TITLE => 'Great Title' );
   $tmpl->param( CONTENT => 'Super cool content is here.' );

   # ...


=cut

$HTML::Template::Default::DEBUG = 0;
sub DEBUG : lvalue { $HTML::Template::Default::DEBUG }


# quick way to allow designer to override a template, if not on disk, use provided
# this sub expects filename (filename) 
sub get_tmpl { # tmpl (d)efault (o)r (o)verride
	my $label = shift; 
	$label or croak('get_tmpl(): no filename provided');
	my $default = shift;
	
	print STDERR "get_tmpl() called for [$label]\ndefault provided:".($default ? 1 :0)."\n" if DEBUG;
	
	my $_tmpl;	


	if ($label=~/^\//){
			$_tmpl = new HTML::Template(  filename => "$label", die_on_bad_params => 0 );
			print STDERR "found abs path tmpl : $label used.\n" if DEBUG;			
			return $_tmpl;
	}

	elsif ($ENV{TMPL_PATH} and -f "$ENV{TMPL_PATH}/$label"){
			$_tmpl = new HTML::Template(  filename => "$ENV{TMPL_PATH}/$label", die_on_bad_params => 0 );
			print STDERR "found ENV TMPL_PATH tmpl : $ENV{TMPL_PATH}/$label used.\n" if DEBUG;			
			return $_tmpl;
	} 	

	elsif ($default){  # a default tmpl present
			$_tmpl = new HTML::Template( die_on_bad_params => 0, scalarref => $default );	
			print STDERR "default provided for [$label] used.\n"if DEBUG;
			return $_tmpl;
	}

	croak("get_tmpl(): no template file found and no default provided for [$label]");
	
}

=head2 get_tmpl()

Takes two arguments. Returns HTML::Template object.

First is a path or filename to an HTML::Template file.
If the path to template is not absolute (if it's just a filename, ie:'this.html')
it will seek it inside ENV TMPL_PATH.

Second argument, optional, is a scalar with default code for the template.
This is what allows a user to override the default look by simply creating a file inside 
the ENV TMPL_PATH.


Returns HTML::Template object. The HTML::Template object returned will have a die_on_bad_params set to 0.

(If you are creating a handler, you can use get_tmpl() to provide a default template to feed stuff into.
This also allows user to place a template of their own in the TMPL_PATH directory.)

=head3 Example 1

In the following example, if main.html does not exist in ENV TMPL_PATH, the '$default' 
code provided is used as the template.

	my $default = "<html>
	<head>
	 <title>Hi.</title>
	</head> 
	<body>
		<TMPL_VAR BODY>		
	</body>	
	</html>";

	my $tmpl = get_tmpl('main.html',$default);

To override that template, one would create the file main.html in ENV TMPL_PATH. The perl
code need not change. This merely lets you provide a default, optionally.

Again, if main.html is not in TMPL_PATH, it will use default string provided- 
if no default string provided, and filename is not found, croaks.

=head3 Example 2

In the following example, the template file 'awesome.html' must exist in ENV TMPL_PATH.
Or the application croaks. Because no default is provided.

	my $tmpl = get_tmpl('awesome.html');

=head1 DEBUG

To set debug:

   $HTML::Template::Default::DEBUG = 1;

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=cut


1;
