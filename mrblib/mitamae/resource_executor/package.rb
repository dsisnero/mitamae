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
        # Check both platform and Docker environment
        node[:platform] == 'windows' || ENV['DOCKER_WINDOWS_CONTAINER'] == '1'
      end

      def in_container?
        ENV['CONTAINER'] == 'true' || File.exist?('/.dockerenv')
      end

      def install_package_on_windows(name, version, options)
        provider = desired.provider&.to_sym

        # Use specified provider if given
        if provider == :chocolatey
          install_with_chocolatey(name, version, options)
        elsif provider == :winget
          install_with_winget(name, version, options)
        # Container-specific logic
        elsif in_container?
          # In Docker containers, prefer Chocolatey
          install_with_chocolatey(name, version, options)
        # Otherwise try to use available package managers in order
        elsif check_command('where choco')
          install_with_chocolatey(name, version, options)
        elsif check_command('where winget')
          install_with_winget(name, version, options)
        else
          # Fall back to specinfra's implementation
          run_specinfra(:install_package, name, version, options)
        end
      end

      def install_with_chocolatey(name, version, options)
        args = ['install', name, '-y']
        args << '--version' << version if version
        args << options if options
        run_command(['choco'] + args)
      end

      def install_with_winget(name, version, options)
        args = ['install', '--accept-source-agreements', '--accept-package-agreements', '-e', name]
        args << '--version' << version if version
        args << options if options
        run_command(['winget'] + args)
      end

      def remove_package_on_windows(name, options)
        provider = desired.provider&.to_sym

        # Use specified provider if given
        if provider == :chocolatey
          remove_with_chocolatey(name, options)
        elsif provider == :winget
          remove_with_winget(name, options)
        # Container-specific logic
        elsif in_container?
          # In Docker containers, prefer Chocolatey
          remove_with_chocolatey(name, options)
        # Otherwise try to use available package managers in order
        elsif check_command('where choco')
          remove_with_chocolatey(name, options)
        elsif check_command('where winget')
          remove_with_winget(name, options)
        else
          # Fall back to specinfra's implementation
          run_specinfra(:remove_package, name, options)
        end
      end

      def remove_with_chocolatey(name, options)
        args = ['uninstall', name, '-y']
        args << options if options
        run_command(['choco'] + args)
      end

      def remove_with_winget(name, options)
        args = ['uninstall', '--accept-source-agreements', '-e', name]
        args << options if options
        run_command(['winget'] + args)
      end
    end
  end
end
