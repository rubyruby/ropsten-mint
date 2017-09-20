require 'rvm/capistrano' # Для работы rvm
require 'bundler/capistrano' # Для работы bundler. При изменении гемов bundler автоматически обновит все гемы на сервере, чтобы они в точности соответствовали гемам разработчика.

task :production do
  set :application, 'ropsten-mint.rubyruby.ru'
  set :rails_env, 'production'
  set :domain, 'deploy@ropsten-mint.rubyruby.ru' # Это необходимо для деплоя через ssh. Именно ради этого я настоятельно советовал сразу же залить на сервер свой ключ, чтобы не вводить паролей.
  set :deploy_to, "/srv/#{application}"
  set :use_sudo, false
  set :unicorn_conf, "#{deploy_to}/current/config/unicorn.rb"
  set :unicorn_pid, "#{deploy_to}/shared/pids/unicorn.pid"

  set :rvm_ruby_string, '2.4.1@ropsten-mint.rubyruby.ru' # Это указание на то, какой Ruby интерпретатор мы будем использовать.

  set :scm, :git # Используем git. Можно, конечно, использовать что-нибудь другое - svn, например, но общая рекомендация для всех кто не использует git - используйте git.
  set :repository,  'git@github.com:rubyruby/ropsten-mint.git' # Путь до вашего репозитария. Кстати, забор кода с него происходит уже не от вас, а от сервера, поэтому стоит создать пару rsa ключей на сервере и добавить их в deployment keys в настройках репозитария.
  set :branch, 'master' # Ветка из которой будем тянуть код для деплоя.
  set :deploy_via, :remote_cache # Указание на то, что стоит хранить кеш репозитария локально и с каждым деплоем лишь подтягивать произведенные изменения. Очень актуально для больших и тяжелых репозитариев.

  set :db_local_clean, true

  role :web, domain
  role :app, domain
  role :db,  domain, :primary => true
  before 'deploy:setup', 'rvm:install_rvm', 'rvm:install_ruby' # интеграция rvm с capistrano настолько хороша, что при выполнении cap deploy:setup установит себя и указанный в rvm_ruby_string руби.

  before 'deploy:assets:precompile', 'deploy:symlink_shared'

  namespace :deploy do
    task :symlink_shared do
      run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
      run "ln -nfs #{shared_path}/config/secrets.yml #{release_path}/config/secrets.yml"
    end
  end

  def run_remote_rake(rake_cmd)
    rake_args = ENV['RAKE_ARGS'].to_s.split(',')
    cmd = "cd #{fetch(:latest_release)} && #{fetch(:rake, 'rake')} RAILS_ENV=#{fetch(:rails_env, 'production')} #{rake_cmd}"
    cmd += "['#{rake_args.join("','")}']" unless rake_args.empty?
    run cmd
    set :rakefile, nil if exists?(:rakefile)
  end

  namespace :deploy do
    namespace :assets do
      task :precompile, :roles => :web, :except => { :no_release => true } do
        begin
          from = source.next_revision(current_revision) # <-- Fail here at first-time deploy
        rescue
          err_no = true
        end
        if err_no || capture("cd #{latest_release} && #{source.local.log(from)} vendor/assets/ app/assets/ | wc -l").to_i > 0
          run %Q{cd #{latest_release} && #{rake} RAILS_ENV=#{rails_env} #{asset_env} assets:precompile}
        else
          logger.info 'Skipping asset pre-compilation because there were no asset changes'
        end
      end
    end
  end

  before 'deploy:create_symlink', 'deploy:force_migrate'

  # Далее идут правила для перезапуска unicorn. Их стоит просто принять на веру - они работают.
  # В случае с Rails 3 приложениями стоит заменять bundle exec unicorn_rails на bundle exec unicorn
  namespace :deploy do
    task :restart do
      run "if [ -f #{unicorn_pid} ] && [ -e /proc/$(cat #{unicorn_pid}) ]; then kill -USR2 `cat #{unicorn_pid}`; else cd #{deploy_to}/current && bundle exec unicorn_rails -c #{unicorn_conf} -E #{rails_env} -D; fi"
    end
    task :start do
      run "cd #{deploy_to}/current && bundle exec unicorn_rails -c #{unicorn_conf} -E #{rails_env} -D"
    end
    task :stop do
      run "if [ -f #{unicorn_pid} ] && [ -e /proc/$(cat #{unicorn_pid}) ]; then kill -QUIT `cat #{unicorn_pid}`; fi"
    end
  end
end
