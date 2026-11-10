desc 'install'
task install: [
  'kariyon:cron:init',
  'kariyon:htdocs:init',
  'kariyon:skel:well_known_dir',
]

desc 'uninstall'
task uninstall: [
  'kariyon:cron:clean',
  'kariyon:periodic:clean',
  'kariyon:htdocs:clean',
]
