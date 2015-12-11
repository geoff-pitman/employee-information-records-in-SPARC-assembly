/******************************************************************************
  Author: Geoffrey Pitman
  Created: 11/30/2015
  Due: 12/5/2015
  Course: CSC235-210
  Professor: Dr. Spiegel
  Assignment: #4
  Filename: employee_records.m
  Description: This program will input up to 5 employee records from keyboard.
               A menu prompt will be presented to the user allowing them to
               print all records, print records by specified gender, or quit.
               [ctrl-d to quit]
               
 **NOTE:: Optimized with pure register parameter passing and returns
          
*****************************************************************************/

!            Main's frame stack: 12 bytes wide  
!#######################################################------->%fp-168/%sp+0
!#                                                     #
!#                                                     #  
!#                                                     #---}64                               
!#                                                     #
!#                                                     # 
!#######################################################------->%fp-104/%sp+64
!#                                                     #---}4  1x4 return area
!#######################################################------->%fp-100 %sp+68
!#                                                     #
!#                                                     #---}24 6x4 param area
!#                                                     #
!#######################################################------->%fp-76/%sp+92
!#[&name(4B)][hours(4B)][pay(2B)][gend(1B)][unused(1B)]#
!#[&name(4B)][hours(4B)][pay(2B)][gend(1B)][unused(1B)]#
!#[&name(4B)][hours(4B)][pay(2B)][gend(1B)][unused(1B)]#---}60
!#[&name(4B)][hours(4B)][pay(2B)][gend(1B)][unused(1B)]#
!#[&name(4B)][hours(4B)][pay(2B)][gend(1B)][unused(1B)]#
!#######################################################------->%fp-16/%sp+152
!#                                                     #
!#                                                     #---}16
!#######################################################------->%fp-0/%sp+168

! offsets and constants
define(empName,0)                   ! 4 byte address(int)
define(empHours,4)                  ! 4 byte int
define(empPay,8)                    ! 2 byte half int
define(empGender,10)                ! 1 byte char
define(dummy,11)                    ! unused byte
define(nextDummy,23)
define(maxLength,25)                ! max length of name string
define(empOffset, 92)               ! array offset from main's %sp
define(empRecArr,-76)               ! array offset from main's %fp
define(recSize, 12)                 ! size of 12 byte record
! ascii values for chars
define(upF, 70)
define(lowF, 102)
define(upM, 77)
define(lowM, 109)
define(upP, 80)
define(lowP, 112)
define(upL, 76)
define(lowL, 108)
define(upQ, 81)
define(lowQ, 113)
! aliases for local registers
define(numEmp,%l0)                  ! number of employee records: max of 5
define(nameAdrs,%l1)                ! points to name string
define(empAdrs, %l2)                ! used for base address of employee array
define(arrIdx,%l3)                  ! used as index when looping through array
define(recOffset,%l4)               ! holds memory offset values
define(choice,%l5)                  ! user's char input from menu options
define(numGender, %l6)              ! number of gender specific records
define(stGender, %l7)               ! stores a given employee records gender

    .data
    .align 8    
!start message	
init_message:
    .asciz "Enter employee records, max 5 (^D at 'Enter name' when done)\n"
! exit message
fin_message:
    .asciz "\nGoodbye!\n"
! print employee record
print_empRec:
     .asciz "Employee name: %-25s   Hours: %3d  Pay/h: %3hi  Gender: %c\n"
! menu input not recognized
menu_error:
    .asciz "\nCommand not recognized\n"
! print the number of employee records for specified gender
gender_message:
    .asciz "Total records of specified gender: %d\n"
!
! prompts
prompt_name:
    .asciz "Enter name: "
prompt_hours:
    .asciz	"Enter hours worked: "
prompt_pay:
    .asciz "Enter hourly pay: "
prompt_gender:
    .asciz "Enter gender (m/f): "
prompt_menu:
    .asciz "\nSelect:\nP)rint All\nL)ist by Gender\nQ)uit\n"
!
!format specifiers
format_string:
    .asciz  "%s"
format_int:
    .asciz  "%d"
format_hi:
    .asciz  "%hi"
format_char:
    .asciz  "%c%c"              
eatCR:	
    .asciz  "%c"
	
	.align 4
    .global main
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    
!
!   #include <Pitman_Assembler_Skills.h>
!
!   // The structure prototype for an employee record.
!   // We will be using an employeeRecord array in the program
!   typedef struct{
!       char* empName;
!       int empHours;
!       short empPay;
!       char  empGender; 
!    }employeeRecord;
!   
!    // "Called by main to input the data.  
!    // Will call other functions to actually input data.
!    // Takes data and saves into record in caller."
!    // Return value: number of records read in  
!    int readEmployees(employeeRecord* empAdrs[]);
!
!   // "Called by readEmployees to input the data.
!   //  Will call readName to input the name string.
!   //  Takes data and saves into record in main's frame."
!   //  Return value: 0 if ctrl-d hit, 1 otherwise
!   int readEmployee(employeeRecord** recAdrs);
!
!   // Called by readEmployee to get address of name string.
!   // "This function mallocs space for a string, prompts
!   // and inputs a name into the string, and returns the address
!   // [where the string was allocated].
!   // The caller stores that address in the caller's frame.
!   // If the user entered ^D, it returns 0."
!   // Return value: pointer to dynamically allocated string
!   char* readName();
!
!   // "Prints all employee data by calling PrintEmployee for each record"
!   void printEmployees(int numEmp, employeeRecord* empAdrs[]);
!    
!   // Prints data for employee record that was passed in
!   void printEmployee(employeeRecord* recAdrs);
!
!   // "Prints all records who gender matches the argument."
!   // Return value: number of records that matched argument
!   int printByGender(employeeRecord* empAdrs[], int numEmp);
!
!
!   int main(int argc, char* argv[])
!   {
!        employeeRecord empAdrs[5];
!    
main:
    ! 60 bytes allocated in stack to store up to 5 employee records
    save    %sp, (-108 -60) & -8, %sp
    
    !start message
    set	    init_message,%o0
    call    printf
    nop
    !get args ready to pass to readEmployees
    clr     %o0                        ! no records so init to 0
    call    readEmployees
    add     %fp, empRecArr, %o1        ! address to employee struct array
    mov     %o0, numEmp                ! store return value   
 menu:
    !print menu prompt
    set     prompt_menu, %o0
    call    printf
    nop
    ! use left-over 1 byte space from employee struct array to store input
    ! and to eat CR
    set	    format_char,%o0
    add	    %sp, 103, %o1
    call    scanf			            
    add     %sp, 115, %o2                ! eat CR
    ldub    [%sp+103], choice  
    ! check what user entered
    ! case insensitive
    cmp     choice, lowQ
    be      done
    nop   
    cmp     choice, upQ
    be      done
    nop
    cmp     choice, lowP
    be      bprintEmployees
    nop
    cmp     choice, upP
    be      bprintEmployees
    nop
    cmp     choice, lowL
    be      bprintByGender
    nop
    cmp     choice, upL
    be      bprintByGender
    nop
    ! print message error if user gives bad input then return to menu
    set     menu_error, %o0
    call    printf
    nop
    b       menu
    nop
 ! set up call to print records then return to menu   
 bprintEmployees:
    mov     numEmp, %o0                ! number of employees
    call    printEmployees
    add     %fp, empRecArr, %o1        ! address to employee struct array     
    b       menu
    nop
 ! set up call to print records then return to menu    
 bprintByGender:
    add     %fp, empRecArr, %o0
    call    printByGender
    mov     numEmp, %o1
    b       menu
    nop
 ! print exit message and terminate   
 done:	
    set	    fin_message,%o0
    call    printf
    nop
    call    exit                      
    mov     0,%o0                    
       
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! int printByGender(employeeRecord* empAdrs[], int numEmp)
!
    .global printByGender
printByGender:
    save    %sp, -108 & -8, %sp
    
    ! get in args: number of employees and employeeRecord array
    mov     %i0, empAdrs
    mov     %i1, numEmp
    mov     empAdrs, %l5                      ! use local reg to hold temp val
    ! ask user which gender's records they want to print
    set     prompt_gender, %o0
    call    printf
    nop
    ! use left-over 1 byte space from employee struct array to store input
    ! and to eat CR
    set	    format_char,%o0
    add	    %l5, dummy, %o1		
    call    scanf			
    add     %l5, nextDummy, %o2               ! throw CR into next record's
                                              !                    unused byte
    ldub    [%l5 + dummy], choice
    !init index count and gender specific record count
    clr     arrIdx
    clr     numGender
    ! check user's choice
    ! case insensitive
    cmp     choice, lowF
    be      pass
    nop
    cmp     choice, upF
    be      pass
    nop
    cmp     choice, lowM
    be      pass
    nop
    cmp     choice, upM
    be      pass
    nop
    ! print error message if choice is not recognized and return to main menu
    set     menu_error, %o0
    call    printf
    nop
    ! return from function
    ret
    restore
 ! handles users gender choice   
 pass:
   ! multiply index by 12 byte rec size to get to next index
    mov     arrIdx, %o0
    call    .mul
    mov     recSize, %o1
    ! add the result to get "index" of record
    add     %o0, empAdrs, recOffset
    ! get employee record's gender out of memory
    ldub    [recOffset + empGender], stGender
    ! check to see if particular record's gender matches the input gender
    ! case insensitive
    cmp     choice, stGender
    be      printByGenderRec
    nop
    add     stGender, 32, stGender
    cmp     choice, stGender
    be      printByGenderRec
    nop
    add     stGender, -64, stGender
    cmp     choice, stGender
    be      printByGenderRec
    ! loop through all the records
    cmp     arrIdx, numEmp
    bne     pass
    ! increment index in delay slot
    inc     arrIdx
    ! print total number of gender specific records then return to main menu
    set     gender_message, %o0
    call    printf
    mov     numGender, %o1
    ret
    restore
 ! use printEmployee function to print records of specific gender
 printByGenderRec:
    inc     arrIdx                       ! increment array index
    inc     numGender                    ! increment found records for gender
    call    printEmployee
    mov     recOffset, %o0
    b       pass
    nop
    
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! void printEmployee(employeeRecord* recAdrs)   
! in definition, using empAdrs in place of recAdrs for lack of L registers
!
    .global printEmployee
printEmployee:
    save    %sp, -108 & -8, %sp
    
    ! get in arg: address to employee record
    mov     %i0, empAdrs
    ! load employee record info into print function
    set     print_empRec, %o0
    ld	    [empAdrs + empName], %o1
    ld	    [empAdrs + empHours], %o2
    lduh    [empAdrs + empPay], %o3
    ldub    [empAdrs + empGender], %o4
    call    printf
    nop
    ! return from function
    ret
    restore
    
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!    
! void printEmployees(int numEmp, employeeRecord* empAdrs[])
!
    .global printEmployees
printEmployees:
    save    %sp, -108 & -8, %sp
    
    ! get in args: number of employees and employeeRecord array
    mov     %i0, numEmp
    mov     %i1, empAdrs
    ! exit function if there are no records to print
    cmp     numEmp, 0
    be      doneprintEmployees
    nop
    ! init employee array "index" to 0
    clr     arrIdx
 ! print all the employee records
 print_loop:
    ! multiply index by 12 byte rec size to get to next index
    mov     arrIdx, %o0
    call    .mul
    mov     recSize, %o1
    ! pass printEmployee the specific record address
    call    printEmployee
    add     %o0, empAdrs, %o0
    ! idx++
    inc     arrIdx
    ! continue looping until index equals total records
    cmp     arrIdx, numEmp
    bne     print_loop
    nop
 ! return from function
 doneprintEmployees: 
    ret 
    restore
    
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! char* readName()
!
    .global readName
readName:
    save    %sp, -108 & -8, %sp
    
    !ask user for employee name
    set	    prompt_name,%o0
    call    printf
    nop  
    ! allocate mem for input string
    call    malloc
    mov     maxLength, %o0       
    ! get user input
    call    gets
    nop
    !check if there was a no read (ctrl-d)
    cmp     %o0, 0
    be      noRead
    nop
    !else set return value and go to end of function
    mov     %o0, %i0 
    b       doneReadName
    nop
 !handle ctrl-d    
 noRead:
    !set return value
    clr     %i0
    !fall through to end of function
 !end function
 doneReadName:
    ret
    restore

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! int readEmployee(employeeRecord* recAdrs)
! in definition, using empAdrs in place of recAdrs for lack of L registers
!
    .global readEmployee
readEmployee:
    save    %sp, -108 & -8, %sp
    
    ! get in arg: address for employee struct array
    mov     %i0, empAdrs
    ! call readName to get employee name string from user    
    call    readName
    nop
    mov     %o0, nameAdrs                 ! make return data safe                
    ! branch if ctrl-d is hit
    cmp     nameAdrs, 0
    be      doneCtrlD      
    nop 
    ! else get user input and store the record info
    ! the data is stored directly into the frame
    !
    ! stores 4 byte address to dyanmically allocated name string
    st      nameAdrs, [empAdrs + empName]       
    ! get hours worked
    set	    prompt_hours, %o0
    call    printf
    nop
    set	    format_int, %o0	
    call    scanf			
    add	    empAdrs,empHours, %o1        ! stores 4 byte int into frame
    ! get pay rate
    set	    prompt_pay, %o0
    call    printf
    nop
    set	    format_hi, %o0
    call    scanf			
    add	    empAdrs,empPay, %o1	         ! stores 2 byte half int into frame
    ! get employee's gender
    set	    prompt_gender, %o0
    call    printf
    nop
    set	    format_char, %o0
    add	    empAdrs, empGender, %o2	     ! stores 1 byte char into frame
    call    scanf						
    add	    empAdrs, dummy, %o1          ! eat extraneous char
    ! eat CR
    set	     eatCR, %o0
    call     scanf
    add	     empAdrs, dummy, %o1
 ! fall through to done
 doneReadEmployee:
    mov     1, %i0
    ret
    restore
 ! handles ctrl-d   
 doneCtrlD:
    mov     0, %i0
    ret
    restore
  
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! int readEmployees(employeeRecord* empAdrs[])
!
    .global readEmployees
readEmployees:
    save    %sp, -108 & -8, %sp 
    
    ! get employee struct array address from main 
    mov     %i1, empAdrs
    clr     numEmp                      
 read_loop: 
    ! multiply index by 12 byte rec size to get to next index
    mov     numEmp, %o0
    call    .mul
    mov     recSize, %o1
    ! add the result to get "index" of record
    add     empAdrs, %o0, %o0    
    call    readEmployee
    nop
    ! finish up if ctrl-d was hit
    cmp     %o0, 0
    be      doneReadEmployees
    nop
    ! else increment numEmp
    inc     numEmp
    ! continuing looping if we haven't reached 5 employees
    cmp     numEmp, 5
    bne     read_loop 
    nop
    ! else fall through
 doneReadEmployees:
    !set up return value and return
    mov     numEmp, %i0
    ret
    restore
 
