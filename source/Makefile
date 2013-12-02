PICOFORCE = 
#-D_PICO_FORCE_
PICOFLAG=-D_PICO_ $(PICOFORCE)
#PICOFLAG =

default: cosmomc		
all : cosmomc getdist
ifneq ($(strip $(PICOFLAG)),)
cmcname=cosmomc_pico
CAMBDIR=camb_Oct13_pico
PICOCAMB = pico_camb.o
CLSFILE = CMB_Cls_pico.o
PICO_INC=$(shell python -c "import pypico; print pypico.get_include()")
PICO_LIB=$(shell python -c "import pypico; print pypico.get_link()")
#PICO_INC=-I/usr/include/python2.7 -I/usr/include/python2.7 -I/usr/lib/python2.7/dist-packages/numpy/core/include -I/home/hou/.local/lib/python2.7/site-packages/pypico
#PICO_LIB=-L/home/hou/.local/lib/python2.7/site-packages/pypico -lpico  -L/usr/lib -lpthread -ldl -lutil -lm -lpython2.7
ifneq ($(strip $(PICOFORCE)),)
cmcname=cosmomc_picoforce
endif
else
cmcname=cosmomc
CAMBDIR = camb
CLSFILE = CMB_Cls_simple.o
PICOCAMB=
PICO_INC=
PICO_LIB=
endif


#Intel MPI
#these settings for ifort 13 and higher
#Can remove -xHost if your cluster is not uniform, or specify specific processor optimizations -x...
ifeq ($(HOSTNAME),Local)
F90C     = mpif90 -f90=ifort
else
F90C     = mpif90
endif

FFLAGS = -mkl -openmp -O4 -xHost -no-prec-div -fpp -DMPI -g -openmp -CB -traceback $(PICOFLAG) $(PICO_INC) -assume byterecl
LAPACKL = -lmpi

CC = icc

#use "make RECOMBINATION=cosmorec" to build with CosmoRec rather than RECFAST default
RECOMBINATION ?=recfast

EXTDATA=

#use PRECISION=SINGLE to use single precision
PRECISION ?=

#set WMAP empty not to compile with WMAP, e.g. WMAP = /scratch/../WMAP9/likelihood_v5
WMAP ?=

#Needed for WMAP; set from ~/.bashrc definition or edit here
cfitsio ?=

#empty not to compile with CLIK, set from ~/.bashrc
PLANCKLIKE = cliklike

#These is not used in public cosmomc
highL ?=
#highL = ../highL

IFLAG = -I
## cosmoslik_on ##
INCLUDE = $(shell python-config --includes)
## cosmoslik_off ##

#clik path and library
ifeq ($(PLANCKLIKE),cliklike)
CLIKL = -L$(CLIKPATH)/lib -lclik_f90
INCLUDE += $(IFLAG)$(CLIKPATH)/include
endif


#COSMOS: use "module load cosmolib latest"
#use "runCosmomc" (globally installed) to run, defining required memory usage
ifeq ($(COSMOHOST),cosmos)
F90C = ifort
FFLAGS = -openmp -fast -w -fpp2 -DMPI
LAPACKL = -mkl=sequential -lmkl_lapack -lmpi
cfitsio = $(CFITSIO)
WMAP = $(COSMOLIB)/WMAP9
GSLPATH = $(GSL_ROOT)
endif

ifeq ($(COSMOHOST),darwin)
WMAP = /scratch/aml1005/wmap_likelihood_v5
cfitsio = /usr/local/Cluster-Apps/cfitsio/intel/3.300
FFLAGS = -mkl -openmp -O3 -xHost -no-prec-div -fpp -DMPI
#FFLAGS = -mkl -openmp -g -check all -traceback -no-prec-div -fpp -DMPI -fpe0
endif


#would like to embed this somehow..
#GIT_HASHTAG = "git log --pretty=format:'%H:%cd' -n 1"

PROPOSE = propose.o
## pico_on ##
#CLSFILE = CMB_Cls_simple.o
## pico_off ##

#Can use params_H if you prefer more generic parameters
PARAMETERIZATION = params_CMB.o

F90FLAGS = $(FFLAGS) $(IFLAG)../$(CAMBDIR) $(INCLUDE)
LINKFLAGS = -L../$(CAMBDIR) -lcamb_$(RECOMBINATION) $(LAPACKL) $(F90CRLINK) $(CLIKL) $(PICO_LIB)

DISTFILES = ParamNames.o Matrix_utils.o settings.o ObjectLists.o samples.o IO.o GetDist.o



ifneq ($(PRECISION),)
FFLAGS += -D$(PRECISION) -DMATRIX_$(PRECISION)
endif

ifneq ($(PLANCKLIKE),)
FFLAGS += -DCLIK
endif

ifneq ($(highL),)
FFLAGS += -DhighL
LINKFLAGS += -L$(highL) -lhigh
INCLUDE += $(IFLAG)$(highL)
endif

PLANCKLIKEFILES=


ifneq ($(PLANCKLIKE),)
PLANCKLIKEFILES += $(PLANCKLIKE).o
endif


SUPERNOVAE = supernovae_Union2.o supernovae_SNLS.o

DATAMODULES = $(PLANCKLIKEFILES) power_spec.o wigglez.o mpk.o bao.o $(SUPERNOVAE) supernovae.o HST.o SDSSLy-a-v3.o

LIKEFILES =  DataLikelihoods.o calclike.o

OBJFILES = ObjectLists.o ParamNames.o Matrix_utils.o settings.o samples.o IO.o GeneralTypes.o cmbtypes.o Planck_like.o  \
	likelihood.o bbn.o $(DATAMODULES) $(CLSFILE) cmbdata.o $(PROPOSE) paramdef.o  $(PARAMETERIZATION) $(LIKEFILES) \
	EstCovmat.o PowellConstrainedMinimize.o postprocess.o MCMC.o minimize.o driver.o coscos_wrapper.o $(PICOCAMB)

F90CRLINK =

ifeq ($(RECOMBINATION),cosmorec)
## This is flag is passed to the Fortran compiler allowing it to link C++ (uncomment the right one).
# GCC (gfortran/g++)
COSMOREC_PATH ?= ../CosmoRec/
F90CRLINK = -L$(COSMOREC_PATH) -lCosmoRec -L$(GSLPATH)/lib -lgsl -lgslcblas -lstdc++
# Intel Compilers (ifort/icpc)
#F90CRLINK = -cxxlib -L$(COSMOREC_PATH) -lCosmoRec -L$(GSLPATH)/lib -lgsl -lgslcblas
FFLAGS +=  -DCOSMOREC
endif

ifeq ($(RECOMBINATION),hyrec)
HYREC_PATH ?= ../HyRec/
F90CRLINK += -L$(HYREC_PATH) -lhyrec
endif

default: cosmomc

all : cosmomc getdist

GetDist.o: IO.o samples.o
supernovae.o: $(SUPERNOVAE)
IO.o: ParamNames.o settings.o
samples.o: ObjectLists.o settings.o
likelihood.o: ObjectLists.o settings.o ParamNames.o coscos.o
DataLikelihoods.o: likelihood.o paramdef.o $(DATAMODULES)
cliklike_CamSpec.o: temp_like.o cmbtypes.o
cliklike.o: cmbtypes.o
settings.o: ../$(CAMBDIR)/libcamb_$(RECOMBINATION).a
cmbtypes.o: settings.o likelihood.o GeneralTypes.o
Planck_like.o: cmbtypes.o
cmbdata.o: Planck_like.o coscos_wrapper.o coscos.o
coscos_wrapper.o: coscos.o
bbn.o: settings.o likelihood.o
powerspec.o : cmbtypes.o
wigglez.o: cmbtypes.o power_spec.o
mpk.o: cmbtypes.o power_spec.o
bao.o: cmbtypes.o
HST.o: cmbtypes.o
supernovae.o: cmbtypes.o
$(CLSFILE): cmbtypes.o IO.o $(PICOCAMB)
paramdef.o: $(CLSFILE) propose.o samples.o coscos.o
$(PROPOSE): settings.o
$(PARAMETERIZATION): paramdef.o
calclike.o: DataLikelihoods.o coscos.o
postprocess.o: calclike.o
MCMC.o: calclike.o
driver.o: EstCovmat.o MCMC.o minimize.o $(PARAMETERIZATION) $(PICOCAMB)
minimize.o: PowellConstrainedMinimize.o calclike.o

ifneq ($(highL),)
cliklike_CamSpec.o: $(highL)/libhigh.a
endif


ifneq ($(WMAP),)
cmbdata.o: $(WMAP)/libwmap9.a
F90FLAGS += $(IFLAG)$(cfitsio)/include $(IFLAG)$(WMAP)
LINKFLAGS +=  -L$(cfitsio)/lib -L$(WMAP) -lcfitsio -lwmap9
else
F90FLAGS += -DNOWMAP
endif

## cosmoslik_on ##
LINKFLAGS += -L$(shell python-config --prefix)/lib $(shell python-config --libs)
## cosmoslik_off ##

export FFLAGS
export F90C

.f.o:
	f77 $(F90FLAGS) -c $<

%.o: %.c
	$(CC) $(GSLINC) -c $*.c $(INCLUDE)

## cosmoslik_on ##
coscos_wrapper.c: coscos_wrapper.pyx
	cython $?
## cosmoslik_off ##

%.o: %.f90
	$(F90C) $(F90FLAGS) -c $*.f90

%.o: %.F90
	$(F90C) $(F90FLAGS) -c $*.F90


cosmomc: camb $(OBJFILES)
	$(F90C) -o ../$(cmcname) $(OBJFILES) $(LINKFLAGS) $(F90FLAGS)


clean: cleancosmomc
	rm -f ../$(CAMBDIR)/*.o ../$(CAMBDIR)/*.obj ../$(CAMBDIR)/*.mod ../$(CAMBDIR)/libcamb_$(RECOMBINATION).a

cleancosmomc:
	rm -f *.o *.mod *.d *.pc *.obj ../core coscos_wrapper.c coscos_wrapper.h


getdist: camb $(DISTFILES)
	$(F90C) -o ../getdist $(DISTFILES) $(LINKFLAGS) $(F90FLAGS)

#If you want to use the ppf module, change equations_ppf to equations
#and halofit_ppf to halofit also comment out wa_ppf in CMB_Cls_simple.f90
camb:
	cd ../$(CAMBDIR) && \
	$(MAKE) --file=Makefile_main libcamb_$(RECOMBINATION).a \
	RECOMBINATION=$(RECOMBINATION) EQUATIONS=equations_ppf NONLINEAR=halofit_ppf

$(highL)/libhigh.a:
	cd $(highL); make libhigh.a;

$(WMAP)/libwmap9.a:
	cd $(WMAP); make libwmap9.a;
