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

;-------------------------------------------------------------------
;	ORIGINATE RESET VECTOR TO 0X00 AT ROM AND
;	ORIGINATE THE INTERRUPT VECTOR TO 0X04
;-------------------------------------------------------------------
	ORG	0x00
	goto 	begin

	ORG	0x04
	goto	_ALARM

;-------------------------------------------------------------------
;	BANK SWITCHING & SETTING COMPARATORS OFF MACROS
;-------------------------------------------------------------------
	#include "bank.inc"
	#include "cmp_off.inc"

;-------------------------------------------------------------------
;	I/O PORTS DESCRIPTION AND ITS DESIGNATION
;-------------------------------------------------------------------
	#define	STAT_RF	PORTA,	0

	#define	STAT_TV	PORTA,	1
	#define STAT_FN	PORTA,	2
	#define	STAT_ST	PORTA,	3
	#define	STAT_PC	PORTA,	4
	#define	TMPRTR	PORTB,	0

	#define	TV	PORTB,	3
	#define	FAN	PORTB,	4
	#define	STEREO	PORTB,	5	
	#define PC	PORTB,	6
	#define	REF	PORTB,	7

;-------------------------------------------------------------------
; AT COMMAND TABLE SET
; * SET AT THIS ROM LOCATION TO AVOID PCL PAGE BOUNDARY OVERFLOW
;-------------------------------------------------------------------
_snd_cmd_cpms_me
	addwf	PCL,	f
	dt "at+cpms=",0x22,"me",0x22,",",0x22,"me",0x22,",",0x22,"me",0x22,0x0D

_snd_cmd_cpms_sim
	addwf	PCL,	f
	dt "at+cpms=",0x22,"sm",0x22,",",0x22,"sm",0x22,",",0x22,"me",0x22,0x0D

_snd_cmd_cnmi
	addwf	PCL,	f
	dt "at+cnmi=3,1,0,0",0x0D

_snd_cmd_cmgd_1
	addwf	PCL,	f
	dt "at+cmgd=1",0x0D

_snd_cmd_cmgd_12
	addwf	PCL,	f
	dt "at+cmgd=12",0x0D

_snd_cmd_cind
	addwf	PCL,	f
	dt "at+cind?",0x0D

_snd_cmss_1
	addwf	PCL,	f
	dt "at+cmss=1",0x0D

_snd_cmss_2
	addwf	PCL,	f
	dt "at+cmss=2",0x0D

_snd_cmss_3
	addwf	PCL,	f
	dt "at+cmss=3",0x0D

_snd_cmss_4
	addwf	PCL,	f
	dt "at+cmss=4",0x0D

_snd_cmss_5
	addwf	PCL,	f
	dt "at+cmss=5",0x0D

_snd_cmss_6
	addwf	PCL,	f
	dt "at+cmss=6",0x0D

_snd_cmss_7
	addwf	PCL,	f
	dt "at+cmss=7",0x0D

_snd_cmss_8
	addwf	PCL,	f
	dt "at+cmss=8",0x0D

_snd_cmss_9
	addwf	PCL,	f
	dt "at+cmss=9",0x0D

_snd_cmss_10
	addwf	PCL,	f
	dt "at+cmss=10",0x0D

_snd_cmss_11
	addwf	PCL,	f
	dt "at+cmss=11",0x0D

_snd_cmgl_0
	addwf	PCL,	f
	dt "at+cmgl=0",0x0D

_snd_cmgr_1
	addwf	PCL,	f
	dt "at+cmgr=1",0x0D

_snd_cmd_AT
	addwf	PCL,	f
	dt "at",0x0D

_snd_cmd_ATD
	addwf	PCL,	f
	dt "atd09173247521",0x3B,0x0D

_snd_cmd_ATH
	addwf	PCL,	f
	dt "ath",0x0D