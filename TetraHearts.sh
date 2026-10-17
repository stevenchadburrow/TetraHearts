

../rgbasm -o TetraHearts.o TetraHearts.asm ;
../rgblink -o TetraHearts.gb TetraHearts.o ;
../rgbfix -v -p 0xFF TetraHearts.gb ;
../PICboy.o TetraHearts.gb 000 ;

