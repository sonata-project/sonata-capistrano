set :sonata_page_managers, ['page', 'snapshot']

namespace :sonata do
    namespace :page do
        desc "Flush all information set in cache managers."
        task "cache-flush-all", :roles => :app do
            fetch(:sonata_page_managers).each {|name|
                run "cd #{latest_release} && #{php_bin} #{symfony_console} sonata:page:cache-flush-all #{name} --env=#{symfony_env_prod}"
            }
        end

        desc "Create a snapshots of all pages available."
        task "create-snapshot", :roles => :app, :only => { :master => true } do
            run "cd #{latest_release} && #{php_bin} #{symfony_console} sonata:page:create-snapshots --env=#{symfony_env_prod}"
        end

        desc "Update core routes, from routing files to page manager."
        task "update-core-routes", :roles => :app, :only => { :master => true } do
            run "cd #{latest_release} && #{php_bin} #{symfony_console} sonata:page:update-core-routes --env=#{symfony_env_prod}"
        end
    end
end
