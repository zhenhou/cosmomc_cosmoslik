module pico_camb


    use CAMBmain, only : InitVars
    use ModelParams, only : CAMBparams, CAMBParams_Set, CosmomcTheta, lmin
    use ModelData, only : cl_scalar, cl_lensed, cl_tensor,&
         CTransScal, CTransTens, CTransVec
    use Transfer, only : MT, transfer_tot, transfer_kh, transfer_allocate, transfer_get_sigma8
    use CAMB, only : CAMBdata,w_lam, CAMB_GetResults, CAMB_TransfersToPowers, &
         C_Temp, C_E, C_last, C_Cross, CT_E, CT_B, CT_Temp, CT_Cross, CT_B
    use InitialPower, only : InitializePowers
    use Reionization, only : Reionization_GetOptDepth

    implicit none

   ! logical, private, save :: camb_set_from_pico = .false.
    integer, save  :: num_camb_calls, num_pico_calls
contains

   !!===================================================================

  subroutine Pico_GetTransfers(Params, OutData, error)
    type(CAMBparams) :: Params
    type (CAMBdata)  :: OutData
    integer, optional :: error !Zero if OK
    logical :: used_pico
    
    
    MT =  OutData%MTrans
    CTransScal = OutData%ClTransScal
    CTransVec  = OutData%ClTransVec
    CTransTens = OutData%ClTransTens
    
!    print*,'gettransfers reion:',Params%Reion%redshift,Params%Reion%optical_depth
!    print*,'pico getresults in get transfers'
    call PICO_GetResults(Params, error,used_pico)
!    print*,'post pico getresults in get transfers'

    OutData%set_by_PICO = used_pico
    OutData%Params = Params
    OutData%MTrans = MT
    OutData%ClTransScal = CTransScal
    OutData%ClTransVec  = CTransVec
    OutData%ClTransTens = CTransTens
    
  end subroutine Pico_GetTransfers

   !!===================================================================

   subroutine Pico_TransfersToPowers(CData)
         type (CAMBdata) :: CData
         !integer :: i

         !! If Pico was used, the Cls are already set, so we
         !! don't need to do anything.
!         print*,'pico transfertopowers'
         if (.not. CData%set_by_PICO) then
!            print*,'calling camb for transfers to powers',CData%ClTransScal%ls%l0
            call CAMB_TransfersToPowers(CData)
         end if

   end subroutine Pico_TransfersToPowers
  
  subroutine Pico_GetResults(P, error, used_pico)

        type(CAMBparams) :: P
        integer, optional, intent(out) :: error !Zero if OK
        logical, optional, intent(out) :: used_pico
        integer(4) :: n_q_trans, dum
        real(8), dimension(:), allocatable :: tmp_arr
        real(8) :: fac
        logical success
        integer(4) isuccess
        !        camb_set_from_pico=.false.
!        print*,'pico get results - start'
        call CAMBParams_Set(P,error)
        
        call fpico_reset_params()
#ifdef _PICO_FORCE_
!        print*,'setting force'
        call  fpico_set_param("force",real(1.0,8)) !defaults to off
#endif
        call fpico_set_param("ombh2", real(p%omegab*(p%H0/100.)**2,8))
        call fpico_set_param("omch2", real(p%omegac*(p%H0/100.)**2,8))
        call fpico_set_param("omnuh2", real(p%omegan*(p%H0/100.)**2,8))
        call fpico_set_param("omvh2", real(p%omegav*(p%H0/100.)**2,8))
        call fpico_set_param("omk", real(p%omegak,8))
        call fpico_set_param("hubble", real(p%H0,8))
        call fpico_set_param("w", real(w_lam,8))
        call fpico_set_param("theta", real(CosmomcTheta(),8))
        call fpico_set_param("helium_fraction", real(p%yhe,8))
        call fpico_set_param("massless_neutrinos", 0_8)
        call fpico_set_param("massive_neutrinos", real(p%Num_Nu_massive,8)+real(p%Num_Nu_massless,8))
!        print*,'massive nu:',real(p%Num_Nu_massive,8))
        call fpico_set_param("scalar_spectral_index(1)",real(p%InitPower%an(1),8))
        call fpico_set_param("tensor_spectral_index(1)",real(p%InitPower%ant(1),8))
        call fpico_set_param("scalar_nrun(1)",real(p%InitPower%n_run(1),8))
        call fpico_set_param("initial_ratio(1)",real(p%InitPower%rat(1),8))
        call fpico_set_param("scalar_amp(1)",real(p%InitPower%ScalarPowerAmp(1),8))
        call fpico_set_param("pivot_scalar",real(p%InitPower%k_0_scalar,8))
        !this had set zre, not optical depth
        if (error/= 0) then
           fac = -1
        else
           if (p%Reion%optical_depth /= 0) then
              fac = p%Reion%optical_depth
           else
!              print*,Reionization_GetOptDepth(P%Reion, P%ReionHist)
              fac = Reionization_GetOptDepth(P%Reion, P%ReionHist)
           endif
        end if
!        print*,'reion:',P%Reion%redshift,P%Reion%optical_depth
!        print*,'reionhist:',P%ReionHist%tau_start, P%ReionHist%tau_complete
        
        call fpico_set_param("re_optical_depth",fac) !fac is a dummy variable for optical depth


!        print*,'pico get results - post param set'
        call fpico_reset_requested_outputs()
        if (P%WantCls) then
            if (P%WantScalars) then
                call fpico_request_output("scalar_TT")
                call fpico_request_output("scalar_TE")
                call fpico_request_output("scalar_EE")
            end if
            if (P%WantTensors) then
                call fpico_request_output("tensor_TT")
                call fpico_request_output("tensor_TE")
                call fpico_request_output("tensor_EE")
                call fpico_request_output("tensor_BB")
            end if
            if (P%DoLensing) then
                call fpico_request_output("lensed_TT")
                call fpico_request_output("lensed_TE")
                call fpico_request_output("lensed_EE")
                call fpico_request_output("lensed_BB")
            end if
            if (P%WantTransfer) then
                call fpico_request_output("k")
                call fpico_request_output("pk")
            end if
        end if

        isuccess=1

        call fpico_compute_result(isuccess)
        success=(isuccess /=0)
!        print*,'pico_getresults:',isuccess,success
!        print*,isuccess,success,'pico assigning:',"force",real(1.0,8),"ombh2", real(p%omegab*(p%H0/100.)**2,8),"omch2", real(p%omegac*(p%H0/100.)**2,8),"omnuh2", real(p%omegan*(p%H0/100.)**2,8),"omvh2", real(p%omegav*(p%H0/100.)**2,8),"omk", real(p%omegak,8),"hubble", real(p%H0,8),"w", real(w_lam,8),"theta", real(CosmomcTheta(),8),"helium_fraction", real(p%yhe,8),"massless_neutrinos", 0_8,"massive_neutrinos", real(p%Num_Nu_massive,8)+real(p%Num_Nu_massless,8),"scalar_spectral_index(1)",real(p%InitPower%an(1),8),"tensor_spectral_index(1)",real(p%InitPower%ant(1),8),"scalar_nrun(1)",real(p%InitPower%n_run(1),8),"initial_ratio(1)",real(p%InitPower%rat(1),8),"scalar_amp(1)",real(p%InitPower%ScalarPowerAmp(1),8),"pivot_scalar",real(p%InitPower%k_0_scalar,8),"re_optical_depth",fac

 !       print*,success
!        print*,'pico get results - post compute results'
        
        if (success) then
           !          print*,'pico get results - was successful'
           call InitVars
           
           if (P%WantCls) then
              !              print*,'pico get results - wantcls'
              if (allocated(Cl_scalar)) deallocate(Cl_scalar)
              if (allocated(Cl_tensor)) deallocate(Cl_tensor)
              if (allocated(Cl_lensed)) deallocate(Cl_lensed)
              allocate(Cl_scalar(lmin:P%Max_l,1,C_Temp:C_last))
              allocate(Cl_tensor(lmin:P%Max_l_tensor,1,CT_Temp:CT_Cross))
              allocate(Cl_lensed(lmin:P%Max_l,1,CT_Temp:CT_Cross))
              
              fac = P%tcmb**(-2) * 1e-12
              
              if (P%WantScalars) then
                 !                   print*,'pico get results - wantscalars'
                 call fpico_read_output("scalar_TT",Cl_scalar(:,1,C_Temp),lmin,P%Max_l)
                 call fpico_read_output("scalar_TE",Cl_scalar(:,1,C_Cross),lmin,P%Max_l)
                 call fpico_read_output("scalar_EE",Cl_scalar(:,1,C_E),lmin,P%Max_l)
                 Cl_scalar = Cl_scalar * fac
                 !                    print*,'pico get results - wantscalars - end'
              end if
              
              if (P%WantTensors) then
                 !                   print*,'pico get results - wanttensors'
                 call fpico_read_output("tensor_TT",Cl_tensor(:,1,CT_Temp),lmin,P%Max_l_tensor)
                 call fpico_read_output("tensor_TE",Cl_tensor(:,1,CT_Cross),lmin,P%Max_l_tensor)
                 call fpico_read_output("tensor_EE",Cl_tensor(:,1,CT_E),lmin,P%Max_l_tensor)
                 call fpico_read_output("tensor_BB",Cl_tensor(:,1,CT_B),lmin,P%Max_l_tensor)
                 Cl_tensor = Cl_tensor * fac
                 !                    print*,'pico get results - wanttensors-end'
              end if
              
              if (P%DoLensing) then
                 !                   print*,'pico get results - wantlensing'
                 call fpico_read_output("lensed_TT",Cl_lensed(:,1,CT_Temp),lmin,P%Max_l)
                 call fpico_read_output("lensed_TE",Cl_lensed(:,1,CT_Cross),lmin,P%Max_l)
                 call fpico_read_output("lensed_EE",Cl_lensed(:,1,CT_E),lmin,P%Max_l)
                 call fpico_read_output("lensed_BB",Cl_lensed(:,1,CT_B),lmin,P%Max_l)
                 Cl_lensed = Cl_lensed * fac
                 !                   print*,'pico get results - wantlensing end'
              end if
              !                print*,'pico get results - cls  - end'
           end if
           
!           print*,'pico get results - wanttransfer?',P%WantTransfer
           if (P%WantTransfer) then
              call fpico_get_output_len("k",n_q_trans)
              
              n_q_trans = n_q_trans-1
              call InitializePowers(p%initpower,p%omegak)
              
              MT%num_q_trans = n_q_trans
              call Transfer_Allocate(MT)
              
              
              allocate(tmp_arr(n_q_trans))
              
              call fpico_read_output("k",tmp_arr,0,n_q_trans-1)
              MT%q_trans(:) = tmp_arr(:)
              MT%TransferData(Transfer_kh,:,1) = tmp_arr
              call fpico_read_output("pk",tmp_arr,0,n_q_trans-1)
              MT%TransferData(Transfer_tot,:,1) = tmp_arr
              deallocate(tmp_arr)
              
              call Transfer_Get_sigma8(MT,8._8)
              !                print*,'pico get results - wanttransfer end'
           end if
           
           !            print*,'succesful call pico in pico_getresults'
        else
           !           print*,'calling CAMB_GetResults in pico_getresults'
           call CAMB_GetResults(P,error)
        end if
        !        print*,'pico get results - end'
        if (present(used_pico)) used_pico = success
        if (success) then
           num_pico_calls= num_pico_calls+1
        else
           num_camb_calls= num_camb_calls+1
        endif
        if (modulo(num_pico_calls + num_camb_calls,1000) == 0) &
             print*,'Total calls:',num_pico_calls + num_camb_calls,', Fraction Camb: ',real(num_camb_calls)/(num_pico_calls + num_camb_calls)
        
      end subroutine Pico_GetResults
      
    end module pico_camb
     
