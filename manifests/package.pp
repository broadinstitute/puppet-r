# package.pp

define r_lang::package (
  Optional[String] $r_path      = undef,
  String $repo                  = 'https://cran.rstudio.com',
  Boolean $dependencies         = false,
  Optional[String] $environment = undef,
  Integer $timeout              = 300,
) {
  case $facts['os']['family'] {
    'Debian', 'RedHat': {
      if ! $r_path {
        $binary = '/usr/bin/R'
      } else {
        $binary = $r_path
      }

      $command = $dependencies ? {
        true    => "${binary} -e \"install.packages('${name}', repos='${repo}', dependencies = TRUE)\"",
        default => "${binary} -e \"install.packages('${name}', repos='${repo}', dependencies = FALSE)\"",
      }

      exec { "install_r_package_${name}":
        command     => $command,
        environment => $environment,
        timeout     => $timeout,
        unless      => "${binary} -q -e \"'${name}' %in% installed.packages()\" | grep 'TRUE'",
        require     => Class['r_lang'],
      }
    }
    'windows': {
      if ! $r_path {
        $binary = 'r.exe'
      } else {
        $binary = $r_path
      }

      $deps = $dependencies ? {
        true    => 'TRUE',
        default => 'FALSE'
      }

      exec { "install_r_package_${name}":
        command  => template('r/windows_install_rpackage.ps1.erb'),
        provider => powershell,
        unless   => template('r/windows_rpackage_check.ps1.erb'),
        require  => Class['r_lang'],
      }
    }
    default: {
      fail("Not supported on osfamily ${facts['os']['family']}")
    }
  }
}
