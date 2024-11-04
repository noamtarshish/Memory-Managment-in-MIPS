.data
	mainMenu: .ascii "\nMain Menu:\n"
	.ascii "1. add_customer\n"
	.ascii "2. display_customer\n"
	.ascii "3. update_balance\n"
	.ascii "4. delete_customer\n"
	.ascii "5. exit_program\n"
	.asciiz "Enter your choice (1-5): "
	
	# variables - first function - add customer
	name_buffer: .space 100
	enter_id: .asciiz "Enter ID: "
	enter_name: .asciiz "Enter Name: "
	enter_balance: .asciiz "Enter Balance: "
	customerAdded1: "Success: Customer " 
	customerAdded2: " was added\n" 
	customerAddedError1: "Error: Customer " 
	customerAddedError2: " already exists\n"
	errorIllegal: .asciiz "Invalid choice. Please enter a number between 1 and 5\n" 
	new_line: .asciiz "\n"
	currentID: .word 0
	currentBalance: .word 0
	counter: .word 0
	customer_database:
		.space 1080 # 10 records * 108 bytes per record
		
	# Variables - Display Function
	successDisplay: .asciiz "Success: "
	comma: .asciiz ", "
	customerDisplayError: .asciiz " doesn't exist\n"
	
	# Variables - Update Balance
	newBalance: .asciiz "Enter New Balance: "
	invalidBalance: .asciiz "Error: The inputted balance isn't valid\n"
		
	# Variables - Delete Customer
	deleteCustomer: .asciiz " deleted\n"
	
	# Variables - Exit Program
	exitProgram: .asciiz "Exiting program..."
			
.text
main:
	mainMenu_loop:
		la $a0, mainMenu # load main menu string
		li $v0, 4
		syscall
		
		li $v0, 5 # read integer to ask from the user to choose option from the menu
		syscall
		
		beq $v0, 1, prep_addCustomer
		beq $v0, 2, prep_displayCustomer
		beq $v0, 3, prep_updateBalance
		beq $v0, 4, prep_deleteCustomer
		beq $v0, 5, exit_program
		j Invalid_Input		

####################################### 1 - Add Customer ##################################################
prep_addCustomer:
	li $v0, 4
	la $a0, enter_id
	syscall
		
	li $v0, 5 # read integer as ID from user
	syscall
	move $t0, $v0
	sw $t0, currentID
		
	# Prompt the user to enter the customer's name
    	li $v0, 4
    	la $a0, enter_name
    	syscall
    		
    	# Read customer's name from user input
    	li $v0, 8
    	la $a0, name_buffer    # Load address of the name field in the record
    	li $a1, 100        # Maximum length of the name
    	syscall
    		
    	# Prompt the user to enter the customer's balance
    	li $v0, 4
    	la $a0, enter_balance
    	syscall

    	# Read customer's balance from user input
    	li $v0, 5
    	syscall
    	move $t1, $v0     # Store customer's balance in $t1
    	sw $t1, currentBalance
    	
    	# Check if customer already exists
    	move $a0, $t0
    	jal customer_exists
    	beq $v0, 1, customer_exists_error # If customer exists, jump to error
    	
    	la $a1, name_buffer
    	lw $a2, currentBalance
    	jal add_customer
    	

# Function to add costumer to the database
# Arguments: $a0 - ID of the customer to check
#	    $a1 - address of name buffer 
#       $a2 - balance of custumer 

add_customer:
	    move $t0, $a0		#customer ID
	    move $t1, $a1		#address of name buffer 
	    move $t2, $a2 		# costumer balance 
	    
	    lw $t3, counter 	#conter of the numbers of costumers in the data base 
	    la $t4, customer_database
	    mul $t9, $t3, 108 #calculate the offset of the current record
	    add $t4, $t4, $t9
	    
	    sw $t0, 0($t4) # store the current id

	    li $t5, 0  #index for name loop
	    # offset of the current record
	    name_loop :
	    		add $t6, $t1, $t5 #cul the address of the next byte in buffer  
	    		lb  $t7, ($t6)	  #load bit from name buffer 
	    		beq $t7, 10, name_end
	    		beqz $t7 , name_end
	    		add $t8, $t4, $t5 
	    		sb $t7, 4($t8)
	    		addi $t5, $t5, 1 
	    		j name_loop 
	    name_end:
	    
	    	sw $t2, 104($t4)
	    	addi $t3, $t3, 1
	    	sw $t3, counter
	    
	    	# Print success message
    		li $v0, 4
    		la $a0, customerAdded1
    		syscall
    
    		# Print the ID
    		move $a0, $t0
    		li $v0, 1
    		syscall
    
    		# Print the rest of the message
		li $v0, 4
    		la $a0, customerAdded2
    		syscall
    
    		j mainMenu_loop 
	    	
####################################### 2 - Display Customer ##################################################
#  Prep Function to get the id to serch  customer with given ID exists
# Arguments: $a0 - ID of the customer to check
# Return: 
#   - If customer exists: $v0 = 1 , $v1= address of the costumer
#   - If customer doesn't exist: $v0 = 0

prep_displayCustomer:
		li $v0, 4
		la $a0, enter_id
		syscall
		
		li $v0, 5 # read integer as ID from user
		syscall
		move $t0, $v0
		sw $t0, currentID
		
		move $a0 ,$t0 
		jal display_customer
		

# Function to display customer with given ID exists
# Arguments: $a0 - ID of the customer to check
# Return: 
#   If customer exists: $v0 = 1 , $v1= address of the costumer
#   If customer doesn't exist: $v0 = 0

display_customer: 

		move $t0, $a0       # id that want find 
		li $t2, 0 	    # here we wiil enter the customer balance to display 
		
		move $a0, $t0 
		jal customer_exists
		beq $v0, 0, customer_exists_error_2_3# If customer exists, jump to error
		
		move $t3, $v1
		la $t1, name_buffer #here we will enter the name 	
		move $a0, $t1
		jal clear_name_buffer
			
		add $t4, $t3, 4
		move $a0, $t1 # name_buffer
		move $a1, $t4 # address of the customer in the database
		jal getName
		
		lw $t2, 104($t3)
		
		li $v0, 4
		la $a0, successDisplay
		syscall
		
		li $v0, 1
		la $a0, ($t0)
		syscall
		
		li $v0, 4
		la $a0, comma
		syscall
		
		li $v0, 4
		move $a0, $t1
		syscall
		
		li $v0, 4
		la $a0, comma
		syscall
		
		li $v0, 1
		la $a0, ($t2)
		syscall
		
		li $v0, 4
		la $a0, new_line
		syscall
		
    		j mainMenu_loop 
		
		
####################################### 3 - Update Balance ##################################################
prep_updateBalance:
		li $v0, 4
		la $a0, enter_id
		syscall
		
		li $v0, 5 # read integer as ID from user
		syscall
		move $t0, $v0
		
		li $v0, 4
		la $a0, newBalance
		syscall
		
		li $v0, 5
		syscall
		move $t1, $v0
		
		move $a0, $t0 # id
		move $a1, $t1 # balance
		jal update_balance
		
		
update_balance:
		move $t0, $a0 # id we want to update the ba
		
		move $a0, $t0 
		jal customer_exists
		beq $v0, 0, customer_exists_error_2_3# If customer exists, jump to error
		move $t2, $v1
		
		move $t1, $a1 # new balance
		bgt $t1, 99999, balanceError 
		blt $t1, 0, balanceError
	
		sw $t1, 104($t2)
		
		move $a0, $t0
		jal display_customer
	
balanceError:
	li $v0, 4
	la $a0, invalidBalance # call the string that display error
	syscall
	j mainMenu_loop
		 
		
######################################## 4 - Delete Customer ###############################################
prep_deleteCustomer:
		li $v0, 4
		la $a0, enter_id
		syscall
		
		li $v0, 5 # read integer as ID from user
		syscall
		move $t0, $v0
		
		move $a0, $t0 # id
		jal delete_customer

delete_customer:
		move $a0, $t0 
		jal customer_exists
		beq $v0, 0, customer_exists_error_2_3# If customer exists, jump to error
		move $t2, $v1 # address of current customer
		
		delete_loop:
    		li $t3, 108 # Set the length of the name_buffer (assuming it's 100 bytes)
		li $t4, 0
		add $t4, $t4, $t2
	
		clear_loop1:
    			sb $zero, 0($t4) # Store null character ('\0') into the name_buffer
    			addi $t4, $t4, 1 # Move to the next byte
    			addi $t3, $t3, -1 # Decrement the counter
    			bnez $t3, clear_loop1 # Loop until all bytes are filled with null characters
    		
    		lw $t5, counter
		subi $t5, $t5, 1
		sw $t5, counter
        		
		# Print success message
    		li $v0, 4
    		la $a0, customerAdded1
    		syscall
    
    		# Print the ID
    		move $a0, $t0
    		li $v0, 1
    		syscall
    
    		# Print the rest of the message
		li $v0, 4
    		la $a0, deleteCustomer
    		syscall
    		
    		j mainMenu_loop
    		
    		
######################################## 5 - Exit Program ###############################################
exit_program:
		li $v0, 4
		la $a0, exitProgram
		syscall
		
		li $v0, 10
		syscall
		
		
######################################## Helper Functions ###############################################
customer_exists_error_2_3 :      # Customer not exists, display error message

    			li $v0, 4
    			la $a0, customerAddedError1
    			syscall
    
   			move $a0, $t0           # Load customer ID
    			li $v0, 1
    			syscall
    
    			li $v0, 4
    			la $a0, customerDisplayError
    			syscall
			j mainMenu_loop

		
##########################################################################################################################
clear_name_buffer:
    li $t5, 0                   # Load null character ('\0') into $t0
    move $t1,$a0        # Load the address of the name_buffer
    li $t6, 100                 # Set the length of the name_buffer (assuming it's 100 bytes)
	li $t7, 0
	add $t7, $t7, $t1 
	
	clear_loop:
    		sb $t5, 0($t7)              # Store null character ('\0') into the name_buffer
    		addi $t7, $t7, 1            # Move to the next byte
    		addi $t6, $t6, -1           # Decrement the counter
    		bnez $t6, clear_loop        # Loop until all bytes are filled with null characters
    		jr $ra                      # Return to the caller

		
#########################################################################################################################
getName:
		move $t1, $a1
		move $t4, $a0
		li $t5, 0  #index for name loop
	    # offset of the current record
	    name_loop_1 :
	    		add $t6, $t1, $t5 #cul the address of the next byte in buffer  
	    		lb  $t7, ($t6)	  #load bit from name buffer 
	    		beq $t7, 10, name_end_1
	    		beqz $t7, name_end_1
	    		add $t8, $t4, $t5 
	    		sb $t7, 4($t8)
	    		addi $t5, $t5, 1 
	    		j name_loop_1 
	    name_end_1:
	    		jr $ra
	    	  
#########################################################################################################################   	
# Function to check if customer with given ID exists
# Arguments: $a0 - ID of the customer to check
# Return: 
#   - If customer exists: $v0 = 1 , $v1= address of the costumer
#   - If customer doesn't exist: $v0 = 0
customer_exists:
		move $t0, $a0	  	 # Load the ID of the customer to check
		la $t1, customer_database # Load base address of the customer database
		
	    # Check if it's the first customer
		lw $t2 , counter 	 
		beq $t2, $zero, customer_exists_not_found
	       
	    # If it's not the first  Loop through the customer database	
	    li $t3, 0 # Initialize index to 0
    customer_exists_loop:
    		# Calculate the address of the current customer record
        		mul $t4, $t3, 108 	# Each record is 108 bytes long (4 bytes for ID, 100 bytes for name, 4 bytes for balance)
    			add  $t5, $t1, $t4 	# Address of current record
    			lw   $t6, 0($t5)		# Load ID of the current customer record
    			beq  $t6, $t0, customer_exists_found # Check if the ID matches the ID we are searching for
	      	addi $t3, $t3, 1		# Increment index
	      	bge  $t3, 10, customer_exists_not_found# Check if reached end of database
	      	j customer_exists_loop
		
    customer_exists_found:
        # Customer with given ID exists
        li $v0, 1
        move $v1, $t5
        jr $ra
    
    customer_exists_not_found:
        # Customer with given ID doesn't exist
        li $v0, 0
        jr $ra
##################################################################################################################################        		
Invalid_Input:
	# handle invalid input - number not in range 1-4 or not a number
	li $v0, 4
	la $a0, errorIllegal # call the string that display error
	syscall
	j mainMenu_loop
###################################################################################################################################
    
customer_exists_error:
    # Customer already exists, display error message
    li $v0, 4
    la $a0, customerAddedError1
    syscall
    
    move $a0, $t0           # Load customer ID
    li $v0, 1
    syscall
    
    li $v0, 4
    la $a0, customerAddedError2
    syscall
    
    j mainMenu_loop



		 		
