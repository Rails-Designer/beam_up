# Beam Up

Static site deployment CLI supporting multiple providers. Just run `beam_up ./output`.


## Installation

If you have a Ruby environment available, you can install:
```bash
gem install beam_up
```


## Configuration

Create a config file:
```bash
beam_up init netlify
```

Or manually create `.beam_up.yml` (or `config/beam_up.yml`):
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
beam_up ./output --to bunny
# or
beam_up ./output --provider bunny
```


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

BeamUp.deploy! "./output"

# Deploy with provider override
BeamUp.deploy! "./output", to: "bunny"
# or
BeamUp.deploy! "./output", provider: "bunny"
```


## Hooks

Run commands before and after deployment:

```yaml
provider: netlify
before_actions:
  - npm run build
after_actions:
  - echo "Deployment complete ✨"
netlify:
  api_token: your_token_here
  project_id: your_project_id
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
