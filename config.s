; See LICENSE file for copyright and license details.

%ifndef CONFIG_S
%define CONFIG_S

section .rodata
; Location
	time_zone:	dq +3.0
	longitude:	dq 39.826168
	latitude:	dq 21.422510
	altitude:	dq 0.0

; calculation
	use_umm_al_qura	db 1
	ramadan		db 0

; Fajr Isha Asr
	fajr_angle	dq 18.5
	isha_angle	dq 17.0	; used if use_umm_al_qura = 0
	use_major	db 1	; Asr method, use hanafi if 0

;Muslim World League				18	17
;Umm al-Qura University, Makkah			18.5	autoset
;Egyptian General Authority of Survey		19.5	17.5
;Islamic Society of North America (ISNA)	15	15
;University of Islamic Sciences, Karachi	18	18
;Institute of Geophysics, University of Tehran	17.7	14*
;Shia Ithna Ashari, Qum				16	14

%endif ;CONFIG_S
