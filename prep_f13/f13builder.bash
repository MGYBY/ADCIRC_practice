#!/bin/bash
#ADCIRC fort.13 nodal attribute file builder main program.  
#
#Taylor Asher
#Updated August 13 2012.  
#
#Updated November 16 2013 to allow multiple starting elevations in sshag and sss.  
#Improved input error checking.  
#
#Updated March 27 2014 to add a framework for future capabilities in wris. 
#Gave sshag the ability to just use a default value (no seed values).  
#Made it so the spatial land cover file doesn't have to exist if no land cover
#dependent attributes are specified.  
#
#Updated October 14 2018 fixed bugs in land cover-based utilities that could 
#cause them to go out-of-bounds on the land cover array for a node near the 
#edge of the land cover data.  Also fixed bug in this code that led to an 
#error when code was run without and land cover-based utilities.  


############################################################
#Subfunctions
function readinput
{
 spatialattrib='n'                                          #initialize assuming no spatial attributes are present
 eval "exec $fidin<$filin"                                    #open input file
 
 read <&$fidin filfort13 stuf                               #nodal attribute file name

 #Read in name of fort.14 file and initialize it
 read <&$fidin filfort14 stuf
 if [ ! -f $filfort14 ] ; then
    echo "!!!!!MESH FILE $filfort14 NOT FOUND, EXITING!!!!!"
    eval "exec $fidin<&-"
    exit
 fi
 initfort14

 read <&$fidin fillc stuf                                   #land cover data file name
 read <&$fidin nattr stuf                                   #number of attributes

 echo "Nodal attrs for $headerfort14">$filfort13
 echo "$nn" >>$filfort13
 echo "$nattr" >>$filfort13

 #Loop over the reading of the attribute names and properties
 for cntri in $(seq 1 $nattr) ; do
    read <&$fidin curnamattr stuf
    echo "Reading attribute $cntri of $nattr, $curnamattr"
    case "$curnamattr" in
    $nammnasf)
       echo "Initializing $nammnasf"
       domnasf=1
       spatialattrib='y'
       initmnasf
       ;;
    $nampwice)
       echo "Initializing $nampwice"
       dopwice=1
       initpwice
       ;;
    $namscc)
       echo "Initializing $namscc"
       doscc=1
       spatialattrib='y'
       initscc
       ;;
    $namsderl)
       echo "Initializing $namsderl"
       dosderl=1
       spatialattrib='y'
       initsderl
       ;;
    $namsshag)
       echo "Initializing $namsshag"
       dosshag=1
       initsshag
       ;;
    $namsss)
       echo "Initializing $namsss"
       dosss=1
       initsss
       ;;
    $namwris)
       echo "Initializing $namwris"
       dowris=1
       initwris
       ;;
    *)
       echo "Nodal attribute $curnamattr not found!!!"
       echo "Program exiting"
       eval "exec $fidin<&-"
       exit
       ;;
    esac

    #Append the info for the nodal attribute to the fort.13 file
    echo "$curnamattr" >>$filfort13
    echo "$curunit" >>$filfort13
    echo "$curvpn" >>$filfort13
    echo "$curdefval" >>$filfort13
 done
 if [ $spatialattrib == 'y' ]; then
    if [ ! -f $fillc ] ; then
       echo "!!!!!LAND COVER FILE $fillc NOT FOUND, EXITING!!!!!"
       eval "exec $fidin<&-"
       exit
    fi
 fi
 
 eval "exec $fidin<&-"                                       #close input file
}


function initfort14
{
 #Open mesh file, read number of nodes, then close file
 eval "exec $fidfort14<$filfort14"
 read <&$fidfort14 headerfort14                             #fort.14 file header
 read <&$fidfort14 ne nn stuf                               #number of elements and nodes
 eval "exec $fidfort14<&-"
}


function initmnasf
{
 read <&$fidin fillc2mnasf stuf                             #file with table converting land cover to mnasf values
 if [ ! -f $fillc2mnasf ] ; then
    echo "!!!!!LAND COVER TO MNASF FILE $fillc2mnasf NOT FOUND, EXITING!!!!!"
    eval "exec $fidin<&-"
    exit
 fi
 read <&$fidin diflcmnasf difdefmnasf stuf                  #whether to use different land cover data (y=yes), whether different default mnasf (y=yes)
 if [ "$diflcmnasf" == 'y' ] ; then
    read <&$fidin fillcmnasf stuf                           #different land cover data file name
    if [ ! -f $fillcmnasf ] ; then
       echo "!!!!!MNASF LAND COVER FILE $fillcmnasf NOT FOUND, EXITING!!!!!"
       eval "exec $fidin<&-"
       exit
    fi
 else
   fillcmnasf=$fillc
 fi
 if [ "$difdefmnasf" == 'y' ] ; then
    read <&$fidin defmnasf stuf                             #different default mnasf value
 fi
 curunit=$unitmnasf; curvpn=$vpnmnasf; curdefval=$defmnasf
}


function initpwice
{
 curunit=$unitpwice; curvpn=$vpnpwice; curdefval=$defpwice
}


function initscc
{
 read <&$fidin fillc2scc stuf
 if [ ! -f $fillc2scc ] ; then
    echo "!!!!!LAND COVER TO SCC FILE $fillc2scc NOT FOUND, EXITING!!!!!"
    eval "exec $fidin<&-"
    exit
 fi
 read <&$fidin diflcscc stuf                                #whether to use different land cover data (y=yes)
 if [ "$diflcscc" == 'y' ] ; then
    read <&$fidin fillcscc stuf                             #different default land cover data file name
    if [ ! -f $fillcscc ] ; then
       echo "!!!!!SCC LAND COVER FILE $fillc NOT FOUND, EXITING!!!!!"
       eval "exec $fidin<&-"
       exit
    fi
 else
    fillcscc=$fillc
 fi
 curunit=$unitscc; curvpn=$vpnscc; curdefval=$defscc
}


function initsderl
{
 read <&$fidin sderlrmax stuf                               #max search distance for finding points in sderl
 read <&$fidin sderlrw stuf                                 #weighting distance for sderl
 read <&$fidin sderlcalcmode stuf                           #whether to do sector (1) or linear (2) calculation of sderl coefficients
 read <&$fidin fillc2sderl stuf                             #file to convert land cover values to sderl values
 if [ ! -f $fillc2sderl ] ; then
    echo "!!!!!LAND COVER TO SDERL FILE $fillc2sderl NOT FOUND, EXITING!!!!!"
    exit
 fi
 read <&$fidin diflcsderl stuf                              #whether to use different land cover data (y=yes)
 if [ "$diflcsderl" == 'y' ] ; then
    read <&$fidin fillcsderl stuf                           #different land cover data file name
    if [ ! -f $fillcsderl ] ; then
       echo "!!!!!SDERL LAND COVER FILE $fillc NOT FOUND, EXITING!!!!!"
       eval "exec $fidin<&-"
       exit
    fi
 else
    fillcsderl=$fillc
 fi
 curunit=$unitsderl; curvpn=$vpnsderl; curdefval=$defsderl
}


function initsshag
{
 read <&$fidin nseedsshag stuf                              #number of seed values for sshag attribute, 0 means to just have one default value
 if [ $nseedsshag -eq 0 ];then
    sshagmode='defaultonly'                                 #mode of operation of sshag, defaultonly means just do a single default value
 elif [ $nseedsshag -gt 0 ];then
    sshagmode='seedextrap'                                  #mode of operation of sshag, seedextrap means use the seeded extrapolation mode
    echo $nseedsshag >$filsshagin
    for cntsshag in $(seq 1 $nseedsshag) ; do
       read <&$fidin seedxsshag seedysshag wetelelimsshag stuf #x-y coordinates and wet elevation to assign
       echo "$seedxsshag $seedysshag $wetelelimsshag" >>$filsshagin
    done
 else
    echo "!!!!!UNKNOWN VALUE FOR nseedsshag $nseedsshag, EXITING!!!!!"
    eval "exec $fidin<&-"
    exit
 fi
 read <&$fidin difdefsshag stuf                             #whether to use a different default value for sshag
 if [ "$difdefsshag" == "y" ] ; then
    read <&$fidin defsshag stuf                             #new default value
 elif [ "$difdefsshag" == 'n' ] ; then
    defsshag="$defsshag"                                    #do nothing
 else
    echo "!!!!!UNKNOWN VALUE FOR difdefsshag $difdefsshag, EXITING!!!!!"
    eval "exec $fidin<&-"
    exit
 fi
 curunit=$unitsshag; curvpn=$vpnsshag; curdefval=$defsshag
}


function initsss
{
 read <&$fidin nseedsss stuf
 echo $nseedsss >$filsssin
 for cntsss in $(seq 1 $nseedsss) ; do
    read <&$fidin seedxsss seedysss wetelelimsss stuf       #x-y coordinates and wet elevation for each seed location
    echo "$seedxsss  $seedysss $wetelelimsss" >>$filsssin
 done
 read <&$fidin difdefwetelelimsss stuf                      #whether to use a different default wet limit for marching
 if [ "$difdefwetelelimsss" == 'y' ] ; then
    read <&$fidin defwetelelimsss stuf                      #default wet limit for marching routine
 elif [ "$difdefwetelelimsss" == 'n' ] ; then
    defwetelelimsss=$defsss
 elif [ "$difdefwetelelimsss" == 'sshagdef' ] ; then
    usesshag='y'                                            #use the sshag value for the wet elevation
 else
    echo "!!!!!UNKNOWN VALUE FOR difdefwetelelimsss $difdefwetelelimsss, EXITING!!!!!"
    eval "exec $fidin<&-"
    exit
 fi
 curunit=$unitsss; curvpn=$vpnsss; curdefval=$defsss
}


function initwris
{
 read <&$fidin nwrisvert stuf                               #flag for vertex count, -1 indicates the corners of a box on one line
 if [ "$nwrisvert" -eq -1 ];then
   read <&$fidin wrisx1 wrisy1 wrisx2 wrisy2 stuf           #lower-left and upper-right x,y coordinates for the box to select wave refraction nodes
 else
   echo "!!!!!UNKNOWN VALUE FOR nwrisvert $nwrisvert, EXITING!!!!!"
   eval "exec $fidin<&-"
   exit
 fi
 curunit=$unitwris; curvpn=$vpnwris; curdefval=$defwris
}





############################################################
#Main
echo "Begin $0 `date`"


#Initializing whether to calculate selected nodal attributes
domnasf=0                                                   #mannings n at sea floor
dopwice=0                                                   #primitive weighting in continuity equation
doscc=0                                                     #surface canopy coefficient
dosderl=0                                                   #surface directional effective roughness length
dosshag=0                                                   #sea surface height above geoid
dosss=0                                                     #surface submergence state
dowris=0                                                    #wave refraction in swan

#Attribute default values
defmnasf='0.0'
defpwice='0.03'
defscc='1'
defsderl='0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0'
defsshag='0.0'
defsss='0'
defwris='1'

#Attribute names
nammnasf='mannings_n_at_sea_floor'
nampwice='primitive_weighting_in_continuity_equation'
namscc='surface_canopy_coefficient'
namsderl='surface_directional_effective_roughness_length'
namsshag='sea_surface_height_above_geoid'
namsss='surface_submergence_state'
namwris='wave_refraction_in_swan'

#Attribute values per node
vpnmnasf=1
vpnpwice=1
vpnscc=1
vpnsderl=12
vpnsshag=1
vpnsss=1
vpnwris=1

#Attribute units
unitmnasf='meters'
unitpwice='unitless'
unitscc='unitless'
unitsderl='meters'
unitsshag='meters'
unitsss='unitless'
unitwris='unitless'

#File names and file identifiers
fidin=10                                                    #input file identifier
fidfort14=14                                                #fort.14 file identifier
filin="$1"                                                  #input file
filsssin='autosssseed.in'                               #input basin seed file for sss
filsshagin='autosshagseed.in'                           #input basin seed file for sshag
filmnasfout='mnasf.out'
filpwiceout='pwice.out'
filsccout='scc.out'
filsderlout='sderl.out'
filsshagout='sshag.out'
filsssout='sss.out'
filwrisout='wris.out'

#Executables
exmnasf='bin/mnasf.x'
# expwice='bin/pwice.x'
expwice='bin/pwice'
exscc='bin/scc.x'
exsderl='bin/sderl.x'
exsshag='bin/sshag.x'
exsss='bin/sss.x'
exwris='bin/wris.x'


#Read and parse input file
if [ ! -f $filin ] ; then
   echo "!!!!!INPUT FILE $filin NOT FOUND, EXITING!!!!!"
   exit
fi
echo "Opening and reading input file $filin"
readinput
echo "Done reading input file $filin"


#Generate non-default values for each attribute, then write them to the 
#fort.13 file.  The generalized steps for this process are as follows:  
#Use the fortran routine to get all the nodes not matching their default 
#values, writing this out to a file.  Then, count the lines 
#in the file to determine the number of nodes without the default value.  
#With the necessary info, write the attribute name, number of non-default 
#nodes, and their values to the fort.13 file.  
if [ $domnasf == '1' ] ; then
   echo "Processing $nammnasf"
   echo "$exmnasf $filfort14 $filmnasfout $fillcmnasf $fillc2mnasf"
   $exmnasf $filfort14 $filmnasfout $fillcmnasf $fillc2mnasf
   nndmnasf=`cat $filmnasfout | wc -l`
   echo $nammnasf >>$filfort13
   echo $nndmnasf >>$filfort13
   cat $filmnasfout >>$filfort13
   rm $filmnasfout
fi
if [ $dopwice == '1' ] ; then
   echo "Processing $nampwice"
   echo "$expwice $filfort14 $filpwiceout"
   $expwice $filfort14 $filpwiceout
   nndpwice=`cat $filpwiceout | wc -l`
   echo $nampwice >>$filfort13
   echo $nndpwice >>$filfort13
   cat $filpwiceout >>$filfort13
   rm $filpwiceout
fi
if [ $doscc == '1' ] ; then
   echo "Processing $namscc"
   echo "$exscc $filfort14 $filsccout $fillcscc $fillc2scc"
   $exscc $filfort14 $filsccout $fillcscc $fillc2scc
   nndscc=`cat $filsccout | wc -l`
   echo $namscc >>$filfort13
   echo $nndscc >>$filfort13
   cat $filsccout >>$filfort13
   rm $filsccout
fi
if [ $dosderl == '1' ] ; then
   echo "Processing $namsderl"
   echo "$exsderl $filfort14 $filsderlout $fillcsderl $fillc2sderl $sderlrmax $sderlrw $sderlcalcmode"
   $exsderl $filfort14 $filsderlout $fillcsderl $fillc2sderl $sderlrmax $sderlrw $sderlcalcmode
   nndsderl=`cat $filsderlout | wc -l`
   echo $namsderl >>$filfort13
   echo $nndsderl >>$filfort13
   cat $filsderlout >>$filfort13
   rm $filsderlout
fi
if [ $dosshag == '1' ] ; then
   echo "Processing $namsshag"
   echo $namsshag >>$filfort13
   if [ $sshagmode == 'seedextrap' ];then
      echo "$exsshag $filfort14 $filsshagout $filsshagin"
      $exsshag $filfort14 $filsshagout $filsshagin
      rm $filsshagin
      nndsshag=`cat $filsshagout | wc -l`
      echo $nndsshag >>$filfort13
      cat $filsshagout >>$filfort13
      rm $filsshagout
   elif [ $sshagmode == 'defaultonly' ];then
      echo 0 >>$filfort13
   else
      echo "!!!!!UNKNOWN VALUE FOR sshagmode $sshagmode, EXITING!!!!!"
      exit
   fi
fi
if [ $dosss == '1' ] ; then
   echo "Processing $namsss"
   if [ "$difdefwetelelimsss" == 'sshagdef' ] ; then
      if [ "$dosshag" == '1' ] ; then
         defwetelelimsss=$defsshag
      else
         echo "!!!!!INPUT difdefwetelelimsss = $difdefwetelelimsss REQUIRES THAT $namsshag BE ENABLED, EXITING!!!!!"
         exit
      fi
   fi
   echo "$exsss $filfort14 $filsssout $filsssin $defwetelelimsss"
   $exsss $filfort14 $filsssout $filsssin $defwetelelimsss
   rm $filsssin
   nndsss=`cat $filsssout | wc -l`
   echo $namsss >>$filfort13
   echo $nndsss >>$filfort13
   cat $filsssout >>$filfort13
   rm $filsssout
fi
if [ $dowris = '1' ] ; then
   echo "Processing $namwris"
   echo "$exwris $filfort14 $filwrisout $wrisx1 $wrisy1 $wrisx2 $wrisy2"
   $exwris $filfort14 $filwrisout $wrisx1 $wrisy1 $wrisx2 $wrisy2
   nndwris=`cat $filwrisout |wc -l`
   echo $namwris >>$filfort13
   echo $nndwris >>$filfort13
   cat $filwrisout >>$filfort13
   rm $filwrisout
fi



echo "Done $0 `date`"

