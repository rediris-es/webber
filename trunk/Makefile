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
LOG= ${VAR}/log/webber/
HTML=${VAR}/www/html/webber

IC=install

# Parece que el install de MacOs no es todo lo bueno que quisieramos

install: ; \
	mkdir -p $(BIN)
	${IC}   webber  ${BIN}
	mkdir -p $(LIB)/webber/proc
	${IC} -p proc/* ${LIB}/webber/proc
	mkdir -p $(DOC)/webber/
#	$(IC)  -d doc/*  $(DOC)/webber
	$(IC) readme $(DOC)/webber
	$(IC) leeme $(DOC)/webber
	mkdir -p $(ETC)/webber/
	${IC}  webber.wbb ${ETC}/webber/
	mkdir -p $(LOG)

install_apache: ; \
	mkdir -p $(ETC)/httpd/conf.d/
	mkdir -p $(ROOT)/usr/lib/perl5/5.8.8/Webber
	$(IC) dynamic/mod_perl2/webber.conf $(ETC)/httpd/conf.d/
	$(IC) dynamic/mod_perl2/readme-modperl2.txt $(DOC)/webber/
	$(IC) dynamic/mod_perl2/apache-config.xml $(ETC)/webber/
	$(IC) dynamic/mod_perl2/Webber/*  $(ROOT)/usr/lib/perl5/5.8.8/Webber/
	$(IC) dynamic/mod_perl2/startup.pl $(ROOT)/usr/lib/perl5/5.8.8/Webber/
	mkdir -p $(HTML)
	$(IC) dynamic/mod_perl2/example/* $(HTML)

