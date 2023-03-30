class ChatBladder

  API_KEY_ENVVAR = "OPENAI_API_KEY"
  Last = "last"

  module Hider

    private def prettymangle rep
     rep.dup.tap { |istr|
       self.class.instance_variable_get(:@hidden_instance_variables)&.tap { |hvar|
         istr.gsub! /@(#{hvar.each.lazy.map(&:to_s).map(&Regexp.method(:escape)).to_a.join(?|)})=[^>,]+([,>])/, '@\1=(redacted)\2'
       }
     }
    end

    def inspect
      prettymangle super
    end

    def pretty_print pp
      "".tap { |b|
        PP.new(b, *%i[maxwidth newline].map(&pp.method(:send)), &pp.genspace).tap { |ppx|
          ppx.pp_object self
          ppx.flush
        }
      }.then(&method(:prettymangle)).then(&pp.method(:text))
    end

  end

  @hidden_instance_variables = %i[api_key]
  include Hider

  def initialize session: nil, api_key: nil, api_key_file: nil
    self.session = session
    self.api_key = case api_key
    when ENV, :env, :environ, :environment
      ENV[API_KEY_ENVVAR]
    when nil
      api_key_file&.then { |f| IO.read(File.expand_path(f)).strip }
    else
      api_key
    end or raise ArgumentError, "either API key or key file is needed"
  end

  attr_reader :session
  attr_accessor :api_key

  def session= sess
    @session = sess&.to_s
  end

  def make_call session: nil, params: nil, key: false, sysargs: nil, &blk
    [%w[python -m chatblade], session&.then { |s| ["-S", s.to_s] }, params].flatten.compact.then { |aa|
      [key ? {API_KEY_ENVVAR=>@api_key} : nil, aa].compact
    }.then { |aa|
      blk ? IO.popen(*aa, *[sysargs].flatten.compact, &blk) : system(*[aa, sysargs].flatten.compact)
    }.tap {
      $?.success? or raise "chatblade failed"
    }
  end

  def ask question_or_session=nil, session: @session, prompt: nil, quiet: false, params0: "-s", params: nil
    if block_given?
      question = yield
      session ||= question_or_session
    else
      question = question_or_session
    end
    puts "# Session: #{session&.to_s.inspect}" unless quiet

    make_call(session:, params: [params0, params, prompt&.then { ["--prompt-file", _1.to_s] }].flatten.compact, key: true, sysargs: ?w) { |f| f << question.strip }
    nil
  end

  def list_sessions
    make_call(params: "--session-list") { |f| f.readlines(chomp: true) }
  end

  def get_session_path session=@session
    make_call(session:, params: "--session-path") { |f| f.read.chomp  }
  end

  def get_session session=@session
    make_call session:, params: "--session-dump", &YAML.method(:load)
  end

  def rename_session session=@session, to:
    make_call session:, params: ["--session-rename", to.to_s]
    nil
  end

  def delete_session session=@session
    make_call session:, params: "--session-delete"
    nil
  end

  def print_session session=@session, pretty: true, extract: false
    make_call session:, params: extract ? "--extract" : (pretty ? nil : "--raw")
    nil
  end

end
