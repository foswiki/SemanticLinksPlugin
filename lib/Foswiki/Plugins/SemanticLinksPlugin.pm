# See bottom of file for default license and copyright information

=begin TML

---+ package SemanticLinksPlugin

=cut

package Foswiki::Plugins::SemanticLinksPlugin;
use strict;
use warnings;

use Foswiki::Func    ();    # The plugins API
use Foswiki::Plugins ();    # For the API version

our $VERSION = '$Rev$ (2010-11-05)';
our $RELEASE = '1.0.2';
our $SHORTDESCRIPTION =
'Populate ad-hoc metadata using =[<nop>[Property::Value]]= Semantic !MediaWiki syntax';
our $NO_PREFS_IN_TOPIC = 1;

my $pluginEnabled;

=begin TML

---++ initPlugin($topic, $web, $user) -> $boolean
   * =$topic= - the name of the topic in the current CGI query
   * =$web= - the name of the web in the current CGI query
   * =$user= - the login name of the user
   * =$installWeb= - the name of the web the plugin topic is in
     (usually the same as =$Foswiki::cfg{SystemWebName}=)
=cut

sub initPlugin {
    my ( $topic, $web, $user, $installWeb ) = @_;

    if ( $Foswiki::Plugins::VERSION < 2.0 ) {
        my $warning =
          'Version mismatch between ' . __PACKAGE__ . ' and Plugins.pm';

        Foswiki::Func::writeWarning($warning);

        return $warning;
    }

    $pluginEnabled =
      Foswiki::Func::getPreferencesFlag('SEMANTICLINKSPLUGIN_ENABLED');
    if ($pluginEnabled) {
        require Foswiki::Plugins::SemanticLinksPlugin::Core;
        %Foswiki::Plugins::SemanticLinksPlugin::Core::templates = ();

        # Foswiki 1.1
        if ( defined &Foswiki::Meta::registerMETA ) {
            Foswiki::Meta::registerMETA(
                'SLPROPERTIES',
                alias   => 'slproperties',
                require => [qw(value)],
                allow   => [qw(num)]
            );
            Foswiki::Meta::registerMETA(
                'SLPROPERTY',
                alias   => 'slproperty',
                many    => 1,
                require => [qw(name values)],
                allow   => [qw(num)]
            );
            Foswiki::Meta::registerMETA(
                'SLPROPERTYVALUE',
                alias   => 'slpropertyvalue',
                many    => 1,
                require => [qw(name value property)],
                allow   => [qw(query anchor text)]
            );
        }
    }

    return 1;
}

sub preRenderingHandler {
    my ( $text, $pMap ) = @_;

    if ($pluginEnabled) {
        Foswiki::Plugins::SemanticLinksPlugin::Core::preRenderingHandler(@_);
    }

    return;
}

sub beforeSaveHandler {
    my ( $text, $topic, $web, $topicObject ) = @_;

    if ($pluginEnabled) {
        Foswiki::Plugins::SemanticLinksPlugin::Core::beforeSaveHandler(@_);
    }

    return;
}

1;

__END__
Foswiki - The Free and Open Source Wiki, http://foswiki.org/

Copyright (C) 2010 Paul.W.Harvey@csiro.au, http://trin.org.au
Copyright (C) 2010 Foswiki Contributors. Foswiki Contributors
are listed in the AUTHORS file in the root of this distribution.
NOTE: Please extend that file, not this notice.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version. For
more details read LICENSE in the root of this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

As per the GPL, removal of this notice is prohibited.
