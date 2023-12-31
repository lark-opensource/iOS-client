# frozen_string_literal: true

RSpec.describe GitDiffInfo do
  it 'works' do
    # stub IO.popen
    allow(IO).to receive(:popen).and_return(<<~DIFF)
      diff --git a/bin/userarch/check.rb b/bin/userarch/check.rb
      index a7ac1f518c..35b99d7224 100755
      --- a/bin/userarch/check.rb
      +++ b/bin/userarch/check.rb
      @@ -17,0 +18 @@ def print_usage
      ... any changes, no use...
      @@ -79,2 +80 @@ class App
      @@ -84,0 +85,3 @@ class App
      @@ -98 +101 @@ class App
      @@ -120,2 +123,2 @@ class App
      @@ -126,0 +130,5 @@ class App
      @@ -163 +171 @@ class App
      @@ -231 +241,0 @@ class App # not include in b
      diff --git a/bin/userarch/ci.yml b/bin/userarch/ci.yml
      new file mode 100644
      index 0000000000..a71bcaec25
      --- /dev/null
      +++ b/bin/userarch/ci.yml
      @@ -0,0 +1,10 @@
      diff --git a/bin/userarch/config.yml b/bin/userarch/config.yml
      index 804a075fa5..e9bdf6a992 100644
      --- a/bin/userarch/config.yml
      +++ b/bin/userarch/config.yml
      @@ -1,0 +2 @@
      @@ -13,2 +14,2 @@ excludePath:
    DIFF
    diff = GitDiffInfo.new
    expect(diff.changed_b).to eq({
                                   'bin/userarch/check.rb' => [18...19, 80...81, 85...88, 101...102, 123...125,
                                                               130...135, 171...172],
                                   'bin/userarch/ci.yml' => [1...11],
                                   'bin/userarch/config.yml' => [2...3, 14...16]
                                 })
    expect(diff.changed_a).to eq({
                                   'bin/userarch/check.rb' => [79...81, 98...99, 120...122, 163...164, 231...232],
                                   'bin/userarch/config.yml' => [13...15]
                                 })
  end
end
