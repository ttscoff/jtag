### 0.1.19

2024-09-16 13:15

#### NEW

- Allows piping of file lists. For actions to which it applies, you can pipe a file list, either from a previous jtag command or from another source (newline separated) to act on only those files, e.g. `jtag posts_tagged keyboard | jtag tags`

#### FIXED

- File.exists? => File.exist? for Ruby 3

### 1.0

Initial release
