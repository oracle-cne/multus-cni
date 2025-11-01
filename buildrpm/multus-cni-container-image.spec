

%global debug_package %{nil}
%{!?registry: %global registry container-registry.oracle.com/olcne}

%global app_name multus-cni
%global app_version 4.2.3
%global oracle_release_version 1

Name:		%{app_name}-container-image
Version:	%{app_version}
Release:	%{oracle_release_version}%{?dist}
Summary:	Multus CNI
License:	Apache 2.0
URL:		https://github.com/k8snetworkplumbingwg/multus-cni
Source0:	%{name}-%{version}.tar.bz2
Vendor:		Oracle America

%description
Multus CNI is a container network interface (CNI) plugin for Kubernetes that enables attaching multiple network interfaces to pods.


%prep
%setup -q -n %{name}-%{version}


%build
%define rpm_name %{app_name}-%{version}-%{release}.%{_build_arch}
dnf clean all
dnf install -y --downloadonly --downloaddir=${PWD}/rpms %{rpm_name}

chmod +x ./olm/builds/build-image.sh
./olm/builds/build-image.sh \
    %{version} \
    _output \
    %{registry}


%install
mkdir -p %{buildroot}/usr/local/share/olcne
install -m 755 -d %{buildroot}/usr/local/share/olcne
echo "+++ INSTALLING DOCKER IMAGE multus-cni.tar"
install -p -m 755 -t %{buildroot}/usr/local/share/olcne _output/oracle_docker/multus-cni.tar


%files -n multus-cni-container-image
%license LICENSE THIRD_PARTY_LICENSES.txt
/usr/local/share/olcne/multus-cni.tar


%changelog
* Sat Nov 01 2025 Oracle Cloud Native Environment Authors <noreply@oracle.com> - 4.2.3-1
- Added Oracle specific files for multus-cni
