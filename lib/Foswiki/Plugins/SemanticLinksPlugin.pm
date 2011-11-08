# See bottom of file for default license and copyright information

=begin TML

---+ package SemanticLinksPlugin

=cut

package Foswiki::Plugins::SemanticLinksPlugin;
use strict;
use warnings;

use Foswiki::Func    ();    # The plugins API
use Foswiki::Plugins ();    # For the API version

our $VERSION = '$Rev$';
our $RELEASE = '2.3.0';
our $SHORTDESCRIPTION =
'QuerySearch backlinks, and populate ad-hoc metadata using =[<nop>[Property::Value]]= Semantic !MediaWiki syntax';
our $NO_PREFS_IN_TOPIC = 1;

my $renderingEnabled;
my @base;

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
    $renderingEnabled =
      Foswiki::Func::isTrue(
        Foswiki::Func::getPreferencesValue('SEMANTICLINKSPLUGIN_RENDERING'),
        1 );
    require Foswiki::Plugins::SemanticLinksPlugin::Core;
    Foswiki::Plugins::SemanticLinksPlugin::Core::init();

    # Foswiki 1.1
    if ( defined &Foswiki::Meta::registerMETA ) {

        Foswiki::Meta::registerMETA(
            'SLPROPERTY',
            alias   => 'slproperties',
            many    => 1,
            require => [qw(name)],
            allow   => [qw(num values)]    # values is legacy
        );
        Foswiki::Meta::registerMETA(
            'SLVALUE',
            alias   => 'slvalues',
            many    => 1,
            require => [qw(name value property)],
            allow   => [
                qw(valueweb valuetopic valueaddress propertyweb propertytopic),
                qw(propertyaddress propertyseq fragment),
                qw(query anchor text)      # These are legacy
            ]
        );
        Foswiki::Meta::registerMETA(
            'SLMETAPROPERTY',
            alias   => 'slmetaproperties',
            many    => 1,
            require => [qw(name)],
            allow   => [qw(num)]
        );
        Foswiki::Meta::registerMETA(
            'SLMETAVALUE',
            alias   => 'slmetavalues',
            many    => 1,
            require => [qw(name value property)],
            allow   => [
                qw(valueweb valuetopic valueaddress propertyweb propertytopic),
                qw(propertyaddress propertyseq fragment),
                qw(ofname ofvalueweb ofvaluetopic ofvalueaddress ofproperty),
                qw(ofpropertyweb ofpropertyaddress ofpropertyseq offragment),
            ]
        );
        Foswiki::Meta::registerMETA(
            'LINK',
            alias   => 'links',
            many    => 1,
            require => [qw(name address scope)],
            allow   => [qw(web topic type)]
        );

        # These are legacy types which we ignore.
        Foswiki::Meta::registerMETA(
            'SLPROPERTIES',
            alias   => 'oldslproperties',
            require => [qw(value)],
            allow   => [qw(num)]
        );
        Foswiki::Meta::registerMETA(
            'SLPROPERTYVALUE',
            alias   => 'oldslpropertyvalues',
            many    => 1,
            require => [qw(name value property)],
            allow   => [qw(query anchor text propertyseq)]
        );
    }
    @base = ( $web, $topic );
    if ( Foswiki::Func::getContext()->{'command_line'} ) {
        Foswiki::Func::registerRESTHandler( 'reparse', \&restReparseHandler );
    }
    else {
        Foswiki::Func::registerRESTHandler( 'reparse', \&restReparseHandler,
            authenticate => 1 );
    }

    return 1;
}

sub restReparseHandler {
    my ( $session, $subject, $verb, $response ) = @_;

    require Foswiki::Plugins::SemanticLinksPlugin::Core;

    return Foswiki::Plugins::SemanticLinksPlugin::Core::restReparseHandler(
        $session, $subject, $verb, $response );
}

sub getBase {

    return @base;
}

sub preRenderingHandler {
    my ( $text, $pMap ) = @_;

    if ($renderingEnabled) {
        Foswiki::Plugins::SemanticLinksPlugin::Core::preRenderingHandler(@_);
    }

    return;
}

sub beforeSaveHandler {
    my ( $text, $topic, $web, $topicObject ) = @_;

    require Foswiki::Plugins::SemanticLinksPlugin::Core;
    Foswiki::Plugins::SemanticLinksPlugin::Core::beforeSaveHandler(@_);

    return;
}

1;

__END__
Foswiki - The Free and Open Source Wiki, http://foswiki.org/

Copyright (C) 2010-2011 Paul.W.Harvey@csiro.au, http://trin.org.au
Copyright (C) 2010-2011 Foswiki Contributors. Foswiki Contributors
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
