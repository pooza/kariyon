desc 'install'
task install: [
  'kariyon:periodic:init',
  'kariyon:htdocs:init',
  'kariyon:skel:well_known_dir',
]

desc 'uninstall'
task uninstall: [
  'kariyon:periodic:clean',
  'kariyon:htdocs:clean',
]
