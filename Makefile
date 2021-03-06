.ONESHELL:
.PHONY: deps download build clean astyle

# OpenCV version to use.
OPENCV_VERSION?=4.5.0

# Temporary directory to put files into.
TMP_DIR?=/tmp/

# Package list for each well-known Linux distribution
RPMS=cmake curl git gtk2-devel libpng-devel libjpeg-devel libtiff-devel tbb tbb-devel libdc1394-devel unzip
DEBS=unzip build-essential cmake curl git libgtk2.0-dev pkg-config libavcodec-dev libavformat-dev libswscale-dev libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev libdc1394-22-dev caffe-cpu libcaffe-cpu-dev

# Detect Linux distribution
distro_deps=
ifneq ($(shell which dnf 2>/dev/null),)
	distro_deps=deps_fedora
else
ifneq ($(shell which zypper 2>/dev/null),)
        distro_deps=deps_opensuse
else
ifneq ($(shell which apt-get 2>/dev/null),)
	distro_deps=deps_debian
else
ifneq ($(shell which yum 2>/dev/null),)
	distro_deps=deps_rh_centos
endif
endif
endif
endif

# Install all necessary dependencies.
deps: $(distro_deps)

deps_rh_centos:
	sudo yum -y install pkgconfig $(RPMS)

deps_fedora:
	sudo dnf -y install pkgconf-pkg-config $(RPMS)

deps_opensuse:
	sudo zypper install -y pkgconf-pkg-config $(RPMS)

deps_debian:
	sudo apt-get -y update
	sudo apt-get -y install $(DEBS)


# Download OpenCV source tarballs.
download:
	rm -rf $(TMP_DIR)opencv
	mkdir $(TMP_DIR)opencv
	cd $(TMP_DIR)opencv
	curl -Lo opencv.zip https://github.com/opencv/opencv/archive/$(OPENCV_VERSION).zip
	unzip -q opencv.zip
	curl -Lo opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/$(OPENCV_VERSION).zip
	unzip -q opencv_contrib.zip
	rm opencv.zip opencv_contrib.zip
	cd -

# Build OpenCV.
build:
	cd $(TMP_DIR)opencv/opencv-$(OPENCV_VERSION)
	mkdir build
	cd build
	cmake -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX=/usr/local -D WITH_TBB=ON -D OPENCV_EXTRA_MODULES_PATH=$(TMP_DIR)opencv/opencv_contrib-$(OPENCV_VERSION)/modules -D BUILD_DOCS=ON BUILD_EXAMPLES=ON -D BUILD_TESTS=ON -D BUILD_PERF_TESTS=ON -D BUILD_opencv_java=OFF -D BUILD_opencv_python=OFF -D BUILD_opencv_python2=OFF -D BUILD_opencv_python3=OFF WITH_JASPER=OFF -DOPENCV_GENERATE_PKGCONFIG=ON ..
	$(MAKE) -j $(shell nproc --all)
	$(MAKE) preinstall
	cd -

# Build OpenCV on Raspbian with ARM hardware optimizations.
build_raspi:
	cd $(TMP_DIR)opencv/opencv-$(OPENCV_VERSION)
	mkdir build
	cd build
	cmake -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX=/usr/local -D WITH_TBB=ON -D OPENCV_EXTRA_MODULES_PATH=$(TMP_DIR)opencv/opencv_contrib-$(OPENCV_VERSION)/modules -D BUILD_DOCS=OFF BUILD_EXAMPLES=OFF -D BUILD_TESTS=OFF -D BUILD_PERF_TESTS=OFF -D BUILD_opencv_java=OFF -D BUILD_opencv_python=OFF -D BUILD_opencv_python2=OFF -D BUILD_opencv_python3=OFF -D ENABLE_NEON=ON -D ENABLE_VFPV3=ON WITH_JASPER=OFF -DOPENCV_GENERATE_PKGCONFIG=ON ..
	$(MAKE) -j $(shell nproc --all)
	$(MAKE) preinstall
	cd -

# Cleanup temporary build files.
clean:
	rm -rf $(TMP_DIR)opencv

# Do everything.
install: deps download build sudo_install clean

# Do everything on Raspbian.
install_raspi: deps download build_raspi sudo_install clean

# Install system wide.
sudo_install:
	cd $(TMP_DIR)opencv/opencv-$(OPENCV_VERSION)/build
	sudo $(MAKE) install
	sudo ldconfig
	cd -



astyle:
	astyle --project=.astylerc --recursive *.cpp,*.h

