NOTE: COREWAR, Get it @ http://www.koth.org/pmars/

- (Jesper)  Kommentarer till Blockschemat:
    *   V�r UART arbetar med 8 bitar och vi anv�nder 13 bitar �ver allt annat i maskinen. Jag anser att vi bygger n�got som tar 2 st 8 bitars medelanden och bygger ihop dem till ett 16 bitars medelande d�r de 3 f�rsta kan vara kontroll bitar (kommandon, etc).
    *   Vi beh�ver en r�nkade till �Datorn s� vi kan st�lla in hur l�ng tid det ska g� mellan varje instruktion (fr�n m�te med handledare).

- (Jonas)
    * Ja. Enklast vore att bara ha ett tv�delat register mellan input och bussen d�r vi fyller ena sidan, sen den andra och sen skickar ut p� bussen. Kan sk�tas av mikrokod ganska simpelt?
    * Ja.

- (Jonas)
    * Har uppdaterat blockschemat. Har delat ut lite in/ut signaler till vissa saker.

      Jag tycker att det h�r ska vi klara av denna vecka:

      * H�mta ut v�r FPGA
      * Rita ut en fyrkant med VGA
      * H�mta en 13 bit input genom uart
      * Dela upp ansvarsomr�den att implementera (tycker VGA + uart g�rs genemsamt, iaf VGA:n)
        Dela upp ut/in signaler i v�ra block.

      Eller vad s�gs?

