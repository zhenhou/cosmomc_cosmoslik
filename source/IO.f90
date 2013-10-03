
    module IO
    !Module to wrap output functions
    !Replace file e.g. to store output in a pipline database (indexed by filename)
    !Valid handles must be /=0
    use AmlUtils
    use settings
    use MatrixUtils
    implicit none



    contains


    subroutine IO_Ini_Load(Ini,InputFile, bad)
    use IniFile
    Type(TIniFile) :: Ini
    character(LEN=*), intent(in) :: InputFile
    logical bad
    integer file_unit

    file_unit = new_file_unit()
    call Ini_Open_File(Ini,InputFile, file_unit, bad, .false.)
    call ClearFileUnit(file_unit)
    end subroutine IO_Ini_Load

    function IO_OpenChainForRead(name, OK) result(handle)
    character(len=*), intent(in) :: name
    integer handle
    logical, optional, intent(out) :: OK

    handle = new_file_unit()
    if (.not. present(OK)) then
        call OpenTxtFile(name,handle)
    else

    open(unit=handle,file=name,form='formatted',status='old', err=28)
    OK=.true.
    return
28  OK=.false.

    endif

    end function IO_OpenChainForRead

    function IO_OpenDataForRead(name) result(handle)
    character(len=*), intent(in) :: name
    integer handle

    !assumes handle is a fortran unit; If want to get from database then probably to file here

    handle = new_file_unit()
    call OpenFile(name,handle,'unformatted')

    end function IO_OpenDataForRead

    function IO_OutputOpenForWrite(name, append, isLogFile) result(handle)
    character(len=*), intent(in) :: name
    logical, intent(in), optional :: append, isLogFile
    logical app
    integer handle

    if (present(append)) then
        app = append
    else
        app = .false.
    end if

    handle = new_file_unit()
    call CreateOpenTxtFile(name,handle,app)

    end function IO_OutputOpenForWrite

    function IO_DataOpenForWrite(name, append) result(handle)
    !e.g. cached C_l data
    character(len=*), intent(in) :: name
    logical, intent(in), optional :: append
    logical app
    integer handle
    !assumes handle is a fortran unit; If want to put in database then probably convert file when handle closed

    if (present(append)) then
        app = append
    else
        app = .false.
    end if

    handle = new_file_unit()
    call CreateOpenFile(name,handle,'unformatted',app)

    end function IO_DataOpenForWrite


    subroutine IO_Close(handle, IsLogFile)
    integer, intent(in) :: handle
    logical, intent(in), optional :: isLogFile

    call CloseFile(handle)

    end subroutine IO_Close

    subroutine IO_DataCloseWrite(handle)
    integer, intent(in) :: handle
    !modify e.g. to grab data from temporary file

    call CloseFile(handle)

    end subroutine IO_DataCloseWrite

    function IO_Exists(name) result(res)
    logical res
    character(LEN=*), intent(in)::name

    res = FileExists(name)

    end function IO_Exists

    subroutine IO_WriteProposeMatrix(pmat, prop_mat, comment)
    real(mcp) pmat(:,:)
    character(LEN=*), intent(in) :: prop_mat
    character(LEN=*), optional, intent(in) :: comment

    if (present(comment)) then
        call Matrix_write(prop_mat,pmat,.true.,commentline=comment)
    else
        call Matrix_write(prop_mat,pmat,.true.)
    endif

    end subroutine IO_WriteProposeMatrix

    subroutine IO_ReadProposeMatrix(pmat, prop_mat)
    use ParamNames
    real(mcp) pmat(:,:)
    character(LEN=1024), intent(in) :: prop_mat
    real(mcp), allocatable :: tmpMat(:,:)
    integer i,x,y
    integer file_id
    character(LEN=4096) :: InLine
    integer num, cov_params(1024)

    file_id = new_file_unit()
    call OpenTxtFile(prop_mat, file_id)
    InLine=''
    do while (InLine == '')
        read(file_id,'(a)', end = 10) InLine
    end do
    InLine = adjustl(InLine)
    If (InLine(1:1)=='#') then
        !Have paramnames to identify
        InLine = InLine(2:len_trim(InLine))
        num=-1
        call ParamNames_ReadIndices(NameMapping,InLine, cov_params, num, unknown_value=0)
        allocate(tmpMat(num,num))
        pmat=0
        y=0
        do
            read(file_id,'(a)', end = 20) InLine
            if (InLine/='') then
                y=y+1
                read(InLine,*,end=20) tmpMat(:,y)
                if (y==num) exit
            end if
        end do
        call CloseFile(file_id)
        do y=1,num
            if (cov_params(y)/=0) then
                do x=1,num
                    if (cov_params(x)/=0) pmat(cov_params(x),cov_params(y)) = tmpMat(x,y)
                end do
            end if
        end do
        deallocate(tmpMat)
        return
20      call mpiStop('ReadProposeMatrix: wrong number of rows/columns in .covmat')

    end if
10  call CloseFile(file_id)

    i=TxtNumberColumns(InLine)
    if (i==num_params) then
        call ReadMatrix(prop_mat,pmat, num_params, num_params)
    else if (i==num_theory_params) then
        allocate(tmpMat(num_theory_params,num_theory_params))
        call ReadMatrix(prop_mat,tmpmat, num_theory_params, num_theory_params)
        pmat=0
        pmat(1:num_theory_params,1:num_theory_params) = tmpMat
        deallocate(tmpMat)
    else
        call MpiStop('Propose matrix the wrong size: '//trim(prop_mat))
    end if

    end subroutine IO_ReadProposeMatrix


    subroutine IO_OutputChainRow(handle, mult, like, values, nvalues)
    integer, intent(in) :: handle
    real(mcp) mult, like, values(:)
    integer, intent(in), optional :: nvalues
    character(LEN =128) fmt
    integer n

    if (present(nvalues)) then
        n = nvalues
    else
        n = size(values)
    end if

    fmt = trim(numcat('(2E16.7,',n))//'E16.7)'
    write (handle,fmt) mult, like, values(1:n)

    if (flush_write) call FlushFile(handle)

    end subroutine IO_OutputChainRow

    subroutine IO_WriteLog(handle, S)
    integer, intent(in) :: handle
    character(LEN=*), intent(in) :: S

    write(handle,*) trim(S)
    if (flush_write) call FlushFile(handle)

    end subroutine IO_WriteLog

    function IO_SkipChainRows(handle,nrows) result(OK)
    integer, intent(in):: handle,nrows
    logical OK
    integer ix
    character(LEN=10000) InLine

    do ix = 1, nrows
        read (handle,'(a)',end=1) InLine
    end do
    OK = .true.
    return
1   OK = .false.

    end function IO_SkipChainRows

    function IO_ReadChainRow(handle, mult, like, values, params_used, chainOK, samples_chains) result(OK)
    !Returns OK=false if end of file or if not enough values on each line, otherwise OK = true
    !Returns chainOK = false if bad line or NaN, chainOK=false and OK=true for NaN (continue reading)
    logical OK
    integer, intent(in) :: handle
    real(mcp), intent(out) :: mult, like, values(:)
    integer, intent(in) :: params_used(:)
    logical, optional, intent(out) :: ChainOK
    logical, optional, intent(in) :: samples_chains
    logical samples_are_chains
    character(LEN=10000) InLine
    real(mcp) invals(size(params_used))

    if (present(samples_chains)) then
        samples_are_chains=samples_chains
    else
        samples_are_chains = .true.
    endif

    if (present(ChainOK)) chainOK = .true.

    read (handle,'(a)',end=100) InLine
    if (SCAN (InLine, 'N') /=0) then
        OK = .true.
        if (present(ChainOK)) chainOK = .false.
        return
    end if

    if (samples_are_chains) then
        read(InLine, *, end=110,err=110) mult, like, invals
    else
        mult=1
        like=1
        read(InLine, *, end=110,err=110) invals
    end if
    values(params_used) =invals
    OK = .true.
    return
100 OK = .false.
    return
110 OK = .false.
    if (present(ChainOK)) chainOK = .false.

    end function IO_ReadChainRow

    subroutine IO_ReadLastChainParams(name, mult, like, values, params_used)
    character(LEN=*), intent(in) :: name
    real(mcp), intent(out) :: mult, like, values(:)
    integer, intent(in) :: params_used(:)
    character(LEN=5000) :: InLine

    InLine = LastFileLine(name)
    read(InLine, *) mult, like, values(params_used)

    end subroutine IO_ReadLastChainParams

    subroutine IO_OutputParamNames(Names, fname, indices, add_derived)
    use ParamNames
    Type(TParamNames) :: Names
    character(len=*), intent(in) :: fname
    integer, intent(in), optional :: indices(:)
    logical, intent(in), optional :: add_derived

    call ParamNames_WriteFile(Names,trim(fname)//'.paramnames', indices, add_derived)

    end subroutine IO_OutputParamNames

    subroutine  IO_WriteBounds(Names, fname, limmin,limmax, limbot,limtop, indices)
    Type(TParamNames) :: Names
    character(LEN=*), intent(in) :: fname
    real(mcp), intent(in) :: limmin(:), limmax(:)
    logical, intent(in) :: limbot(:), limtop(:)
    integer, intent(in) :: indices(:)
    integer :: unit
    integer i,ix
    character(LEN=17) :: lim1,lim2

    unit = new_file_unit()
    call CreateTxtFile(fname,unit)
    do i=1, size(indices)
        ix = indices(i)
        if (limbot(ix) .or. limtop(ix)) then
            if (limbot(ix)) then
                write(lim1, '(1E17.7)') limmin(ix)
            else
                lim1='    N'
            end if
            if (limtop(ix)) then
                write(lim2, '(1E17.7)') limmax(ix)
            else
                lim2='    N'
            end if
            write(unit,'(1A22,2A17)') ParamNames_NameOrNumber(Names,ix-2), lim1, lim2
        end if
    end do
    call CloseFile(unit)

    end subroutine IO_WriteBounds


    subroutine IO_ReadParamNames(Names, in_root, prior_ranges)
    use ParamNames
    Type(TParamNames) :: Names
    character(LEN=*), intent(in) :: in_root
    character(LEN=Ini_max_string_len) infile, name
    real(mcp) :: prior_ranges(:,:), minmax(2)
    integer file_id, ix

    prior_ranges=0
    infile = trim(in_root) // '.paramnames'
    if (FileExists(infile)) then
        call ParamNames_Init(Names,infile)
        infile = trim(in_root) // '.ranges'
        if (FileExists(infile)) then
            file_id = new_file_unit()
            call OpenTxtFile(infile, file_id)
            do
                read(file_id, *, end=100,err=100) name, minmax
                ix = ParamNames_index(Names, name)
                if (ix/=-1) prior_ranges(:,ix) = minmax
            end do

100         call CloseFile(file_id)
        end if
    end if

    end subroutine IO_ReadParamNames


    function IO_ReadChainRows(in_root, chain_ix,chain_num, ignorerows, nrows, &
    ncols,max_rows,coldata,samples_are_chains) result(OK)
    !OK = false if chain not found or not enough samples
    character(LEN=*), intent(in) :: in_root
    integer,intent(in) :: chain_ix, chain_num
    integer, intent(in) :: max_rows, ignorerows
    integer, intent(in) :: ncols
    real(KIND(1.d0)), intent(inout) :: coldata(ncols,0:max_rows) !(col_index, row_index)
    logical, intent(in) :: samples_are_chains
    integer, intent(inout) :: nrows
    logical OK
    real(mcp) invars(1:ncols)
    logical chainOK
    integer chain_handle, row_start
    integer, allocatable :: indices(:)
    character(LEN=Ini_max_string_len) infile, numstr

    row_start=nrows
    if (chain_num == 0) then
        infile = trim(in_root) // '.txt'
    else
        write (numstr,*) chain_ix
        infile = trim(in_root) //'_'//trim(adjustl(numstr))// '.txt'
    end if

    write (*,*) 'reading ' // trim(infile)

    chain_handle = IO_OpenChainForRead(infile, chainOK)
    if (.not. chainOK) then
        write (*,'(" chain ",1I4," missing")') chain_ix
        OK = .false.
        return
    end if

    if (ignorerows >=1) then
        if (.not. IO_SkipChainRows(chain_handle,ignorerows)) then
            call IO_Close(chain_handle)
            OK = .false.
            return
        end if
    end if

    allocate(indices(ncols-2))
    indices=[3:ncols]
    OK = .true.
    do
        if (.not. IO_ReadChainRow(chain_handle, invars(1), invars(2), &
        invars,indices,chainOK,samples_are_chains)) then
            if (.not. chainOK) then
                write (*,*) 'error reading line ', nrows -row_start + ignorerows ,' - skipping to next row'
                cycle
            endif
            call IO_Close(chain_handle)
            return
        else
            if (.not. chainOK) then
                write (*,*) 'WARNING: skipping line with probable NaN'
                cycle
            end if
        end if

        coldata(1:ncols, nrows) = invars(1:ncols)
        nrows = nrows + 1
        if (nrows > max_rows) stop 'need to increase max_rows'

    end do

    end function IO_ReadChainRows

    subroutine IO_WriteLeftTextNoAdvance(file_id, Form, str)
    integer file_id
    character(LEN=*) str, Form
    Character(LEN=128) tmp

    tmp = str
    write(file_id,form, advance='NO') tmp

    end subroutine IO_WriteLeftTextNoAdvance

    subroutine IO_OutputMargeStats(Names, froot,num_vars,num_contours, contours,contours_str, &
    cont_lines, colix, mean, sddev, has_limits_bot, has_limits_top, labels)
    use ParamNames
    Type(TParamNames) :: Names
    character(LEN=*), intent(in) :: froot
    integer, intent(in) :: num_vars, num_contours
    logical,intent(in) :: has_limits_bot(:,:),has_limits_top(:,:)
    real(mcp), intent(in) :: mean(*), sddev(*), contours(*), cont_lines(:,:,:)
    character(LEN=*), intent(in) :: contours_str
    integer,intent(in) :: colix(*)
    character(LEN=128) labels(*), tag, nameFormat
    integer i,j,file_id
    character(LEN=*), parameter :: txtFormat = '(1A15)'

    j = max(9,ParamNames_MaxNameLen(Names))
    nameFormat = concat('(1A',j+1,')')

    file_id = new_file_unit()
    open(unit=file_id,file=trim(froot)//'.margestats',form='formatted',status='replace')
    write (file_id,'(a)') 'Marginalized limits: ' // trim(contours_str)
    write (file_id,*) ''
    call IO_WriteLeftTextNoAdvance(file_id,nameFormat,'parameter')
    write(file_id,'(a)', advance='NO') '  '
    call IO_WriteLeftTextNoAdvance(file_id,txtFormat,'mean')
    call IO_WriteLeftTextNoAdvance(file_id,txtFormat,'sddev')
    do j=1, num_contours
        call IO_WriteLeftTextNoAdvance(file_id,txtFormat,concat('lower',j))
        call IO_WriteLeftTextNoAdvance(file_id,txtFormat,concat('upper',j))
        call IO_WriteLeftTextNoAdvance(file_id,'(1A7)',concat('limit',j))
    end do
    write(file_id,'(a)') ''

    do j=1, num_vars
        call IO_WriteLeftTextNoAdvance(file_id,nameFormat,ParamNames_NameOrNumber(Names,colix(j)-2))
        write(file_id,'(2E15.7)', advance='NO')  mean(j), sddev(j)
        do i=1, num_contours
            write(file_id,'(2E15.7)',advance='NO') cont_lines(j,1:2,i)
            if (has_limits_bot(i,colix(j)).and. has_limits_top(i,colix(j))) then
                tag='none'
            elseif (has_limits_bot(i,colix(j))) then
                tag= '>'
            elseif (has_limits_top(i,colix(j))) then
                tag = '<'
            else
                tag = 'two'
            end if
            write(file_id,'(1A7)', advance='NO') '  '//tag
        end do
        write(file_id,'(a)') '   '//trim(labels(colix(j)))
    end do

    call CloseFile(file_id)

    end subroutine IO_OutputMargeStats

    end module IO
