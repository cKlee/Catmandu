#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Log::Any::Adapter;
use Data::Dumper;
use Cwd;
use File::Spec;

my $pkg;

BEGIN {
    $pkg = 'Catmandu';
    use_ok $pkg;
}
require_ok $pkg;

# Logging ----------------------------
Log::Any::Adapter->set('Test');

isa_ok(Catmandu->log,          'Log::Any::Proxy',         'logger test');
isa_ok(Catmandu->log->adapter, 'Log::Any::Adapter::Test', 'logger test');

Catmandu->log->debug('debug test');
Catmandu->log->info('info test');
Catmandu->log->warn('warn test');

Catmandu->log->adapter->contains_ok(qr/debug test/, 'debug log');
Catmandu->log->adapter->contains_ok(qr/info test/,  'info log');
Catmandu->log->adapter->contains_ok(qr/warn test/,  'info log');

# Default_load_path ------------------
ok(my $curr_path = Catmandu->default_load_path, 'get current path');

Catmandu->default_load_path('/tmp');
is(Catmandu->default_load_path, '/tmp', 'got default_load_path');

Catmandu->default_load_path($curr_path);
is(Catmandu->default_load_path, $curr_path, 'got default_load_path 2');

# Load
Catmandu->load;
is(Catmandu->config->{test}, 'ok', 'load and conf test');

is(Catmandu->default_store,    'default', 'default store');
is(Catmandu->default_fixer,    'default', 'default fixer');
is(Catmandu->default_importer, 'default', 'default importer');
is(Catmandu->default_exporter, 'default', 'default exporter');

isa_ok(Catmandu->importer, 'Catmandu::Importer::YAML', 'importer test');
isa_ok(Catmandu->importer('mock'),
    'Catmandu::Importer::Mock', 'importer test');
isa_ok(Catmandu->exporter, 'Catmandu::Exporter::YAML', 'exporter test');
isa_ok(Catmandu->exporter('csv'), 'Catmandu::Exporter::CSV', 'exporter test');
isa_ok(Catmandu->store,           'Catmandu::Store::Hash',   'store test');
isa_ok(Catmandu->store('hash'),   'Catmandu::Store::Hash',   'store test');
isa_ok(Catmandu->fixer,           'Catmandu::Fix',           'fixer test');

like(Catmandu->export_to_string({foo => 'bar'}, 'JSON'),
    qr/{"foo":"bar"}/, 'export_to_string');

my ($root_vol, $root_path, $root_file)
    = File::Spec->splitpath(File::Spec->catfile(getcwd(), 't'));
my $root = File::Spec->catfile($root_path, $root_file);

is(Catmandu->root, $root, 'root');
is_deeply(Catmandu->roots, [$root], 'roots');

is(Catmandu->default_importer_package, 'JSON', 'default_importer_package');
is(Catmandu->default_exporter_package, 'JSON', 'default_exporter_package');

my $exporter = Catmandu->exporter('Mock');
Catmandu->export({n => 1}, $exporter);
is_deeply($exporter->as_arrayref, [{n => 1}]);

# Set config
Catmandu->config({test => 'reload'});
is(Catmandu->config->{test}, 'reload', 'reload config');

done_testing;
