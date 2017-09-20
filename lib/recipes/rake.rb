namespace :myrake do
  desc "Run a task on a remote server."
  task :invoke, :roles => :db, :on_no_matching_servers => :continue, :only => {:primary => true}  do
    run("cd #{current_path} && bundle exec rake #{ENV['task']} RAILS_ENV=#{rails_env}")
  end
end

namespace :runner do
  desc "Run a task on a remote server."
  task :invoke, :roles => :db, :on_no_matching_servers => :continue, :only => {:primary => true}  do
    run(%Q[cd #{current_path} && bundle exec rails runner -e #{rails_env} "#{ENV['xxx']}"])
  end
end
