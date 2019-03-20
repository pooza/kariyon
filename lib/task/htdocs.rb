namespace :kariyon do
  namespace :htdocs do
    task init: [:clean, :create]

    desc 'clear htdocs'
    task :clean do
      Kariyon::Deployer.instance.clean
    end

    desc 'create htdocs link'
    task :create do
      Kariyon::Deployer.instance.create
    end

    desc 'update htdocs link'
    task :update do
      Kariyon::Deployer.instance.update
    end
  end
end
