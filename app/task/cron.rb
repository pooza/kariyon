namespace :kariyon do
  namespace :cron do
    # cron の 1 行を置けてから、古い periodic のリンクを消す（置けなければ periodic のまま動き続ける）。
    desc 'put the cron entry (and remove the old periodic link)'
    task init: [:clean, :create, 'kariyon:periodic:clean']

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
