use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'HTML::Template::Default',
   VERSION_FROM => 'lib/HTML/Template/Default.pm',
   PREREQ_PM => {
      'HTML::Template' => 0,
      'Carp' => 0,
   }
);

