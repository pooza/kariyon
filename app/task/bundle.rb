namespace :bundle do
  desc 'update gems'
  task :update do
    sh 'bundle update'
  end

  desc 'check gems'
  task :check do
    exit 1 unless Kariyon::Environment.gem_fresh?
  end
end
