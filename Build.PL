use Module::Build;

my $build = Module::Build->new(module_name => 'Net::Backpack',
                               dist_version => '1.14',
			       license => 'perl',
 			       requires => {
			 		    perl             => '5.6.0',
                                            'LWP::UserAgent' => 0,
                                            'HTTP::Request'  => 0,
                                            'XML::Simple'    => 0,
					   },
                               build_requires => {
                                                  'Test::More' => 0,
                                                 },
                               create_makefile_pl => 'traditional',
                               sign => 1,
			      );

$build->create_build_script;
