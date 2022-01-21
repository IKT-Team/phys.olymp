namespace :application do
  desc 'Start application'
  task :start do
    on roles(:app), in: :sequence, wait: 5 do
      within current_path do
        execute 'sudo systemctl start ikt'
      end
    end
  end

  desc 'Stop application'
  task :stop do
    on roles(:app), in: :sequence, wait: 5 do
      within current_path do
        execute 'sudo systemctl stop ikt'
      end
    end
  end

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      within current_path do
        execute 'sudo systemctl restart ikt'
      end
    end
  end
end
