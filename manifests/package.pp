# @summary
#   Installs RShiny CPAN packates
#
# @param r_path
#   Alternative path to R executable
#   Default: undef
#
# @param repo
#  CRAN repository to install from. 
#  Default: https://cran.rstudio.com
#
# @param dependencies
#   Boolean to install dependencies with the package
#   Default: false
#
# @param environment
#   Add and environment path loactions to execute the install command
#
# @param timeout
#   Time in seconds to wait for the install command to exit
#
# @param tmpdir
#   Manually set the tmpdir for the install command
#   Note: RHEL 8 & 9 set noexec on /tmp by default
#   Default: /opt/shiny-server/tmp
#
#
define r::package (
  Optional[String] $r_path       = undef,
  String           $repo         = 'https://cran.rstudio.com',
  Boolean          $dependencies = false,
  Optional[String] $environment  = undef,
  Integer          $timeout      = 300,
  String           $tmpdir       = '/opt/shiny-server/tmp',
) {
  case $facts['os']['family'] {
    'Debian', 'RedHat': {
      if $r_path {
        $binary = $r_path
      }
      else {
        $binary = '/usr/bin/R'
      }
      $command = $dependencies ? {
        true    => "${binary} -e \"install.packages('${name}', 
                   repos='${repo}',
                   configure.vars = \"TMPDIR=${tmpdir}\",
                   dependencies = TRUE)\"",
        default => "${binary} -e \"install.packages('${name}',
                   repos='${repo}',
                   dependencies = FALSE)\""
      }
      exec { "install_r_package_${name}":
        command     => $command,
        environment => $environment,
        timeout     => $timeout,
        unless      => "${binary} -q -e \"'${name}' %in% installed.packages()\" | grep 'TRUE'",
        require     => Class['r'],
      }
    }
    'windows': {
      if $r_path == '' {
        $binary = 'r.exe'
      }
      else {
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
        require  => Class['r'],
      }
    }
    default: { fail("Not supported on osfamily ${facts['os']['family']}") }
  }
}
