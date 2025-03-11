# This patch modifies the mruby build system to handle large file lists better on Windows
# Apply this patch to mruby/lib/mruby/build/command.rb

module MRuby
  module Command
    class Mrbc
      # Override the run method to handle large file lists
      alias_method :original_run, :run
      
      def run(out, infiles)
        if infiles.length > 100 && RUBY_PLATFORM =~ /mswin|mingw|windows/i
          # Process files in batches to avoid command line length limits
          infiles.each_slice(50) do |batch|
            original_run(out, batch)
          end
        else
          original_run(out, infiles)
        end
      end
    end
  end
end
