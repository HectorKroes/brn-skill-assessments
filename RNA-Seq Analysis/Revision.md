# RNA-Seq Analysis Revision 1

Commit reviewed: [84d179ce18e514df62b6ddf5e405bcd5b4561ec0](https://github.com/HectorKroes/brn-skill-assessments/commit/84d179ce18e514df62b6ddf5e405bcd5b4561ec0)

>Your citations don't actually link to the reference at the bottom. How can you fix this (hint: likely missing something in your YAML header)

Added `link-citations: true` in the YAML header so the references now link to the bibliography section.

>You should add something to your `.gitignore` so you don't push `rse_gene.Rdata` to your repo

I deleted the Rdata file from the repository and added a [new line](https://github.com/HectorKroes/brn-skill-assessments/commit/a517a9a882d8321f02f93dc3a3d3afc7c07005bb) in the `.gitignore` file so the dataset isn't pushed anymore.

>(Optional) Use [inline code](https://rmarkdown.rstudio.com/lesson-4.html) to render R variables in your Markdown sections. That way, if you change any variables, those changes will also reflect in Markdown

I changed my report so the genes discussed in the biological relevance section are presented using inline code.

>(Optional) Add a relevant `.csl` to your YAML header to change the citation style to numbered instead

Added the `citation_style.csl` file to the YAML header so the citations are now numbered.

## If there's anything more I should change, please let me know. Thank you very much for the thoughtful review!