       PROGRAM sssider

!Program to identify nodes that should be set to a starting water 
!elevation in the fort.13 nodal attribute file.  Assumes nodes and 
!elements in mesh file are ordered in ascending order from 1.  This 
!program has to guess at the largest number of nodes connected to any 
!other node, if a guess isn't provided as an input.  If this value is 
!too small, an error will occur.  
!
!Taylor Asher, created 2013-11-15





      IMPLICIT NONE
!Parameter declaration/definition
!======================================
      LOGICAL                          :: alldone                               !whether all wet nodes connected to the "current" seed node have been found
      INTEGER                          :: cnt1                                  !counter 1
      INTEGER                          :: cnt2                                  !counter 2
      INTEGER                          :: cnt3                                  !counter 3
      INTEGER                          :: cval                                  !"current" value of econtab inside loop
!      REAL(8)                          :: defwetdeplim                          !negative of defwetelelim, to go with mesh depth convention
!      REAL(8)                          :: defwetelelim                          !default wet limit, above this elevation, nodes are dry
!      CHARACTER(LEN=60)                :: defwetelelimstr                       !string input version of defwetelelim
      REAL(8),ALLOCATABLE              :: dep(:)                                !node depth
      REAL(8),ALLOCATABLE              :: dist(:)                               !distance between "current" seed node and nodes in mesh
      REAL(8)                          :: dryval                                !value set for nodes that are "dry"
      CHARACTER(LEN=100)               :: dumc1                                 !dummy character variable 1
      INTEGER                          :: dumi1                                 !dummy integer variable 1
      REAL(8)                          :: dumr1                                 !dummy real variable 1
      INTEGER,ALLOCATABLE              :: econtab(:,:)                          !element connectivity table
      CHARACTER(LEN=300)               :: filgrid                               !name of input grid file
      CHARACTER(LEN=300)               :: filout                                !name of output nodal connectivity table file
      CHARACTER(LEN=300)               :: filseed                               !name of the seed file containing x,y coordinates of seed locations
!      CHARACTER(LEN=120)               :: fmat                                  !format for output
!      CHARACTER(LEN=60)                :: fmatnum                               !number of connected nodes, for formatting in fmat
      INTEGER                          :: guessmaxncon                          !guess as to the largest number of nodes that are connected to any other node in the mesh
      CHARACTER(LEN=60)                :: guessmaxnconstr                       !guess as to max number of nodes connected to any other node, as a string
      INTEGER                          :: maxncon                               !actual maximum number of nodes connected to any node in the mesh
      INTEGER,ALLOCATABLE              :: ncontab(:,:)                          !node connectivity table
      INTEGER                          :: nseed                                 !number of seed locations
      INTEGER                          :: noda                                  !node in element rotation
      INTEGER                          :: nodb                                  !node in element rotation
      INTEGER                          :: nodc                                  !node in element rotation
      INTEGER                          :: nelm                                  !number of elements (NE in ADCIRC)
      LOGICAL,ALLOCATABLE              :: newwet(:)                             !logical indicating which nodes were found to be wet in the "current" round of the loop
      INTEGER                          :: nnod                                  !number of nodes (NP in ADCIRC)
      LOGICAL,ALLOCATABLE              :: oldwet(:)                             !logical indicating which nodes were found to be wet in the "last" round of the loop
      INTEGER,ALLOCATABLE              :: pos(:)                                !number of nodes connected to each node in mesh
      INTEGER,ALLOCATABLE              :: seednod(:)                            !node numbers of nodes nearest to seed locations
      REAL(8),ALLOCATABLE              :: seedx(:)                              !seed x coordinate
      REAL(8),ALLOCATABLE              :: seedy(:)                              !seed y coordinate
      INTEGER,ALLOCATABLE              :: sortorder(:)                          !array providing the order of the sorted seed elevations
      LOGICAL,ALLOCATABLE              :: startdry(:)                           !logical indicating which nodes are to start dry (including those that would do so naturally)
      REAL(8),ALLOCATABLE              :: tempseed(:)                           !working array
      REAL(8),ALLOCATABLE              :: wetdeplim(:)                          !negative of wetelelim, to go with mesh depth convention
      REAL(8),ALLOCATABLE              :: wetelelim(:)                          !above this elevation, nodes are dry
      REAL(8),ALLOCATABLE              :: wetele(:)                             !wetted elevation to set for nodes
      REAL(8),ALLOCATABLE              :: x(:)                                  !node x coordinate
      REAL(8),ALLOCATABLE              :: y(:)                                  !node y coordinate



      WRITE(*,*)'Begin sshagider'
!INPUTS
!======================================
!Get inputs
      dryval=-99999d0
      CALL GETARG(1,filgrid)                                                    !grid file
      CALL GETARG(2,filout)                                                     !output file
      CALL GETARG(3,filseed)                                                    !file containing seed coordinates
      IF(COMMAND_ARGUMENT_COUNT().GE.4) THEN
!         CALL GETARG(4,defwetelelimstr)                                         !above this elevation, nodes are dry
!      ELSE
!         defwetelelimstr='0'
!      ENDIF
!      IF(COMMAND_ARGUMENT_COUNT().GE.5) THEN
!         CALL GETARG(5,guessmaxnconstr)
         CALL GETARG(4,guessmaxnconstr)
      ELSE
         guessmaxnconstr='30'                                                        !guess as to the largest number of nodes that are connected to any one node in the mesh
      ENDIF
!      READ(defwetelelimstr,*)defwetelelim
!      defwetdeplim=-1d0*defwetelelim
      READ(guessmaxnconstr,*)guessmaxncon


      !Read in file containing x/y coordinates and wet limits of seed locations
      WRITE(*,*)'Opening, reading seed file: '//TRIM(filseed)
      OPEN(15,FILE=TRIM(filseed))
      READ(15,*)nseed
      ALLOCATE(seedx(nseed))
      ALLOCATE(seedy(nseed))
      ALLOCATE(seednod(nseed))
      ALLOCATE(wetelelim(nseed))
      ALLOCATE(wetdeplim(nseed))
      ALLOCATE(sortorder(nseed))
      ALLOCATE(tempseed(nseed))
      DO cnt1=1,nseed
!         READ(15,*)seedx(cnt1),seedy(cnt1)
         READ(15,*)seedx(cnt1),seedy(cnt1),wetelelim(cnt1)
      ENDDO

      !Sort seed points in descending order.  This ensures that when 
      !the routine marches outward, a higher elevation seed isn't 
      !blocked by area already covered by a lower seed.  
      CALL ShellSort(wetelelim,sortorder,nseed)
      tempseed=wetelelim
      DO cnt1=1,nseed
         wetelelim(nseed+1-cnt1)=tempseed(cnt1)
      ENDDO
      tempseed=seedx
      DO cnt1=1,nseed
         seedx(nseed+1-cnt1)=tempseed(sortorder(cnt1))
      ENDDO
      tempseed=seedy
      DO cnt1=1,nseed
         seedy(nseed+1-cnt1)=tempseed(sortorder(cnt1))
      ENDDO
      wetdeplim=-1d0*wetelelim
      write(*,*)wetelelim
      write(*,*)seedx
      write(*,*)seedy


      !Read grid
      WRITE(*,*) "Opening, reading grid file:  "//TRIM(filgrid)
      OPEN(14,FILE=TRIM(filgrid))
      READ(14,*) dumc1
      READ(14,*) nelm,nnod
      ALLOCATE(ncontab(nnod,guessmaxncon))
      ALLOCATE(econtab(nelm,3))
      ALLOCATE(newwet(nnod))
      ALLOCATE(oldwet(nnod))
      ALLOCATE(dist(nnod))
      ALLOCATE(pos(nnod))                                                       !number of nodes connected to each node
      ALLOCATE(x(nnod))                                                         !nodal x coordinate
      ALLOCATE(y(nnod))                                                         !nodal y coordinate
      ALLOCATE(dep(nnod))                                                       !depth
      ALLOCATE(startdry(nnod))                                                  !whether nodes will start dry
      ALLOCATE(wetele(nnod))                                                    !elevation for wet node
      pos=0
      maxncon=0
      !Read node info
      DO cnt1=1,nnod
         READ(14,*)dumi1,x(cnt1),y(cnt1),dep(cnt1)
      ENDDO
      !Read elemental connectivity table
      DO cnt1=1,nelm
         READ(14,*)dumi1,dumi1,&
                   econtab(cnt1,1),econtab(cnt1,2),econtab(cnt1,3)
      ENDDO


!BUILD NODAL CONNECTIVITY TABLE
!======================================
!Loop over elements, building nodal connectivity table.  This is done 
!by inspecting the nodes in each element and adding each node to the 
!others' rows in the nodal connectivity table, if those nodes haven't 
!already been added.  If the maximum number of nodes connected to any 
!any other node is exceeded, the program issues a warning before 
!proceeding to the next statement, which should make it crash.  
      WRITE(*,*)"Building connectivity table"
      DO cnt1=1,nelm
         DO cnt2=1,3
            !Rotate through the 3 nodes in the element
            noda=cnt2
            IF(noda.EQ.1) THEN
               nodb=2
               nodc=3
            ELSEIF(noda.EQ.2) THEN
               nodb=3
               nodc=1
            ELSEIF(noda.EQ.3) THEN
               nodb=1
               nodc=2
            ELSE
               WRITE(*,*)"Invalid value for noda encountered",noda
               WRITE(*,*)"Possible non-triangular element"
            ENDIF

            !Determine uniqueness of nodes in connectivity table and add if unique
            !Do this twice, once for nodb and once for nodc
            cval=econtab(cnt1,noda)                                             !the node number of the current node
            IF(ALL(ncontab(cval,:).NE.econtab(cnt1,nodb))) THEN                 !if nodb is not yet listed as being connected to node cval
               pos(cval)=pos(cval)+1                                            !increment the number of nodes connected to the current node
               IF(pos(cval).GT.maxncon) THEN                                    !keeping track of the maximum number of connected nodes
                  maxncon=pos(cval)
               ENDIF
               IF(maxncon.GT.guessmaxncon) THEN
                  WRITE(*,*)'This program will error, guessmaxncon=',&
                             guessmaxncon
                  WRITE(*,*)'Increase the value of guessmaxncon'
                  WRITE(*,*)'It is the (optional) last input variable'
               ENDIF
               ncontab(cval,pos(cval))=econtab(cnt1,nodb)
            ENDIF
            IF(ALL(ncontab(cval,:).NE.econtab(cnt1,nodc))) THEN
               pos(cval)=pos(cval)+1
               IF(pos(cval).GT.maxncon) THEN
                  maxncon=pos(cval)
               ENDIF
               IF(maxncon.GT.guessmaxncon) THEN
                  WRITE(*,*)'This program will error, guessmaxncon=',&
                             guessmaxncon
                  WRITE(*,*)'Increase the value of guessmaxncon'
                  WRITE(*,*)'It is the (optional) last input variable'
               ENDIF
               ncontab(cval,pos(cval))=econtab(cnt1,nodc)
            ENDIF
!TGA-Dont use this method, it is very slow            econtab=CSHIFT(econtab,1,2)                                         !shift columns of econtab around once
         ENDDO
      ENDDO
!      maxncon=MAXVAL(pos)                                                       !what you'd want to set guessmaxncon to if you had known



!BUILD CONNECTED BASIN(S)
!======================================
!First, find the node nearest each seed location.  No conversion is 
!done from latitude/longitude to a uniform measure of distance, so 
!this is somewhat approximate.  This node, if wet, is considered the 
!seed node.  For each seed node, the algorithm marches outward, 
!finding every node connected to the seed node that should be 
!considered wet, then every node connected to those wet ones that 
!should be wet, and so on until no new wet nodes are discovered.  
!Once all connected nodes that should be classified as wet have been 
!found, the search is complete.  The remaining nodes that should be 
!classified as wet, but that are not connected back to one of the seed 
!nodes are therefore the isolated nodes that must be set to start as 
!dry.  

      !Search for nearest node for each seed
      WRITE(*,*) "Searching for nearest node(s)"
      DO cnt1=1,nseed
         DO cnt2=1,nnod
            dist(cnt2)=SQRT((seedx(cnt1)-x(cnt2))**2+&
                            (seedy(cnt1)-y(cnt2))**2)
         ENDDO
         seednod(cnt1)=MINLOC(dist,1)
      ENDDO

      !Find connected wet nodes to seed node(s)
      WRITE(*,*)'Finding connected wet nodes'
      wetele=dryval
      startdry=.TRUE.
!      WHERE(dep.GE.wetdeplim)
!         startdry(:)=.FALSE.
!      ENDWHERE
      DO cnt1=1,nseed
         newwet=.FALSE.                                                         !whether a new wet node has been found in the current round of the DO WHILE loop
         !If the node is deep enough to be wet
         IF(dep(seednod(cnt1)).LT.wetdeplim(cnt1).OR.&
            wetele(seednod(cnt1)).GT.wetelelim(cnt1)) THEN
            startdry(seednod(cnt1))=.FALSE.
            alldone=.TRUE.                                                      !whether all the wet nodes connected to the current seednod have been found
            IF(dep(seednod(cnt1)).LT.wetdeplim(cnt1))THEN
               WRITE(*,*)'The seed node at ',seedx(cnt1),seedy(cnt1)
               WRITE(*,*)'is in a dry area. Please place by a wet node.'
            ELSEIF(wetele(seednod(cnt1)).GT.wetelelim(cnt1))THEN
               WRITE(*,*)'The seed node at ',seedx(cnt1),seedy(cnt1)
               WRITE(*,*)'is lower than another seed node that has '
               WRITE(*,*)'reached the start location of this seed.  '
               WRITE(*,*)'It therefore will not be used.'
            ENDIF
         ELSE
            alldone=.FALSE.
            newwet(seednod(cnt1))=.TRUE.
         ENDIF
         !Repeat this loop until no new wet nodes are identified
         DO WHILE (.NOT.(alldone))
            oldwet=newwet
            newwet=.FALSE.
            DO cnt2=1,nnod
               IF(oldwet(cnt2)) THEN
                  DO cnt3=1,pos(cnt2)
                     IF(startdry(ncontab(cnt2,cnt3))) THEN
                        IF(dep(ncontab(cnt2,cnt3)).GE.wetdeplim(cnt1)) THEN
                           startdry(ncontab(cnt2,cnt3))=.FALSE.
                           newwet(ncontab(cnt2,cnt3))=.TRUE.
                           wetele(ncontab(cnt2,cnt3))=wetelelim(cnt1)
                        ENDIF
                     ENDIF
                  ENDDO
               ENDIF
            ENDDO
         IF(.NOT.(ANY(newwet))) alldone=.TRUE.                                    !if new wet nodes were found in this round of the loop
         ENDDO
      ENDDO



!OUTPUT
!======================================
!Program only outputs those nodes that are deep enough to be wet, but 
!were not found to be connected (networked) to one of the seed nodes 
!in the previous step.  A "1" is added for insertion into a fort.13 
!file.  
      WRITE(*,*)'Opening, writing output file: '//TRIM(filout)
      OPEN(17,FILE=TRIM(filout))
!.63output      write(17,*)'header'
!.63output      write(17,*)'1 ',nnod,' 1 1 1'
!.63output      write(17,*)'1 1'
      DO cnt1=1,nnod
         IF(wetele(cnt1).NE.dryval)THEN
            WRITE(17,*)cnt1,wetele(cnt1)
!.63output         else
!.63output            write(17,*)cnt1,dryval
         ENDIF
      ENDDO


      WRITE(*,*)"Done sshagider."
      END PROGRAM



      SUBROUTINE ShellSort(a,order,n)
!     Sort array "a".  Returns the array "a" sorted and the sort order 
!     in the "order" variable.  
!     Obtained from:  
!     http://rosettacode.org/wiki/Sorting_algorithms/Shell_sort#Fortran
!     Taylor Asher November 14, 2013
       
      IMPLICIT NONE
      INTEGER :: i, j, increment, n, tempi
      REAL(8) :: temp
      REAL(8), INTENT(in out) :: a(n)
      INTEGER, INTENT(out)    :: order(n)
      
      order=(/(i,i=1,n)/)
      increment = SIZE(a) / 2
      DO WHILE (increment > 0)
         DO i = increment+1, SIZE(a)
            j = i
            temp = a(i)
            tempi=order(i)
            DO WHILE (j >= increment+1 .AND. a(j-increment) > temp)
               a(j) = a(j-increment)
               order(j)=order(j-increment)
               j = j - increment
            END DO
            a(j) = temp
            order(j)=tempi
         END DO
         IF (increment == 2) THEN
            increment = 1
         ELSE
            increment = increment * 5 / 11
         END IF      
      END DO
      END SUBROUTINE
