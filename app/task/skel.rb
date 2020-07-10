namespace :kariyon do
  namespace :skel do
    desc 'link .well-known dir'
    task :well_known_dir do
      Kariyon::Skeleton.new.link_well_known_dir
    end
  end
end
