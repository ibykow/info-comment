# info-comment
C style multi-line block comments

Tired of formatting multi-line C-style block comments by hand?  
Well now you can use `ctrl-cmd-/` to change this:

```javascript
This is a comment
describing the code
below.

function my_code() {
    ...
}
```

into this:

```javascript
/*
 * This is a comment
 * describing the code
 * below.
 */

function my_code() {
    ...
}
```

#### Supported Languages
By default, this package supports the following languages:

- ActionScript
- AutoHotkey
- C
- C++
- C#
- D
- Go
- Java
- JavaScript
- Objective-C
- PHP
- PL/I
- Rust
- Scala
- SASS
- SQL
- Swift
- Visual Prolog
- CSS

#### Settings

##### Languages
Add languages that are not on the list above to have this package work with them.

##### Leave Top Blank  
When checked, this will leave the top line of the comment blank as in:

```
/*
 * Hello World!
 * This is my comment.
 * It's a short one.
 */
```

When cleared, you get the following instead:

```
/* Hello World!
 * This is my comment.
 * It's a short one.
 */
```

##### Mid String  
Configure the string you want to use as the start of every line between the first and last. The default is ` * `, but if you want comments to look like this instead:

```
/*
 + Hello World!
 + This is my comment.
 */
```

then change the Mid String setting to ` + `.  
Don't forget to add a space before and after the character you want to use, as in '\_+\_'. Otherwise, you'll wind up with comments looking like the following:

```
/*
+Hello World!
+This is my ugly comment.
+I forgot to add a space before and after
+the '+' character in the Mid String setting.
 */
```
