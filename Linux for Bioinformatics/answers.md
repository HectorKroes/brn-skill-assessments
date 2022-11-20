# Linux for bioinformatics task report - Hector Kroes

## Part 1

**Q1. What is your home directory?**

A: 
`/home/ubuntu`

**Q2. Change the file location to the my_folder/ directory and then type ls. What is the output of this command?**

A:
```bash
ubuntu@ip-172-31-87-211:~/my_folder$ ls
hello_world.txt
```

**Q3. Copy the file from my_folder1 to my_folder2 and afterwards delete it from my_folder1. List the contents of my_folder/ and my_folder2/. What is the output of each ls command?**

A:
```bash
ubuntu@ip-172-31-87-211:~/my_folder$ ls
ubuntu@ip-172-31-87-211:~/my_folder2$ ls
hello_world.txt
```

**Q4. Move the file from my_folder2 to my_folder3. List the contents of my_folder/, my_folder2/, and my_folder3. What is the output of each?**

A:
```bash
ubuntu@ip-172-31-87-211:~/my_folder$ ls
ubuntu@ip-172-31-87-211:~/my_folder2$ ls
ubuntu@ip-172-31-87-211:~/my_folder3$ ls
hello_world.txt
```

**Q5. What editor did you use and what was the command to save your file changes?**

A: 
I used nano. `Ctrl+X` saves and closes the file being edited.

**Q6. Try to connect as sudouser. What is the error?**

A: 
`Server refused our key`. We're trying to connect to sudouser with ubuntu's authorized keys, so it shoots an authentication error.

**Q7. Solve the issue. What was the solution?**

A:
I created a new key pair and added its public key to the file `authorized_keys` on `/home/sudouser/.ssh`. This way, all I have to do to login as ubuntu or sudouser is choosing the adequate key.

**Q8. what does the sudo docker run part of the command do? and what does the salmon swim part of the command do?**

A:
The `sudo docker run` part creates a docker container, an isolated standard unit of software that packages up code and all its dependencies so we can run applications quickly and reliably from one computing environment to another. Multiple of these containers can run on a computer at the same time and we can look at them with the command `sudo docker ps -a`:
```bash
sudouser@ip-172-31-87-211:~$ sudo docker ps -a
CONTAINER ID   IMAGE               COMMAND         CREATED         STATUS                     PORTS     NAMES
73a5a7e150d4   combinelab/salmon   "salmon swim"   2 minutes ago   Exited (0) 2 minutes ago             eager_ardinghelli
93f9bdef9cd3   hello-world         "/hello"        3 minutes ago   Exited (0) 3 minutes ago             gracious_mendeleev
```
The `combinelab/salmon salmon swin` part loads the `combinelab/salmon` image into the docker container to execute the function `salmon swim`. The result is the following:
```bash
sudouser@ip-172-31-87-211:~$ sudo docker run combinelab/salmon salmon swim
Version Info: This is the most recent version of salmon.

    _____       __
   / ___/____ _/ /___ ___  ____  ____
   \__ \/ __ `/ / __ `__ \/ __ \/ __ \
  ___/ / /_/ / / / / / / / /_/ / / / /
 /____/\__,_/_/_/ /_/ /_/\____/_/ /_/

```

**Q9. What is the output of the command sudo ls /root when executed by serveruser?**

A:
```bash
serveruser@ip-172-31-87-211:~$ sudo ls /root
[sudo] password for serveruser:
serveruser is not in the sudoers file.  This incident will be reported.
```

**Q10. What is the output of flask --version?**

A:
```bash
(base) serveruser@ip-172-31-87-211:~$ flask --version
Python 3.9.12
Flask 2.1.3
Werkzeug 2.0.3
```

**Q11. What is the output of mamba -V?**

A:
```bash
(base) serveruser@ip-172-31-87-211:~$ mamba -V
conda 22.9.0
```

**Q12. What is the output of which python when inside py27?**

A:
```bash
(py27) serveruser@ip-172-31-87-211:~$ which python
/home/serveruser/mambaforge/envs/py27/bin/python
```

**Q13. And what is the output of which python in the (base) environment?**

A:
```bash
(base) serveruser@ip-172-31-87-211:~$ which python
/home/serveruser/mambaforge/bin/python
```

**Q14. What is the output of salmon -h?**

```bash
(salmonEnv) serveruser@ip-172-31-87-211:~$ salmon -h
salmon v1.4.0

Usage:  salmon -h|--help or
        salmon -v|--version or
        salmon -c|--cite or
        salmon [--no-version-check] <COMMAND> [-h | options]

Commands:
     index      : create a salmon index
     quant      : quantify a sample
     alevin     : single cell analysis
     swim       : perform super-secret operation
     quantmerge : merge multiple quantifications into a single file
```

**Q15. What does the -o athal.fa.gz part of the command do?**

A:
This argument specifies the output file name for the curl command.

**Q16. What is a .gz file?**

A:
A `.gz` file is an archive file compressed by the standard GNU zip (gzip) compression algorithm.

**Q17. What does the zcat command do?**

A:
The `zcat` command lets you view contents of a compressed file.

**Q18. What does the head command do?**

A:
The `head` command prints the top N lines of data of the given input.

**Q19. What does the number 100 signify in the command?**

A:
100 is the amount of data lines the `head` command will print from the file.

**Q20. What is | doing? -- Hint using | in Linux is called "piping"**

A:
A `|` directs the output from its left term to the input of its right term, piping the results through other commands. 

**Q21. What is a .fa file? What is this file format used for?**

A:
`.fa` files are FASTA Formatted Sequence Files and usually contain nucleic or aminoacid sequences.

## Part 2

**Q22. Download the RNA-Seq sample "SRR074122" using prefetch. What format are the downloaded sequencing reads in?**

A:
The sequencing reads are downloaded in the `.sra` format.

**Q23. What is the total size of the disk?**

A:
The total space in `/dev/root` is 7.6 Gb.

**Q24. How much space is remaining on the disk?**

A:
The remaining space in `/dev/root` at this moment is 1.3 Gb.

**Q25. Convert the reads to fastq format using this command: fastq-dump SRR074122. What went wrong?**

A:
There's no sufficient space in disk to conclude the operation:
```bash
2022-11-19T21:55:27 fastq-dump.3.0.0 err: storage exhausted while writing file within file system module - system bad file descriptor error fd='6'

=============================================================
An error occurred during processing.
A report was generated into the file '/home/serveruser/ncbi_error_report.txt'.
If the problem persists, you may consider sending the file
to 'sra-tools@ncbi.nlm.nih.gov' for assistance.
=============================================================

fastq-dump quit with error code 3
```

**Q26: What was your solution?**

A:
Using the `gzip` argument in the `fastq-dump` command.