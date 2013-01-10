# making a new version:
#    change version number near top of program
#    change version number in *TWO PLACES* in /home/bcrowell/Documents/web/source/when/when.source
#    make install (so make test will run the right version)
#    make test
#    make debian (see password file for password)
#    make post
#    touch /home/bcrowell/Documents/web/source/when/when.source
#    cd /home/bcrowell/Documents/web/source && make
# Update it on freecode.com.
# Updating manpage doesn't work right, for reasons I don't understand. M4 seems to remember
# the previous version of manpage.txt rather than reading it in afresh. To work around this,
# need to rename it to something other than manpage.txt, alter the when.source file to refer
# to the new name, run M4.
# Formatting of holidays section of manpage is also messed up. Fixed by hand in html version.
# M4 tries to carry out the stuff about M4 in the manpage, so fix that by hand.

FILES = when Makefile README when.1

prefix=/usr
exec_prefix=$(prefix)
bindir=$(exec_prefix)/bin

MANDIR = $(prefix)/share/man/man1

# The following two lines are used only for Debian packaging:
MAINTAINER_EMAIL = debiancrowell05@lightandmatter.com
#                       ... can't change this, or it breaks the script
MAINTAINER_NAME = Ben Crowell
# ... This is also in debian_stuff/control
VERSION = `perl when --bare_version`
DEB_NAME = when-$(VERSION)
DEB_SCRATCH = $(DEB_NAME)
DEB_TARBALL = $(DEB_NAME).tar.gz

default:
	# No compilation is required. The file ``when'' contains the
	# Perl source code. See the README file for information on how
	# to view the documentation.

install: when.1
	perl -e 'open(F,"<when") or die "file not found"; local $$/; $$code = <F>; close F; open(F,">temp") or die "error writing"; print F "#!".`which perl`."\n$$code"; close F;'
	# ... make sure it starts with the proper #! line, regardless of whether we're on Linux, BSD, etc.
	- test -d $(DESTDIR)$(bindir) || mkdir -p $(DESTDIR)$(bindir)
	# ... if the intended directory doesn't exist, create it
	install -m 755 temp $(DESTDIR)$(bindir)/when
	# ... 755=u:rwx,go:rx
	rm temp
	gzip -9 <when.1 >when.1.gz
	- test -d $(DESTDIR)$(MANDIR) || mkdir -p $(DESTDIR)$(MANDIR)
	install -m 644 when.1.gz $(DESTDIR)$(MANDIR)
	rm -f when.1.gz

deinstall:
	rm -f $(DESTDIR)$(bindir)/when
	rm -f $(DESTDIR)$(MANDIR)/when.1.gz

dist: when.tar.gz debian
	#

when.tar.gz: $(FILES) when.1
	rm -Rf when_dist
	mkdir when_dist
	cp $(FILES) when_dist
	cp -R debian_stuff when_dist/debian_stuff
	tar -zcvf when.tar.gz when_dist
	rm -Rf when_dist

clean:
	rm -Rf when*.tar.gz
	rm -f when.1.gz
	rm -Rf $(DEB_SCRATCH) *.deb *.dsc *.asc *.changes *.diff.gz
	rm -Rf debian_stuff/*~
	rm -f *~
	rm -f when.1

post: when.tar.gz when when.1
	cp when.tar.gz $(HOME)/Lightandmatter/when
	cp when_$(VERSION)-debian-source.tar.gz $(HOME)/Lightandmatter/when
	cp when_$(VERSION)-*_all.deb $(HOME)/Lightandmatter/when
	make_plain_text_manpage.pl >$(HOME)/Documents/web/source/when/manpage.txt

when.1: when
	pod2man --section=1 --center="When $(VERSION)" --release="$(VERSION)" \
	        --name=WHEN <when >when.1

debian: when.1
	# debian source package
	echo $(VERSION)
	mkdir $(DEB_SCRATCH)
	cp $(FILES) $(DEB_SCRATCH)
	tar -zcf $(DEB_TARBALL) $(DEB_SCRATCH)
	-cd $(DEB_SCRATCH) && export DEBFULLNAME='$(MAINTAINER_NAME)' && dh_make -e "$(MAINTAINER_EMAIL)" -s -copyright GPL -f ../$(DEB_TARBALL)
	cp debian_stuff/* $(DEB_SCRATCH)/debian
	cd $(DEB_SCRATCH)/debian && ls && rm *.ex *.EX README.Debian
	cd $(DEB_SCRATCH) && dpkg-buildpackage -rfakeroot
	rm -Rf $(DEB_SCRATCH)
	rm -Rf when_$(VERSION)
	mkdir when_$(VERSION)
	cp when_$(VERSION).orig.tar.gz when_$(VERSION)
	-cp when_$(VERSION)-*.diff.gz when_$(VERSION)
	cp when_$(VERSION)-*.dsc when_$(VERSION)
	tar -zcf when_$(VERSION)-debian-source.tar.gz when_$(VERSION)
	rm -Rf when_$(VERSION)

test:
	when --test_accent_filtering
	when --language="en" --test_expression="2004 dec 25,1,m=dec & d=25,should match"
	when --language="en" --test_expression="2004 dec 26,0,m=dec & d=25,should not match"
	when --language="en" --test_expression="2004 jan  1,1,d=1 | d=15,test | operator"
	when --language="en" --test_expression="2004 jan 15,1,d=1 | d=15,test | operator"
	when --language="en" --test_expression="2004 jan 10,0,d=1 | d=15,test | operator"
	when --language="en" --test_expression="2004 jan  1,1,m=jan & (d=1 | d=15),test parentheses"
	when --language="en" --test_expression="2004 jan 15,1,m=jan & (d=1 | d=15),test parentheses"
	when --language="en" --test_expression="2004 feb 15,0,m=jan & (d=1 | d=15),test parentheses"
	when --language="en" --test_expression="2004 jan 10,0,m=jan & (d=1 | d=15),test parentheses"
	when --language="en" --test_expression="2004 jan 10,0,((d=1 | d=15)),nested parens should be ok"
	when --language="en" --test_expression="2004 jan 10,0,(d=1 | d=15),single parens should not cause error"
	when --language="en" --test_expression="2004 jan  1,1,(d=1 | d=15),single parens should not cause error"
	when --language="en" --test_expression="2004 jan 15,1,(d=1 | d=15),single parens should not cause error"
	when --language="en" --test_expression="2004 dec 25,1,y=2004,test year"
	when --language="en" --test_expression="2004 dec 25,1,m=dec,test month"
	when --language="en" --test_expression="2004 dec 25,1,m=12,test month, numerical"
	when --language="en" --test_expression="2004 dec 25,1,d=25,test day"
	when --language="en" --test_expression="2004 dec 25,1,w=sat,test day of week"
	when --language="en" --test_expression="2004 dec 25,0,w=wed,test day of week"
	when --language="en" --test_expression="2004 dec 25,0,!m=dec,test ! operator"
	when --language="en" --test_expression="2004 jan 25,1,!m=dec,test ! operator"
	when --language="en" --test_expression="2004 dec 25,1,!!m=dec,double negative, !!"
	when --language="en" --test_expression="2004 dec 25,0,!(m=dec & d=25),test !(...)"
	when --language="en" --test_expression="2004 jan 25,1,!(m=dec & d=25),test !(...)"
	when --language="en" --test_expression="2005 jan 15,1,j=53386,test j variable"
	when --language="en" --test_expression="2005 jan 25,1,!(j%14),test % operator"
	when --language="en" --test_expression="2005 jan 26,1,j%14,test % operator"
	when --language="en" --test_expression="2005 jan 26,1,!(j%14-1),test - operator"
	when --language="en" --test_expression="2005 jan 27,0,!(j%14-1),test - operator"
	when --language="en" --test_expression="2007 apr 8,1,e=0,test e (Easter) variable"
	when --language="en" --orthodox_easter --test_expression="2008 apr 27,1,e=0,test e (Easter) variable for Orthodox calendar"
	when --language="en" --test_expression="2010 jan 1,1,z=1,day of year variable"
	when --language="en" --test_expression="2009 nov 10,1,z=314,day of year variable"
	when --language="en" --test_expression="2010 jul 4,1,c=0-1,c variable, for a weekend"
	when --language="en" --test_expression="2010 jul 5,1,c=4,c variable, for a Monday"
	when --language="en" --test_expression="2015 jul 3,1,c=4,c variable, for a Friday"
	when --language="en" --test_expression="2012 jul 4,1,c=0-1,c variable, for a Tu-Th weekday"
	when --language="en" --test_expression="2011 mar 11,1,w=f,unambiguous single-letter literal for weekday"
	when --language="en" --test_expression="2011 mar 10,e,w=t,ambiguous single-letter literal for weekday"
	when --language="en" --test_expression="2011 mar 10,1,m%6=3,parser properly differentiates m=... (month literal expected on r.h.s.) from m%..."
