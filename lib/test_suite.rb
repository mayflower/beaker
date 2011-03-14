class TestSuite
  attr_reader :test_files, :random_seed
  attr_reader :log, :options, :config

  def initialize(log, options, config)
    @log     = log
    @options = options
    @config  = config

    @test_files = []
    Array(options[:tests] || 'tests').each do |root|
      if File.file? root then
        @test_files << root
      else
        @test_files += Dir[File.join(root, "**/*.rb")].select { |f| File.file?(f) }
      end
    end
    fail "no test files found..." if @test_files.empty?

    if options[:random]
      @random_seed = (options[:random] == true ? Time.now : options[:random]).to_i
      srand @random_seed
      @test_files = @test_files.sort_by { rand }
    else
      @test_files = @test_files.sort
    end
  end

  def run
    summary = []
    Log.notify "Using random seed #{random_seed}" if random_seed
    test_files.each do |test_file|
      Log.notify
      result = TestCase.new(config, options, test_file).run_test
      status_color = case result.test_status
                     when :pass
                       Log::GREEN
                     when :fail
                       Log::RED
                     when :error
                       Log::YELLOW
                     end
      Log.notify "#{status_color}#{test_file} #{result.test_status}ed#{Log::NORMAL}"
      log.record_result(test_file, result)
    end
    log.results
  end
end
