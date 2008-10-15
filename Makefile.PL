use 5.008008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Continuity::Monitor',
    VERSION_FROM      => 'lib/Continuity/Monitor.pm',
    ABSTRACT_FROM     => 'lib/Continuity/Monitor.pm',
    AUTHOR            => 'Brock Wilcox <awwaiid@thelackthereof.org>',
    LICENSE           => 'perl',
    PREREQ_PM         => {
      'Continuity'                                         => '0.996',
      'Coro::Generator'                                    => 0,
      'Devel::StackTrace::WithLexicals'                    => '0.01',
      'Method::Signatures'                                 => '20081008',
      'Moose'                                              => '0.58',
      'Moose::Exporter'                                    => 0,
      'Module::Refresh'                                    => 0,
    },
);
