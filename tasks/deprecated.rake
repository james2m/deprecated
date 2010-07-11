require 'find'
def deprecated
  {
    '@params'         => 'Use params[] instead',
    '@session'        => 'Use session[] instead',
    '@flash'          => 'Use flash[] instead',
    '@request'        => 'Use request[] instead',
    '@env'            => 'Use env[] instead',
    'find_all'        => 'Use all() instead',
    'find_first'      => 'Use first() instead',
    'render_partial'  => 'Use render :partial instead',
    'paginate'        => 'The default paginator is slow. Writing your own may be faster',
    'start_form_tag'  => 'Use form_for or form_tag </form> instead',
    'end_form_tag'    => 'Use form_for or form_tag </form> instead',
    ':post => true'   => 'Use :method => :post instead',
    'component'       => 'nonexistent in Rails 2.3. If you still need it, install the render_component plugin',
    'render_component'  => 'nonexistent in Rails 2.3. If you still need it, install the render_component plugin',
    'session_enabled?'  => 'is deprecated because sessions are lazy-loaded now',
    'protect_from_forgery.*(:digest|:secret)' => 'The :digest and :secret options to protect_from_forgery are deprecated and have no effect.',
    'formatted_polymorphic_url' => 'is deprecated. Use polymorphic_url with :format instead.',
    'set_cookie.*:http_only'    => 'The :http_only option in ActionController::Response#set_cookie has been renamed to :httponly',
    'to_sentence.*(:connector|:two_words_connector)' => 'The :connector and :skip_last_comma options of to_sentence have been replaced by :words_connnector, , and :last_word_connector options.',
    '\.transaction\(.*\)' => 'Object transactions <a href="http://dev.rubyonrails.org/changeset/6439">are removed</a> use <a href="http://code.bitsweat.net/svn/object_transactions/">object_transactions<\a> plugin if you must use object transactions'
  }
end

# Take a directory, and a list of patterns to match, and a list of
# filenames to avoid
def recursive_search(dir,patterns,
         excludes=[/\.svn/, /,v$/, /\.cvs$/, /\.git$/, /\.tmp$/, /^RCS$/, /^SCCS$/])
  results = Hash.new{|h,k| h[k] = []}

  Find.find(dir) do |path|
    fb =  File.basename(path) 
    next if excludes.any?{|e| fb =~ e}
    if File.directory?(path)
      if fb =~ /\.{1,2}/ 
        Find.prune
      else
        next
      end
    else  # file...
      File.open(path, 'r') do |f|
        ln = 1
        while (line = f.gets)
          line = line.to_s.gsub(/\t/, '  ')
          patterns.each do |p|
            if col = Regexp.new(p) =~ line
              results[p] << {:path => path, :ln => ln, :col => col, :line => line}
            end
          end
          ln += 1
        end
      end
    end
  end
  return results
end

def template
  %{
<html>
  <head>
    <title>Deprecated in this application</title>
    <style media="screen">
      body {font: normal normal normal 75% Verdana,sans-serif; color: #333;}
      h1 {font: italic normal bold 1.8em Verdana, sans-serif; margin-bottom: 10px;}
      h2 {font: normal normal bold 1.55em Verdana, sans-serif; text-decoration: underline; margin-bottom: 10px;}
      h3 {font: italic normal bold 1.2em Verdana, sans-serif; margin-bottom: 5px;}
      div {margin-bottom: 20px;}
    </style>
  </head>
  <body>
    <h1>Deprecated in this application</h1>
<% deprecated.each do |key, warning| %>
    <div>
      <h2><%= key %></h2>
    <% unless @results[key].empty? %>
      <h3>!!!! <%= warning %></h3>
      <% @results[key].each do |line| %>
      <a href="txmt://open?url=file://<%= line[:path] %>&line=<%= line[:ln] %>&column=<%= line[:col] %>">
        <%= line[:path] %>:<%= line[:ln] %> col:<%= line[:col] +1 %>
      </a>
      <br />
      <% end %>
    <% else %>
      <p>No problems found</p>
    <% end %>
    </div>
<% end %>

  </body>
</html>
  }
end

desc "Checks your app and warns you if you are using deprecated code."
task :deprecated => :environment do
  file = 'tmp/deprecated.html'

  @results = recursive_search("#{File.expand_path('app', RAILS_ROOT)}",deprecated.keys)
  File.open(file, "w+") do |f|
    f.write(ERB.new(template).result())
  end
  sh %{open #{file}}
end
