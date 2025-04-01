#!/bin/bash
quarto render

export PATH="/usr/local/texlive/2024/bin/universal-darwin:$PATH"
export PATH="/Applications/RStudio.app/Contents/Resources/app/quarto/bin/tools/x86_64:$PATH"
Rscript -e "rmarkdown::render('supplementary_figures.Rmd', output_dir = 'sup-figs')"
