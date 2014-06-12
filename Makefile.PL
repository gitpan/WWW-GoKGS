use inc::Module::Install;

all_from 'lib/WWW/GoKGS.pm';
readme_from 'lib/WWW/GoKGS.pm';

repository 'https://github.com/anazawa/p5-WWW-GoKGS';

no_index directory => 'examples';

requires 'Carp';
requires 'parent';
requires 'URI';
requires 'Web::Scraper';
requires 'Exporter';
requires 'LWP::UserAgent';
requires 'Scalar::Util';
requires 'String::CamelCase';

test_requires 'Test::More' => '0.98';
test_requires 'Test::Exception';
test_requires 'Test::Pod'  => '1.45';
test_requires 'Path::Class';

tests 't/*.t xt/*.t';

WriteAll;
