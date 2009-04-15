### Makefile de Webber
#
# Instalacion de webber
# binario BIN/webber
# Proc {Librerias} LIB/WEBBER
# configuracion {principal} ETC/webber/webber.conf
# logs VAR/webber/

#ROOT=
USR=${ROOT}/usr
BIN=${USR}/bin
LIB=${USR}/lib
VAR=${ROOT}/var
DOC=$(USR)/share/doc/
ETC=${ROOT}/etc

IC=install

# Parece que el install de MacOs no es todo lo bueno que quisieramos

install: ; \
	mkdir -p $(BIN)
	${IC}   webber  ${BIN}
	mkdir -p $(LIB)/webber/proc
	${IC} -d proc/ ${LIB}/webber/proc
	mkdir -p $(DOC)/webber/
	$(IC)  -d doc  $(DOC)/webber
	$(IC) readme $(DOC)/webber
	$(IC) leeme $(DOC)/webber
	$(IC install $(DOC)/webber
	mkdir -p $(ETC)/webber/
	${IC}  webber.wbb ${ETC}/webber/
	mkdir -p $(VAR)/log/webber
	
