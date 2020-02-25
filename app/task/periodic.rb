namespace :kariyon do
  namespace :periodic do
    task init: [:clean, :create]

    desc 'clear periodic'
    task :clean do
      Kariyon::PeriodicCreator.instance.clean
    end

    desc 'create periodic link'
    task :create do
      Kariyon::PeriodicCreator.instance.create
    end
  end
end
