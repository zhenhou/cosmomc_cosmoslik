module coscos

    ! Manually make sure our C types and Fortran types are the same size
    ! See corresponding line in coscos_wrapper.pyx
    integer, parameter :: ccint = 8
    integer, parameter :: ccreal = 8

    !!cosmoslik
    type cosmoslik_params
        integer(ccint)     :: num_params = 0
        character(1024), pointer, dimension(:) :: pnames
        real(ccreal), pointer, dimension(:,:) :: info
    end type
    !!cosmoslik

    
    interface

        subroutine init_coscos(kill_on_error)
            !
            ! Initialize the coscos plugin. This must be called before any other coscos functions are used. 
            !
            ! Parameters:
            ! -----------
            ! integer kill_on_error : 1 to exit the program and print a stack trace on a 
            !                         Python error, otherwise 0 to ignore Python errors
            !
            !
            import :: ccint
            integer(ccint) :: kill_on_error

        end subroutine



        subroutine init_script(slik_id,filename)
            !
            ! Initialize a CosmoSlik script.
            !
            import ccint
            character(len=*) :: filename
            integer(ccint) :: slik_id
        
        end subroutine

        
        
        subroutine get_num_params(slik_id,num_params)
            !
            ! Get the number of sampled parameters in the CosmoSlik script
            !
            import ccint
            integer(ccint) :: num_params, slik_id
        
        end subroutine
        
        
        subroutine get_param_info(slik_id,i,paramname,start,min,max,width,scale)
            !
            ! Get parameter info for a given parameter
            !
            ! Parameters:
            ! -----------
            ! 
            ! integer i        : The index of the parameter (indexing starts at 1)
            !
            !
            ! Returns:
            ! --------
            ! string paramname : Pass a character array large enough to hold the
            !                    parameter name. Will be set to the parameters
            !                    name
            ! double start, min, max, width, scale : Will be set to
            !                                        corresponding values
            !                  
            !
            import :: ccint, ccreal
            integer(ccint) :: i, slik_id
            real(ccreal) :: start,min,max,width,scale
            character(len=*) :: paramname
       
        end subroutine
       

        subroutine set_param(slik_id,i,val)
            !
            ! Set a parameter's value
            !
            import :: ccint, ccreal
            integer(ccint) :: i, slik_id
            real(ccreal) :: val

        end subroutine


        subroutine set_cls(slik_id,cls,lmax)
            !
            ! Set the Cls
            !
            ! Order is TT, EE, BB, TE, EB, TB
            !
            import :: ccint, ccreal
            integer(ccint) :: lmax, slik_id
            real(ccreal), dimension(lmax,4) :: cls

        end subroutine


        subroutine get_lnl(slik_id,lnl)
            !
            ! Evaluate the CosmoSlik likelihood at the point in parameter space
            ! specified by all the previous calls to set_param
            !
            import :: ccreal, ccint
            real(ccreal) :: lnl
            integer(ccint) :: slik_id

        end subroutine


    end interface
    
end module
