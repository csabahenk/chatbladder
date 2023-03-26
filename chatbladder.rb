class ChatBladder

  SESSION_DIR = "~/.cache/chatblade.d"
  API_KEY_ENVVAR = "OPENAI_API_KEY"

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

  def initialize session: nil, session_dir: SESSION_DIR, api_key: nil, api_key_file: nil
    self.session = session
    self.session_dir = session_dir
    self.api_key = case api_key
    when ENV, :env, :environ, :environment
      ENV[API_KEY_ENVVAR]
    when nil
      api_key_file&.then { |f| IO.read(File.expand_path(f)).strip }
    else
      api_key
    end or raise ArgumentError, "either API key or key file is needed"
  end

  attr_reader :session, :session_dir
  attr_accessor :api_key

  def session= sess
    @session = sess&.to_s
  end

  def session_dir= dir
    @session_dir = File.expand_path(dir)
  end

  def ask question=nil, session: @session, quiet: false, params: %w[-s]
    question ||= yield
    puts "# Session: #{session&.to_s.inspect}" unless quiet

    system({API_KEY_ENVVAR=>@api_key}, *[["python", "-m", "chatblade"],  params, session&.then { |s| ["-S", s.to_s] }, question].flatten.compact)
  end

  def list_sessions path: false
    Dir.glob(@session_dir + "/*.yaml").map { |f| path ? f : File.basename(f).sub(/\.[^.]*/, "") }
  end

  def get_session session=@session
    YAML.load_file(File.join(@session_dir, session + ".yaml"))
  end

  def print_session session=@session, via: nil
    get_session(session).then { |a|
      if via
        ->(&blk) { IO.popen([via].flatten, ?w, &blk) }
      else
        ->(&blk) { blk.(STDOUT) }
      end.call { |f|
        a.each { |u,m| f.puts "**" + u.upcase + "**: " + m, "" }}
      }
      nil
  end

end
