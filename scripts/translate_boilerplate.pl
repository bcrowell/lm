#!/usr/bin/perl

# Translate boilerplate phrases appearing in books into another language.
# Reads stdin, writes stdout.
# Only makes sense on plain text, e.g., wiki or html output.
# Have to give it, e.g., -l fr on the command line to specify output language.
# Doesn't try to be smart about doing substitutions only in places where they really are boilerplate.
#   For instance, if "Problems" occurs as a capitalized word at the beginning of a sentence,
#   it will happily translate it as if it were the section heading at the beginning of the homework problems.
#   This is not a big deal, because this is what we do as a time-saving step at the beginning of a translation.
#   The whole thing is going to be translated by hand afterward anyway.

use Getopt::Std;

use strict;

my %args;
getopt("l",\%args);
my $l = $args{l};

print STDERR "output language=$l\n";


# some accented characters:
#   áéíóúàèìòùâêîôûäëïöüñå

#============================= English ===================================
my $tr = {
  "en" => {
    "summary"=>"Summary",
    "solforch"=>"Solutions for Chapter",
    "scansch"=>"Answers to Self-Checks for Chapter",
    "page"=>"Page",
    "selfcheck"=>"self-check",
    "dq"=>"Discussion Question",
    "dqs"=>"Discussion Questions",
    "notation"=>"Notation",
    "othernotation"=>"Other Terminology and Notation",
    "selvocab"=>"Selected Vocabulary",
    "exploring"=>"Exploring Further",
    "problems"=>"Problems",
    "key"=>"Key",
    "example"=>"example",
  },
  #============================= French ===================================
  "fr" => {
    "summary"=>"Résumé",
    "solforch"=>"Réponses aux exercices",
    "scansch"=>"Réponses aux auto-interrogations",
    "page"=>"Page",
    "prob"=>"problème",
    "selfcheck"=>"Auto contrôle",
    "dq"=>"Discussion",
    "dqs"=>"Discussions",
    "notation"=>"Symboles",
    "othernotation"=>"Symboles et terminologie supplémentaires",
    "selvocab"=>"Vocabulaire choisi",
    "exploring"=>"A poursuivre",
    "problems"=>"Problèmes",
    "key"=>"Clé",
    "example"=>"exemple",
  },
  #========================================================================
};

local $/;


my $t = <>;

my $en = $tr->{en};
my %en = %$en;
die "no translations were provided for language $l" unless exists $tr->{$l};
my $to = $tr->{$l};
my %to = %$to;
foreach my $key(keys %en) {
  if (exists $to{$key}) {
    my $a = quotemeta($en{$key});
    my $b = $to{$key};
    $t =~ s/$a/$b/g;
  }
  else {
    print STDERR "Warning: no translation found for $key=>$en{$key}\n";
  }
}

print $t;
