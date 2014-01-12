class Rticles::Railtie < Rails::Railtie
  generators do
    require 'rticles/generators/install_generator'
    require 'rticles/generators/update_generator'
  end
end
