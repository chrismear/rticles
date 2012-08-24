class Rticles::Railtie < Rails::Railtie
  generators do
    require 'rticles/generators/install_generator'
  end
end
