## Introduction 

Regex is something I have always been slighly afraid of - long, intimidating and barely readable strings. However, today is the day I learn regex, and start to use them to be more productive. Most of the examples and resources I used come from [RegexOne](https://regexone.com).

### Basic Matching

The most basic regex is simply the text you want to match.

```
/abc/ -> matches anything starting with "abc"
```

Easy enough.

### Digits and Characters with \d  and \d

We can also match *any* non digit character using `\D`. Digits match using `\d\`.

For example, we can match `12` using `\d\`. Or `a1` with `\D\d`.

### Wildcards with the .

`.` matches anything. **Anything**. Even whitespace. You can match a literal `.` by escaping with \.

### Groups with []

You can specify groups to match using `[]`. For example we can match `man` and `can` but not `dan` with `[mc]`.

### Excluding matches with ^

You can exclude matches using `^`. We can match `hog` and `dog` but ignore `bog` using `[^b]`. For completeness we can do `[^b]og`.

### Ranges

 You can define ranges, for example to match English words the follow is often used: `[A-Za-z0-9_]`. Writing that is tiresome, so you can use the metacharacter `\w` which accomplishes the same thing. An example of a range is `[A-D`], which matches anything containing A, B, C or D.

### Matching a repetitions

You can match repetitions using `{}`. For example `a{2}` matches two *or more* `a` letters. It also works with ranges, for example `[a-c]{2}` matches a, b or c twice in a row. You can also match `bear` with `b{1}..r{1}`.

### * and + for arbitrary matching

You can match any number of occurrences with `*` and at least one or more with `+`. For example `a+` matches any string with at least one `a`. Or `[abc]+` matches any string with either a, b or c.
 
### Optional matches with ?

`?` indicates a character  is optional. `ab?c` will match both `abc` and `ac`, since `b?` is optional.

Take the following:

```
1 file found?
2 files found?
24 files found?
0 files found.
```

We can match the first three, but not the last, `\?`. Or a complete match with `\d?.*\?`. An optional digit, any number of characters and a `?`.

### Whitespace with \s

You can match whitespace with `\s`. For example:

```
  a
    b
c
```

We can match the first two with `\s+`. This means "starting with whitespace". We can improve it with `\s+.*`, to look for characters after the whitespace.

### Matching start end ends with ^ and $

We can match the start of a line with ^ and the end with $. For example, we can match Australia with `^A.*a$`. Starting with `A`, and arbitrary amount of characters, then ending with `a`.


### Captures

We can specify which part of the regex we want to keep, or capture, using `()`. Say we have a bunch of files, and we want the filename part of all the `.pdf` files.

```
file_record.pdf
file_aaa.pdf
other.png
```

We can match and capture the pdf file names using `(^file.*)\.pdf`. Anything starting with `file` and ending with `.pdf`, but only keep the filename part.

### Multiple capture groups

You can capture multiple sets of charaters in the same expression. Take this example:

```
Jan 1987
Mar 1983
Oct 2012
```

We can match the month and year, and then just the year part, with the following:

```
(\D{3}\s+(\d{4}))
```

Which reads: 

- any three non digits
- at least one whitespace
- any four digits

Another example:


```
1280x720 
1920x1600	
1024x768	
```

We want to capture both the width and height. the height is three and an optional fourth digit. The regex looks like this:

```
(\d{4})x+(\d{3}\d?)
```

### Or with |

You can match using logical OR using `|`. For example you can match "I love cats" and "I love dogs" with `I love (cats|dogs)`.

### Some other metacharacters

`\S` matches non whitespace
`\b` matches the boundary between a word and non word character.

## Conclusion

Learning just some basic regex make the whole system a lot less scary, and is very exciting. I will continue practising and learning regex.
