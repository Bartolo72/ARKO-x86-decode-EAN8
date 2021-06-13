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
        xor	    esi, esi			    ;where binary code of number is
        xor 	edx, edx			    ;checksum
        xor	    ecx, ecx			    ;for counters
        mov     edi, 8
        mov     dx, [ebx]

check_101:
        mov     cl, 3                   ;counter of 101 sequence
check_101_loop:
        call    check_bits              ;get bits of column
        dec     cl                      ;decrement cl
        test    cl, cl                  ;check if cl == 0
        jnz     check_101_loop          ;if not repeat
check_101_value:
        mov     cl, [prefix]
        cmp     ecx, esi                ;compare prefix with read value
        jne     error_bits              ;if not the same barcode is invalid
        xor     esi, esi                ;prepare for numbers decoding
        xor     ecx, ecx

decode_left_numbers:
        mov     ch, 7                   ;counter of bits for one number
        mov     cl, 4                   ;counter of number left to decode
number_loop:
        call    check_bits              ;get bits of column
        dec     ch
        test    ch, ch
        jnz     number_loop             ;if not each column has been decoded repeat
number_value:
        push    ebx
        push    ecx

        mov     ecx, -1                 ;value which will move pointer to codes_values
number_value_loop:
        mov     ebx, codes_left
        inc     ecx
        mov     bl, [ebx + ecx]         ;get next code
        xor     bh, bh
        cmp     si, bx                  ;check if equal
        jne     number_value_loop
        mov     [eax], cl               ;put index of code in *out buff
        inc     eax

        pop     ecx
        pop     ebx
next_number:
        xor     esi, esi
        dec     cl
        test    cl, cl
        jz      middle
        mov     ch, 7
        jmp     number_loop

middle:
        xor     ecx, ecx
        mov     cl, 5
middle_loop:
        call    check_bits
        dec     cl
        test    cl, cl
        jnz     middle_loop
middle_value:
        xor     ecx, ecx
        mov     cl, [middle_v]
        cmp     ecx, esi
        jne     error_bits
        xor     esi, esi

decode_right_numbers:
        xor     ecx, ecx
        mov     ch, 7
        mov     cl, 4
r_number_loop:
        call    check_bits
        dec     ch
        test    ch, ch
        jnz     r_number_loop
r_number_value:
        push    ebx
        push    ecx

        mov     ecx, -1
r_number_value_loop:
        mov     ebx, codes_right
        inc     ecx
        mov     bl, [ebx + ecx]
        xor     bh, bh
        cmp     si, bx
        jne     r_number_value_loop
        mov     [eax], cl
        inc     eax

        pop     ecx
        pop     ebx
next_r_number:
        xor     esi, esi
        dec     cl
        test    cl, cl
        jz      checksum
        mov     ch, 7
        jmp     r_number_loop

checksum:
        xor     edx, edx
        xor     ecx, ecx
        xor     ebx, ebx
        xor     edi, edi
        mov     eax, [ebp + 8]
checksum_loop:
        cmp     dl, 7
        je      checksum_value
        mov     bl, [eax + edx]
        mov     edi, ebx
        inc     edx
        mov     bh, dl
        shl     bh, 7                     ;modulo 2
        test    bh, bh
        jz      checksum_even_number
checksum_odd_number:
        lea     edi, [edi + edi*2]
        lea     ecx, [edi + ecx]
        xor     bh, bh
        jmp     checksum_loop
checksum_even_number:
        lea     ecx, [edi + ecx]
        xor     bh, bh
        jmp     checksum_loop
checksum_value:
        xor     eax, eax
        xor     ebx, ebx
        mov     bl, 10
        mov     eax, ecx
        div     bl
        xor     al, al
        sub     bl, al
        cmp     bl, 10
        jne     checksum_check
        xor     bl, bl
checksum_check:
        mov     eax, [ebp + 8]
        mov     cl, [eax + 7]
        cmp     bl, cl
        jne     error_bits
        jmp     epilog



check_bits:
        push    ecx

        xor     ecx, ecx
        mov     ch, [ebp + 16]              ;pixels per one column
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
        test    cl, cl
        jz      check_bits_white
check_bits_black:
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