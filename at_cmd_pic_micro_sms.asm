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

;-------------------------------------------------------------------
;	"Tv st?" USER DATA STRING COMPARISON
;-------------------------------------------------------------------
_tv_?	movlw	0x35
	subwf	chr1,	w
	btfss	STATUS,	Z
	goto	_out_tv_?	
	
	movlw	0x34
	subwf	chr2,	w
	btfss	STATUS,	Z
	goto	_out_tv_?

	movlw	0x33
	subwf	chr3,	w
	btfss	STATUS,	Z
	goto	_out_tv_?
	
	movlw	0x42
	subwf	chr4,	w
	btfss	STATUS,	Z
	goto	_out_tv_?

	movlw	0x36
	subwf	chr5,	w
	btfss	STATUS,	Z
	goto	_out_tv_?	
	
	movlw	0x38
	subwf	chr6,	w
	btfss	STATUS,	Z
	goto	_out_tv_?

	movlw	0x34
	subwf	chr7,	w
	btfss	STATUS,	Z
	goto	_out_tv_?
	
	movlw	0x45
	subwf	chr8,	w
	btfss	STATUS,	Z
	goto	_out_tv_?

	movlw	0x46
	subwf	chr9,	w
	btfss	STATUS,	Z
	goto	_out_tv_?
	
	movlw	0x46
	subwf	chr10,	w
	btfss	STATUS,	Z
	goto	_out_tv_?
	goto	_set_flag_tv?
	
_set_flag_tv?
	movlw	b'00000001'
	movwf	flg_tv?
	movlw	b'00000001'
	movwf	flg_chk
	goto	_chk3

_out_tv_?
	clrf	flg_tv?
	clrf	flg_chk
	goto	_chk3

_chk3	btfss	flg_chk,	0
	goto	_fan_on
	goto	_BREAK

;-------------------------------------------------------------------
;	"Fan on" USER DATA STRING COMPARISON
;-------------------------------------------------------------------
_fan_on	movlw	0x43
	subwf	chr1,	w
	btfss	STATUS,	Z
	goto	_out_fn_on	
	
	movlw	0x36
	subwf	chr2,	w
	btfss	STATUS,	Z
	goto	_out_fn_on

	movlw	0x42
	subwf	chr3,	w
	btfss	STATUS,	Z
	goto	_out_fn_on
	
	movlw	0x30
	subwf	chr4,	w
	btfss	STATUS,	Z
	goto	_out_fn_on

	movlw	0x31
	subwf	chr5,	w
	btfss	STATUS,	Z
	goto	_out_fn_on	
	
	movlw	0x42
	subwf	chr6,	w
	btfss	STATUS,	Z
	goto	_out_fn_on

	movlw	0x46
	subwf	chr7,	w
	btfss	STATUS,	Z
	goto	_out_fn_on
	
	movlw	0x34
	subwf	chr8,	w
	btfss	STATUS,	Z
	goto	_out_fn_on

	movlw	0x37
	subwf	chr9,	w
	btfss	STATUS,	Z
	goto	_out_fn_on
	
	movlw	0x36
	subwf	chr10,	w
	btfss	STATUS,	Z
	goto	_out_fn_on
	goto	_set_flag_fn1
	
_set_flag_fn1
	movlw	b'00000001'
	movwf	flg_fn1
	movlw	b'00000001'
	movwf	flg_chk
	goto	_chk4

_out_fn_on
	clrf	flg_fn1
	clrf	flg_chk
	goto	_chk4

_chk4	btfss	flg_chk,	0
	goto	_fan_off
	goto	_BREAK

;-------------------------------------------------------------------
;	"Fan off" USER DATA STRING COMPARISON
;-------------------------------------------------------------------
_fan_off
	movlw	0x43
	subwf	chr1,	w
	btfss	STATUS,	Z
	goto	_out_fn_off	
	
	movlw	0x36
	subwf	chr2,	w
	btfss	STATUS,	Z
	goto	_out_fn_off

	movlw	0x42
	subwf	chr3,	w
	btfss	STATUS,	Z
	goto	_out_fn_off
	
	movlw	0x30
	subwf	chr4,	w
	btfss	STATUS,	Z
	goto	_out_fn_off

	movlw	0x31
	subwf	chr5,	w
	btfss	STATUS,	Z
	goto	_out_fn_off	
	
	movlw	0x42
	subwf	chr6,	w
	btfss	STATUS,	Z
	goto	_out_fn_off

	movlw	0x46
	subwf	chr7,	w
	btfss	STATUS,	Z
	goto	_out_fn_off
	
	movlw	0x34
	subwf	chr8,	w
	btfss	STATUS,	Z
	goto	_out_fn_off

	movlw	0x33
	subwf	chr9,	w
	btfss	STATUS,	Z
	goto	_out_fn_off
	
	movlw	0x36
	subwf	chr10,	w
	btfss	STATUS,	Z
	goto	_out_fn_off
	goto	_set_flag_fn0
	
_set_flag_fn0
	movlw	b'00000001'
	movwf	flg_fn0
	movlw	b'00000001'
	movwf	flg_chk
	goto	_chk5

_out_fn_off
	clrf	flg_fn0
	clrf	flg_chk
	goto	_chk5

_chk5	btfss	flg_chk,	0
	goto	_fan_?
	goto	_BREAK

;-------------------------------------------------------------------
;	"Fan st?" USER DATA STRING COMPARISON
;-------------------------------------------------------------------
_fan_?	movlw	0x43
	subwf	chr1,	w
	btfss	STATUS,	Z
	goto	_out_fn_?	
	
	movlw	0x36
	subwf	chr2,	w
	btfss	STATUS,	Z
	goto	_out_fn_?

	movlw	0x42
	subwf	chr3,	w
	btfss	STATUS,	Z
	goto	_out_fn_?
	
	movlw	0x30
	subwf	chr4,	w
	btfss	STATUS,	Z
	goto	_out_fn_?

	movlw	0x31
	subwf	chr5,	w
	btfss	STATUS,	Z
	goto	_out_fn_?	
	
	movlw	0x42
	subwf	chr6,	w
	btfss	STATUS,	Z
	goto	_out_fn_?

	movlw	0x33
	subwf	chr7,	w
	btfss	STATUS,	Z
	goto	_out_fn_?
	
	movlw	0x34
	subwf	chr8,	w
	btfss	STATUS,	Z
	goto	_out_fn_?

	movlw	0x41
	subwf	chr9,	w
	btfss	STATUS,	Z
	goto	_out_fn_?
	
	movlw	0x37
	subwf	chr10,	w
	btfss	STATUS,	Z
	goto	_out_fn_?
	goto	_set_flag_fn?
	
_set_flag_fn?
	movlw	b'00000001'
	movwf	flg_fn?
	movlw	b'00000001'
	movwf	flg_chk
	goto	_chk6

_out_fn_?
	clrf	flg_fn?
	clrf	flg_chk
	goto	_chk6

_chk6	btfss	flg_chk,	0
	goto	_stereo_on
	goto	_BREAK

_BREAK	goto	_BREAK_true

;-------------------------------------------------------------------
;	"Str on" USER DATA STRING COMPARISON
;-------------------------------------------------------------------
_stereo_on
	movlw	0x35
	subwf	chr1,	w
	btfss	STATUS,	Z
	goto	_out_st_on	
	
	movlw	0x33
	subwf	chr2,	w
	btfss	STATUS,	Z
	goto	_out_st_on

	movlw	0x42
	subwf	chr3,	w
	btfss	STATUS,	Z
	goto	_out_st_on
	
	movlw	0x41
	subwf	chr4,	w
	btfss	STATUS,	Z
	goto	_out_st_on

	movlw	0x31
	subwf	chr5,	w
	btfss	STATUS,	Z
	goto	_out_st_on	
	
	movlw	0x43
	subwf	chr6,	w
	btfss	STATUS,	Z
	goto	_out_st_on

	movlw	0x46
	subwf	chr7,	w
	btfss	STATUS,	Z
	goto	_out_st_on
	
	movlw	0x34
	subwf	chr8,	w
	btfss	STATUS,	Z
	goto	_out_st_on

	movlw	0x37
	subwf	chr9,	w
	btfss	STATUS,	Z
	goto	_out_st_on
	
	movlw	0x36
	subwf	chr10,	w
	btfss	STATUS,	Z
	goto	_out_st_on
	goto	_set_flag_st1
	
_set_flag_st1
	movlw	b'00000001'
	movwf	flg_st1
	movlw	b'00000001'
	movwf	flg_chk
	goto	_chk7

_out_st_on
	clrf	flg_st1
	clrf	flg_chk
	goto	_chk7

_chk7	btfss	flg_chk,	0
	goto	_stereo_off
	goto	_BREAK

;-------------------------------------------------------------------
;	"Str off" USER DATA STRING COMPARISON
;-------------------------------------------------------------------
_stereo_off
	movlw	0x35
	subwf	chr1,	w
	btfss	STATUS,	Z
	goto	_out_st_off	
	
	movlw	0x33
	subwf	chr2,	w
	btfss	STATUS,	Z
	goto	_out_st_off

	movlw	0x42
	subwf	chr3,	w
	btfss	STATUS,	Z
	goto	_out_st_off
	
	movlw	0x41
	subwf	chr4,	w
	btfss	STATUS,	Z
	goto	_out_st_off

	movlw	0x31
	subwf	chr5,	w
	btfss	STATUS,	Z
	goto	_out_st_off	
	
	movlw	0x43
	subwf	chr6,	w
	btfss	STATUS,	Z
	goto	_out_st_off

	movlw	0x46
	subwf	chr7,	w
	btfss	STATUS,	Z
	goto	_out_st_off
	
	movlw	0x34
	subwf	chr8,	w
	btfss	STATUS,	Z
	goto	_out_st_off

	movlw	0x33
	subwf	chr9,	w
	btfss	STATUS,	Z
	goto	_out_st_off
	
	movlw	0x36
	subwf	chr10,	w
	btfss	STATUS,	Z
	goto	_out_st_off
	goto	_set_flag_st0
	
_set_flag_st0
	movlw	b'00000001'
	movwf	flg_st0
	movlw	b'00000001'
	movwf	flg_chk
	goto	_chk8

_out_st_off
	clrf	flg_st0
	clrf	flg_chk
	goto	_chk8

_chk8	btfss	flg_chk,	0
	goto	_stereo_?
	goto	_BREAK

;-------------------------------------------------------------------
;	"Str st?" USER DATA STRING COMPARISON
;-------------------------------------------------------------------
_stereo_?
	movlw	0x35
	subwf	chr1,	w
	btfss	STATUS,	Z
	goto	_out_st_?	
	
	movlw	0x33
	subwf	chr2,	w
	btfss	STATUS,	Z
	goto	_out_st_?

	movlw	0x42
	subwf	chr3,	w
	btfss	STATUS,	Z
	goto	_out_st_?
	
	movlw	0x41
	subwf	chr4,	w
	btfss	STATUS,	Z
	goto	_out_st_?

	movlw	0x31
	subwf	chr5,	w
	btfss	STATUS,	Z
	goto	_out_st_?	
	
	movlw	0x43
	subwf	chr6,	w
	btfss	STATUS,	Z
	goto	_out_st_?

	movlw	0x33
	subwf	chr7,	w
	btfss	STATUS,	Z
	goto	_out_st_?
	
	movlw	0x34
	subwf	chr8,	w
	btfss	STATUS,	Z
	goto	_out_st_?

	movlw	0x41
	subwf	chr9,	w
	btfss	STATUS,	Z
	goto	_out_st_?
	
	movlw	0x37
	subwf	chr10,	w
	btfss	STATUS,	Z
	goto	_out_st_?
	goto	_set_flag_st?
	
_set_flag_st?
	movlw	b'00000001'
	movwf	flg_st?
	movlw	b'00000001'
	movwf	flg_chk
	goto	_chk9

_out_st_?
	clrf	flg_st?
	clrf	flg_chk
	goto	_chk9

_chk9	btfss	flg_chk,	0
	goto	_pc_on
	goto	_BREAK

;-------------------------------------------------------------------
;	"Pc on" USER DATA STRING COMPARISON
;-------------------------------------------------------------------
_pc_on	movlw	0x44
	subwf	chr1,	w
	btfss	STATUS,	Z
	goto	_out_pc_on	
	
	movlw	0x30
	subwf	chr2,	w
	btfss	STATUS,	Z
	goto	_out_pc_on

	movlw	0x33
	subwf	chr3,	w
	btfss	STATUS,	Z
	goto	_out_pc_on
	
	movlw	0x31
	subwf	chr4,	w
	btfss	STATUS,	Z
	goto	_out_pc_on

	movlw	0x45
	subwf	chr5,	w
	btfss	STATUS,	Z
	goto	_out_pc_on	
	
	movlw	0x38
	subwf	chr6,	w
	btfss	STATUS,	Z
	goto	_out_pc_on

	movlw	0x45
	subwf	chr7,	w
	btfss	STATUS,	Z
	goto	_out_pc_on
	
	movlw	0x44
	subwf	chr8,	w
	btfss	STATUS,	Z
	goto	_out_pc_on

	movlw	0x30
	subwf	chr9,	w
	btfss	STATUS,	Z
	goto	_out_pc_on
	
	movlw	0x36
	subwf	chr10,	w
	btfss	STATUS,	Z
	goto	_out_pc_on
	goto	_set_flag_pc1
	
_set_flag_pc1
	movlw	b'00000001'
	movwf	flg_pc1
	movlw	b'00000001'
	movwf	flg_chk
	goto	_chk10

_out_pc_on
	clrf	flg_pc1
	clrf	flg_chk
	goto	_chk10

_chk10	btfss	flg_chk,	0
	goto	_pc_off
	goto	_BREAK_true

;-------------------------------------------------------------------
;	"Pc off" USER DATA STRING COMPARISON
;-------------------------------------------------------------------
_pc_off	movlw	0x44
	subwf	chr1,	w
	btfss	STATUS,	Z
	goto	_out_pc_off	
	
	movlw	0x30
	subwf	chr2,	w
	btfss	STATUS,	Z
	goto	_out_pc_off

	movlw	0x33
	subwf	chr3,	w
	btfss	STATUS,	Z
	goto	_out_pc_off
	
	movlw	0x31
	subwf	chr4,	w
	btfss	STATUS,	Z
	goto	_out_pc_off

	movlw	0x45
	subwf	chr5,	w
	btfss	STATUS,	Z
	goto	_out_pc_off	
	
	movlw	0x38
	subwf	chr6,	w
	btfss	STATUS,	Z
	goto	_out_pc_off

	movlw	0x36
	subwf	chr7,	w
	btfss	STATUS,	Z
	goto	_out_pc_off
	
	movlw	0x44
	subwf	chr8,	w
	btfss	STATUS,	Z
	goto	_out_pc_off

	movlw	0x33
	subwf	chr9,	w
	btfss	STATUS,	Z
	goto	_out_pc_off
	
	movlw	0x36
	subwf	chr10,	w
	btfss	STATUS,	Z
	goto	_out_pc_off
	goto	_set_flag_pc0
	
_set_flag_pc0
	movlw	b'00000001'
	movwf	flg_pc0
	movlw	b'00000001'
	movwf	flg_chk
	goto	_chk11

_out_pc_off
	clrf	flg_pc0
	clrf	flg_chk
	goto	_chk11

_chk11	btfss	flg_chk,	0
	goto	_pc_?
	goto	_BREAK_true

;-------------------------------------------------------------------
;	"Pc st?" USER DATA STRING COMPARISON
;-------------------------------------------------------------------
_pc_?	movlw	0x44
	subwf	chr1,	w
	btfss	STATUS,	Z
	goto	_out_pc_?	
	
	movlw	0x30
	subwf	chr2,	w
	btfss	STATUS,	Z
	goto	_out_pc_?

	movlw	0x33
	subwf	chr3,	w
	btfss	STATUS,	Z
	goto	_out_pc_?
	
	movlw	0x31
	subwf	chr4,	w
	btfss	STATUS,	Z
	goto	_out_pc_?

	movlw	0x36
	subwf	chr5,	w
	btfss	STATUS,	Z
	goto	_out_pc_?	
	
	movlw	0x38
	subwf	chr6,	w
	btfss	STATUS,	Z
	goto	_out_pc_?

	movlw	0x34
	subwf	chr7,	w
	btfss	STATUS,	Z
	goto	_out_pc_?
	
	movlw	0x45
	subwf	chr8,	w
	btfss	STATUS,	Z
	goto	_out_pc_?

	movlw	0x46
	subwf	chr9,	w
	btfss	STATUS,	Z
	goto	_out_pc_?
	
	movlw	0x46
	subwf	chr10,	w
	btfss	STATUS,	Z
	goto	_out_pc_?
	goto	_set_flag_pc?
	
_set_flag_pc?
	movlw	b'00000001'
	movwf	flg_pc?
	movlw	b'00000001'
	movwf	flg_chk
	goto	_chk12

_out_pc_?
	clrf	flg_pc?
	clrf	flg_chk
	goto	_chk12

_chk12	btfss	flg_chk,	0
	goto	_ref_on
	goto	_BREAK_true

;-------------------------------------------------------------------
;	"Ref on" USER DATA STRING COMPARISON
;-------------------------------------------------------------------
_ref_on	movlw	0x44
	subwf	chr1,	w
	btfss	STATUS,	Z
	goto	_out_rf_on	
	
	movlw	0x32
	subwf	chr2,	w
	btfss	STATUS,	Z
	goto	_out_rf_on

	movlw	0x42
	subwf	chr3,	w
	btfss	STATUS,	Z
	goto	_out_rf_on
	
	movlw	0x32
	subwf	chr4,	w
	btfss	STATUS,	Z
	goto	_out_rf_on

	movlw	0x31
	subwf	chr5,	w
	btfss	STATUS,	Z
	goto	_out_rf_on	
	
	movlw	0x39
	subwf	chr6,	w
	btfss	STATUS,	Z
	goto	_out_rf_on

	movlw	0x46
	subwf	chr7,	w
	btfss	STATUS,	Z
	goto	_out_rf_on
	
	movlw	0x34
	subwf	chr8,	w
	btfss	STATUS,	Z
	goto	_out_rf_on

	movlw	0x37
	subwf	chr9,	w
	btfss	STATUS,	Z
	goto	_out_rf_on
	
	movlw	0x36
	subwf	chr10,	w
	btfss	STATUS,	Z
	goto	_out_rf_on
	goto	_set_flag_rf1
	
_set_flag_rf1
	movlw	b'00000001'
	movwf	flg_rf1
	movlw	b'00000001'
	movwf	flg_chk
	goto	_chk13

_out_rf_on
	clrf	flg_pc1
	clrf	flg_chk
	goto	_chk13

_chk13	btfss	flg_chk,	0
	goto	_ref_off
	goto	_BREAK_true

;-------------------------------------------------------------------
;	"Ref off" USER DATA STRING COMPARISON
;-------------------------------------------------------------------
_ref_off
	movlw	0x44
	subwf	chr1,	w
	btfss	STATUS,	Z
	goto	_out_rf_off	
	
	movlw	0x32
	subwf	chr2,	w
	btfss	STATUS,	Z
	goto	_out_rf_off

	movlw	0x42
	subwf	chr3,	w
	btfss	STATUS,	Z
	goto	_out_rf_off
	
	movlw	0x32
	subwf	chr4,	w
	btfss	STATUS,	Z
	goto	_out_rf_off

	movlw	0x31
	subwf	chr5,	w
	btfss	STATUS,	Z
	goto	_out_rf_off	
	
	movlw	0x39
	subwf	chr6,	w
	btfss	STATUS,	Z
	goto	_out_rf_off

	movlw	0x46
	subwf	chr7,	w
	btfss	STATUS,	Z
	goto	_out_rf_off
	
	movlw	0x34
	subwf	chr8,	w
	btfss	STATUS,	Z
	goto	_out_rf_off

	movlw	0x33
	subwf	chr9,	w
	btfss	STATUS,	Z
	goto	_out_rf_off
	
	movlw	0x36
	subwf	chr10,	w
	btfss	STATUS,	Z
	goto	_out_rf_off
	goto	_set_flag_rf0
	
_set_flag_rf0
	movlw	b'00000001'
	movwf	flg_rf0
	movlw	b'00000001'
	movwf	flg_chk
	goto	_chk14

_out_rf_off
	clrf	flg_pc0
	clrf	flg_chk
	goto	_chk14

_chk14	btfss	flg_chk,	0
	goto	_ref_?
	goto	_BREAK_true

;-------------------------------------------------------------------
;	"Ref st?" USER DATA STRING COMPARISON
;-------------------------------------------------------------------
_ref_?	movlw	0x44
	subwf	chr1,	w
	btfss	STATUS,	Z
	goto	_out_rf_?	
	
	movlw	0x32
	subwf	chr2,	w
	btfss	STATUS,	Z
	goto	_out_rf_?

	movlw	0x42
	subwf	chr3,	w
	btfss	STATUS,	Z
	goto	_out_rf_?
	
	movlw	0x32
	subwf	chr4,	w
	btfss	STATUS,	Z
	goto	_out_rf_?

	movlw	0x31
	subwf	chr5,	w
	btfss	STATUS,	Z
	goto	_out_rf_?	
	
	movlw	0x39
	subwf	chr6,	w
	btfss	STATUS,	Z
	goto	_out_rf_?

	movlw	0x33
	subwf	chr7,	w
	btfss	STATUS,	Z
	goto	_out_rf_?
	
	movlw	0x34
	subwf	chr8,	w
	btfss	STATUS,	Z
	goto	_out_rf_?

	movlw	0x41
	subwf	chr9,	w
	btfss	STATUS,	Z
	goto	_out_rf_?
	
	movlw	0x37
	subwf	chr10,	w
	btfss	STATUS,	Z
	goto	_out_rf_?
	goto	_set_flag_rf?
	
_set_flag_rf?
	movlw	b'00000001'
	movwf	flg_rf?
	movlw	b'00000001'
	movwf	flg_chk
	goto	_chk15

_out_rf_?
	clrf	flg_pc?
	clrf	flg_chk
	goto	_chk15

_chk15	btfss	flg_chk,	0
	goto	_all_on
	goto	_BREAK_true

;-------------------------------------------------------------------
;	"All on" USER DATA STRING COMPARISON
;-------------------------------------------------------------------
_all_on	movlw	0x34
	subwf	chr1,	w
	btfss	STATUS,	Z
	goto	_out_al1	
	
	movlw	0x31
	subwf	chr2,	w
	btfss	STATUS,	Z
	goto	_out_al1

	movlw	0x33
	subwf	chr3,	w
	btfss	STATUS,	Z
	goto	_out_al1
	
	movlw	0x36
	subwf	chr4,	w
	btfss	STATUS,	Z
	goto	_out_al1

	movlw	0x31
	subwf	chr5,	w
	btfss	STATUS,	Z
	goto	_out_al1	
	
	movlw	0x42
	subwf	chr6,	w
	btfss	STATUS,	Z
	goto	_out_al1

	movlw	0x46
	subwf	chr7,	w
	btfss	STATUS,	Z
	goto	_out_al1
	
	movlw	0x34
	subwf	chr8,	w
	btfss	STATUS,	Z
	goto	_out_al1

	movlw	0x37
	subwf	chr9,	w
	btfss	STATUS,	Z
	goto	_out_al1
	
	movlw	0x36
	subwf	chr10,	w
	btfss	STATUS,	Z
	goto	_out_al1
	goto	_set_flag_al1
	
_set_flag_al1
	movlw	b'00000001'
	movwf	flg_al1
	movlw	b'00000001'
	movwf	flg_chk
	goto	_chk16

_out_al1
	clrf	flg_al1
	clrf	flg_chk
	goto	_chk16

_chk16	btfss	flg_chk,	0
	goto	_all_of
	goto	_BREAK_true

;-------------------------------------------------------------------
;	"All off" USER DATA STRING COMPARISON
;-------------------------------------------------------------------
_all_of	movlw	0x34
	subwf	chr1,	w
	btfss	STATUS,	Z
	goto	_out_al0	
	
	movlw	0x31
	subwf	chr2,	w
	btfss	STATUS,	Z
	goto	_out_al0

	movlw	0x33
	subwf	chr3,	w
	btfss	STATUS,	Z
	goto	_out_al0
	
	movlw	0x36
	subwf	chr4,	w
	btfss	STATUS,	Z
	goto	_out_al0

	movlw	0x31
	subwf	chr5,	w
	btfss	STATUS,	Z
	goto	_out_al0	
	
	movlw	0x42
	subwf	chr6,	w
	btfss	STATUS,	Z
	goto	_out_al0

	movlw	0x46
	subwf	chr7,	w
	btfss	STATUS,	Z
	goto	_out_al0
	
	movlw	0x34
	subwf	chr8,	w
	btfss	STATUS,	Z
	goto	_out_al0

	movlw	0x33
	subwf	chr9,	w
	btfss	STATUS,	Z
	goto	_out_al0
	
	movlw	0x36
	subwf	chr10,	w
	btfss	STATUS,	Z
	goto	_out_al0
	goto	_set_flag_al0
	
_set_flag_al0
	movlw	b'00000001'
	movwf	flg_al0
	movlw	b'00000001'
	movwf	flg_chk
	goto	_chk17

_out_al0
	clrf	flg_al0
	clrf	flg_chk
	goto	_chk17

_chk17	btfss	flg_chk,	0
	goto	_INVALID
	goto	_BREAK_true

_jmp_Accept_Cmds
	goto	_ACCEPT_COMMANDS

;-------------------------------------------------------------------
;	WAIT FOR A POSITIVE REPLY (FUNCTION) FROM THE MOBILE PHONE
;-------------------------------------------------------------------
_OK
_get_O	call	_rx1
	
	movwf	buffr
	movlw	0x4F 		
	subwf	buffr,	w
	btfss	STATUS,	Z
	goto	_get_E	
	retlw	b'00000000'

_get_E	movlw	0x45
	subwf	buffr,	w
	btfss	STATUS,	Z
	goto	_get_O
	retlw	b'00000001'

_chk_ERROR
	movwf	ERROR_?	
	movlw	b'00000001'
	subwf	ERROR_?,	w
	return	
	
;-------------------------------------------------------------------
;	START OF FLAG VALUE CHECKING
;-------------------------------------------------------------------

_BREAK_true	
		
_BREAK_	btfss	flg_tv1,	0
	goto	_nxt1
	call	_exec_tv1
	goto	_THE_END

_nxt1	btfss	flg_tv0,	0
	goto	_nxt2
	call	_exec_tv0
	goto	_THE_END

_nxt2	btfss	flg_tv?,	0
	goto	_nxt3
	call	_notify_tv?
	goto	_THE_END

_nxt3	btfss	flg_fn1,	0
	goto	_nxt4
	call	_exec_fn1
	goto	_THE_END

_nxt4	btfss	flg_fn0,	0
	goto	_nxt5
	call	_exec_fn0
	goto	_THE_END

_nxt5	btfss	flg_fn?,	0
	goto	_nxt6
	call	_notify_fn?
	goto	_THE_END

_nxt6	btfss	flg_st1,	0
	goto	_nxt7
	call	_exec_st1
	goto	_THE_END

_nxt7	btfss	flg_st0,	0
	goto	_nxt8
	call	_exec_st0
	goto	_THE_END

_nxt8	btfss	flg_st?,	0
	goto	_nxt9
	call	_notify_st?
	goto	_THE_END

_nxt9	btfss	flg_pc1,	0
	goto	_nxt10
	call	_exec_pc1
	goto	_THE_END

_nxt10	btfss	flg_pc0,	0
	goto	_nxt11
	call	_exec_pc0
	goto	_THE_END

_nxt11	btfss	flg_pc?,	0
	goto	_nxt12
	call	_notify_pc?
	goto	_THE_END

_nxt12	btfss	flg_rf1,	0
	goto	_nxt13
	call	_exec_rf1
	goto	_THE_END

_nxt13	btfss	flg_rf0,	0
	goto	_nxt14
	call	_exec_rf0
	goto	_THE_END

_nxt14	btfss	flg_rf?,	0
	goto	_nxt15
	call	_notify_rf?
	goto	_THE_END

_nxt15	btfss	flg_al1,	0
	goto	_nxt16
	call	_exec_al1
	goto	_THE_END

_nxt16	btfss	flg_al0,	0
	goto	_INVALID
	call	_exec_al0
	goto	_THE_END

_exec_tv1
	bcf	TV
_CMSS_d	call	_settle
	call	_set_msg_snd8
	call	_settle
	call	_OK
	call	_chk_ERROR
	btfsc	STATUS,	Z
	goto	_CMSS_d
	return

_exec_fn1
	bcf	FAN
_CMSS_e	call	_settle
	call	_set_msg_snd8
	call	_settle
	call	_OK
	call	_chk_ERROR
	btfsc	STATUS,	Z
	goto	_CMSS_e
	return

_exec_st1
	bcf	STEREO
_CMSS_f	call	_settle
	call	_set_msg_snd8
	call	_settle
	call	_OK
	call	_chk_ERROR
	btfsc	STATUS,	Z
	goto	_CMSS_f
	return

_exec_pc1
	bcf	PC
_CMSS_g	call	_settle
	call	_set_msg_snd8
	call	_settle
	call	_OK
	call	_chk_ERROR
	btfsc	STATUS,	Z
	goto	_CMSS_g
	return

_exec_rf1
	bcf	REF
_CMSS_h	call	_settle
	call	_set_msg_snd8
	call	_settle
	call	_OK
	call	_chk_ERROR
	btfsc	STATUS,	Z
	goto	_CMSS_h
	return

_exec_tv0
	bsf	TV
_CMSS_i	call	_settle
	call	_set_msg_snd9
	call	_settle
	call	_OK
	call	_chk_ERROR
	btfsc	STATUS,	Z
	goto	_CMSS_i
	return

_exec_fn0
	bsf	FAN
_CMSS_j	call	_settle
	call	_set_msg_snd9
	call	_settle
	call	_OK
	call	_chk_ERROR
	btfsc	STATUS,	Z
	goto	_CMSS_j
	return

_exec_st0
	bsf	STEREO
_CMSS_k	call	_settle
	call	_set_msg_snd9
	call	_settle
	call	_OK
	call	_chk_ERROR
	btfsc	STATUS,	Z
	goto	_CMSS_k
	return

_exec_pc0
	bsf	PC
_CMSS_l	call	_settle
	call	_set_msg_snd9
	call	_settle
	call	_OK
	call	_chk_ERROR
	btfsc	STATUS,	Z
	goto	_CMSS_l
	return

_exec_rf0
	bsf	REF
_CMSS_m	call	_settle
	call	_set_msg_snd9
	call	_settle
	call	_OK
	call	_chk_ERROR
	btfsc	STATUS,	Z
	goto	_CMSS_m
	return

_notify_tv?
	btfsc	STAT_TV
	goto	_tv_is_off	
	goto	_tv_is_on
_tv_end	nop
	return
	
_tv_is_on
	call	_settle
	call	_set_msg_snd4
	call	_settle
	call	_OK
	call	_chk_ERROR
	btfsc	STATUS,	Z
	goto	_tv_is_on
	goto	_tv_end

_tv_is_off
	call	_settle	
	call	_set_msg_snd5
	call	_settle
	call	_OK
	call	_chk_ERROR
	btfsc	STATUS,	Z
	goto	_tv_is_off
	goto	_tv_end

_notify_fn?
	btfsc	STAT_FN
	goto	_fn_is_off	
	goto	_fn_is_on
_fn_end	nop
	return
	
_fn_is_on
	call	_settle
	call	_set_msg_snd4
	call	_settle
	call	_OK
	call	_chk_ERROR
	btfsc	STATUS,	Z
	goto	_fn_is_on
	goto	_fn_end

_fn_is_off	
	call	_settle
	call	_set_msg_snd5
	call	_settle
	call	_OK
	call	_chk_ERROR
	btfsc	STATUS,	Z
	goto	_fn_is_off
	goto	_fn_end

_notify_st?
	btfsc	STAT_ST
	goto	_st_is_off	
	goto	_st_is_on
_st_end	nop
	return
	
_st_is_on
	call	_settle
	call	_set_msg_snd4
	call	_settle
	call	_OK
	call	_chk_ERROR
	btfsc	STATUS,	Z
	goto	_st_is_on
	goto	_st_end

_st_is_off
	call	_settle	
	call	_set_msg_snd5
	call	_settle
	call	_OK
	call	_chk_ERROR
	btfsc	STATUS,	Z
	goto	_st_is_off
	goto	_st_end

_notify_pc?
	btfsc	STAT_PC
	goto	_pc_is_off	
	goto	_pc_is_on
_pc_end	nop
	return
	
_pc_is_on
	call	_settle
	call	_set_msg_snd4
	call	_settle
	call	_OK
	call	_chk_ERROR
	btfsc	STATUS,	Z
	goto	_pc_is_on
	goto	_pc_end

_pc_is_off	
	call	_settle
	call	_set_msg_snd5
	call	_settle
	call	_OK
	call	_chk_ERROR
	btfsc	STATUS,	Z
	goto	_pc_is_off
	goto	_pc_end

_notify_rf?
	btfsc	STAT_RF
	goto	_rf_is_off	
	goto	_rf_is_on
_rf_end	nop
	return
	
_rf_is_on
	call	_settle
	call	_set_msg_snd4
	call	_settle
	call	_OK
	call	_chk_ERROR
	btfsc	STATUS,	Z
	goto	_rf_is_on
	goto	_rf_end

_rf_is_off
	call	_settle	
	call	_set_msg_snd5
	call	_settle
	call	_OK
	call	_chk_ERROR
	btfsc	STATUS,	Z
	goto	_rf_is_off
	goto	_rf_end

_exec_al1
	movlw	0x00
	movwf	PORTB
_CMSS_n	call	_settle
	call	_set_msg_snd10
	call	_settle
	call	_OK
	call	_chk_ERROR
	btfsc	STATUS,	Z
	goto	_CMSS_n	
	return

_exec_al0
	movlw	0xFF
	movwf	PORTB
_CMSS_o	call	_settle
	call	_set_msg_snd11
	call	_settle
	call	_OK
	call	_chk_ERROR
	btfsc	STATUS,	Z
	goto	_CMSS_o
	return

_INVALID
	call	_settle
	call	_set_msg_snd7
	call	_settle
	call	_OK
	call	_chk_ERROR
	btfsc	STATUS,	Z
	goto	_INVALID
	goto	_THE_END

_THE_END

_exit	call	_settle
	call	_set_msg_del12
	call	_settle
	call	_OK
	call	_chk_ERROR
	btfsc	STATUS,	Z
	goto	_exit
	goto	_jmp_Accept_Cmds

;-------------------------------------------------------------------
;   DISPLAY USER DATA STRING TO ENSURE CORRECT TRUNCATION OF DATA
;-------------------------------------------------------------------
_disp	movf	chr1,	w
	call	_tx
	movf	chr2,	w
	call	_tx
	movf	chr3,	w
	call	_tx
	movf	chr4,	w
	call	_tx
	movf	chr5,	w
	call	_tx
	movf	chr6,	w
	call	_tx
	movf	chr7,	w
	call	_tx
	movf	chr8,	w
	call	_tx
	movf	chr9,	w
	call	_tx
	movf	chr10,	w
	call	_tx
	call	_CR_LF
	return	

_CR_LF	movlw	0x0A
	call	_tx
	movlw	0x0D
	call 	_tx
	return

;-------------------------------------------------------------------
;		RX FUNCTION 1
;-------------------------------------------------------------------

_rx1	btfss	PIR1,	RCIF
	goto	_rx1
	movf	RCREG,	w
	return

;-------------------------------------------------------------------
;		NEW MESSAGE AT MEMORY INDEX 12
;-------------------------------------------------------------------
_index_12?
_chk1_	call	_rx1
	movwf	buffr
	movlw	0x31 		
	subwf	buffr,	w
	btfss	STATUS,	Z
	goto	_chk1_
	goto	_chk_2	
	
_chk_2	call	_rx1
	movwf	buffr
	movlw	0x32
	subwf	buffr,	w
	btfss	STATUS,	Z
	goto	_chk_2
	return

;-------------------------------------------------------------------
;		AT+COMMAND TABLE INITIALIZATION
;-------------------------------------------------------------------
_set_msg_store
	call	_set_str_var_cpms
_shift1	movf	ch_cnt,	w
	call	_snd_cmd_cpms_me
	movwf	ch_buff
	call	_tx
	incf	ch_cnt,	f
	decfsz	countr,	f
	goto	_shift1
	return
	
_set_msg_indicatr
	call	_set_str_var_cnmi
_shift2	movf	ch_cnt,	w
	call	_snd_cmd_cnmi
	movwf	ch_buff
	call	_tx
	incf	ch_cnt,	f
	decfsz	countr,	f
	goto	_shift2
	return
	
_set_msg_snd1
	call	_set_str_var_cmss
_shift3	movf	ch_cnt,	w
	call	_snd_cmss_1
	movwf	ch_buff
	call	_tx
	incf	ch_cnt,	f
	decfsz	countr,	f
	goto	_shift3
	return

_set_msg_snd2
	call	_set_str_var_cmss
_shift4	movf	ch_cnt,	w
	call	_snd_cmss_2
	movwf	ch_buff
	call	_tx
	incf	ch_cnt,	f
	decfsz	countr,	f
	goto	_shift4
	return

_set_msg_snd3
	call	_set_str_var_cmss
_shift5	movf	ch_cnt,	w
	call	_snd_cmss_3
	movwf	ch_buff
	call	_tx
	incf	ch_cnt,	f
	decfsz	countr,	f
	goto	_shift5
	return

_set_msg_snd4
	call	_set_str_var_cmss
_shiftA	movf	ch_cnt,	w
	call	_snd_cmss_4
	movwf	ch_buff
	call	_tx
	incf	ch_cnt,	f
	decfsz	countr,	f
	goto	_shiftA
	return

_set_msg_snd5
	call	_set_str_var_cmss
_shiftB	movf	ch_cnt,	w
	call	_snd_cmss_5
	movwf	ch_buff
	call	_tx
	incf	ch_cnt,	f
	decfsz	countr,	f
	goto	_shiftB
	return

_set_msg_snd6
	call	_set_str_var_cmss
_shiftC	movf	ch_cnt,	w
	call	_snd_cmss_6
	movwf	ch_buff
	call	_tx
	incf	ch_cnt,	f
	decfsz	countr,	f
	goto	_shiftC
	return

_set_msg_snd7
	call	_set_str_var_cmss
_shiftD	movf	ch_cnt,	w
	call	_snd_cmss_7
	movwf	ch_buff
	call	_tx
	incf	ch_cnt,	f
	decfsz	countr,	f
	goto	_shiftD
	return

_set_msg_snd8
	call	_set_str_var_cmss
_shiftE	movf	ch_cnt,	w
	call	_snd_cmss_8
	movwf	ch_buff
	call	_tx
	incf	ch_cnt,	f
	decfsz	countr,	f
	goto	_shiftE
	return

_set_msg_snd9
	call	_set_str_var_cmss
_shiftF	movf	ch_cnt,	w
	call	_snd_cmss_9
	movwf	ch_buff
	call	_tx
	incf	ch_cnt,	f
	decfsz	countr,	f
	goto	_shiftF
	return

_set_msg_snd10
	call	_set_str_var_cmgd
_shiftG	movf	ch_cnt,	w
	call	_snd_cmss_10
	movwf	ch_buff
	call	_tx
	incf	ch_cnt,	f
	decfsz	countr,	f
	goto	_shiftG
	return

_set_msg_snd11
	call	_set_str_var_cmgd
_shiftH	movf	ch_cnt,	w
	call	_snd_cmss_11
	movwf	ch_buff
	call	_tx
	incf	ch_cnt,	f
	decfsz	countr,	f
	goto	_shiftH
	return

_set_msg_del12
	call	_set_str_var_cmgd
_shift8	movf	ch_cnt,	w
	call	_snd_cmd_cmgd_12
	movwf	ch_buff
	call	_tx
	incf	ch_cnt,	f
	decfsz	countr,	f
	goto	_shift8
	return

_set_msg_cmgl_0
	call	_set_str_var_cmss
_shift6	movf	ch_cnt,	w
	call	_snd_cmgl_0
	movwf	ch_buff
	call	_tx
	incf	ch_cnt,	f
	decfsz	countr,	f
	goto	_shift6
	return

_set_msg_AT
	call	_set_str_var_at
_shift7	movf	ch_cnt,	w
	call	_snd_cmd_AT
	movwf	ch_buff
	call	_tx
	incf	ch_cnt,	f
	decfsz	countr,	f
	goto	_shift7
	return

_set_CALL_USER
	call	_set_str_var_atd
_shiftI	movf	ch_cnt,	w
	call	_snd_cmd_ATD
	movwf	ch_buff
	call	_tx
	incf	ch_cnt,	f
	decfsz	countr,	f
	goto	_shiftI
	return

_set_END_CALL
	call	_set_str_var_ath
_shiftJ	movf	ch_cnt,	w
	call	_snd_cmd_ATH
	movwf	ch_buff
	call	_tx
	incf	ch_cnt,	f
	decfsz	countr,	f
	goto	_shiftJ
	return

;-------------------------------------------------------------------
;	AT+COMMAND DEFINE TABLE SETUP / VARIABLE INITIALIZATION
;-------------------------------------------------------------------
_set_str_var_cpms
	movlw	0x00
	movwf	ch_cnt
	movlw	d'23'
	movwf	countr
	return

_set_str_var_cnmi
	movlw	0x00
	movwf	ch_cnt
	movlw	d'16'
	movwf	countr
	return

_set_str_var_cmss
	movlw	0x00
	movwf	ch_cnt
	movlw	d'10'	
	movwf	countr
	return

_set_str_var_cmgd
	movlw	0x00
	movwf	ch_cnt
	movlw	d'11'	
	movwf	countr
	return

_set_str_var_at
	movlw	0x00
	movwf	ch_cnt
	movlw	d'3'
	movwf	countr
	return

_set_str_var_atd
	movlw	0x00
	movwf	ch_cnt
	movlw	d'16'
	movwf	countr
	return

_set_str_var_ath
	movlw	0x00
	movwf	ch_cnt
	movlw	d'4'
	movwf	countr
	return

;-------------------------------------------------------------------
;		RESET BYTES OF DATA STORAGE
;-------------------------------------------------------------------
_reset_char
	clrf	chr1
	clrf	chr2
	clrf	chr3
	clrf	chr4
	clrf	chr5
	clrf	chr6
	clrf	chr7
	clrf	chr8
	clrf	chr9
	clrf	chr10
	return

;-------------------------------------------------------------------
;		TX FUNCTION
;-------------------------------------------------------------------
_tx 	movwf	TXREG
_wait	BANK1
	btfss	TXSTA,	TRMT
	goto	_wait
	BANK0
	return	

;-------------------------------------------------------------------
;    	CHECK FRAMING BIT ERROR AND OVERRUN ERROR  
;	* RESET CREN WHEN IT ENCOUNTERS AN OVERRUN ERROR
;	* SAVE BYTE WHEN IT ENCOUNTERS A FRAMING ERROR
;-------------------------------------------------------------------
_rx_ERROR
	btfss	RCSTA,	OERR
	goto	_chk_FERR
	bcf	RCSTA,	CREN
	bsf	RCSTA,	CREN	
_chk_FERR
	btfss	RCSTA,	FERR
	goto	_out_rx
	movf	RCREG,	w
	movwf	temp

_out_rx goto	_rx

;-------------------------------------------------------------------
;    	MAIN RX FUNCTION 
;	* WILL NOT OVERWRITE REGISTER IF IT HAS A VALUE
;	* IF REGISTER'S VALUE = NULL, COPY SIGNIFICANT BYTE
;-------------------------------------------------------------------

_rx	btfss	PIR1,	RCIF
	goto	_rx_ERROR
		
_copy	movf	RCREG,	w
	movwf	chr_tmp
	movlw	0x00
	subwf	chr1,	w
	btfss	STATUS,	Z
	goto	_chk_chr_2	
	goto	_chr_1

_chk_chr_2	
	movlw	0x00
	subwf	chr2,	w
	btfss	STATUS,	Z
	goto	_chk_chr_3	
	goto	_chr_2

_chk_chr_3	
	movlw	0x00
	subwf	chr3,	w
	btfss	STATUS,	Z
	goto	_chk_chr_4	
	goto	_chr_3

_chk_chr_4	
	movlw	0x00
	subwf	chr4,	w
	btfss	STATUS,	Z
	goto	_chk_chr_5	
	goto	_chr_4

_chk_chr_5	
	movlw	0x00
	subwf	chr5,	w
	btfss	STATUS,	Z
	goto	_chk_chr_6	
	goto	_chr_5

_chk_chr_6	
	movlw	0x00
	subwf	chr6,	w
	btfss	STATUS,	Z
	goto	_chk_chr_7	
	goto	_chr_6

_chk_chr_7	
	movlw	0x00
	subwf	chr7,	w
	btfss	STATUS,	Z
	goto	_chk_chr_8	
	goto	_chr_7

_chk_chr_8	
	movlw	0x00
	subwf	chr8,	w
	btfss	STATUS,	Z
	goto	_chk_chr_9	
	goto	_chr_8

_chk_chr_9	
	movlw	0x00
	subwf	chr9,	w
	btfss	STATUS,	Z
	goto	_chk_chr_10	
	goto	_chr_9

_chk_chr_10	
	movlw	0x00
	subwf	chr10,	w
	btfss	STATUS,	Z
	goto	_bck	
	goto	_chr_10

_bck	return

;-------------------------------------------------------------------
;	SAVE SIGNIFICANT BYTES - USER DATA (TEXT MESSAGE)
;-------------------------------------------------------------------
_chr_1
	movf	chr_tmp,w
	movwf	chr1
	goto	_bck

_chr_2
	movf	chr_tmp,w
	movwf	chr2
	goto	_bck

_chr_3	
	movf	chr_tmp,w
	movwf	chr3
	goto	_bck

_chr_4
	movf	chr_tmp,w
	movwf	chr4
	goto	_bck

_chr_5
	movf	chr_tmp,w
	movwf	chr5
	goto	_bck

_chr_6
	movf	chr_tmp,w
	movwf	chr6
	goto	_bck

_chr_7
	movf	chr_tmp,w
	movwf	chr7
	goto	_bck

_chr_8
	movf	chr_tmp,w
	movwf	chr8
	goto	_bck

_chr_9
	movf	chr_tmp,w
	movwf	chr9
	goto	_bck

_chr_10
	movf	chr_tmp,w
	movwf	chr10
	goto	_bck

;-------------------------------------------------------------------
;	DELAY ROUTINE TO SETTLE THINGS UP
;-------------------------------------------------------------------
_settle	movlw 	0xFF
	movwf	buffr
_loop	decfsz	buffr,	f
	goto	_loop
	return

;-------------------------------------------------------------------
;	MAIN DELAY FUNCTION
;-------------------------------------------------------------------
_delay	movlw	0xff		
	movwf	num1
dlay1	movlw	0xff
	movwf	num
dlay0	decfsz	num, 	f
	goto	dlay0		
	decfsz	num1, 	f
	goto	dlay0		
	return

;-------------------------------------------------------------------
;	I/O PORTS, USART AND INTERRUPT INITIALIZATION
;	TRANSMIT & RECEIVE Status and Control Register Configuration
;
;	* Asynchronous Mode
;	* 8-bit Transmission
;	* 8-bit Reception
;	* High Speed Baud Rate
;	* Set Baud Rate Generator to 9600
;	* Enable Serial Port
;	* Enable Continuous Reception
;
;	* Disable Transmit & Receive Interrupt
;	* Enable RB0 External Interrupt (for the ALARM SYSTEM)
;-------------------------------------------------------------------
_init 	clrf	PORTA
	clrf	PORTB
	BANK0
	CMP_OFF

	BANK1
	movlw 	b'00000011'
	movwf	TRISB

	movlw	b'00011111'
	movwf	TRISA

	movlw 	d'25'
	movwf 	SPBRG

	movlw 	b'00100100'
	movwf	TXSTA

	BANK0
	movlw	b'10010000'
	movwf	RCSTA

	bcf	PIE1,	RCIE
	bcf	PIE1,	TXIE

	bsf	INTCON,	GIE
	bsf	INTCON,	INTE

	return
;-------------------------------------------------------------------
	END	