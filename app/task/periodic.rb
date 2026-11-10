namespace :kariyon do
  namespace :periodic do
    # 切り替えは毎分の cron へ移した（#306）。古い版が置いた periodic のリンクを消すためだけに残す。
    desc 'remove the old periodic link'
    task :clean do
      Kariyon::PeriodicCreator.instance.clean
    end
  end
end
