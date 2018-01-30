@******************************************************************************
@ File: head.S
@ ����: ����SDRAM���������Ƶ�SDRAM��Ȼ������SDRAM����ִ��
@******************************************************************************       
#define S3C2440_MPLL_200MHZ     ((0x5c<<12)|(0x01<<4)|(0x02))
#define S3C2440_MPLL_400MHZ     ((0x5c<<12)|(0x01<<4)|(0x01))
#define MEM_CTL_BASE    0x48000000
.extern     main
.text 
.global _start 
_start:
@******************************************************************************       
@ �ж��������������У���Reset��HandleIRQ�⣬�����쳣��û��ʹ��
@******************************************************************************       
    b   Reset

@ 0x04: δ����ָ����ֹģʽ��������ַ
    ldr pc, = HandleUndef 
 
@ 0x08: ����ģʽ��������ַ��ͨ��SWIָ������ģʽ
    b   HandleSWI

@ 0x0c: ָ��Ԥȡ��ֹ���µ��쳣��������ַ
    ldr pc, = HandlePrefetchAbort

@ 0x10: ���ݷ�����ֹ���µ��쳣��������ַ
    ldr pc, = HandleDataAbort

@ 0x14: ����
HandleNotUsed:
    b   HandleNotUsed

@ 0x18: �ж�ģʽ��������ַ
    b   HandleIRQ

@ 0x1c: ���ж�ģʽ��������ַ
HandleFIQ:
    b   HandleFIQ

Reset:
	ldr sp, =0x4096
/* 1. �ؿ��Ź� */
	bl disable_watch_dog

/* 2. ����ʱ�� */
	bl clock_init

	/* ����ICACHE */
	bl enable_ICACNE
	
	
/* 3. ��ʼ��SDRAM */
	bl memsetup
		
    ldr sp, =0x33f80000     @ ���ù���ģʽջָ��
	
	bl nand_init_ll
	
	@ ���ƴ��뵽SDRAM��					
    ldr r0, =_start			@ 1. Ŀ���ַ = 0x30000000������SDRAM����ʼ��ַ
    mov r1, #0				@ 2. Դ��ַ   = 4096�����е�ַ��SDRAM�еĴ��뱣����NAND Flash 4096��ַ��ʼ��
	ldr r2, =__bss_start
	sub r2, r2, r0			@ 3. ���Ƴ��� = __bss_start - _start
    bl  copy_code_to_sdram  @ ����C����copy_code_to_SDRAM
	
    bl  clean_bss           @ ���bss�Σ�δ��ʼ�����ֵΪ0��ȫ��/��̬����������bss��
	
    msr cpsr_c, #0xd2       @ �����ж�ģʽ
    ldr sp, =0x33d00000     @ �����ж�ģʽջָ��

    msr cpsr_c, #0xdf       @ ����ϵͳģʽ
    ldr sp, =0x33e00000     @ ����ϵͳģʽջָ��
	
	msr cpsr_c, #0xd7       @ �������ݷ�����ֹģʽ
    ldr sp, =0x33e80000     @ �������ݷ�����ֹģʽջָ��
	
	msr cpsr_c, #0xdb       @ ����δ����ָ����ֹģʽ
    ldr sp, =0x33f00000     @ ����δ����ָ����ֹģʽջָ��

	msr cpsr_c, #0x53		@ �������ģʽ����I-bit=0����IRQ�ж�
    ldr lr, =ret_initirq    @ ���÷��ص�ַ
    ldr pc, =init_irq       @ �����жϳ�ʼ������
ret_initirq:
    
	
	bl  create_page_table	@ ����ҳ��
    bl  mmu_init			@ ����MMU
	
	
	@��ת��ַ��������blָ��
    ldr lr, =halt_loop      @ ���÷��ص�ַ
    ldr pc, =main           @ ����main����
halt_loop:
    b   halt_loop

HandleIRQ:
    sub lr, lr, #4                  @ ���㷵�ص�ַ
    stmdb   sp!,    { r0-r12,lr }   @ ����ʹ�õ��ļĴ���
                                    @ ע�⣬��ʱ��sp���ж�ģʽ��sp
                                    @ ��ʼֵ���������õ�0x33d00000
    
    ldr lr, =int_return             @ ���õ���IRQ_Handle������ķ��ص�ַ  
    ldr pc, =IRQ_Handle             @ �����жϷַ���������interrupt.c��
int_return:
    ldmia   sp!,    { r0-r12,pc }^  @ �жϷ���, ^��ʾ��spsr��ֵ���Ƶ�cpsr

HandleSWI:
	ldr pc, =vector_swi