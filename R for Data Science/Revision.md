# R for Data Science Revision 1

Commit reviewed: [a8e3bc3164cfadc147e946bfd0347e91f40034c4](https://github.com/HectorKroes/brn-skill-assessments/commit/a8e3bc3164cfadc147e946bfd0347e91f40034c4)

>1. Interface:
    - The report looks good to me. But maybe instead of just printing the R shell results directly in the report, you can use in-line code to make the results more presentable. It makes the report look much better, but it isn't necessary.

Understood! I removed the R shell results and implemented the in-line codes in order to exhibit test results without hard coding.

>2. Statistical Reasoning:
    - The tests and why you use them are explained very well now.
    - For the `CO2 emissions` vs `GDP per capita` graphs, the linear scale for Y-axis seems unsuitable as the data points are clumped up at the bottom because of the outlier `Asia`, this doesn't help in understanding the data distribution, try converting it to a different scale(Example: log10, ln scale, etc), it will help understand the data much better.

I changed the scale of the CO2 emissions vs GDP per capita to log10, now allowing a much better presentation of the data.

>3. Coding Practices and style:
    - Don't hard code your results, the in-line codes that were mentioned above are a great way to avoid this. This makes your report much more scalable, meaning by just changing one line like the `year` we want to study about, it automatically changes all the results data, etc. This not only makes your report looks good but helps you to make changes quickly, if required, before a meeting to present a report.
    - Use methods like `map()`, `apply()`, `lapply()`, etc instead of `for loops`. `for loops` are considered bad practice in R language, as they are generally slower than other methods when it comes to large datasets. For the places you have used them, it won't slow down much as the loops are simple and the data is relatively small. But because loops are considered bad practice in general in R, I would encourage you to learn how to avoid them. <https://stackoverflow.com/questions/30240573/are-for-loops-evil-in-r>

The part of hard coding the results was solved in the changes announced in item 1. About the second topic in this item, I created functions to substitute all the for loops in the code, using mainly sapply (that yields vectors as output so it's generally more efficient than lapply). This didn't result in an improvement in execution time, as already predicted in your note (since the data is relatively small), but it served as practice.

## If there's anything more I should change, please let me know. Thank you very much for the thoughtful review!