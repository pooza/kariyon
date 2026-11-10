namespace :kariyon do
  namespace :cron do
    # cron の 1 行を上書きで置けてから、古い periodic のリンクを消す（置けなければ、いまの形のまま動き続ける）。
    # ⚠ 先に :clean しない。置けなかったときに、動いている 1 行まで消える
    desc 'put the cron entry (and remove the old periodic link)'
    task init: [:create, 'kariyon:periodic:clean']

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
