module coscos
    
    interface

        subroutine init_script(filename)
        
            character(len=*) :: filename
        
        end subroutine
        
        
        function get_num_params()
        
            integer(8) :: get_num_params
        
        end function
        
        
        function get_param_info(i,paramname,min,max,width,scale)
       
            integer(8) :: i
            real(8) :: min,max,width,scale
            character(len=*) :: paramname
       
        end function
       
       
    end interface
    
end module
