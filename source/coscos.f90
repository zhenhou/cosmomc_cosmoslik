module coscos
    
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

            integer :: kill_on_error

        end subroutine



        subroutine init_script(filename)
            !
            ! Initialize a CosmoSlik script.
            !
        
            character(len=*) :: filename
        
        end subroutine

        
        
        subroutine get_num_params(num_params)
            !
            ! Get the number of sampled parameters in the CosmoSlik script
            !
        
            integer :: num_params
        
        end subroutine
        
        
        subroutine get_param_info(i,paramname,start,min,max,width,scale)
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
       
            integer :: i
            real(8) :: start,min,max,width,scale
            character(len=*) :: paramname
       
        end subroutine
       

        subroutine set_param(i,val)
            !
            ! Set a parameter's value
            !

            integer :: i
            real(8) :: val

        end subroutine


        subroutine set_cls(cls,lmax)
            !
            ! Set the Cls
            !
            ! Order is TT, EE, BB, TE, EB, TB
            !
            integer :: lmax
            real(8), dimension(6,lmax) :: cls

        end subroutine


        subroutine get_lnl(lnl)
            !
            ! Evaluate the CosmoSlik likelihood at the point in parameter space
            ! specified by all the previous calls to set_param
            !

            real(8) :: lnl

        end subroutine


    end interface
    
end module
