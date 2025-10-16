#!/bin/bash

# Function to install R if it doesn't already exist
install_r() {
    # Check if R is already installed
    if command -v R >/dev/null 2>&1; then
        echo "R is already installed."
        echo "Skipping installation."
        return
    fi

    echo "Installing R."

    # Get the system information
    os=$(uname -s)

    # Execute different installation commands based on the detected system
    case "$os" in
    Linux*)
        if [ -f /etc/lsb-release ]; then
            # Ubuntu system
            echo "Installing r for Ubuntu system."

            # # Release version
            # # Reference: https://cloud.r-project.org/
            # # update indices
            # apt update -qq
            # # install two helper packages need
            # apt install --no-install-recommends software-properties-common dirmngr
            # # add the signing key (by Michael Rutter) for these repos
            # # To verify key, run gpg --show-keys /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
            # # Fingerprint: E298A3A825C0D65DFD57CBB651716619E084DAB9
            # wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
            # # add the R 4.0 repo from CRAN -- adjust 'focal' to 'groovy' or 'bionic' as needed

            # Reference: https://blog.csdn.net/tiansyun/article/details/131255627
            # sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup
            # sudo nano /etc/apt/sources.list
            # add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/"
            # add-apt-repository "deb http://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse"
            # add-apt-repository "deb http://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse"
            # add-apt-repository "deb http://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse"
            # add-apt-repository "deb http://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse"

            # # install R and its dependencies
            # apt install --no-install-recommends r-base

            # # Run this command to add the current R 4.0 or later ‘c2d4u’ repository:
            # # add-apt-repository ppa:c2d4u.team/c2d4u4.0+

            # # Devel version
            sudo apt update
            sudo apt upgrade
            sudo sh -c 'echo "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/" >> /etc/apt/sources.list'
            sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9
            sudo apt update
            sudo apt install r-base
            sudo apt install r-base-dev

        elif [ -f /etc/debian_version ]; then
            # Debian system
            echo "Debian system."
            # apt-get update
            # apt-get install -y r-base

            # Reference: https://cloud.r-project.org/
            apt search "^r-.*" | sort
            apt update
            apt install r-base r-base-dev
            apt rdepends r-base-core

        elif [ -f /etc/fedora-release ]; then
            # Fedora system
            echo "Fedora system."
            dnf install -y R

        elif [ -f /etc/arch-release ]; then
            # Arch Linux system
            echo "Arch Linux system."
            pacman -S --noconfirm r

        elif [ -f /etc/SuSE-release ] || [ -f /etc/openSUSE-release ]; then
            # OpenSuse system
            echo "OpenSuse system."
            zypper --non-interactive in -y R

        elif [ -f /etc/centos-release ]; then
            # CentOS system
            echo "CentOS system."
            yum install -y epel-release
            yum install -y R

        elif [ -f /etc/gentoo-release ]; then
            # Gentoo system
            echo "Gentoo system."
            emerge --ask dev-lang/R

        else
            echo "Unsupported Linux distribution."
            exit 1
        fi
        ;;
    *)
        echo "Unsupported operating system: $os"
        exit 1
        ;;
    esac

    # Check if R was installed successfully
    if [ $? -eq 0 ]; then
        echo "R installed successfully."
    else
        echo "R installation failed."
        echo "If your system is one of 'Fedora', 'CentOS'  and 'RHEL', please see: https://cloud.r-project.org/, for more information."
        exit 1
    fi
}

# Function to check if R is installed
check_r_packages_installed() {
    if command -v R >/dev/null 2>&1; then
        echo "R is already installed."
    else
        echo "R is not installed."
        install_r
    fi
}

install_dependence() {
    # Function to install packages for Debian/Ubuntu systems
    install_ubuntu_packages() {
        required_packages=(
            libcurl4-openssl-dev
            libxml2-dev
            libfontconfig1-dev
            libharfbuzz-dev
            libfribidi-dev
            libfreetype6-dev
            libpng-dev
            libtiff5-dev
            libjpeg-dev
            libgdal-dev
            libgeos-dev
            libproj-dev
            libgmp-dev
            libmpfr-dev
            libclang-dev
            cmake
            libmagick++-dev
        )

        for package in "${required_packages[@]}"; do
            if ! dpkg -l | grep -q "ii  $package"; then
                echo "Installing $package."
                apt-get install -y "$package"
            else
                echo "$package is already installed."
            fi
        done
    }

    # Function to install packages for Red Hat/CentOS/Fedora systems
    install_redhat_packages() {
        required_packages=(
            libcurl-devel
            libxml2-devel
            fontconfig-devel
            harfbuzz-devel
            fribidi-devel
            freetype-devel
            libpng-devel
            libtiff-devel
            libjpeg-devel
            gdal-devel
            geos-devel
            proj-devel
            gmp-devel
            mpfr-devel
            clang-devel
            cmake
            ImageMagick-c++-devel
        )

        wget http://security.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2.19_amd64.deb
        dpkg -i libssl1.1_1.1.1f-1ubuntu2.19_amd64.deb
        rm libssl1.1_1.1.1f-1ubuntu2.17_amd64.deb

        for package in "${required_packages[@]}"; do
            if ! rpm -q "$package" &>/dev/null; then
                echo "Installing $package."
                yum install -y "$package"
            else
                echo "$package is already installed."
            fi
        done
    }

    # Function to install packages for Arch Linux
    install_arch_packages() {
        required_packages=(
            curl
            libxml2
            fontconfig
            harfbuzz
            libfreetype2
            libpng
            libtiff
            libjpeg-turbo
            gdal
            geos
            proj
            gmp
            mpfr
            clang
            cmake
            imagemagick
        )

        for package in "${required_packages[@]}"; do
            if ! pacman -Q "$package" &>/dev/null; then
                echo "Installing $package..."
                pacman -S --noconfirm "$package"
            else
                echo "$package is already installed."
            fi
        done
    }

    # Detect the Linux distribution and call the appropriate function
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        case $ID in
        debian | ubuntu)
            echo "Detected Debian/Ubuntu system."
            install_ubuntu_packages
            ;;
        fedora | centos | rhel)
            echo "Detected Red Hat/CentOS/Fedora system."
            install_redhat_packages
            ;;
        arch)
            echo "Detected Arch Linux system."
            install_arch_packages
            ;;
        *)
            echo "Unsupported Linux distribution: $ID"
            exit 1
            ;;
        esac
    else
        echo "Unsupported operating system."
        exit 1
    fi

    echo "All required packages installed successfully."
}

# Function to install RStudio Server if not already installed
install_rstudio_server() {
    echo "Checking if RStudio Server is already installed..."
    if systemctl is-active rstudio-server &>/dev/null; then
        echo "RStudio Server is already installed."
        echo "Skipping installation."
        return
    fi

    echo "Installing RStudio Server."
    # Get the system information
    os=$(uname -s)

    # Execute different installation commands based on the detected system
    case "$os" in
    Linux*)
        if [ -f /etc/lsb-release ] || [ -f /etc/debian_version ]; then
            # Ubuntu system
            echo "Ubuntu or Debian system."
            apt-get install r-base
            apt-get install -y gdebi-core # Install gdebi-core for dependency handling
            #wget https://download2.rstudio.org/server/focal/amd64/rstudio-server-2023.06.2-561-amd64.deb
            wget https://download2.rstudio.org/server/jammy/amd64/rstudio-server-2024.04.1-748-amd64.deb
            gdebi rstudio-server-2023.06.2-561-amd64.deb
            rm rstudio-server-2023.06.2-561-amd64.deb
        elif [ -f /etc/fedora-release ]; then
            # Fedora system
            echo "Fedora system."
            dnf install -y wget
            wget https://download2.rstudio.org/server/centos7/x86_64/rstudio-server-rhel-2023.06.2-561-x86_64.rpm
            yum install rstudio-server-rhel-2023.06.2-561-x86_64.rpm
            rm rstudio-server-rhel-2023.06.2-561-x86_64.rpm
        elif [ -f /etc/SuSE-release ] || [ -f /etc/openSUSE-release ]; then
            # OpenSuse system
            echo "OpenSuse system."
            zypper --non-interactive in -y wget
            zypper install libgfortran43
            wget https://download2.rstudio.org/server/opensuse15/x86_64/rstudio-server-2023.06.2-561-x86_64.rpm
            zypper install rstudio-server-2023.06.2-561-x86_64.rpm
            rm rstudio-server-2023.06.2-561-x86_64.rpm
        elif [ -f /etc/centos-release ]; then
            # CentOS system
            echo "CentOS system."
            wget https://download2.rstudio.org/server/centos7/x86_64/rstudio-server-rhel-2023.06.2-561-x86_64.rpm
            yum install rstudio-server-rhel-2023.06.2-561-x86_64.rpm
            rm rstudio-server-rhel-2023.06.2-561-x86_64.rpm
        else
            echo "Unsupported Linux distribution."
            exit 1
        fi
        ;;
    *)
        echo "Unsupported operating system: $os"
        exit 1
        ;;
    esac

    # Check if RStudio Server was installed successfully
    if systemctl is-active rstudio-server &>/dev/null; then
        echo "RStudio Server installed successfully."
    else
        echo "RStudio Server installation failed."
        exit 1
    fi
}

# Function to check and install required packages...
install_packages() {
    echo "Checking and installing required packages..."

    # Function to check if a package is installed
    is_package_installed() {
        Rscript -e "if (!require($1, quietly = TRUE)) quit(save = 'no', status = 1)"
    }

    # # Install 'stringi'
    # if is_package_installed "stringi"; then
    #     echo "'stringi' is already installed."
    # else
    #     echo "Installing stringi."
    #     git clone https://github.com/gagolews/stringi.git
    #     cd stringi
    #     R CMD INSTALL .
    # fi

    cd ..

    # List of required packages
    required_packages=(
        "BiocManager"
        "data.table"
        "doParallel"
        "parallel"
        "dplyr"
        "foreach"
        "igraph"
        "patchwork"
        "progress"
        "purrr"
        "Rcpp"
        "ggnetwork"
        "ggplot2"
        "ggraph"
        "RcppArmadillo"
        "gtools"
        "circlize"
        "precrec"
        "tidygraph"
        "pROC"
        "spelling"
    )

    # Install 'devtools'
    if is_package_installed "devtools"; then
        echo "'devtools' is already installed."
    else
        echo "Installing devtools."
        Rscript -e "install.packages("devtools", repos = 'https://cloud.r-project.org')"
    fi

    # Install 'digest'
    # Note: the package 'digest' may encounter errors during the installation process on the macOS system of M1/M2 chip machines
    if is_package_installed "digest"; then
        echo "'digest' is already installed."
    else
        echo "Installing digest."
        Rscript -e "install.packages("digest", repos = c("https://eddelbuettel.r-universe.dev", "https://cloud.r-project.org"))"
    fi

    # Check and install each package
    for package in "${required_packages[@]}"; do
        if is_package_installed "$package"; then
            echo "$package is already installed."
        else
            echo "Installing $package..."
            Rscript -e "install.packages('$package', repos = 'https://cloud.r-project.org')"
        fi
    done

    # Install "ComplexHeatmap" using BiocManager
    if is_package_installed "ComplexHeatmap"; then
        echo "'ComplexHeatmap' is already installed."
    else
        echo "Installing 'ComplexHeatmap'."
        Rscript -e "BiocManager::install('ComplexHeatmap')"
    fi

    echo "Required packages installation complete."
}

# Running
check_r_packages_installed
install_rstudio_server
install_dependence
install_packages
