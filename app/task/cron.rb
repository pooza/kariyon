namespace :kariyon do
  namespace :cron do
    desc 'put the cron entry (and remove the old periodic link)'
    task init: ['kariyon:periodic:clean', :clean, :create]

    desc 'remove the cron entry'
    task :clean do
      Kariyon::CronCreator.instance.clean
    end

    desc 'put the cron entry'
    task :create do
      Kariyon::CronCreator.instance.create
    end
  end
end
