module MItamae
  module ResourceExecutor
    class Service < Base
      def initialize(*)
        super
        @under = attributes.provider ? "_under_#{attributes.provider}" : ''
      end

      def apply
        if run_on_windows? && attributes.provider.nil?
          apply_windows_service
        else
          apply_generic_service
        end
      end

      private

      def run_on_windows?
        node[:platform] == 'windows'
      end

      def apply_generic_service
        if desired.has_key?(:running)
          if desired.running && !current.running
            run_specinfra(:"start_service#{@under}", attributes.name)
          elsif !desired.running && current.running
            run_specinfra(:"stop_service#{@under}", attributes.name)
          end
        end

        if desired.restarted
          run_specinfra(:"restart_service#{@under}", attributes.name)
        end

        if desired.reloaded && current.running
          run_specinfra(:"reload_service#{@under}", attributes.name)
        end

        return unless desired.has_key?(:enabled)

        if desired.enabled && !current.enabled
          run_specinfra(:"enable_service#{@under}", attributes.name)
        elsif !desired.enabled && current.enabled
          run_specinfra(:"disable_service#{@under}", attributes.name)
        end
      end

      def apply_windows_service
        if desired.has_key?(:running)
          if desired.running && !current.running
            start_windows_service(attributes.name)
          elsif !desired.running && current.running
            stop_windows_service(attributes.name)
          end
        end

        if desired.restarted
          restart_windows_service(attributes.name)
        end

        # Windows doesn't have reload concept for services
        if desired.reloaded && current.running
          MItamae.logger.warn 'Reload action not supported on Windows services'
        end

        return unless desired.has_key?(:enabled)

        if desired.enabled && !current.enabled
          enable_windows_service(attributes.name)
        elsif !desired.enabled && current.enabled
          disable_windows_service(attributes.name)
        end
      end

      def start_windows_service(name)
        run_command(['sc', 'start', name])
      end

      def stop_windows_service(name)
        run_command(['sc', 'stop', name])
      end

      def restart_windows_service(name)
        stop_windows_service(name)
        # Wait a bit for service to stop
        sleep 2
        start_windows_service(name)
      end

      def enable_windows_service(name)
        run_command(['sc', 'config', name, 'start=', 'auto'])
      end

      def disable_windows_service(name)
        run_command(['sc', 'config', name, 'start=', 'disabled'])
      end

      def check_windows_service_running(name)
        result = run_command(['sc', 'query', name], error: false)
        result.stdout.include?('RUNNING')
      end

      def check_windows_service_enabled(name)
        result = run_command(['sc', 'qc', name], error: false)
        if result.exit_status == 0
          result.stdout.include?('AUTO_START') || result.stdout.include?('DEMAND_START')
        else
          false
        end
      end

      def set_current_attributes(current, _action)
        if run_on_windows? && attributes.provider.nil?
          current.running = check_windows_service_running(attributes.name)
          current.enabled = check_windows_service_enabled(attributes.name)
        else
          current.running = run_specinfra(:"check_service_is_running#{@under}", attributes.name)
          current.enabled = run_specinfra(:"check_service_is_enabled#{@under}", attributes.name)
        end
        current.restarted = false
        current.reloaded = false
      end

      def set_desired_attributes(desired, action)
        case action
        when :start
          desired.running = true
        when :stop
          desired.running = false
        when :restart
          desired.restarted = true
        when :reload
          desired.reloaded = true
        when :enable
          desired.enabled = true
        when :disable
          desired.enabled = false
        end
      end
    end
  end
end
