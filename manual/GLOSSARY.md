# MiGA API
Ruby Application Interface to MiGA.

# MiGA CLI
Command Line Interface to MiGA.

# MiGA GUI
Graphical User Interface to MiGA.

# MiGA Web
Web-based interface to MiGA.

# MiGA Names
MiGA names are non-empty strings composed exclusively of alphanumerics and
underscores. All the dataset names in MiGA must conform this restriction, but
not all the projects do. Other objects must conform the MiGA name restrictions,
such as taxonomic entries.

# MiGA Dates
The official format in which MiGA represents date/times is the default of Ruby's
`Time.now.to_s`. In the *nix `date` utility this corresponds to the format:
`+%Y-%m-%d %H:%M:%S %z`.