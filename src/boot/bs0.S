.section .text

.global bootstrap0
bootstrap0:
	cli

	# enable SSE in CR0 and CR4
	movq %cr0, %rax
	andw $0xFFFB, %ax # clear CR0.EM
	orw  $0x0002, %ax # set CR0.MP
	movq %rax, %cr0

	movq %cr4, %rax
	orq  $0x00000200, %rax # set CR4.OSFXSR
	orq  $0x00000400, %rax # set CR4.OSXMMEXCPT
	movq %rax, %cr4

	movabs $_stack_end, %rsp
	xorq %rbp, %rbp

	call bootstrap1

1:  hlt
	jmp 1b
