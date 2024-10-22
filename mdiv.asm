global mdiv

section .text

; rdi -> x (pointer na dzielnej) [znak -> r8b]
; rsi -> n (dlugosc dzielnej) -> r10
; rdx -> y (dzielnik) -> rcx [znak -> r9b]
; przechowujemy informacje o znakach w r8b i r9b | rejestr = 0 to -> - | 1 -> +/0

; ogolne dzialanie nastepujace: zapisujemy znaki x i y po czym negujemy liczbe jezeli jest ujemna. Pozniej dzielimy liczby bez znaku
; i odpowiednio negujemy wynik tego dzielenia (iloraz i reszte) zaleznie od znakow zapisanych na poczatku.

mdiv:
	mov rcx, rdx						; od teraz dzielnik bedzie w rcx
	mov r10, rsi						; zapisujemy n
	xor eax, eax						; to bedzie iterator negacji x
	xor r8b, r8b
	mov r11b, 1							; od teraz r11b bedzie sluzyl do zapisywania informacji o stanie flagi CF
	cmp qword [rdi + rsi * 8 - 8], 0	; zapisujemy znaki dzielnej
	js .negateX1
	mov r8b, 1
.powrot1x:								; zapisujemy znak dzielnika
	cmp rdx, 0
	js .negativeY						; skaczemy jezeli y ujemny
	mov r9b, 1
.poczDzielenia:							; od tego momentu implementujemy niejako dzielenie pisemne
	dec r10								; bedziemy dzielic na poczatku tylko pierwszy segment zeby pozniej nie wystapil overflow przy instrukcji div
	xor rdx, rdx
	mov rax, [rdi + r10 * 8]			; dzielimy najbardziej znaczace 64 bity
	div rcx								; iloraz -> rax | reszta -> rdx
	mov [rdi + r10 * 8], rax			; ustawiamy najbardziej znaczace 64 bity wyniku
.loop:									; teraz juz zwykle dzielenie pisemne
	cmp r10, 1							; sprawdzamy czy to ostatni segment
	jl .koniec
	dec r10
	mov rax, [rdi + r10 * 8]			; do rax kolejny segment, reszta z wczesniejszego dzielenia juz znajduje sie w rdx
	div rcx								; reszta -> rdx | iloraz -> rax
	mov [rdi + r10 * 8], rax			; ustawiamy kolejny segment wyniku
	jmp .loop
.koniec:								; odzielamy przypadki i odpowiednio negujemy wynik
	add r8b, r9b
	xor eax, eax
	mov r11b, 1							; ustawiamy rejestr przechowujacy CF zeby za pierwszym razem w petli sprobowac dodac 1
	cmp r8b, 1							; r8 = 1 -> iloraz musi byc ujemny (x i y maja rozne znaki)
	je .negateX2						; skaczemy do negacji ilorazu
	cmp qword [rdi + (rsi - 1) * 8], 0  ; sprawdzamy czy jest overflow
	jl .of
.powrot2x:								; bedziemy negowali (lub nie) reszte
	sub r8b, r9b						; przywracamy poprzedni znak w r9
	cmp r8b, 0							; jezeli r8 == 0 to negujemy reszte (dzielna ujemna)
	je .negateY
	mov rax, rdx						; na samym koncu przenosimy reszte do rax
	ret
.negativeY:
	mov r9b, 0							; oznaczamy znak y
	neg rcx
	jmp .poczDzielenia
.negateX1:								; negujemy x na poczatku
	cmp rax, rsi						; musimy zrobic xor z -1 i dodac jeden do x aby zanegowac
	je .powrot1x
	xor qword [rdi + rax * 8], -1
	cmp r11b, 1							; czy jest CF
	je .zwieksz1						; jezeli tak to znaczy ze wczesniej nie zmiescila sie jedynka i musimy ja dodac do tego segmentu
	inc rax
	jmp .negateX1
.zwieksz1:								; dodajemy jeden do segmentu gdy CF = 1
	add qword [rdi + rax * 8], 1
	setc r11b							; spawdzamy czy zmiescila sie jedynka i zapisujemy w r11b
	inc rax
	jmp .negateX1
.negateX2:								; negujemy podobnie jak wyzej
	cmp rax, rsi
	je .powrot2x						; koniec tablicy ilorazu
	xor qword [rdi + rax * 8], -1
	cmp r11b, 1							; czy jest CF
	je .zwieksz2
	inc rax
	jmp .negateX2
.zwieksz2:								; dzialanie takie samo jak w x1
	add qword [rdi + rax * 8], 1
	setc r11b
	inc rax
	jmp .negateX2
.of:									; wywolujemy oveflowa dzielac przez 0
	mov r10, 0
	div r10
.negateY:								; negujemy dzielnik i konczymy dzialanie
	neg rdx
	mov rax, rdx
	ret
