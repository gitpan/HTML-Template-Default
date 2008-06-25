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

$VERSION = sprintf "%d.%02d", q$Revision: 1.8 $ =~ /(\d+)/g;

$HTML::Template::Default::DEBUG = 0;

sub DEBUG : lvalue { $HTML::Template::Default::DEBUG }

sub debug {
	DEBUG or return 1;
	my $msg = shift;
	print STDERR "# HTML::Template::Default - $msg\n";
	return 1;
}

sub _get_abs_tmpl {
   my $filename = shift;
   $filename or return;
   #$filename or die('missing filename argument to get_tmpl');

   my @possible_abs;

   for my $envar ( $ENV{HTML_TEMPLATE_ROOT}, $ENV{TMPL_PATH}, $ENV{HTML_TEMPLATE_ROOT} ){
      defined $envar or next;
      push @possible_abs, "$envar/$filename";
   }

   # lastly try the filename
   push @possible_abs, $filename;


   for my $abs ( @possible_abs ){
      if( -f $abs ){
         debug("file found: $abs");
         return $abs;
      }
      else {
         debug("file not found: $abs");
      }
   }

   debug("$filename : not found on disk.\n");
   return;
}





sub get_tmpl {
   if( scalar @_ > 3 ){ 
      debug('over');
      return tmpl(@_);
   } 
   else {
      debug('under');
      my %arg;
      for (@_){
         defined $_ or next;
         if( ref $_ eq 'SCALAR' ){
            $arg{scalarref} = $_;
            next;
         }
         $arg{filename} = $_;
      }
      
      # insert my default params
      $arg{die_on_bad_params} = 0;
      
      return tmpl(%arg);
   }

}

sub tmpl {
   my %a = @_;
   defined %a or confess('missing argument');

   ### %a

   my $debug = sprintf 'using filename: %s, using scalarref: %s',
      ( $a{filename} ? $a{filename} : 'undef' ),
      ( $a{scalarref} ? 1 : 0 ),
      ;
   
   $a{filename} or $a{scalarref} or confess("no filename or scalarref provided");


   if( my $abs = _get_abs_tmpl($a{filename})){
      
      my %_a = %a;      
      #if there is a scalarref, delete it
      delete $_a{scalarref};

      #replace filename with what we resolved..
      $_a{filename} = $abs;

      if ( my $tmpl = HTML::Template->new(%_a) ){
         debug("filename, $debug");
         return $tmpl;
      }
   }


   if( $a{scalarref} ){
   
      my %_a = %a;
      #if there is a filename, delete it
      delete $_a{filename};

      if ( my $tmpl = HTML::Template->new(%_a) ){
         debug("scalarref - $debug");
         return $tmpl;
      }
   }

   carp(__PACKAGE__ ."::tmpl() can't instance a template - $debug");
   return;
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

The files are sought in $ENV{HTML_TEMPLATE_ROOT}

=head1 SYNOPSIS

   use HTML::Template::Default 'get_tmpl';

   $ENV{HTML_TEMPLATE_ROOT} = '/home/myself/public_html/templates';

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






=head1 get_tmpl()

Takes arguments.
Returns HTML::Template object.

=head2 two argument usage

If there are two arguments, the values are to be at least one of the following..

- A path or filename to an HTML::Template file.

- A scalar ref with default code for the template.

Examples:

   my $tmpl = get_tmpl('main.html', \$default_tmpl_html );
   my $tmpl = get_tmpl('main.html');
   my $tmpl = get_tmpl(\$default_html);

=head2 hash argument usage

arguments are the same as to HTML::Template constructor.
The difference is that you can set *both* 'filename' and 'scalarref' arguments,
and we try to instance via 'filename' first (if it is defined), and second
via 'scalarref'.

If neither filename or scalarref are defined, will throw a nasty exception with confess.

If returns undef if we cannot instance.

   my $tmpl = get_tmpl( filename => 'main.html', scalarref =>\$default_tmpl_html );


=head3 Erroneous usage

These examples will be interpreted as two argument usage when you meant hash usage..

   my $tmpl = get_tmpl( filename => 'main.html' ); 
   my $tmpl = get_tmpl( scalarref => \$default_html );



=head1 EXAMPLE USAGE
   

=head2 Example 1

In the following example, if main.html does not exist in $ENV{HTML_TEMPLATE_ROOT}, the '$default' 
code provided is used as the template.

	my $default = "<html>
	<head>
	 <title>Hi.</title>
	</head> 
	<body>
		<TMPL_VAR BODY>		
	</body>	
	</html>";

	my $tmpl = get_tmpl('main.html', \$default);

To override that template, one would create the file main.html in $ENV{HTML_TEMPLATE_ROOT}. The perl
code need not change. This merely lets you provide a default, optionally.

Again, if main.html is not in $ENV{HTML_TEMPLATE_ROOT}, it will use default string provided- 
if no default string provided, and filename is not found, croaks.

=head2 Example 2

In the following example, the template file 'awesome.html' must exist in $ENV{HTML_TEMPLATE_ROOT}.
Or the application croaks. Because no default is provided.

	my $tmpl = get_tmpl('awesome.html');

=head2 Example 3

If you don't provide a filename but do provide a default code, this is ok..


	my $tmpl = get_tmpl(\$defalt_code);


=head2 Example 4
   
If you want to pass arguments to the template..

   my $tmpl = get_tmpl( filename => 'super.tmpl', scalarref => \$default, case_sensitive => 1 );
   

=head2 Example 5

In this example we provide both the default code we want, and filename for a file
on disk that is given higher priority.
If the file 'main.html' is on disk, it will be loaded.

   use HTML::Template::Default 'get_tmpl';
   
   my $code = '<html><title><TMPL_VAR TITLE></title></html>';
   
   my $tmpl = get_tmpl ( 
      filename => 'main.html',
      scalarref => \$code,
      die_on_bad_params => 0,
      case_sensitive => 1,
   );



=head1 DEBUG

To set debug:

   $HTML::Template::Default::DEBUG = 1;

Gives useful info like if we got from disk or default provided etc to STDERR.

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=head1 CAVEATS

In two argument usage, die_on_bad_params is set to 0, if you want to change that, use hash argument.

   get_tmpl(filename => $filename, scalarref => \$code); # leaves HTML::Template defaults intact
   get_tmpl( $filename, \$scalarref ) # invokes die_on_bad_params => 0


=head1 SEE ALSO

HTML::Template

=cut

