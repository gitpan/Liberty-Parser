package Liberty::Parser;

use 5.008005;
use strict;
use warnings;
use liberty;

# Export
# {{{
require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Liberty::Parser ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
# }}}

=head1 NAME

Liberty::Parser - Parser for Synopsys Liberty(.lib).

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

our $e = 1;
our $e2 = 2;


=head1 SYNOPSIS

  use Liberty::Parser;
  my $p = new Liberty::Parser;
  my $g_func  = $p->read_file("func.lib");

=head1 DESCRIPTION

Liberty::Parser is indeed a Perl wrapper for Synopsys Open Liberty Project.

=head1 BASIC FUNTIONS

=cut

# new
# {{{

=head2 new

To new a Liberty::Parser object.

=cut
sub new {
  my $self=shift;
  my $class=ref($self) || $self;
  return bless {}, $class;
}
# }}}
# read_file
# {{{

=head2 read_file :*group : (string filename)

Read the liberty format file and return a group handle.

=cut
sub read_file{
  my $self = shift;
  my $file = shift;
  my $gs;
  my $g;
  lib_PIInit(\$e);
  lib_ReadLibertyFile("$file", \$e);
  $gs = lib_PIGetGroups(\$e);
  $g = lib_IterNextGroup($gs,\$e);
  return $g;
}
# }}}
# locate_cell
# {{{

=head2 locate_cell : *group : (*group, string cell_name)

Return the handle of group type `cell'.

=cut

sub locate_cell {
  my $self = shift;
  my $g = shift;
  my $name = shift;
  my $cell = lib_GroupFindGroupByName($g,$name,"cell",\$e);
  return $cell;
}
# }}}
# locate_port
# {{{

=head2 locate_port : *group : (*group, string port_name)

Return the handle of group type `port'.

=cut
sub locate_port {
  my $self = shift;
  my $g = shift;
  my $name = shift;
  my $port = lib_GroupFindGroupByName($g,$name,"pin",\$e);
  #print lib_PIGetErrorText($e, \$e2);
  if($e == 9){
    $port = lib_GroupFindGroupByName($g,$name,"bus",\$e);
  }
  if($e == 9){
    print lib_PIGetErrorText($e, \$e2);
    exit;
  }
  return $port;
}
# }}}
# locate_group
# {{{

=head2 locate_group : *group : (*group, string group_name)

Return the handle of group type `cell'.

=cut
sub locate_group {
  my $self = shift;
  my $g = shift;
  my $name = shift;
  my $gps = lib_GroupGetGroups($g,\$e);
  my $ng;
  my $gt;
  while( !lib_ObjectIsNull($ng = lib_IterNextGroup($gps,\$e), \$e2)){
    if( $name eq $self->get_group_name($ng)){
      return $ng;
    }
  } lib_IterQuit($gps, \$e);
  die "Can't find group `$name'\n";
}
# }}}
# get_group_name
# {{{

=head2 get_group_name : string : (*group)

Return the group name while input a group handle.
Example:

  print $p->get_group_name($g_func);

=cut
sub get_group_name{
  my $self = shift;
  my $g = shift;
	my $names = lib_GroupGetNames($g, \$e);
	my $name = lib_IterNextName($names,\$e);
  if (!defined($name)){
    $name = "";
  }
  return $name;
}
# }}}
# get_group_names
# {{{

=head2 get_group_names : array : (*group G)

Return the handle of group type `cell'. Example:

 my @j = $p->get_group_names ($f_cell);
 dump_array(\@j);

=cut
sub get_group_names {
  my $self = shift;
  my $g = shift;
  my $gps = lib_GroupGetGroups($g,\$e);
  my $ng;
  my @name_list;
  while( !lib_ObjectIsNull($ng = lib_IterNextGroup($gps,\$e), \$e2)){
    push @name_list, $self->get_group_name($ng);
  } lib_IterQuit($gps, \$e);
  return @name_list;
}
# }}}
# get_group_type
# {{{

=head2 get_group_type : string : (*group G)

Return the type name of the group G. Example:

 print $p->get_group_type($g);

=cut
sub get_group_type {
  my $self = shift;
  my $g = shift;
	my $type = lib_GroupGetGroupType($g, \$e);
  return $type;
}
# }}}
# get_attr_name
# {{{

=head2 get_attr_name : string : (*attr A)

Return the attribute name while input a attribute handle.

=cut
sub get_attr_name{
  my $self = shift;
  my $a = shift;
	return lib_AttrGetName($a, \$e);
}
# }}}
# get_attr_type
# {{{

=head2 get_attr_type : string : (*attr A)

Return the attribute type while input a attribute handle.

=cut
sub get_attr_type {
  my $self = shift;
  my $a = shift;
	my $type = lib_AttrGetAttrType($a, \$e);
  return $type;
}
# }}}
# get_value_type
# {{{

=head2 get_value_type : string : (*attr)

Return the value type of attribute A.

=cut
sub get_value_type {
  my $self = shift;
  my $a = shift;
	return lib_SimpleAttrGetValueType($a, \$e);
}
# }}}
# get_attr_with_value
# {{{

=head2 get_attr_with_value : string : (*group, string attr_name)

Return a string with attriubte name and attribute value.

=cut
sub get_attr_with_value {
  my $self = shift;
  my $g = shift;
  my $aname = shift;
  my $print_op;
  my $ats = lib_GroupGetAttrs($g, \$e);
  my $at = lib_GroupFindAttrByName($g,$aname,\$e);
  my $atype = $self->get_attr_type($at);
  my $indent = "";
  my $indent2 = "  ".$indent;
  my $indent3 = "    ".$indent;
  my $eg = "";
  my $vtype;
  my $print_content;

  my $is_var = $self->is_var($at);
  if($is_var){
    $print_op = " =";
  }else{
    $print_op = " :";
  }

# Simple attribute
    if ($atype == $liberty::SI2DR_SIMPLE) {
      $vtype = $self->get_value_type($at);
      # STRING
      if($vtype == $liberty::SI2DR_STRING){
          $eg .= $print_op." \"" . lib_SimpleAttrGetStringValue($at,\$e) . "\";\n";
      # FLOAT64
      }elsif($vtype == $liberty::SI2DR_FLOAT64){
        $eg .= $print_op." ".lib_SimpleAttrGetFloat64Value($at,\$e)." ;\n";
      # INT32
      }elsif($vtype == $liberty::SI2DR_INT32){
        $eg .= $print_op." ".lib_SimpleAttrGetInt32Value($at,\$e)." ;\n";
      # EXPR
      }elsif($vtype == $liberty::SI2DR_EXPR){
        $eg .= "expr\n";
        die;
      # BOOLEAN
      }elsif($vtype == $liberty::SI2DR_BOOLEAN){
        if(lib_SimpleAttrGetBooleanValue($at,\$e)){
          $print_content = "true";
        }else{
          $print_content = "false";
        }
        $eg .= " ".$print_op." ".$print_content." ;\n";
      }
# Complex attribute
    }elsif($atype == $liberty::SI2DR_COMPLEX){
      my $vals = lib_ComplexAttrGetValues($at,\$e);
      my $first = 1;
      $eg .= " ( ";

      while(1){
        my $cplex = lib_IterNextComplex($vals, \$e);
        my $vt = lib_ComplexValGetValueType($cplex, \$e);

        # STRING
        if($vt == $liberty::SI2DR_STRING) {
          my $str6 = lib_ComplexValGetStringValue($cplex, \$e);
          if(!$first){
            $eg .= ",";
            $eg .= "\\\n ";
            $eg .= $indent3."      "."\"".$str6."\"";
          }else{
            $eg .= "\"$str6\"";
          }
        # FLOAT64
        } elsif($vt == $liberty::SI2DR_FLOAT64) {
          my $f1 = lib_ComplexValGetFloat64Value($cplex, \$e);
          $eg .= $f1;
        } elsif($vt == $liberty::SI2DR_INT32) {
          $eg .= "Boolean\n";
        } elsif($vt == $liberty::SI2DR_BOOLEAN) {
          $eg .= "String\n";
        } elsif($vt == $liberty::SI2DR_EXPR) {
          $eg .= "Expr\n";
        } else{ last; }
        $first = 0;
      }
      $eg .= ");\n";
    }
  return $aname.$eg;
}
# }}}
# print_attrs
# {{{

=head2 print_attrs : void : (*group G)

Print all attributes of a group G.

=cut
sub print_attrs {
  my $self = shift;
  my $g = shift;
  my $ats = lib_GroupGetAttrs($g, \$e);
  my $at;
  while (!lib_ObjectIsNull (($at = lib_IterNextAttr($ats, \$e)), \$e2)) {
    print lib_AttrGetName($at, \$e), "\n";
  } lib_IterQuit($ats, \$e);
}
# }}}
# print_timing_arc
# {{{

=head2 print_timing_arc : void : (*group G)

Print timing arc of group G(must be a pin type group.)

=cut
sub print_timing_arc {
  my $self = shift;
  my $g = shift;
  my $gps = lib_GroupGetGroups($g,\$e);
  my $ng;
  my $gt;
  while( !lib_ObjectIsNull($ng = lib_IterNextGroup($gps,\$e), \$e2)){
    $gt = lib_GroupGetGroupType($ng,\$e);
    my $at = lib_GroupFindAttrByName($ng,"related_pin",\$e);
    my $related_pin = lib_SimpleAttrGetStringValue($at, \$e);
       $at = lib_GroupFindAttrByName($ng,"timing_type",\$e);
    my $timing_type = lib_SimpleAttrGetStringValue($at, \$e);
    print "$related_pin:$timing_type\n";
  } lib_IterQuit($gps, \$e);
}
# }}}
# print_groups
# {{{

=head2 print_groups : void : (*group G)

Print groups contained in group G in format "type:name". Example:

 $p->print_groups($g);

=cut

sub print_groups {
  my $self = shift;
  my $g = shift;
  my $gps = lib_GroupGetGroups($g,\$e);
  my $ng;
  my $gt;
  while( !lib_ObjectIsNull($ng = lib_IterNextGroup($gps,\$e), \$e2)){
    $gt = lib_GroupGetGroupType($ng,\$e);
    my $name = $self->get_group_name($ng);
    print "$gt: $name \n";
  } lib_IterQuit($gps, \$e);
}

# }}}
# is_var
# {{{

=head2 is_var : 

Return the handle of group type `cell'.

=cut
sub is_var{
  my $self = shift;
  my $a = shift;
	return lib_SimpleAttrGetIsVar($a, \$e);
}
# }}}

=head1 COMPLEX FUNTIONS

=cut

# extract_group
# {{{

=head2 extract_group : string : (*group G, int indent)

Return the whole content of the group G.

=cut
sub extract_group{
  my $self = shift;
  my $g = shift;
  my $pre_indent = shift;
  my $at;
  my $vtype;
  my $is_var;
  my $print_op;
  my $print_content;
  my $indent = $pre_indent;
  my $indent2 = "  ".$pre_indent;
  my $indent3 = "    ".$pre_indent;
  my $eg = "";

# type, name
  $eg .= $indent.$self->get_group_type($g)." (".$self->get_group_name($g). ") {\n";

# attribute
  $eg .= $self->all_attrs($g,$indent);

# print the groups
  my $ng;
  my $gt;
  my $gps = lib_GroupGetGroups($g,\$e);
  while( !lib_ObjectIsNull($ng = lib_IterNextGroup($gps,\$e), \$e2)){
    $eg .= $self->extract_group($ng,$indent2);
  } lib_IterQuit($gps, \$e);

  $eg .= $indent."}\n";
  return $eg;
}
# }}}
# extract_group_1
# {{{

=head2 extract_group_1 : string : (*group G, int indent)

Return the "surface" of the group G.

=cut

sub extract_group_1{
  my $self = shift;
  my $g = shift;
  my $pre_indent = shift;
  my $at;
  my $vtype;
  my $is_var;
  my $print_op;
  my $print_content;
  my $indent = $pre_indent;
  my $indent2 = "  ".$pre_indent;
  my $indent3 = "    ".$pre_indent;
  my $eg = "";

# type, name
  $eg .= $indent.$self->get_group_type($g)." (".$self->get_group_name($g). ") {\n";

  $eg .= $self->all_attrs($g,$indent);

  return $eg;
}
# }}}
# all_attrs
# {{{

=head2 all_attrs : string : (*group G, int indent)

Return the handle of group type `cell'.

=cut
sub all_attrs {
  my $self = shift;
  my $g = shift;
  my $pre_indent = shift;
  my $is_var;
  my $print_op;
  my $print_content;
  my $vtype;
  my $at;
  my $indent = $pre_indent;
  my $indent2 = "  ".$pre_indent;
  my $indent3 = "    ".$pre_indent;
  my $eg = "";


  # print Attribute
  my $ats = lib_GroupGetAttrs($g, \$e);
  while (!lib_ObjectIsNull (($at = lib_IterNextAttr($ats, \$e)), \$e2)) {
    my $atype = $self->get_attr_type($at);
    my $aname = $self->get_attr_name($at);
    if($aname eq "default_operating_conditions"){
      next;
    }else{
      $eg .= $indent2.$aname;
    }

    $is_var = $self->is_var($at);
    if($is_var){
      $print_op = " =";
    }else{
      $print_op = " :";
    }

# Simple attribute
    if ($atype == $liberty::SI2DR_SIMPLE) {
      $vtype = $self->get_value_type($at);
      # STRING
      if($vtype == $liberty::SI2DR_STRING){
          $eg .= $print_op." \"" . lib_SimpleAttrGetStringValue($at,\$e) . "\";\n";
      # FLOAT64
      }elsif($vtype == $liberty::SI2DR_FLOAT64){
        $eg .= $print_op." ".lib_SimpleAttrGetFloat64Value($at,\$e)." ;\n";
      # INT32
      }elsif($vtype == $liberty::SI2DR_INT32){
        $eg .= $print_op." ".lib_SimpleAttrGetInt32Value($at,\$e)." ;\n";
      # EXPR
      }elsif($vtype == $liberty::SI2DR_EXPR){
        $eg .= "expr\n";
        die;
      # BOOLEAN
      }elsif($vtype == $liberty::SI2DR_BOOLEAN){
        if(lib_SimpleAttrGetBooleanValue($at,\$e)){
          $print_content = "true";
        }else{
          $print_content = "false";
        }
        $eg .= " ".$print_op." ".$print_content." ;\n";
      }
# Complex attribute
    }elsif($atype == $liberty::SI2DR_COMPLEX){
      my $vals = lib_ComplexAttrGetValues($at,\$e);
      my $first = 1;
      $eg .= " ( ";

      while(1){
        my $cplex = lib_IterNextComplex($vals, \$e);
        my $vt = lib_ComplexValGetValueType($cplex, \$e);

        # STRING
        if($vt == $liberty::SI2DR_STRING) {
          my $str6 = lib_ComplexValGetStringValue($cplex, \$e);
          if(!$first){
            $eg .= ",";
            $eg .= "\\\n ";
            $eg .= $indent3."      "."\"".$str6."\"";
          }else{
            $eg .= "\"$str6\"";
          }
        # FLOAT64
        } elsif($vt == $liberty::SI2DR_FLOAT64) {
          my $f1 = lib_ComplexValGetFloat64Value($cplex, \$e);
          $eg .= $f1;
        } elsif($vt == $liberty::SI2DR_INT32) {
          $eg .= "Boolean\n";
        } elsif($vt == $liberty::SI2DR_BOOLEAN) {
          $eg .= "String\n";
        } elsif($vt == $liberty::SI2DR_EXPR) {
          $eg .= "Expr\n";
        } else{ last; }
        $first = 0;
      }
      $eg .= ");\n";
    }
  } lib_IterQuit($ats, \$e);

  # print Defines
  my $deft;
  my $def;
  my $defs = lib_GroupGetDefines($g, \$e);
  while (!lib_ObjectIsNull (($def = lib_IterNextDefine($defs, \$e)), \$e2)) {
    my $deftype = lib_DefineGetValueType($def,\$e);
    if ($deftype == $liberty::SI2DR_STRING){
      $deft = "string";
    }elsif($deftype == $liberty::SI2DR_FLOAT64){
      $deft = "float";
    }elsif($deftype == $liberty::SI2DR_INT32){
      $deft = "integer";
    }elsif($deftype == $liberty::SI2DR_BOOLEAN){
      $deft = "boolean";
    }
    my $defg = lib_DefineGetAllowedGroupName($def,\$e);
    my $defn = lib_DefineGetName($def,\$e);

    $eg .= $indent2."define(".$defn.", ".$defg.", ".$deft.");\n";
  } lib_IterQuit($defs, \$e);

  return $eg;
}
# }}}

=head1 SEE ALSO

=head2 OpenSource Liberty Project

http://www.opensourceliberty.org

=head1 AUTHOR

yorkwu, E<lt>yorkwuo@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut

1;
# vim:fdm=marker
