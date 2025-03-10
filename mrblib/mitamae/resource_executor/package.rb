module MItamae
  module ResourceExecutor
    class Package < Base
      def apply
        if desired.installed
          unless run_specinfra(:check_package_is_installed, desired.name, desired.version)
            if run_on_windows? && desired.provider.nil?
              install_package_on_windows(desired.name, desired.version, desired.options)
            else
              run_specinfra(:install_package, desired.name, desired.version, desired.options)
            end
            updated!
          end
        else
          if current.installed
            if run_on_windows? && desired.provider.nil?
              remove_package_on_windows(desired.name, desired.options)
            else
              run_specinfra(:remove_package, desired.name, desired.options)
            end
            updated!
          end
        end
      end

      private

      def set_current_attributes(current, action)
        case action
        when :install, :remove
          current.installed = run_specinfra(:check_package_is_installed, attributes.name)
          if current.installed
            current.version = run_specinfra(:get_package_version, attributes.name).stdout.strip
          end
        end
      end

      def set_desired_attributes(desired, action)
        case action
        when :install
          desired.installed = true
        when :remove
          desired.installed = false
        end
      end

      def run_on_windows?
        node[:platform] == 'windows'
      end

      def install_package_on_windows(name, version, options)
        # Try to use Chocolatey if available
        if check_command('where choco')
          args = ['install', name, '-y']
          args << '--version' << version if version
          args << options if options
          run_command(['choco'] + args)
        # Fall back to winget if available (Windows 10+)
        elsif check_command('where winget')
          args = ['install', '--accept-source-agreements', '--accept-package-agreements', '-e', name]
          args << '--version' << version if version
          args << options if options
          run_command(['winget'] + args)
        else
          # Fall back to specinfra's implementation
          run_specinfra(:install_package, name, version, options)
        end
      end

      def remove_package_on_windows(name, options)
        # Try to use Chocolatey if available
        if check_command('where choco')
          args = ['uninstall', name, '-y']
          args << options if options
          run_command(['choco'] + args)
        # Fall back to winget if available
        elsif check_command('where winget')
          args = ['uninstall', '--accept-source-agreements', '-e', name]
          args << options if options
          run_command(['winget'] + args)
        else
          # Fall back to specinfra's implementation
          run_specinfra(:remove_package, name, options)
        end
      end
    end
  end
end
