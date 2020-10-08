# Sequence Alignment

## Overview

This repository contains my Part II Project (3rd year project) from my Computer Science BA at the University of
Cambridge. This has been edited and generally tidied up from the state it was submitted in, mainly for brevity and
clarity. The dissertation is identical to the one I submitted, and received 79/100 marks.

In short, the project was investigating different processor architectures (CPUs, GPUs, and custom hardware on an FPGA)
to compare their performance when solving [Sequence Alignment](https://en.wikipedia.org/wiki/Sequence_alignment)
problems using the [Smith–Waterman algorithm](https://en.wikipedia.org/wiki/Smith–Waterman_algorithm). This algorithm
is commonly used in the field of bioinformatics, to compare biological polymers like proteins or DNA. It is a
dynamic programming problem that at worst can scale quadratically in space and time, though can be reduced to using
linear space. There is significant scope for parallelisation but it is not embarrassingly parallel, which provided
some interesting design challenges.

The code for the CPU was written in C, for the GPU in CUDA, and for the FPGA in SystemVerilog (with a rudimentary
driver written in C). Perhaps unsurprisingly, even a basic FPGA design was much faster than the CPU or GPU could
manage, and the FPGA design in particular had a lot of scope for optimisation, whilst running on a fairly old board
(especially when compared to the CPU and GPU I used). This is a new repository for the published version, made from
my development files. It is much tidier and comes without the large diagnostic files that probably should have never
been checked into Git in the first place...

## Uses of this repository

This project is finished as far as I'm concerned, and I will not be maintaining it. There are other implementations for
all three platforms that exist already, some of which are being actively maintained, and most of which have had more
than 1 undergraduate-year's worth of work put into them. Much of this was a learning exercise for me; this was the
first time I wrote any CUDA, and the first time I used SystemVerilog for more than a toy example.

That is not to say no one will find this repository useful. I imagine this will be useful to students embarking on
large projects, from looking at how I've written my dissertation in LaTeX to the general design on my FPGA accelerator.
I have tried to document most of the general architectural choices I made when using a DE1 SoC board, which are the
standard boards used in hardware labs at Cambridge. If you are doing a project making an FPGA accelerator of some kind
on one of these boards, then I hope those files will be of use for you!
