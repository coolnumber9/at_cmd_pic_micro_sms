list	p=16f628
#include <p16f628.inc>
__CONFIG _CP_OFF & _WDT_OFF & _PWRTE_ON & _XT_OSC & _MCLRE_ON & _BODEN_ON & _LVP_OFF
	
;-------------------------------------------------------------------
;	DEFINING MEMORY ALLOCATION FOR VARIABLES
;-------------------------------------------------------------------
countr	EQU	0x20
ch_buff	EQU	0x21
ch_cnt	EQU	0x22
num	EQU	0x23
num1	EQU	0x24

chr1	EQU	0x25
chr2	EQU	0x26
chr3	EQU	0x27
chr4	EQU	0x28
chr5	EQU	0x29
chr6	EQU	0x2A
chr7	EQU	0x2B
chr8	EQU	0x2C
chr9	EQU	0x2D
chr10	EQU	0x2E

chr_lmt	EQU	0x2F
chr_tmp	EQU	0x30

flg_pw	EQU	0x31
flg_chk	EQU	0x32

flg_tv1	EQU	0x33
flg_fn1	EQU	0x34
flg_st1	EQU	0x35
flg_pc1	EQU	0x36
flg_rf1	EQU	0x37

flg_tv0	EQU	0x38
flg_fn0	EQU	0x39
flg_st0	EQU	0x3A
flg_pc0	EQU	0x3B
flg_rf0	EQU	0x3C

flg_tv?	EQU	0x3D
flg_fn?	EQU	0x3E
flg_st?	EQU	0x3F
flg_pc?	EQU	0x40
flg_rf?	EQU	0x41

flg_al1	EQU	0x42
flg_al0	EQU	0x43

ERROR_?	EQU	0x44
rx_ERR	EQU	0x45

buffr	EQU	0x7D
temp	EQU	0x7E