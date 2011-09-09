require 'capistrano/recipes/deploy/strategy/copy'
require 'fileutils'
require 'tempfile'  # Dir.tmpdir

module Capistrano
  module Deploy
    module Strategy

      # This class implements the strategy for deployments which work
      # by preparing the source code locally, compressing it, copying the
      # file to each target host, and uncompressing it to the deployment
      # directory.
      #
      # By default, the SCM checkout command is used to obtain the local copy
      # of the source code. If you would rather use the export operation,
      # you can set the :copy_strategy variable to :export.
      #
      #   set :copy_strategy, :export
      #
      # For even faster deployments, you can set the :copy_cache variable to
      # true. This will cause deployments to do a new checkout of your
      # repository to a new directory, and then copy that checkout. Subsequent
      # deploys will just resync that copy, rather than doing an entirely new
      # checkout. Additionally, you can specify file patterns to exclude from
      # the copy when using :copy_cache; just set the :copy_exclude variable
      # to a file glob (or an array of globs).
      #
      #   set :copy_cache, true
      #   set :copy_exclude, ".git/*"
      #
      # Note that :copy_strategy is ignored when :copy_cache is set. Also, if
      # you want the copy cache put somewhere specific, you can set the variable
      # to the path you want, instead of merely 'true':
      #
      #   set :copy_cache, "/tmp/caches/myapp"
      #
      # This deployment strategy also supports a special variable,
      # :copy_compression, which must be one of :gzip, :bz2, or
      # :zip, and which specifies how the source should be compressed for
      # transmission to each host.
      class Symfony2VendorCopy < Copy
        # Obtains a copy of the source code locally (via the #command method),
        # compresses it to a single file, copies that file to all target
        # servers, and uncompresses it on each of them into the deployment
        # directory.
        def deploy!
          if copy_cache
            if File.exists?(copy_cache)
              logger.debug "refreshing local cache to revision #{revision} at #{copy_cache}"
              system(source.sync(revision, copy_cache))
            else
              logger.debug "preparing local cache at #{copy_cache}"
              system(source.checkout(revision, copy_cache))
            end

            # Check the return code of last system command and rollback if not 0
            unless $? == 0
              raise Capistrano::Error, "shell command failed with return code #{$?}"
            end

            logger.debug "Update external vendors"
            system(copy_cache + '/bin/vendors install')

            FileUtils.mkdir_p(destination)

            logger.debug "copying cache to deployment staging area #{destination}"
            Dir.chdir(copy_cache) do
              queue = Dir.glob("*", File::FNM_DOTMATCH)
              while queue.any?
                item = queue.shift
                name = File.basename(item)

                next if name == "." || name == ".."
                next if copy_exclude.any? { |pattern| File.fnmatch(pattern, item) }

                if File.symlink?(item)
                  FileUtils.ln_s(File.readlink(item), File.join(destination, item))
                elsif File.directory?(item)
                  queue += Dir.glob("#{item}/*", File::FNM_DOTMATCH)
                  FileUtils.mkdir(File.join(destination, item))
                else
                  FileUtils.ln(item, File.join(destination, item))
                end
              end
            end
          else
            logger.debug "getting (via #{copy_strategy}) revision #{revision} to #{destination}"
            system(command)

            logger.debug "Update external vendors"
            system(destination + '/bin/vendors install --reinstall')

            if copy_exclude.any?
              logger.debug "processing exclusions..."
              if copy_exclude.any?
                copy_exclude.each do |pattern|
                  delete_list = Dir.glob(File.join(destination, pattern), File::FNM_DOTMATCH)
                  # avoid the /.. trap that deletes the parent directories
                  delete_list.delete_if { |dir| dir =~ /\/\.\.$/ }
                  FileUtils.rm_rf(delete_list.compact)
                end
              end
            end
          end

          File.open(File.join(destination, "REVISION"), "w") { |f| f.puts(revision) }


          logger.trace "compressing #{destination} to #{filename}"
          Dir.chdir(copy_dir) { system(compress(File.basename(destination), File.basename(filename)).join(" ")) }

          distribute!
        ensure
          FileUtils.rm filename rescue nil
          FileUtils.rm_rf destination rescue nil
        end

      end

    end
  end
end
