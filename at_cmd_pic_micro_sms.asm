;***********************************************************************
;
;   MICROCONTROLLER-BASED HOME CONTROL AND SECURITY SYSTEM VIS SMS
;
;	Author: Kristoffer Dominic R. Amora
;
;	SPECS:
;		Mobile Phone	: ERICSSON T10s / A2618s
;		Cable		: SONY ERICSSON RS232 Cable DRS-11 and
;				  and our own makeshift FBUS Cable :)
;		TTL Driver	: Maxim's MAX232
;		Microcontroller	: Microchip's PIC16F628 / PIC16F877
;		Oscillator	: 4MHZ XTAL
;		
;		Source Code	: Microchip's PIC Instruction Set (Assembly)
;		Language Suite	: Microchip
;		Language Tool	: MPASM	
;
;***********************************************************************

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

;-------------------------------------------------------------------
;	HIGH TEMPERATURE MONITOR INTERRUPT ROUTINE
;-------------------------------------------------------------------

_ALARM
	bcf	INTCON, GIE
	call	_delay
	call	_delay
	call	_delay
	btfss	INTCON,	INTF
	retfie
	goto	_alert	

_alert	call	_settle
	call	_set_CALL_USER
	call	_settle
	call	_OK

	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	
	call	_set_END_CALL
	call	_settle
	call	_OK
	call	_delay
	call	_delay
	goto	_exit_int

_exit_int
	bcf	INTCON,	INTF
	retfie

;-------------------------------------------------------------------
;	PROVIDE TIME FOR WARM-UP AND PIC INITIALIZATION		
;-------------------------------------------------------------------

begin	call	_init

	movlw	0xFF
	movwf	PORTB

	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_settle
		
	call	_reset_char

	call	_delay
	call	_delay
	call	_delay
	call	_delay
	call	_settle

;-------------------------------------------------------------------
;	MOBILE PHONE INITIALIZATION
;-------------------------------------------------------------------
_ON	call	_set_msg_AT
	call	_OK
	call	_chk_ERROR
	btfsc	STATUS,	Z
	goto	_ON
_CPMS	call	_settle
	call	_set_msg_store
	call	_OK
	call	_chk_ERROR
	btfsc	STATUS,	Z
	goto	_CPMS
_CNMI	call	_settle
	call	_set_msg_indicatr
	call	_OK
	call	_chk_ERROR
	btfsc	STATUS,	Z
	goto	_CNMI
_CMSS_a	call	_set_msg_snd1
	call	_OK
	call	_chk_ERROR
	btfsc	STATUS,	Z
	goto	_CMSS_a
	call	_settle

;-------------------------------------------------------------------
;	STARTING PROCEDURE
;-------------------------------------------------------------------
_again	clrf	PORTA
	
	clrf	flg_pw
	clrf	flg_chk

	clrf	flg_tv1
	clrf	flg_fn1
	clrf	flg_st1
	clrf	flg_pc1
	clrf	flg_rf1

	clrf	flg_tv0
	clrf	flg_fn0
	clrf	flg_st0
	clrf	flg_pc0
	clrf	flg_rf0

	call	_settle
	call	_index_12?
	call	_settle
	call	_reset_char

	movlw	d'85'
	movwf	chr_lmt
	call	_set_msg_cmgl_0
	call	_settle
	
_cont	decfsz	chr_lmt,	f
	goto	_get_data
	goto	_cont2

_get_data
	call	_rx1
	goto	_cont

_cont2	movlw	d'11'
	movwf	chr_lmt
	
	call	_reset_char

_cont3	decfsz	chr_lmt,	f
	goto	_get_UserData
	goto	_decipher_passwrd		
	
_get_UserData
	call	_rx
	goto	_cont3

_decipher_passwrd

	call	_OK
	
	movlw	0x43
	subwf	chr1,	w
	btfss	STATUS,	Z
	goto	_out	
	
	movlw	0x35
	subwf	chr2,	w
	btfss	STATUS,	Z
	goto	_out

	movlw	0x37
	subwf	chr3,	w
	btfss	STATUS,	Z
	goto	_out
	
	movlw	0x31
	subwf	chr4,	w
	btfss	STATUS,	Z
	goto	_out

	movlw	0x35
	subwf	chr5,	w
	btfss	STATUS,	Z
	goto	_out	
	
	movlw	0x39
	subwf	chr6,	w
	btfss	STATUS,	Z
	goto	_out

	movlw	0x33
	subwf	chr7,	w
	btfss	STATUS,	Z
	goto	_out
	
	movlw	0x36
	subwf	chr8,	w
	btfss	STATUS,	Z
	goto	_out

	movlw	0x30
	subwf	chr9,	w
	btfss	STATUS,	Z
	goto	_out
	
	movlw	0x33
	subwf	chr10,	w
	btfss	STATUS,	Z
	goto	_out
	goto	_set_flag_pw
	
_set_flag_pw
	movlw	b'00000001'
	movwf	flg_pw
	goto	_snd_feedbck

_out	clrf	flg_pw
	goto	_snd_feedbck

_snd_feedbck
	movlw	0x01
	subwf	flg_pw,	w
	btfss	STATUS,	Z
	goto	_NO
	goto	_YES

_NO	call	_disp
_CMSS_b	call	_settle
	call	_set_msg_snd2
	call	_settle
	call	_OK
	call	_chk_ERROR
	btfsc	STATUS,	Z
	goto	_CMSS_b
_CMGD_a	call	_settle
	call	_set_msg_del12
	call	_settle
	call	_OK
	call	_chk_ERROR
	btfsc	STATUS,	Z
	goto	_CMGD_a	
	call	_reset_char
	call	_delay
	goto	_again

_YES	call	_disp
_CMSS_c	call	_settle
	call	_set_msg_snd3
	call	_settle
	call	_OK
	call	_chk_ERROR
	btfsc	STATUS,	Z
	goto	_CMSS_c
_CMGD_b	call	_settle
	call	_set_msg_del12
	call	_settle
	call	_OK
	call	_chk_ERROR
	btfsc	STATUS,	Z
	goto	_CMGD_b
	call	_reset_char
	call	_delay
	goto	_ACCEPT_COMMANDS

;-------------------------------------------------------------------
;		BEGIN ACCEPTING SMS COMMANDS
;-------------------------------------------------------------------
_ACCEPT_COMMANDS
	call	_reset_char
		
	call	_index_12?
	call	_settle

_get_txt
	movlw	d'85'
	movwf	chr_lmt
	call	_settle
	call	_set_msg_cmgl_0
	call	_settle
	
__cont	decfsz	chr_lmt,	f
	goto	__get_data
	goto	__cont2

__get_data
	call	_rx1
	goto	__cont

__cont2	movlw	d'11'
	movwf	chr_lmt
	
	call	_reset_char

__cont3	decfsz	chr_lmt,	f
	goto	__get_UserData
	goto	_decipher_msgs		
	
__get_UserData
	call	_rx
	goto	__cont3
	
;-------------------------------------------------------------------
;	DECIPHER PROTOCOL DESCRIPTION UNIT (PDU) OF SMS RECEIVED
;-------------------------------------------------------------------
_decipher_msgs

	call	_OK

;-------------------------------------------------------------------
;	"Tv on" USER DATA STRING COMPARISON  
;-------------------------------------------------------------------
_tv_on	movlw	0x35
	subwf	chr1,	w
	btfss	STATUS,	Z
	goto	_out_tv_on	
	
	movlw	0x34
	subwf	chr2,	w
	btfss	STATUS,	Z
	goto	_out_tv_on

	movlw	0x33
	subwf	chr3,	w
	btfss	STATUS,	Z
	goto	_out_tv_on
	
	movlw	0x42
	subwf	chr4,	w
	btfss	STATUS,	Z
	goto	_out_tv_on

	movlw	0x45
	subwf	chr5,	w
	btfss	STATUS,	Z
	goto	_out_tv_on	
	
	movlw	0x38
	subwf	chr6,	w
	btfss	STATUS,	Z
	goto	_out_tv_on

	movlw	0x45
	subwf	chr7,	w
	btfss	STATUS,	Z
	goto	_out_tv_on
	
	movlw	0x44
	subwf	chr8,	w
	btfss	STATUS,	Z
	goto	_out_tv_on

	movlw	0x30
	subwf	chr9,	w
	btfss	STATUS,	Z
	goto	_out_tv_on
	
	movlw	0x36
	subwf	chr10,	w
	btfss	STATUS,	Z
	goto	_out_tv_on
	goto	_set_flag_tv1

_set_flag_tv1
	movlw	b'00000001'
	movwf	flg_tv1
	movlw	b'00000001'
	movwf	flg_chk
	goto	_chk1

_out_tv_on
	clrf	flg_tv1
	clrf	flg_chk
	goto	_chk1

_chk1	btfss	flg_chk,	0
	goto	_tv_off
	goto	_BREAK

;-------------------------------------------------------------------
;	"Tv off" USER DATA STRING COMPARISON
;-------------------------------------------------------------------
_tv_off	movlw	0x35
	subwf	chr1,	w
	btfss	STATUS,	Z
	goto	_out_tv_off	
	
	movlw	0x34
	subwf	chr2,	w
	btfss	STATUS,	Z
	goto	_out_tv_off

	movlw	0x33
	subwf	chr3,	w
	btfss	STATUS,	Z
	goto	_out_tv_off
	
	movlw	0x42
	subwf	chr4,	w
	btfss	STATUS,	Z
	goto	_out_tv_off

	movlw	0x45
	subwf	chr5,	w
	btfss	STATUS,	Z
	goto	_out_tv_off	
	
	movlw	0x38
	subwf	chr6,	w
	btfss	STATUS,	Z
	goto	_out_tv_off

	movlw	0x36
	subwf	chr7,	w
	btfss	STATUS,	Z
	goto	_out_tv_off
	
	movlw	0x44
	subwf	chr8,	w
	btfss	STATUS,	Z
	goto	_out_tv_off

	movlw	0x33
	subwf	chr9,	w
	btfss	STATUS,	Z
	goto	_out_tv_off
	
	movlw	0x36
	subwf	chr10,	w
	btfss	STATUS,	Z
	goto	_out_tv_off
	goto	_set_flag_tv0
	
_set_flag_tv0
	movlw	b'00000001'
	movwf	flg_tv0
	movlw	b'00000001'
	movwf	flg_chk
	goto	_chk2

_out_tv_off
	clrf	flg_tv0
	clrf	flg_chk
	goto	_chk2

_chk2	btfss	flg_chk,	0
	goto	_tv_?
	goto	_BREAK