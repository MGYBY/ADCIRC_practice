#!/bin/sh
#Quick script to compile Fortran codes using an input compiler
#Taylor Asher 2014-03-01
#Updated 2014-03-27 to compile checker utility
#Updated 2018-11-20 added logging and error for no command line input
#Updated 2021-08-24 for surface_canopy_v9auto.f

if [ -z "$1" ]; then
   echo "ERROR: must specify compiler at command line"
   exit
fi

ficpiler="$1"
bindir='../bin'
checkdir='../check'
compilelogfile="$bindir/f13builderCompileLog"

#Compile programs for running f13builder
# $cpiler -fdec-math -o $bindir/mnasf mannings_n_finder_v11auto.f
# $cpiler -o $bindir/sshag sshagiderv01.f90
# $cpiler -o $bindir/sss sssiderv02.f90
# $cpiler -o $bindir/scc surface_canopy_v9auto.f
# $cpiler -fdec-math -o $bindir/sderl surface_roughness_calc_v23auto.f
# $cpiler -o $bindir/pwice tau0_genautov1.1.f
# $cpiler -o $bindir/wris wrisoutabox.f90

$ficpiler -fdec-math -o $bindir/mnasf mannings_n_finder_v11auto.f
$ficpiler -o $bindir/sshag sshagiderv01.f90
$ficpiler -o $bindir/sss sssiderv02.f90
$ficpiler -o $bindir/scc surface_canopy_v9auto.f
$ficpiler -fdec-math -o $bindir/sderl surface_roughness_calc_v23auto.f
$ficpiler -o $bindir/pwice tau0_genautov1.1.f
$ficpiler -o $bindir/wris wrisoutabox.f90

#Compile program for checker utility
# $cpiler -o $checkdir/inflate.x $checkdir/inflate.F
$ficpiler -o $checkdir/inflate.x $checkdir/inflate.F
