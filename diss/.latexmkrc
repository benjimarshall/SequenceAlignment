# Compile to pdf
$pdf_mode = 1;

# Use BibTeX
$bibtex_use = 2;

# Only compile the root document files, the other .tex files are components of
# these documents
@default_files = ('diss.tex', 'proposal.tex', 'progress_report.tex');

# Quieten down the very noisy LaTeX compiler
$silent = 1;

