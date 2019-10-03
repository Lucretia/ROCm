# Copyright
#

EAPI=7

inherit cmake-utils

DESCRIPTION=""
HOMEPAGE="https://github.com/ROCmSoftwarePlatform/rocFFT"
SRC_URI="https://github.com/ROCmSoftwarePlatform/rocFFT/archive/rocm-$(ver_cut 1-2).tar.gz -> rocFFT-${PV}.tar.gz"

LICENSE=""
SLOT="0"
KEYWORDS="~amd64"
IUSE="examples gfx701 +gfx803 gfx900 gfx906 test"
REQUIRED_USE="^^ ( gfx701 gfx803 gfx900 gfx906 )"

RDEPEND="=sys-devel/hip-$(ver_cut 1-2)*"
DEPEND="${RDEPEND}
	dev-util/cmake
	test? ( dev-cpp/gtest )"

S="${WORKDIR}/rocFFT-rocm-$(ver_cut 1-2)"

src_prepare() {
	cd ${S}

	eapply "${FILESDIR}/rocFFT-library_src_CMakeListstxt.patch"
	eapply "${FILESDIR}/rocFFT-library_src_device_CMakeListstxt.patch"
	eapply "${FILESDIR}/0001-Add-gfx701-Hawaii.patch"

	sed -e "s: PREFIX rocfft:# PREFIX rocfft:" -i ${S}/library/src/CMakeLists.txt
	sed -e "s:rocm_install_symlink_subdir( rocfft ):#rocm_install_symlink_subdir( rocfft ):" -i ${S}/library/src/CMakeLists.txt
	sed -e "s:<INSTALL_INTERFACE\:include:<INSTALL_INTERFACE\:include/rocFFT:" -i ${S}/library/src/CMakeLists.txt

	sed -e "s: PREFIX rocfft:# PREFIX rocfft:" -i ${S}/library/src/device/CMakeLists.txt
	sed -e "s:rocm_install_symlink_subdir( rocfft ):#rocm_install_symlink_subdir( rocfft ):" -i ${S}/library/src/device/CMakeLists.txt

	eapply_user
	cmake-utils_src_prepare
}

src_configure() {
        # if the ISA is not set previous to the autodetection,
        # /opt/rocm/bin/rocm_agent_enumerator is executed,
        # this leads to a sandbox violation
        if use gfx701; then
                CurrentISA="gfx701"
        fi
        if use gfx803; then
                CurrentISA="gfx803"
        fi
        if use gfx900; then
                CurrentISA="gfx900"
        fi
        if use gfx906; then
                CurrentISA="gfx906"
        fi

	export PATH=$PATH:/usr/lib/hcc/$(ver_cut 1-2)/bin
	export hcc_DIR=/usr/lib/hcc/$(ver_cut 1-2)/lib/cmake/
	export hip_DIR=/usr/lib/hip/$(ver_cut 1-2)/lib/cmake/
	export HIP_DIR=/usr/lib/hip/$(ver_cut 1-2)/lib/cmake/
	export CXX=/usr/lib/hcc/$(ver_cut 1-2)/bin/hcc

	local mycmakeargs=(
		-DHIP_PLATFORM=hcc
		-DCMAKE_INSTALL_PREFIX="/usr"
		-DCMAKE_INSTALL_INCLUDEDIR="include/rocFFT/"
		-DAMDGPU_TARGETS="${CurrentISA}"
		-DBUILD_CLIENTS_SAMPLES=$(usex examples ON OFF)
		-DBUILD_CLIENTS_TESTS=$(usex test ON OFF)
		-DBUILD_CLIENTS_SELFTEST=$(usex test ON OFF)
	)

	cmake-utils_src_configure
}

src_compile() {
	cmake-utils_src_compile

	if use examples; then
		cmake-utils_src_compile clients/samples/all
	fi

	if use test; then
		cmake-utils_src_compile clients/tests/all
	fi
}

src_install() {
	cmake-utils_src_install

	if use examples; then
		cmake-utils_src_compile clients/samples/install
		cmake-utils_src_compile clients/selftest/all
	fi

	if use test; then
		cmake-utils_src_compile clients/tests/install
		cmake-utils_src_compile clients/selftest/install
	fi
}
