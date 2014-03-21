require 'pathname'

class DeploySpec
  BUNDLE_PATH = File.join(Rails.root, "data", "bundler")
  DEFAULT_BUNDLER_WITHOUT = %w(developement test benchmark debug)
  Error = Class.new(StandardError)

  def initialize(app_dir)
    @app_dir = Pathname(app_dir)
  end

  def config(*keys)
    @config ||= load_config
    keys.flatten.reduce(@config) { |h, k| h[k] if h.respond_to?(:[]) }
  end

  def dependencies_steps
    config('dependencies', 'override') || discover_bundler || []
  end

  def deploy_steps
    config('deploy', 'override') || discover_capistrano || cant_detect_deploy_steps
  end

  def discover_bundler
    bundle_install if bundler?
  end

  def bundle_install
    [%Q(bundle install --frozen --path=#{BUNDLE_PATH} --retry=2 --without=#{bundler_without.join(':')})]
  end

  def bundler_without
    config('dependencies', 'bundler', 'without') || DEFAULT_BUNDLER_WITHOUT
  end

  def discover_capistrano
    bundle_exec = ''
    bundle_exec = 'bundle exec ' if bundler?
    ["#{bundle_exec}cap $ENVIRONMENT deploy"] if capistrano?
  end

  def capistrano?
    @app_dir.join('Capfile').exist?
  end

  def bundler?
    @app_dir.join('Gemfile').exist?
  end

  def cant_detect_deploy_steps
    raise DeploySpec::Error, 'Impossible to detect how to deploy this application. Please define `deploy.override` in your shipit.yml'
  end

  def load_config
    if shipit_yml.exist?
      SafeYAML.load(shipit_yml.read)
    else
      {}
    end
  end

  def shipit_yml
    @app_dir.join('shipit.yml')
  end

end