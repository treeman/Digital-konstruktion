NOTE: COREWAR, Get it @ http://www.koth.org/pmars/

- (Jonas)
    Ang�ende styrsignaler och skit


    * memory source address �r samma f�r alla minnen
        Vi beh�ver aldrig broadcasta d� alla minnen har samma address pekare.
    * ALU s�tter alltid Z
    * Du byggde ihop ALU och memory management? Och hanterar ej PC?
        Det �r v�ldigt opraktiskt att dra memory source address fr�n bussen om det var det du hade t�nkt?
        Vi saknar PC + ADR. ADR �r n�dv�ndig! D� vi m�ste spara den address vi vill anv�nda mellan olika mikrorader.

        Jag tror att det �r v�ldigt dumt att f�rs�ka kombinera ALU + prim�rminne, det �r l�ttare att kombinera alla olika signaler i en stor modul ist�llet.

        Vi vill minimera antalet styrsignaler?

        Jag t�nkte mig dessa styrsignaler till bussen:

        buss_in
            PC
            OP (-> IR)
            AR B (+ PC)
            FIFO
            I/O
            3 bit

        buss_out
            nothing
            PC
            M1
            M2
            OP
            ALU B (-> PC)
            IR
            FIFO
            4 bit

        Du har nu:

        buss_in
            3 x 2 bit bara memory source data (beh�ver inte skicka till bussen dock, eventuellt OP)
            3 bit buss_output

            och d� saknar vi FIFO, I/O

        buss_out
            3 x 2 bit samma?
                eller
            3 bit buss_output

            saknar FIFO, IR

        S� jag anser att vi inte k�r som du g�r nu, utan vi f�rs�ker definiera globala styrsignaler liknande jag gjort i filen styrsignaler.


    * Saknade styrsignaler:
        ALU action

    * Jag f�resl�r att du bryter ut ALU och minneshanteringen i separata moduler.

        Man skulle kanske t�nka sig s�h�r:

        ALU:n kommer vara j�tteenkel med signaler:

            ALU A in 13 bit
            ALU B in 13 bit

            Styrsignal
            ALU action in 3? bit

            skriver alltid ut
            AR A out 13 bit
            AR B out 13 bit

            Z out 1 bit

        Och minneshanteringen kan g�ra:

            OP in/ut 8 bit
            M1 in/ut 13 bit
            M2 in/ut 13 bit

            ADR in 13 bit

            Styrsignaler
            OP action in 2 bit (l�s in, skriv ut, g�r inget)
            M1 action in 2 bit
            M2 action in 2 bit

            mem1 read/write in 2 bit
            mem2 read/write in 2 bit
            mem3 read/write in 2 bit

            1 bit grafik reset?

        Resterande d v s i stort sett alla muxar styrs fr�n main module. Jag tror att detta blir mycket l�ttare d�rf�r att

        1. Vi styr hela bussen d�rifr�n
        2. Vi styr i stort sett alla muxar fr�n ett st�lle
           Vilket g�r att vi kan ha lite if satser och g�r typ
               if styr_buss_in = "0001" then
                   buss = OP

               if styr_buss_ut = "0100" then
                   IR = buss

               o s v

           F�r muxarna sitter alltid f�re/efter store moduler s� v�r main module f�r som uppgift att l�sa styrsignaler och rerouta signaler vars de ska. Blir mycket renare och l�ttare att h�lla reda p�.

    Eller vad anser du?
