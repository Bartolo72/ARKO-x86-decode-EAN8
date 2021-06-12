section         .rodata
prefix:         db 00000010b
middle_v:       db 00010101b
codes_right:    db 00001101b, 00011001b, 00010011b, 00111101b, 00100011b, 00110001b, 00101111b, 00111011b, 00110111b, 00001011b
codes_left:     db 01110010b, 01100110b, 01101100b, 01000010b, 01011100b, 01001110b, 01010000b, 01000100b, 01001000b, 01110100b
section         .text
global          decode_ean8

decode_ean8:
        push 	ebp
        mov	    ebp, esp
        push	ebx
        push	edx
        push	ecx
        push	esi
        push	edi

        mov     eax, [ebp + 8]
        mov	    ebx, [ebp + 12]			;void *img
        mov	    edi, -1			        ;counter for current byte
        xor	    esi, esi			    ;where binary code of number is
        xor 	edx, edx			    ;checksum
        xor	    ecx, ecx			    ;for counters
        mov     edi, 8
        mov     dx, [ebx]

check_101:
;1) set $cl to 3
        mov     cl, 3
check_101_loop:
;1) go to check_bits
;2) decrement $cl
;3) shift left $esi
;4) if $cl != 0 go to check_101_loop
        call    check_bits
        dec     cl
        test    cl, cl
        jnz     check_101_loop
check_101_value:
;1) mov prefix to $ecx
;2) negation of $esi
;3) compare $ecx and $esi
;4) if not equal go to error_bits
;5) xor $esi and $ecx !(?)!
        mov     cl, [prefix]
        cmp     ecx, esi
        jne     error_bits
        xor     esi, esi
        xor     ecx, ecx

decode_first_numbers:
;1) set two counters - 7 and 4 in $ch and $cl
        mov     ch, 7
        mov     cl, 4
decode_number_loop:
;1) go to check_bits
;2) dec $dh
;3) shift left $esi <- space for next bit
;4) if $dh != 0, go to decode_number_loop
        call    check_bits
        dec     ch
        test    ch, ch
        jnz     decode_number_loop
decode_number_value:
;1) push $ebx, and $ecx
;2) set $ch to 0
        push    ebx
        push    ecx

        mov     ecx, -1
decode_number_value_loop:
;1) mov left_codes + $ch to $ebx
;2) compare $esi and $ebx
;3) increment $ch
;4) if not equal go to decode_number_value_loop
;5) save $ch to $eax
;6) decrement $al
;7) pop $ebx, $ecx
        mov     ebx, codes_left
        inc     ecx
        mov     bl, [ebx + ecx]
        xor     bh, bh
        cmp     si, bx
        jne     decode_number_value_loop
        mov     [eax], cl
        inc     eax

        pop     ecx
        pop     ebx
decode_next_number:
;1) if $dl == 0 go to middle
;2) set $dh to 7 again
;3) go to decode_number_loop
        xor     esi, esi
        dec     cl
        test    cl, cl
        jz      middle
        mov     ch, 7
        jmp     decode_number_loop

middle:
;1) set $cl to 5
        xor     ecx, ecx
        mov     cl, 5
middle_loop:
;1) go to check bits
;2) decrement $cl
;3) shift left $esi <- value for next bit
;4) if $cl != 0 go to middle_loop
        call    check_bits
        dec     cl
        test    cl, cl
        jnz     middle_loop
middle_value:
;1) mov middle (data) to $ecx
;2) compare middle and $esi
;3) if not equal go to error_bits
;4) xor $esi, $ecx
        xor     ecx, ecx
        mov     cl, [middle_v]
        cmp     ecx, esi
        jne     error_bits
        xor     esi, esi

decode_lnumbers:
;1) set two counters - 7 and 3 in $dh and $dl
        xor     ecx, ecx
        mov     ch, 7
        mov     cl, 4
decode_lnumber_loop:
;1) go to check_bits
;2) dec $dh
;3) shift left $esi <- space for next bit
;4) if $dh != 0, go to decode_lnumber_loop
        call    check_bits
        dec     ch
        test    ch, ch
        jnz     decode_lnumber_loop
decode_lnumber_value:
;1) push $ebx, and $ecx
;2) set $ch to 0
        push    ebx
        push    ecx

        mov     ecx, -1
decode_lnumber_value_loop:
        mov     ebx, codes_right
        inc     ecx
        mov     bl, [ebx + ecx]
        xor     bh, bh
        cmp     si, bx
        jne     decode_lnumber_value_loop
        mov     [eax], cl
        inc     eax

        pop     ecx
        pop     ebx
decode_next_lnumber:
        xor     esi, esi
        dec     cl
        test    cl, cl
        jz      epilog
        mov     ch, 7
        jmp     decode_lnumber_loop

;checksum:
;1) xor $edx
;2) set counter $cl to 0
;        xor     edx, edx
;        xor     ecx, ecx
;        xor     ebx, ebx
;checksum_loop:
;1) check if $cl == 7 if yes go to checksum_check
;2) mov [$eax + $cl] to $ebx
;3) add $edx, $ebx*3
;4) increment $cl
;5) mod%2 if value == 0 go to checksum_even_number
;        cmp     dl, 7
;        je      checksum_check
;        mov     ebx, [eax + edx]
;        inc     edx
;        shr     ebx, 1                      ;modulo 2
;        test    ebx, ebx
;        jz      checksum_even_number
;checksum_odd_number:
;        lea     ecx, [ebx + ebx*2]
;        jmp     checksum_loop
;checksum_even_number:
;        lea     ecx, ebx
;        jmp     checksum_loop
;checksum_check:
;1) compare $edx with $esi
;2) if not equal go to error_bits
;3) daj index tej wartości do eax
;modulo_10:
;        push    eax
;        mov     eax, edx
;        push    edx
;        push    ebx
;        mov     ebx, 10
;        div     ebx
;        test    edx, edx
;        cmp     edx, esi
;        jne     error_bits
;        jmp     epilog


check_bits:
;1) push $edx and $ecx, then get byte into $dl
;2) mov $edi into $ch - number of pixel in one column
;3) shift left $dl (get first bit to $dh)
;4) move $dh to $cl
        push    ecx

        xor     ecx, ecx
        mov     ch, [ebp + 16]
check_bits_get_byte:
        test    edi, edi
        jz      get_byte
check_bits_byte:
        xor     dh, dh
        shl     dx, 1
        mov     cl, dh
        dec     ch
        dec     edi
check_bits_loop:
;1) xor $dh and shift left $dl
;2) check whether $dl is empty if yes go to check_bits
;3) compare $dh and $cl if not the same go to error_bits
;4) move $cl to $dh
;5) decrement $ch
;6) if $ch != 0 go to check_bits
        test    ch, ch
        jz      check_bits_write_value
        test    edi, edi
        jz      get_byte
        cmp     dh, cl
        jne     error_bits
        xor     dh, dh
        shl     dx, 1
        dec     ch
        dec     edi
        jmp     check_bits_loop
check_bits_write_value:
;1) test $cl if zero go to check_bits_white
;2) increment $esi
        test    cl, cl
        jz      check_bits_white
        shl     esi, 1
        inc     esi
        jmp     check_bits_return
check_bits_white:
        shl     esi, 1
check_bits_return:
        pop     ecx
        ret

get_byte:
        mov     edi, 8
        inc     ebx
        mov     dl, [ebx]
        jmp     check_bits_byte

error_bits:
;1) leave *out buff empty
        xor     eax, eax

epilog:
	    pop	    edi
	    pop	    esi
	    pop	    ecx
	    pop	    edx
	    pop	    ebx
	    mov	    esp, ebp
	    pop     ebp
	    ret