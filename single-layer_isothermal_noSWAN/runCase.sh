./adcprep --np 10 --partmesh
./adcprep --np 10 --prepall
./adcprep --np 10 --prep15
./adcprep --np 10 --prep13

mpirun -np 10 ./padcirc
