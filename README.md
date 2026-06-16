# Beam Up

Static site deployment CLI supporting [multiple providers](#supported-providers). Just run `beam_up ./output`.


## Installation

If you have a Ruby environment available, you can install:
```bash
gem install beam_up
```


## Configuration

Create a config file interactively:
```bash
beam_up init
```

Or specify values programmatically (see [Usage from Ruby](#usage-from-ruby) for details).

You can also manually create `.beam_up.yml` (or `config/beam_up.yml`):
```yaml
provider: netlify
# path: ./output  # optional
netlify:
  api_token: your_token_here
  project_id: your_project_id
```

If both files exist, `config/beam_up.yml` takes priority.


## Deploy

```bash
# Deploy using configured provider
beam_up ./output

# Override provider for this deploy
beam_up ./output --to seal_static
# or
beam_up ./output --provider seal_static
```


## Deploy without configuration

If you run `beam_up ./output` without a config, or want to quickly deploy without signing up for a provider. Beam Up deploys to [Seal Static](https://sealstatic.com/). Just verify your email and you're live. Config is saved for future deploys.

Seal Static terms of service apply. See [sealstatic.com](https://sealstatic.com/) for details.


## Supported providers

- aws_s3
- bunny
- digital_ocean_spaces
- hetzner
- neocities
- netlify
- [Seal Static](https://sealstatic.com/)
- sftp
- statichost


## Usage from Ruby

```ruby
require "beam_up"

# Configure a provider interactively
BeamUp.init! "netlify"

# Deploy
BeamUp.deploy! "./output"

# Deploy with provider override
BeamUp.deploy! "./output", to: "hetzner"
# or
BeamUp.deploy! "./output", provider: "hetzner"
```


## Hooks

Run commands before and after deployment:

```yaml
provider: seal_static

seal_static:
  api_key: api_key_here
  project_id: your_project_id

before_actions:
  - RAILS_ENV=production bin/rails perron:build
after_actions:
  - echo "Deployment complete ✨"
```

If a `before_action` fails, deployment is cancelled.


## SFTP

Beam Up supports SFTP like the good ol' days. Requires additional gems:

```bash
gem install net-ssh net-sftp
```

Configuration:

```yaml
provider: sftp

sftp:
  host: your-server.com
  username: deploy_user
  remote_path: /var/www/html
  # Use either password OR key:
  password: your_password
  # key: ~/.ssh/id_rsa
```


## Contributing

This project uses [Standard](https://github.com/testdouble/standard) for formatting. Run `rake` before submitting pull requests.


## License

MIT License


---

*Fun fact: “Beam me up, Scotty” was never spoken in any Star Trek television episode or film.*
