I am learning Perl, a sysadmin language from the late 80s for my job at DoseMe, where we create precision dosing software.

This article was published on 11/15/2018.

## Variables

Variables are pretty similar to most languages, with a few quirks:

```pl
my $name; # scalar
my @_private_names; # array
my %Names_to_Addresses; # hash
sub myFunction; # function (known as subroutine)
```

You use `$` to access a single element of an array or hash, which of course, is a scalar (an array of scalars):

```pl
my @vals = ('a', 'b', 'c');

print "@vals\n"; # a b c
print "$vals[0]\n"; # a
```

Hashes are a little less nice to print:

```pl
use Data::Dumper;

my %other_vals = (
  'a' => 'aa',
  'b' => 'bb',
  'c' => 'cc'
);

print Dumper \%other_vals; 

$VAR1 = {
          'a' => 'aa',
          'b' => 'bb',
          'c' => 'cc'
        };
```

Or a slick one liner:

```pl
print "$_ $others_vals{$_}\n" for (keys %other_vals);

# not necessarily in order
# c
# a
# b
```

You can set values like so:

```pl
print "new_arr[0]: $new_arr[0]\n"; 
print "new_hash{'a'}: $new_hash{'a'}\n";

# prints new_arr[0]: 1
# prints new_hash{'a'}: 1
```

Moose is a object system for Perl. OO was basically bolted onto Perl as an afterthough. Let's see an example.

```pl
package Store::Toy { 
  use Moose;

  has 'discount' => (is => 'ro', isa => 'Num');
}

my $store = Store::Toy->new(discount => 0.1);

my $discount = $store->discount;

print "Discount is $discount"; # 0.1
```

Types coercion is a thing. For example, using the scalar `$` on an array returns the count:

```pl
my @arr = (1, 2, 3);
my $count = @arr;

print "Count of (@arr) is: $count\n";
```

There is also the _quoting operator_, and _heredoc_, similar to Ruby: 

```pl
print qq("Ouch", he said); # prints "Ouch", he said. Note, it keeps the doublequotes.

my $longquote =<<'END_BLURB';

I can type really
long
text
END_BLURB
```

Reading a textfile is done like so:

```pl
my $textfile = 'README.md';

open $fh, '<:utf8', $textfile;

while (my $row = <$fh>) {
  chomp $row;
  print "$row\n";
}

```

Perl's version of `undefined` is `undef`:

```pl
my $rank; # undef
my $name = undef;
```

`undef` evaluates to `false` in a boolean context. The opposite is `defined`:

```pl
if (defined 'str') {
  print 'true';
} else {;
  print 'false';
}

# prints true
```

A common perl idiom that takes advantage of `()` on the LHS of an assignment is the following, to get the count of a lsit without using a temporary variable:

```pl
my $count = () = (1, 2, 3); # () on the LHS forces a list context
print $count; # prints the count, 3
```
 
There is a `..` operator, or the range operator:

```pl
print 1..4 # 1234
```

There are few ways to do loops in perl:


```pl
foreach (1..10) {
  say "$_";
}
```

This sets the _topic variable_ `$_`.

Another way:

```pl
say "$_" for 1..10;
```
