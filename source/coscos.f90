module coscos
    
    interface

        subroutine init_script(filename)
        
            character(len=*) :: filename
        
        end subroutine
        
        
        function get_num_params()
        
            integer(8) :: get_num_params
        
        end function
        
        
        subroutine get_param_info(i,paramname,start,min,max,width,scale)
       
            integer(8) :: i
            real(8) :: start,min,max,width,scale
            character(len=*) :: paramname
       
        end subroutine
       
       
    end interface
    
end module
