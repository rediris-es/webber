Name: webber
Version: 1.3.1
Release: 1
Source0:   webber.tgz 
Group: web/CMS
URL: http://www.rediris.es/webber/
License: GPL
Summary: HTML page generator
Buildroot: %{_tmppath}/%{name}-%{version}-buildroot
#BuildRequires: 
#Requires: 
BuildArch: noarch

%description

Webber is a perl program used at RedIRIS to generate most
of the static HTML contents. The main idea behind webber
is that you only need to write the content of the HTML
pages (the information you want to show) and webber can
generate automagically all the surroinding (menus, navigation
bar, style , etc), so it's quite easy to rebuild with a different
look & feel the web pages.


%prep
%setup -q -n webber

%build
# No build for now

%install

cd trunk
make ROOT=%{buildroot} -B install



%clean
rm -rf %{buildroot}

%post
# Post installation script here


%preun
# Pre run scripts here

%files
%defattr(-,root,root)
%doc /usr/share/doc/webber/ 
%config /etc/webber/
/usr/bin/webber
/usr/lib/webber/
/var/log/webber/

%changelog
* Wed Apr  15 2009 Francisco Monserrat <francisco.monserrat@rediris.es>
- initial rpm package 
