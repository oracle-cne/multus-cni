{{{$version := printf "%s.%s.%s" .major .minor .patch}}}

%global debug_package %{nil}
{{{- if semverCompare "<4.2.1" $version }}}
%global build_dir src/github.com/projectcalico/calicoctl
{{{- end }}}

%global app_name multus-cni
%global app_version {{{$version}}}
%global oracle_release_version 1
%ifarch %{arm} arm64 aarch64
%global custom_arch linux/arm64
%else
%global custom_arch linux/amd64
%endif

Name:           %{app_name}
Version:        %{app_version}
Release:        %{oracle_release_version}%{?dist}
Summary:        Multus CNI
License:        Apache 2.0
Url:            https://github.com/k8snetworkplumbingwg/multus-cni
Source:         %{name}-%{version}.tar.bz2
Vendor:         Oracle America
BuildRequires:  git
BuildRequires:  golang >= 1.21.0
Patch0:		build-go.patch

%description
Multus CNI is a container network interface (CNI) plugin for Kubernetes that enables attaching multiple network interfaces to pods.


%prep
%setup -n %{name}-%{version}
%patch0
go mod tidy

%build
export TARGETPLATFORM=%{custom_arch}
./hack/build-go.sh


%install
install -D -m 755 bin/multus %{buildroot}%{_bindir}/multus
install -D -m 755 bin/multus-daemon %{buildroot}%{_bindir}/multus-daemon
install -D -m 755 bin/multus-shim %{buildroot}%{_bindir}/multus-shim
install -D -m 755 bin/install_multus %{buildroot}%{_bindir}/install_multus
install -D -m 755 bin/thin_entrypoint %{buildroot}%{_bindir}/thin_entrypoint
{{{- if semverCompare ">=4.2.1" $version }}}
install -D -m 755 bin/passthru %{buildroot}%{_bindir}/passthru
{{{- end }}}

%files
%license LICENSE THIRD_PARTY_LICENSES.txt
%attr(755,root,root) %{_bindir}/multus
%attr(755,root,root) %{_bindir}/multus-daemon
%attr(755,root,root) %{_bindir}/multus-shim
%attr(755,root,root) %{_bindir}/install_multus
%attr(755,root,root) %{_bindir}/thin_entrypoint
{{{- if semverCompare ">=4.2.1" $version }}}
%attr(755,root,root) %{_bindir}/passthru
{{{- end }}}

%changelog
* {{{.changelog_timestamp}}} - {{{$version}}}-1
- Added Oracle specific files for multus-cni
- Removed generate-kubeconfig
{{{- if semverCompare ">=4.2.1" $version }}}
- Added multus-daemon, multus-shim, install_multus, thin_entrypoint and passthru
{{{- else }}}
- Added multus-daemon, multus-shim, install_multus, thin_entrypoint
{{{- end }}}
