# See bottom of file for default license and copyright information

=begin TML

---+ package SemanticLinksPlugin

=cut

package Foswiki::Plugins::SemanticLinksPlugin::Core;
use strict;
use warnings;

use Foswiki::Func ();    # The plugins API
use Foswiki::Plugins();
use Data::Dumper;

my %templates;
my %semanticlinks;

# @attrs = ( $property, $value, $valuequery, $valueanchor, $metaproperties,
#            $text, $propertyweb, $propertytopic, $valueweb, $valuetopic )
my %tokenidents = (
    property => {
        _     => 0,
        web   => 6,
        topic => 7
    },
    propertyweb   => 6,
    propertytopic => 7,
    value         => {
        _prefixes => {
            qquery  => '?',
            aanchor => '#'
        },
        _       => 1,
        query   => 2,
        qquery  => 2,
        anchor  => 3,
        aanchor => 3,
        web     => 8,
        topic   => 9
    },
    _prefixes => {
        valueqquery  => '?',
        valueaanchor => '#'
    },
    valueweb     => 8,
    valuetopic   => 9,
    valuequery   => 2,
    valueqquery  => 2,
    valueanchor  => 3,
    valueaanchor => 3,
    text         => 5
);

sub init {
    %templates = ();
}

=begin TML
---++ preRenderingHandler( $text, \%map )
   * =$text= - text, with the head, verbatim and pre blocks replaced
   with placeholders
   * =\%removed= - reference to a hash that maps the placeholders to
   the removed blocks.

Handler called immediately before Foswiki syntax structures (such as lists) are
processed, but after all variables have been expanded. Use this handler to
process special syntax only recognised by your plugin.

... snip ... refer to EmptyPlugin.pm

=cut

sub preRenderingHandler {
    my ( $text, $pMap ) = @_;
    my $linkHandler = \&renderLink;

    if ( not defined $pMap ) {

        # SMELL: are we really being called from beforeSaveHandler()?
        $linkHandler = \&stashLink;
    }

    # You can work on $text in place by using the special perl
    # variable $_[0]. These allow you to operate on $text
    # as if it was passed by reference; for example:
    # $_[0] =~ s/SpecialString/my alternative/ge;
    # Handle [[][] and [[]] links
    # Change '![[...'  to ' [<nop>[...' to protect from further rendering
    $_[0] =~ s/(^|\s)\!\[\[/$1\[<nop>\[/gm;

    # Change ' [[$1::$2?$3#$4|$5]] '
    $_[0] =~
s/\[\[([^:][^\|\]\n?]+?)::([^\|\]\n?\#]+)(\?[^\|\]\n\#]+)?(\#[^\|\]\n]+)?\|([^\]\n]+)\]\]/&{$linkHandler}( $1, $2, $3, $4, undef, $5 )/ge;

    # Change ' [[$1::$2?$4#$6 {$7}][$9]] '
    $_[0] =~
s/\[\[([^:][^\]\n?]+?)::([^\]\n?\#\{]+?)(\?([^\]\n\#\{]+?))?(\#([^\]\n\{]+?))?(\s*\{[^\]\n]+)?\](\[([^\]\n]+)\])?\]/&{$linkHandler}( $1, $2, $4, $6, $7, $9 )/ge;

    # Change ' [[:...' to ' [[... ' so the link will be handled by Foswiki core
    $_[0] =~ s/(^|\s)[^!]?\[\[:/$1\[\[/gm;

    return;
}

# SMELL: Reproducing Foswiki::Render, but only partially (links have ~500 LOC!)
# What about protocol:// links? Interwiki:links? email@address.es?
# TODO: Allow values which aren't links. This would require special meta on
# the property topic. For now you can cheat by using your own
# SemanticLinksPlugin::MissingLink template on the property topic.
sub renderLink {

#my ( $property, $value, $valuequery, $valueanchor, $metaproperties, $text ) = @_;
    my @attrs    = @_;
    my $topicWeb = $Foswiki::Plugins::SESSION->{webName};
    my ( $propertyweb, $propertytopic ) =
      Foswiki::Func::normalizeWebTopicName( $topicWeb, $attrs[0] );
    my ( $valueweb, $valuetopic ) =
      Foswiki::Func::normalizeWebTopicName( $topicWeb, $attrs[1] );
    my $templatetxt;
    my $tmplName = '';

    push( @attrs, $propertyweb, $propertytopic, $valueweb, $valuetopic );
    if ( $attrs[5] ) {
        $tmplName = 'WithText';
    }
    if ( Foswiki::Func::topicExists( $valueweb, $valuetopic ) ) {
        $tmplName = 'Link' . $tmplName;
    }
    else {
        $tmplName = 'MissingLink' . $tmplName;
    }

    $templatetxt = getTemplate( $propertyweb, $propertytopic, $tmplName );
    $templatetxt =~
s/\$([a-z]+)(\(\s*([^\)]+)\s*\))?/_expandToken($1, $3, \@attrs, \%tokenidents )/ge;
    print STDERR "Template: $templatetxt\n";

    return Foswiki::Func::expandCommonVariables($templatetxt);
}

sub _expandToken {
    my ( $token, $args, $attrs, $ident ) = @_;
    my $val;

    if ( defined $token ) {
        if ( exists $ident->{$token} ) {
            $val = $ident->{$token};
            if ( ref($val) eq 'CODE' ) {
                $val = $val->( $attrs->[ $ident->{_} ] );
            }
            elsif ( ref($val) eq 'HASH' ) {
                $val = _expandToken( $args || '_', undef, $attrs, $val );
            }
            else {
                $val = $attrs->[$val] || '';
            }
            if (    exists $ident->{_prefixes}
                and exists $ident->{_prefixes}->{$token} )
            {
                $val = $ident->{_prefixes}->{$token} . $val;
            }
        }
        else {
            $val = $token;
        }
    }
    else {
        $val = '';
    }

    return $val;
}

sub _getTemplateFromExplicitDef {
    my ( $property, $tmplName ) = @_;

    return Foswiki::Func::expandTemplate(
        'SemanticLinksPlugin::' . $property . '::' . $tmplName );
}

sub _getRequestObject {
    my $req;

    if ( defined &Foswiki::Func::getRequestObject ) {

        # Foswiki >= 1.1
        $req = Foswiki::Func::getRequestObject();
    }
    else {

        # Foswiki <= 1.0
        $req = Foswiki::Func::getCgiQuery();
    }

    return $req;
}

sub _getTemplateFromPropertyTopic {
    my ( $web, $topic, $tmplName, $custTMPL ) = @_;
    my $tmpl;

    if ( Foswiki::Func::topicExists( $web, $topic ) ) {
        Foswiki::Func::readTemplate( $web . '.' . $topic, '' );
        if ($custTMPL) {
            $tmpl = Foswiki::Func::expandTemplate(
                'SemanticLinksPlugin::' . $custTMPL . '::' . $tmplName );
        }
        if ( not $tmpl ) {
            $tmpl = Foswiki::Func::expandTemplate(
                'SemanticLinksPlugin::' . $tmplName );
        }
    }

    return $tmpl;
}

sub _getTemplateFromSkinPath {
    my ($tmplName) = @_;

    Foswiki::Func::readTemplate('semanticlinksplugin');

    return Foswiki::Func::expandTemplate( 'SemanticLinksPlugin::' . $tmplName );
}

# Lazy-load templates, only when we need them.
sub getTemplate {
    my ( $propertyweb, $propertytopic, $tmplName ) = @_;
    my $property = $propertyweb . '.' . $propertytopic;
    my $custTMPL =
         _getRequestObject()->param('SEMANTICLINKSPLUGIN_TMPL')
      || Foswiki::Func::getPreferencesValue('SEMANTICLINKSPLUGIN_TMPL')
      || 0;
    my $tmpl;

    if ( not $templates{$property}{$tmplName}{$custTMPL} ) {
        $tmpl = _getTemplateFromExplicitDef( $property, $tmplName );
        if ( not $tmpl ) {
            $tmpl = _getTemplateFromPropertyTopic( $propertyweb, $propertytopic,
                $tmplName, $custTMPL );
            if ( not $tmpl ) {
                $tmpl = _getTemplateFromSkinPath($tmplName);
            }
        }

        # Zap the escaped newlines
        $tmpl =~ s/\\\n//smg;
        $templates{$property}{$tmplName}{$custTMPL} = $tmpl;
    }

    return $templates{$property}{$tmplName}{$custTMPL};
}

=begin TML

---++ beforeSaveHandler($text, $topic, $web, $meta )
   * =$text= - text _with embedded meta-data tags_
   * =$topic= - the name of the topic in the current CGI query
   * =$web= - the name of the web in the current CGI query
   * =$meta= - the metadata of the topic being saved, represented by a Foswiki::Meta object.

   This handler is called each time a topic is saved.

   *NOTE:* meta-data is embedded in =$text= (using %META: tags). If you modify
   the =$meta= object, then it will override any changes to the meta-data
   embedded in the text. Modify *either* the META in the text *or* the =$meta=
   object, never both. You are recommended to modify the =$meta= object rather
   than the text, as this approach is proof against changes in the embedded
   text format.

   *Since:* Foswiki::Plugins::VERSION = 2.0

=cut

sub beforeSaveHandler {
    my ( $text, $topic, $web, $topicObject ) = @_;
    my @SLPROPERTIES;
    my @SLPROPERTY;
    my @SLPROPERTYVALUE;
    my @properties;

    %semanticlinks = ();

    # Instead of rendering, linkHandler will be set to stashLink() which
    # populates the %semanticlinks hash.
    preRenderingHandler($text);
    @properties = keys %semanticlinks;

    if ( scalar(@properties) ) {

        # In a perfect world, we'd have query syntax sufficient to avoid needing
        # the SLPROPERTIES and SLPROPERTY keys at all. For now, SLPROPERTIES can
        # tell a wiki app what distinct properties are present on a given topic.
        @SLPROPERTIES = {
            value => join( ',', @properties ),
            num   => scalar(@properties)
        };
        foreach my $property (@properties) {

            # As for SLPROPERTY, this can tell a wiki app what distinct values
            # there are for a given property.
            push(
                @SLPROPERTY,
                {
                    name   => $property,
                    values => join( ',', keys %{ $semanticlinks{$property} } ),
                    num    => scalar( keys %{ $semanticlinks{$property} } )
                }
            );
            my $valuecount = 1;
            foreach my $value ( keys %{ $semanticlinks{$property} } ) {
                push(
                    @SLPROPERTYVALUE,
                    {
                        name     => $property . '__' . $valuecount,
                        property => $property,
                        value    => $value,

                        # query, anchor, text
                        %{ $semanticlinks{$property}{$value} }
                    }
                );
                $valuecount = $valuecount + 1;
            }
        }

        $topicObject->putAll( 'SLPROPERTIES',    @SLPROPERTIES );
        $topicObject->putAll( 'SLPROPERTY',      @SLPROPERTY );
        $topicObject->putAll( 'SLPROPERTYVALUE', @SLPROPERTYVALUE );
    }

    return;
}

sub stashLink {
    my ( $property, $value, $valuequery, $valueanchor, $metaproperties, $text )
      = @_;

    $semanticlinks{$property}{$value} =
      { query => $valuequery, anchor => $valueanchor, text => $text };

    return '';
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
