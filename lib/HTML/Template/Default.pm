package HTML::Template::Default;
use strict;
use warnings;
use Carp;
use HTML::Template;
use LEOCHARRE::DEBUG;

require Exporter;
use vars qw(@EXPORT_OK @ISA %EXPORT_TAGS);
@ISA = qw(Exporter);
@EXPORT_OK = qw(get_tmpl);
%EXPORT_TAGS = ( 
	all => \@EXPORT_OK,
);
our $VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /(\d+)/g;

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


sub _get_tmpl {
   my $filename = shift;
   $filename or die;

   if ( defined $ENV{HTML_TEMPLATE_PATH} and $ENV{HTML_TEMPLATE_PATH} ){
      if (-f "$ENV{HTML_TEMPLATE_PATH}/$filename"){
         debug("$filename : ondisk : $ENV{HTML_TEMPLATE_PATH}/$filename\n");
         return "$ENV{HTML_TEMPLATE_PATH}/$filename";
      }
      # otherwise just return if it was set
      debug("$filename : ondisk : not on disk.\n");
      return;
   }

   $ENV{TMPL_PATH}||='./';

   if (-f $ENV{TMPL_PATH}."/$filename"){
      debug("$filename : ondisk : $ENV{TMPL_PATH}/$filename\n");
      return $ENV{TMPL_PATH}."/$filename";
   }
   debug("$filename : not on disk.\n");
   return;
}





sub get_tmpl {
   my ($filename, $default_code ) = @_;
   defined $filename or confess('no filename provided');
   
   my $tmpl;
   my $abs_path; 
   
   if ( $abs_path = _get_tmpl($filename)){

      $tmpl = new HTML::Template(  filename => $abs_path, die_on_bad_params => 0 ) or die;
      return $tmpl;
   }

   defined $default_code and $default_code or confess("$filename was not found and no default code was provided.");
   ref $default_code or confess("default code for $filename is not a scalarref");
      
   $tmpl = new HTML::Template( die_on_bad_params => 0, scalarref => $default_code ) or die;

   return $tmpl;        
}


=head2 get_tmpl()

Takes two arguments. Returns HTML::Template object.

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

=head1 DEBUG

To set debug:

   $HTML::Template::Default::DEBUG = 1;

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=head1 SEE ALSO

L<HTML::Template>

=cut


1;
