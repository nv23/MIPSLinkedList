.data

saveword:
	.space 60

save:
	.space 4

savenextNode:
	.space 60


AskName:
	.asciiz "Please type in last name (to end type DONE): \n"
AskPoints:
	.asciiz "Please type in points: \n"
AskRebounds:
	.asciiz "Please type in rebounds: \n"
AskTO:
	.asciiz "Please type in turnovers: \n"
ending:
	.asciiz "DONE"
pspace:
	.asciiz " "
newline:
	.asciiz "\n"
print:
	.asciiz "WHY\n"

.text
.align 2

main:
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	li $v0, 9 					#first node
	li $a0, 124
	syscall

	move $s0, $v0 				#made head
	move $s1, $v0 				#1st pointer

	jal RecordInfo

	li $v0, 10
	syscall

#### Functions: ####

# $s2 is pointer
# $s4 holds input name
# $f12 contains player's stats
# RecordInfo takes in user input and then passes on info to make nodes
RecordInfo:

	la $a0, AskName				#prints AskName
	li $v0, 4
	syscall

	li $v0, 9				# sbrk, saves to heap
	li $a0, 60				#saves input, restricted to 60 bytes
	syscall
	move $s4, $v0

	move $a0, $s4			
	li $a1, 60
	li $v0, 8
	syscall

	move $t5, $a0				#string counter for strip
	la $t6, newline				#load variable with "\n"
	lb $t8, 0($t6)

	jal strip				#strips off newline from input

	move $s4, $a0 				#loads input
	move $t0, $a0
	la $s5, ending 				#loads address of "DONE" for StringCompare

	jal StringCompare

	beq $s6, 1, done 			#checks value of StringCompare, if true, goes to done

	la $a0, AskPoints
	li $v0, 4
	syscall

	li $v0, 6
	syscall

	mov.s $f12, $f0				#saves number of points

	la $a0, AskRebounds
	li $v0, 4
	syscall

	li $v0, 6
	syscall

	mov.s $f11, $f0 			#save number of rebounds

	add.s $f12, $f12, $f11

	la $a0, AskTO
	li $v0, 4
	syscall

	li $v0, 6
	syscall						

	mov.s $f10, $f0 			#save number of turnovers

	div.s $f12, $f12, $f10


	j addNode


done:
	jal sortList
	move $s7, $s0			#initialize $s7 pointer to head node
	j printList

finish:
	li $v0, 10				#end program
	syscall

# $t5 is string counter
# $t6 contains address of "\n"
# $t8 is already initialized variable containing byte "\n"
# $t7 contains byte of $t5
# strips off newline from input
strip:
	lb $t7, 0($t5)
	beq $t7, $t8, check
	addi $t5, $t5, 1

	beq $t7, $0, backup

	j strip

backup:
	jr $ra
# checks "n" of "\n"
check:
	addi $t5, $t5, 1
	addi $t6, $t6, 1
	lb $t7, 0($t5)
	lb $t8, 0($t6)
	beq $t7, $t8, remove

	jr $ra

# removes "\n"
remove:
	sb $0, 0($t5)
	sb $0, -1($t5)

	jr $ra

# $s7 is list looper
# $t2 will hold next node value
printList:
	beqz $s7, endloop		# if next node is null, end the loop
	# print name
	li $v0, 4
	lw $a0, 0($s7)
	syscall

	# print space
	li $v0, 4
	la $a0, pspace
	syscall

	# print stats
	li $v0, 2
	l.s $f12, 60($s7)
	syscall

	# print new line
	li $v0, 4
	la $a0, newline
	syscall

	# moves to next node value
	lw $t2, 64($s7)
	move $s7, $t2

	j printList

endloop:
	j finish

# $s6 is current pointer sorting through list
# $s7 is node previous to $s6
# $s5 is the next node current node is pointing to
# $f1 contains stats of current node
# $s4 holds swapping counter
sortList:
	li $s4, 1
	move $s7, $s0				#initialize $s7 to head
	move $s6, $s0				#intialzize $s6 to head
	lw $t3, 64($s6)
	beqz $t3, ret
	# move $a0, $t3
 # 	li $v0, 4
 # 	syscall
	move $s5, $t3				#initialize $s5 to next
	sortloop:
 		l.s $f1, 60($s6)
 		l.s $f2, 60($s5)
 		l.s $f12, 60($s6)
 		li $v0, 2
 		syscall
 		l.s $f12, 60($s5)
 		li $v0, 2
 		syscall
 		c.lt.s $f2, $f1 
 		bc1t swap

 		move $s7, $s6			#move pointer $s7
 		move $s6 $s5
 		lw $t3, 64($s6)
 		beqz $t3, endSort
		move $s5, $t3
		# la $a0, print
		# li $v0, 4
		# syscall


		j sortloop

endSort:
	beq $s4, 1, ret
	j sortList

ret:
	jr $ra


# $s6 is current node
# $s5 is next node
swap:
	la $a0, print
	li $v0, 4
	syscall
	li $s4, 0
	lw $t8, 64($s5)				#temporarily store where next node is pointing
	lw $t9, 0($s6)				#store where current is pointing
	sw $t8, 64($s6)				#make current point to that
	lw $t7, 0($s6)
	sw $t7, 64($s5)				#make next node point to current
	bne $s7, $s0, updatePrev

	move $s0, $s5

	j sortList

updatePrev:
	#update prev node point to swapped node
	sw $t9, 64($s7)
	move $s7, $t9				#move prev node pointer
	j sortList


# $s2 holds current node/ new node
# $s4 holds input name
# $f12 holds player's stats
createNode:
	li $v0, 9 					#allocate memory for node
	li $a0, 124
	syscall

	move $s2, $v0				#2nd pointer
	sw $s4, 0($s2)				#stores name in node
	s.s $f12, 60($s2)			#stores stats in node
	sw $0, 64($s2)				#makes next node null for now

	jr $ra



# $s0 is head node pointer
# $s2 points to new node
# $s3 points to current node
# $f12 will contain stats of new node
# $f11 will contain stats of current node
addNode:
	la $t4, saveword
	lw $t4, 0($s0)
	jal createNode
	beqz $t4, makeHead			#checks if head exists

	sw $s2, 64($s1)
	move $s1, $s2	


	j RecordInfo

makeHead:
	# makes $s2 the head and updates $s1, the current counter
	move $s0, $s2
	move $s1, $s0

	j RecordInfo


# $s6 returns 0 (false, different strings) or 1 (true, same string)
# $t1 loads the character of string
# $s5 holds address of "DONE" string
# $t0 contains input
# $t3 holds character of $s5
StringCompare:
	li $s6, 1
	lb $t1, 0($t0)
	lb $t3, 0($s5)

	bne $t1, $t3, diff

	beq $t3, $zero, back

	addi $t0, $t0, 1
	addi $s5, $s5, 1

	j StringCompare

back:
	la $s5, ending
	jr $ra

diff:
	li $s6, 0
	jr $ra
