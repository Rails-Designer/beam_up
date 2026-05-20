require "optparse"
require "yaml"

module BeamUp
  class CLI
    def self.start(arguments)
      new(arguments).run
    end

    def initialize(arguments)
      @arguments = arguments
      @provider = nil
      @config_file = nil
    end

    def run
      command = @arguments.shift

      case command
      when "init" then init
      when "scotty" then scotty
      when "--help", "-h" then help
      when nil then deploy_or_help
      else
        @arguments.unshift(command)

        deploy
      end
    end

    def init
      provider_name = @arguments.shift&.downcase

      if provider_name.nil? || !PROVIDERS.key?(provider_name)
        puts "Available providers:"

        PROVIDERS.keys.reject { it == "transporter" }.sort.each { puts "  - #{it}" }

        exit(1)
      end

      provider_config_class = PROVIDERS[provider_name]::Config
      config_keys = provider_config_class.config_keys
      config_file = ["config/beam_up.yml", ".beam_up.yml"].find { File.exist?(it) }

      if config_file
        existing_config = YAML.safe_load_file(config_file) || {}

        if existing_config.key?(provider_name)
          puts "Provider '#{provider_name}' already configured in #{config_file}"

          exit(1)
        end

        provider_section = YAML.dump({provider_name => config_keys.to_h { [it, ""] }}, indent: 2, line_width: 80).sub(/^---\n/, "")
        File.write(config_file, File.read(config_file) + "\n" + provider_section)

        puts "Updated #{config_file} with #{provider_name} provider"
      else
        configuration = YAML.dump({
          "provider" => provider_name,
          "path" => nil,
          provider_name => config_keys.to_h { |key| [key, ""] }
        }, indent: 2, line_width: 80).gsub(/^path:$/, "# path: ./output # uncomment to set a default folder")

        File.write(".beam_up.yml", configuration)
        puts "Created .beam_up.yml with #{provider_name} provider"
      end
    end

    def deploy_or_help
      if File.exist?(".beam_up.yml") || File.exist?("config/beam_up.yml")
        deploy
      else
        puts "No .beam_up.yml found. Run `beam_up init PROVIDER` to get started"
        puts

        help
      end
    end

    def deploy
      input = parse_options

      beamed = BeamUp.deploy! input, provider: @provider, config_file: @config_file

      puts beamed.message
      puts "Deploy ID: #{beamed.deploy_id}" if beamed.deploy_id

      exit(1) unless beamed.success?
    end

    def scotty
      puts <<~STARFLEET
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*+=%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%***++@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%***+++=@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%**+++++++%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#*+++++++++-%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@***+*++++++++:@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%****++++++++++=@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@***+*++++++++++++=%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@%***+++++++++++++++=%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@*****+++++++++++++++=%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@@@%****+++++++++++++++++=%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@@@@@@%+****+++++++++++++++++++=%@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@@@@@@@%%=##%***+++++++++++++++++++++==++*-%%@@@@@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@@@%%%#*+-=#*%%*++++++++++++++++++++++++==*+*#.++**@@@@@@@@@@@@@@@@@@
        @@@@@@@@@@@@%-*+.#%%#####**++++++++++++++++++++++++++=+++++++*%+*%@@@@@@@@@@@@@@
        @@@@@@@@%%%*+=#%%%%#%%%%-*+++++++++++++++++++++++++++===++++=+==*:=**@@@@@@@@@@@
        @@@@@@%%*+-#%%%%%%%%###%*++++++++++++++++++++++++++++==-=++++++====+.+:%@@@@@@@@
        @@@@@%*+-#%%%%%%%%#%#%#=+++++++++++++++++++++++++++++===:=++++++======*==%@@@@@@
        @@@@%*:###%%%%%######%%++++++++++++++++++++++++++++======:++++++========*=:%@@@@
        @@%%+-###############%-++++++++++++++++++++++++++++=======.+++++++========:*%@@@
        @@#+=#################++++++++++++++++++++++++++++++=======-++++++=+=======:*%@@
        @%+-**##############%=+++++++++++++++++++++++++++++=========+++++++++=======:*@@
        %*:*******##########%=++++++++++++++++++++++++++============.+++++++=========.=%
        **:**+********#####*#+++++++++++++++++++++++++=============== +++++++=========*%
        =*=++++++**********#.++++++++++++++++++++++++================-=+++++++=======**:
        +*.+====++++*******#++++++++++++++++++++======================.+++++++=======++:
        *#:==-====++++++++-.+++++++++++++==+===========================:++++=========+*=
        %-*+----=====+++++- ++++++=====================================:=++==========%+%
        @*:*#----=======+=*==========================-++++#.============-===========#*=%
        @%=:**=---=====+=-#======================-:+++++++++:-=====================*#-@@
        @@%==*.+---======..=====================:+++++++++++++..=========.========%*-@@@
        @@@@%--*-=--=====. ===================:++++++++++++++++.:========-======+%+%@@@@
        @@@@@%=--*-======-.=================:+++++++++++++++++++*.+=======.===+**=%@@@@@
        @@@@@@@%#- #:*==:%-=================++++++++++++++++++++++ -======-=*%+=%%@@@@@@
        @@@@@@@@@@%-=:#:% ==============-:+++++++++++++++++++++++++.:====== -%@@@@@@@@@@
        @@@@@@@@@@@@@%---.=============:++++++++++++++++++++++++++++ +======%@@@@@@@@@@@
        @@@@@@@@@@@@@@@%-.=============+++++++++++++++++++++++++#**#*--===== @@@@@@@@@@@
        @@@@@@@@@@@@@@@%=:==========.%%+.:-%*****+*+**#*---%#*+--::*%::-====-%@@@@@@@@@@
        @@@@@@@@@@@@@@%* :=========*#:::::-=+-::-===+=-:::::+%@@@@@@@%.:-====.@@@@@@@@@@
        @@@@@@@@@@@@@@@= -=======:%%@@@@@%%%%%%%%%@@@@@@@@@@@@@@@@@@@@@::.===-%@@@@@@@@@
        @@@@@@@@@@@@@@@= ======:%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@=:--==+@@@@@@@@@
        @@@@@@@@@@@@@@@=.=====-%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@=-.==-@@@@@@@@@
        @@@@@@@@@@@@@@%=:====:@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@--+==%@@@@@@@@
        @@@@@@@@@@@@@@%=:==:%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%-===%@@@@@@@@
        @@@@@@@@@@@@@@@=:=:@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@-:-@@@@@@@@@
        @@@@@@@@@@@@@@%-:+@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
      STARFLEET
      exit
    end

    private

    def help
      puts <<~HELP
        Usage:
          beam_up init PROVIDER                 # Initialize config file for provider
          beam_up [FOLDER]                      # Deploy using .beam_up.yml config
          beam_up [FOLDER] --to PROVIDER        # Deploy with provider override
          beam_up [FOLDER] --provider PROVIDER  # Alias for --to
          beam_up [FOLDER] --config FILE        # Use a specific config file

        Examples:
          beam_up init netlify
          beam_up ./output
          beam_up ./output --to aws_s3
          beam_up ./output --config /path/to/config.yml
      HELP

      exit
    end

    def parse_options
      if @arguments.first && !@arguments.first.start_with?("--")
        input = @arguments.shift
      end

      OptionParser.new do |options|
        options.on("--provider PROVIDER", "Override the provider from config") do |value|
          @provider = value
        end

        options.on("--to PROVIDER", "Alias for --provider") do |value|
          @provider = value
        end

        options.on("--config FILE", "Use a specific config file") do |value|
          @config_file = value
        end

        options.on("--help", "-h", "Show this help") do
          help

          exit
        end
      end.parse!(@arguments)

      input
    end
  end
end
