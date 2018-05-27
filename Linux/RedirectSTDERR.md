## Redirect Stderr

There are two main output streams in Linux (and other OSs), standard output (stdout) and standard error (stderr). Error messages, like the ones you show, are printed to standard error. The classic redirection operator (command > file) only redirects standard output, so standard error is still shown on the terminal. To redirect stderr as well, you have a few choices:

Redirect stdout to one file and stderr to another file:
    command > out 2>error

Redirect stderr to stdout (&1), and then redirect stdout to a file:
    command >out 2>&1

Redirect both to a file:
    command &> out