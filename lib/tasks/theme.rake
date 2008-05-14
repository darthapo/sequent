namespace :theme do
  namespace :cache do

    desc "Creates the cached (public) theme folders"
    task :create do
      for theme in Dir.glob("#{RAILS_ROOT}/themes/*")
        theme_name = theme.split( File::Separator )[-1]
        puts "Creating #{File.expand_path RAILS_ROOT}/public/themes/#{theme_name}"
    
        FileUtils.mkdir_p "#{RAILS_ROOT}/public/themes/#{theme_name}"
        
        FileUtils.cp_r "#{theme}/images", "#{RAILS_ROOT}/public/themes/#{theme_name}/images", :verbose => false
        FileUtils.cp_r "#{theme}/stylesheets", "#{RAILS_ROOT}/public/themes/#{theme_name}/stylesheets", :verbose => false
        FileUtils.cp_r "#{theme}/javascripts", "#{RAILS_ROOT}/public/themes/#{theme_name}/javascripts", :verbose => false
      end
    end

    desc "Removes the cached (public) theme folders"
    task :remove do
      puts "Removing #{File.expand_path RAILS_ROOT}/public/themes"
      FileUtils.rm_r "#{RAILS_ROOT}/public/themes", :force => true
    end

    desc "Updates the cached (public) theme folders"
    task :update => [:remove, :create]

  end
end
