    ! UNION 2.1 Supernovae Ia dataset
    !
    ! This module uses the SCP (Supernova Cosmology Project) Union 2
    ! compilation. Please cite
    ! "Suzuki et al. (SCP) 2011, arXiv:1105.3470 (2011 ApJ Dec 20 issue)".
    ! and the references of other compiled supernovae data are in there.
    !
    ! Originally by A Slosar, heavily based on the original code by A Lewis, S Bridle
    ! and D Rapetti E-mail: Anze Slosar (anze@berkeley.edu) for questions
    ! about the code and David Rubin (rubind@berkeley.edu) for questions
    ! regarding the dataset itself.   Updated by Nao Suzuki (nsuzuki@lbl.gov)
    !
    ! Marginalizes anayltically over H_0 with flat prior.  (equivalent to
    ! marginalizing over M, absolute magnitude; see appendix F of cosmomc
    ! paper). Resultant log likelihood has arbitary origin and is
    ! numerically equal to -chi^2/2 value at the best-fit value.
    !
    ! Update Note :
    !
    ! Union1   (Kowalski et al 2008)  : 307 SNe with SALT1 fit (Guy et al 2005)
    ! Union2   (Amanullah et al 2010) : 557 SNe with SALT2 fit (Guy et al 2007)
    ! Union2.1 (Suzuki et al 2011)    : 580 SNe with SALT2 fit (Guy et al 2007)
    !
    ! The following parameters are used to calculate distance moduli
    ! (see Suzuki et al. 2011 for complete description)
    !
    ! alpha 0.121851859725    ! Stretch Correction Factor
    ! beta 2.46569277393      ! Color   Correction Factor
    ! delta -0.0363405630486
    ! M(h=0.7, statistical only) -19.3182761161 ! Absolute B Magnitue of SNIa
    ! M(h=0.7, with systematics) -19.3081547178 ! Absolute B Magnitue of SNIa
    !
    !  Tips for running cosmomc with SCP UNION2.1 data
    !
    !  1) Place the following 3 data files in your cosmomc data dir (DataDir)
    !     a) sn_z_mu_dmu_plow_union2.1.txt : SN data
    !        SN name, z, distance moduli mu, mu error, host mass weight probability
    !     b) sn_covmat_sys_union2.1.txt    : Covariance Matrix with    systematic error
    !     c) sn_covmat_nosys_union2.1.txt  : Covariance Matrix without systematic error
    !
    !  2) Make sure DataDir is set in your settings.f90
    !     character(LEN=1024) :: DataDir='yourdirpathto/cosmomc/data/'
    !     The default is 'data/' and if it works for you, just leave it as it is
    !
    !  3) Pick SN data 'with' or 'without' systematic error
    !     (default is 'with' systematic error)
    !     Modify the folowing SN_syscovamat=.True. or .False.
    !
    !  4) To make UNION2 as your default,
    !     either rename supernovae_union2.1.f90 as supernovae.f90 and recompile it
    !     or change targets in your Makefile from supernova to supernovae_union2.1
    !
    !  Note: In your default params.ini, there is a line for 'SN_filename', but this
    !     union2 module does not use it.  You can leave it as it is, and cosmomc
    !     runs without any error but that information is not used.
    !     To avoid confusion, you may want to comment it out.
    !
    !   Update Note by Nao Suzuki (LBNL)

    module Union2
    use cmbtypes
    use MatrixUtils
    use likelihood
    implicit none

    integer, parameter :: SN_num = 580

    type, extends(CosmologyLikelihood) :: Union2Likelihood
        double precision :: SN_z(SN_num), SN_moduli(SN_num), SN_modulierr(SN_num), SN_plow(SN_num)
        double precision :: SN_Ninv(SN_num,SN_Num)
    contains
    procedure :: LogLikeTheory => SN_LnLike
    end type Union2Likelihood

    contains

    subroutine Union2Likelihood_Add(LikeList, Ini)
    use IniFile
    use settings
    class(LikelihoodList) :: LikeList
    Type(TIniFile) :: ini
    Type(Union2Likelihood), pointer :: like
    character (LEN=20):: name
    integer i
    ! The following line selects which error estimate to use
    ! default .True. = with systematic errors
    logical :: Union_syscovmat = .False.  !! Use covariance matrix with or without systematics


    if (.not. Ini_Read_Logical_File(Ini, 'use_Union',.false.)) return

    allocate(like)
    Like%LikelihoodType = 'SN'
    Like%name='Union2.1'
    like%needs_background_functions = .true.
    call LikeList%Add(like)

    Union_syscovmat = Ini_read_Logical_File(Ini,'Union_syscovmat',Union_syscovmat)

    if (Feedback > 0) write (*,*) 'Reading: supernovae data'
    call OpenTxtFile(trim(DataDir)//'sn_z_mu_dmu_plow_union2.1.txt',tmp_file_unit)
    do i=1,  sn_num
        read(tmp_file_unit, *) name, Like%SN_z(i),Like%SN_moduli(i), &
        Like%SN_modulierr(i),Like%SN_plow(i)
        !     read(tmp_file_unit, *) name, SN_z(i),SN_moduli(i)
    end do
    close(tmp_file_unit)

    if (Union_syscovmat) then
        call OpenTxtFile(trim(DataDir)//'sn_wmat_sys_union2.1.txt',tmp_file_unit)
    else
        call OpenTxtFile(trim(DataDir)//'sn_wmat_nosys_union2.1.txt',tmp_file_unit)
    end if

    do i=1, sn_num
        read (tmp_file_unit,*) Like%sn_ninv (i,1:sn_num)
    end do

    close (tmp_file_unit)

    end subroutine Union2Likelihood_Add

    function SN_LnLike(like, CMB)
    use camb
    !Assume this is called just after CAMB with the correct model  use camb
    Class(CMBParams) CMB
    Class(Union2Likelihood) :: like
    real(mcp) SN_LnLike
    integer i
    double precision z
    real(mcp) diffs(SN_num), chisq

    !! This is actually seems to be faster without OMP
    do i=1, SN_num
        z= Like%SN_z(i)
        diffs(i) = 5*log10((1+z)**2*AngularDiameterDistance(z))+25 -Like%sn_moduli(i)
    end do

    chisq = dot_product(diffs,matmul(Like%sn_ninv,diffs))

    !! H0 normalisation alla Bridle and co.

    if (Feedback > 1) write (*,*) 'SN chisq: ', chisq

    SN_LnLike = chisq/2


    end function SN_LnLike


    end module Union2
