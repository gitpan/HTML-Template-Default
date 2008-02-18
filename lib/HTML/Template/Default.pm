package HTML::Template::Default;
use strict;
use Carp;
use HTML::Template;
use vars qw(@EXPORT_OK @ISA %EXPORT_TAGS $VERSION);
@ISA = qw(Exporter);
@EXPORT_OK = qw(get_tmpl);
%EXPORT_TAGS = ( 
	all => \@EXPORT_OK,
);
$VERSION = sprintf "%d.%02d", q$Revision: 1.5 $ =~ /(\d+)/g;


$HTML::Template::Default::DEBUG = 0;

sub DEBUG : lvalue { $HTML::Template::Default::DEBUG }

sub debug {
	DEBUG or return 1;
	my $msg = shift;
	print STDERR "# HTML::Template::Default - $msg\n";
	return 1;
}

sub _get_tmpl {
   my $filename = shift;
   $filename or die('missing filename argument to get_tmpl');

   my $abs;
   
   if ($filename=~/\//){
      -f $filename or return;
      return $filename;
   }

   for my $path ( $ENV{HTML_TEMPLATE_PATH}, $ENV{TMPL_PATH} ){
      defined $path or next;
      
      $abs = "$path/$filename";

      if( -f $abs){
         debug("$filename ondisk $abs");
         return $abs;
      }
   }

   debug("$filename : not on disk.\n");
   return;
}





sub get_tmpl {
   my ($filename, $default_code ) = @_;
   ($filename or $default_code)
	or confess('no filename provided, no default code provided');
   
   my $tmpl;
   my $abs_path; 
   
   if ( $filename ){
      if ($abs_path = _get_tmpl($filename) ){

         $tmpl = new HTML::Template(  filename => $abs_path, die_on_bad_params => 0 ) or die;
         return $tmpl;
      }
   }

   defined $default_code 
      and $default_code 
      or confess("$filename was not found and no default code was provided.");

   ref $default_code 
      or confess("default code for $filename is not a scalarref");
      
   $tmpl = new HTML::Template( die_on_bad_params => 0, scalarref => $default_code ) or die;

   return $tmpl;        
}

1;

__END__

=pod

=head1 NAME

HTML::Template::Default - unless template file is on disk, use default hard coded

=head1 DESCRIPTION

I sometimes code implementations of CGI::Application for multiple client installations.
I want to provide and use a default template for runmodes, and also allow the site admin to change the templates.
This module allows me to do this, without requiring that tmpl files be in place, and if they are, those override the defaults.

Of course you don't have to use CGI::Application to find this module useful.

The files are sought in $ENV{HTML_TEMPLATE_PATH}, ( $ENV{TMPL_PATH}  will deprecate )

=head1 SYNOPSIS

   use HTML::Template::Default 'get_tmpl';

   $ENV{HTML_TEMPLATE_PATH} = '/home/myself/public_html/templates';

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


=head1 SUBROUTINES

You must ask to import these.

=head2 get_tmpl()

Takes two arguments.
Returns HTML::Template object.

First is a path or filename to an HTML::Template file.
If the path to template is not absolute (if it's just a filename, ie:'this.html')
it will seek it inside $ENV{TEMPLATE_PATH}.

Second argument, optional, is a scalar with default code for the template.
This is what allows a user to override the default look by simply creating a file inside 
the $ENV{HTML_TEMPLATE_PATH}.


Returns HTML::Template object. The HTML::Template object returned will have a die_on_bad_params set to 0.

(If you are creating a handler, you can use get_tmpl() to provide a default template to feed stuff into.
This also allows user to place a template of their own in the $ENV{HTML_TEMPLATE_PATH} directory.)

=head3 Example 1

In the following example, if main.html does not exist in $ENV{HTML_TEMPLATE_PATH}, the '$default' 
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

To override that template, one would create the file main.html in $ENV{HTML_TEMPLATE_PATH}. The perl
code need not change. This merely lets you provide a default, optionally.

Again, if main.html is not in $ENV{HTML_TEMPLATE_PATH}, it will use default string provided- 
if no default string provided, and filename is not found, croaks.

=head3 Example 2

In the following example, the template file 'awesome.html' must exist in $ENV{HTML_TEMPLATE_PATH}.
Or the application croaks. Because no default is provided.

	my $tmpl = get_tmpl('awesome.html');

=head3 Example 3

If you don't provide a filename but do provide a default code, this is ok..


	my $tmpl = get_tmpl(undef,\$defalt_code);



=head1 DEBUG

To set debug:

   $HTML::Template::Default::DEBUG = 1;

Gives useful info like if we got from disk or default provided etc to STDERR.

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=head1 SEE ALSO

L<HTML::Template>

=cut

