namespace :deploy do
  task :default do
    update
    symlink
  end

  task :update do
    transaction do
      update_code
    end
  end

  task :activate do
    transaction do
      symlink
    end
  end
end

task :ping, :role => :web do
    run "uname -a"
end


after "deploy:finalize_update" do
  if update_vendors
    # share the children first (to get the vendor symlink)
    # deploy.share_childs
    # symfony.vendors.update                # 1. Update vendors
  end

  symfony.cache.warmup                    # 2. Warmup clean cache
  symfony.assets.install                  # 3. Publish bundle assets
  if dump_assetic_assets
     symfony.assetic.dump                  # 4. Dump assetic assets
  end
end