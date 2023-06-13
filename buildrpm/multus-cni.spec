{{{$version := printf "%s.%s.%s" .major .minor .patch}}}

%global debug_package %{nil}
%global build_dir src/github.com/projectcalico/calicoctl

%global app_name multus-cni
%global app_version {{{$version}}}
%global oracle_release_version 1

Name:           %{app_name}
Version:        %{app_version}
Release:        %{oracle_release_version}%{?dist}
Summary:        Multus CNI
License:        Apache 2.0
Url:            https://github.com/k8snetworkplumbingwg/multus-cni
Source:         %{name}-%{version}.tar.bz2
Vendor:         Oracle America
BuildRequires:  git
BuildRequires:  golang >= 1.18

%description
Multus CNI is a container network interface (CNI) plugin for Kubernetes that enables attaching multiple network interfaces to pods.


%prep
%setup -n %{name}-%{version}


%build
./hack/build-go.sh


%install
install -D -m 755 bin/multus %{buildroot}%{_bindir}/multus
install -D -m 755 bin/multus-daemon %{buildroot}%{_bindir}/multus-daemon
install -D -m 755 bin/multus-shim %{buildroot}%{_bindir}/multus-shim
install -D -m 755 bin/install_multus %{buildroot}%{_bindir}/install_multus
install -D -m 755 bin/thin_entrypoint %{buildroot}%{_bindir}/thin_entrypoint


%files
%license LICENSE THIRD_PARTY_LICENSES.txt
%attr(755,root,root) %{_bindir}/multus
%attr(755,root,root) %{_bindir}/multus-daemon
%attr(755,root,root) %{_bindir}/multus-shim
%attr(755,root,root) %{_bindir}/install_multus
%attr(755,root,root) %{_bindir}/thin_entrypoint


%changelog
* {{{.changelog_timestamp}}} - %{version}-%{oracle_release_version}
- Added Oracle specific files for multus-cni
- Removed generate-kubeconfig
- Added multus-daemon, multus-shim, install_multus, thin_entrypoint
