# Windows path compatibility module
# Provides utilities for handling Windows paths in a cross-platform way

module MItamae
  module WindowsPath
    class << self
      # Node instance for platform detection
      # This should be set when mitamae initializes
      @node = nil

      attr_accessor :node

      # Check if running on Windows
      def windows?
        return false unless node

        node[:platform] == 'windows'
      end

      # Normalize a path for the current platform
      # Converts forward slashes to backslashes on Windows
      # Handles drive letters and UNC paths
      def normalize(path)
        return path unless path.is_a?(String)

        if windows?
          normalize_windows_path(path)
        else
          normalize_unix_path(path)
        end
      end

      # Join path components for the current platform
      def join(*parts)
        return '' if parts.empty?

        # Filter out nil parts
        parts = parts.compact

        if windows?
          join_windows(*parts)
        elsif ::File.respond_to?(:original_join)
          # Use original File.join to avoid recursion
          ::File.original_join(*parts)
        else
          ::File.join(*parts)
        end
      end

      # Expand a path for the current platform
      def expand_path(path, dir = nil)
        if windows?
          expand_windows_path(path, dir)
        elsif ::File.respond_to?(:original_expand_path)
          # Use original File.expand_path to avoid recursion
          ::File.original_expand_path(path, dir)
        else
          ::File.expand_path(path, dir)
        end
      end

      # Check if a path is absolute for the current platform
      def absolute?(path)
        return false unless path.is_a?(String)

        if windows?
          windows_absolute?(path)
        else
          unix_absolute?(path)
        end
      end

      # Convert a Windows path to Unix style (for display/logging)
      def to_unix_path(path)
        return path unless path.is_a?(String)

        # Replace backslashes with forward slashes
        # Handle drive letters: C:\path -> /c/path
        path = path.tr('\\', '/')

        if %r{^([A-Za-z]):/}.match?(path)
          # Convert drive letter to Unix-style path
          "/#{path[0].downcase}#{path[2..-1]}"
        else
          path
        end
      end

      # Convert a Unix path to Windows style
      def to_windows_path(path)
        return path unless path.is_a?(String)

        # Replace forward slashes with backslashes
        # Handle /c/path -> C:\path
        path = path.tr('/', '\\')

        if path =~ %r{^/([a-z])(.*)}
          # Convert Unix-style drive path to Windows
          "#{::Regexp.last_match(1).upcase}:\\#{::Regexp.last_match(2)}"
        else
          path
        end
      end

      private

      def normalize_windows_path(path)
        # Convert forward slashes to backslashes
        path = path.tr('/', '\\')

        # Handle multiple backslashes
        path = path.gsub(/\\\\+/, '\\')

        # Handle drive letters (ensure uppercase and colon)
        if path =~ /^([a-z]):\\/i
          path = "#{::Regexp.last_match(1).upcase}:\\#{path[3..-1]}"
        end

        # Remove trailing backslash unless it's a drive root
        if path =~ /^[A-Z]:\\$/ || path =~ /^\\\\[^\\]+\\[^\\]+\\?$/
          path
        elsif path.end_with?('\\')
          path[0..-2]
        else
          path
        end
      end

      def normalize_unix_path(path)
        # Convert backslashes to forward slashes (in case someone used them)
        path = path.tr('\\', '/')

        # Handle multiple slashes
        path = path.gsub(%r{//+}, '/')

        # Remove trailing slash unless it's root
        if path == '/'
          path
        elsif path.end_with?('/')
          path[0..-2]
        else
          path
        end
      end

      def join_windows(*parts)
        return '' if parts.empty?

        # Start with first part
        result = parts.first.to_s

        # Process remaining parts
        parts[1..-1].each do |part|
          part = part.to_s
          next if part.empty?

          # Remove leading/trailing backslashes
          part = part.gsub(/^\\+|\\+$/, '')

          result = if result.empty?
                     part
                   else
                     # Ensure result ends with backslash if not empty
                     result.gsub(/\\+$/, '') + '\\' + part
                   end
        end

        normalize_windows_path(result)
      end

      def expand_windows_path(path, dir = nil)
        # Simple expansion - in a real implementation this would handle:
        # - ~ expansion (user home)
        # - . and ..
        # - environment variables
        # - Current directory relative paths

        # For now, basic implementation
        if absolute?(path)
          normalize_windows_path(path)
        elsif dir
          join_windows(dir, path)
        else
          join_windows(Dir.pwd, path)
        end
      end

      def windows_absolute?(path)
        # Check for drive letter path: C:\path
        return true if /^[A-Za-z]:\\/.match?(path)

        # Check for UNC path: \\server\share\path
        return true if /^\\\\[^\\]+\\[^\\]+/.match?(path)

        false
      end

      def unix_absolute?(path)
        path.start_with?('/')
      end
    end
  end
end

# Monkey patch File class for Windows compatibility
# This will be applied when WindowsPath.node is set
# Monkey patch File class for Windows compatibility
# This will be applied when WindowsPath.node is set
if defined?(MItamae::WindowsPath)
  class File
    class << self
      # Store original methods before monkey patching
      alias original_join join
      alias original_expand_path expand_path

      # Override File.join to use Windows path separator on Windows
      def join(*args)
        if MItamae::WindowsPath.node && MItamae::WindowsPath.windows?
          MItamae::WindowsPath.join(*args)
        else
          original_join(*args)
        end
      end

      # Override File.expand_path for Windows
      def expand_path(path, dir = nil)
        if MItamae::WindowsPath.node && MItamae::WindowsPath.windows?
          MItamae::WindowsPath.expand_path(path, dir)
        else
          original_expand_path(path, dir)
        end
      end
    end
  end

  class Dir
    class << self
      # Store original method before monkey patching
      alias original_pwd pwd

      # Override Dir.pwd to return Windows-style path on Windows
      def pwd
        if MItamae::WindowsPath.node && MItamae::WindowsPath.windows?
          MItamae::WindowsPath.normalize(original_pwd)
        else
          original_pwd
        end
      end
    end
  end
end
