require 'spec'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'diffy'))

describe Diffy::Diff do

  describe "diffing two files" do
    def tempfile(string)
      t = Tempfile.new('diffy-spec')
      t.print(string)
      t.flush
      t.path
    end

    it "should accept file paths as arguments" do
      string1 = "foo\nbar\nbang\n"
      string2 = "foo\nbang\n"
      path1, path2 = tempfile(string1), tempfile(string2)
      Diffy::Diff.new(path1, path2, :source => 'files').to_s.should == <<-DIFF
 foo
-bar
 bang
      DIFF
    end

    describe "with no line different" do
      before do
        string1 = "foo\nbar\nbang\n"
        string2 = "foo\nbar\nbang\n"
        @path1, @path2 = tempfile(string1), tempfile(string2)
      end

      it "should show everything" do
        Diffy::Diff.new(@path1, @path2, :source => 'files').to_s.should == <<-DIFF
 foo
 bar
 bang
        DIFF
      end
    end
  end

  describe "#to_s" do
    describe "with no line different" do
      before do
        @string1 = "foo\nbar\nbang\n"
        @string2 = "foo\nbar\nbang\n"
      end

      it "should show everything" do
        Diffy::Diff.new(@string1, @string2).to_s.should == <<-DIFF
 foo
 bar
 bang
        DIFF
      end
    end
    describe "with one line different" do
      before do
        @string1 = "foo\nbar\nbang\n"
        @string2 = "foo\nbang\n"
      end

      it "should show one line removed" do
        Diffy::Diff.new(@string1, @string2).to_s.should == <<-DIFF
 foo
-bar
 bang
        DIFF
      end

      it "to_s should accept a format key" do
        Diffy::Diff.new(@string1, @string2).to_s(:color).
          should == " foo\n\e[31m-bar\e[0m\n bang\n"
      end

      it "should accept a default format option" do
        old_format = Diffy::Diff.default_format
        Diffy::Diff.default_format = :color
        Diffy::Diff.new(@string1, @string2).to_s.
          should == " foo\n\e[31m-bar\e[0m\n bang\n"
        Diffy::Diff.default_format = old_format
      end

      it "should show one line added" do
        Diffy::Diff.new(@string2, @string1).to_s.should == <<-DIFF
 foo
+bar
 bang
        DIFF
      end
    end

    describe "with one line changed" do
      before do
        @string1 = "foo\nbar\nbang\n"
        @string2 = "foo\nbong\nbang\n"
      end
      it "should show one line added and one removed" do
        Diffy::Diff.new(@string1, @string2).to_s.should == <<-DIFF
 foo
-bar
+bong
 bang
        DIFF
      end
    end

    describe "with totally different strings" do
      before do
        @string1 = "foo\nbar\nbang\n"
        @string2 = "one\ntwo\nthree\n"
      end
      it "should show one line added and one removed" do
        Diffy::Diff.new(@string1, @string2).to_s.should == <<-DIFF
-foo
-bar
-bang
+one
+two
+three
        DIFF
      end
    end

    describe "with a somewhat complicated diff" do
      before do
        @string1 = "foo\nbar\nbang\nwoot\n"
        @string2 = "one\ntwo\nthree\nbar\nbang\nbaz\n"
        @diff = Diffy::Diff.new(@string1, @string2)
      end
      it "should show one line added and one removed" do
        @diff.to_s.should == <<-DIFF
-foo
+one
+two
+three
 bar
 bang
-woot
+baz
        DIFF
      end

      it "should make an awesome simple html diff" do
        @diff.to_s(:html_simple).should == <<-HTML
<div class="diff">
  <ul>
    <li class="del"><del>foo</del></li>
    <li class="ins"><ins>one</ins></li>
    <li class="ins"><ins>two</ins></li>
    <li class="ins"><ins>three</ins></li>
    <li class="unchanged"><span>bar</span></li>
    <li class="unchanged"><span>bang</span></li>
    <li class="del"><del>woot</del></li>
    <li class="ins"><ins>baz</ins></li>
  </ul>
</div>
        HTML
      end

      it "should accept overrides to diff's options" do
        @diff = Diffy::Diff.new(@string1, @string2, :diff => "--rcs")
        @diff.to_s.should == <<-DIFF
d1 1
a1 3
one
two
three
d4 1
a4 1
baz
          DIFF
      end
    end

    describe "html" do
      it "should not allow html injection on the last line" do
        @string1 = "hahaha\ntime flies like an arrow\nfoo bar\nbang baz\n<script>\n"
        @string2 = "hahaha\nfruit flies like a banana\nbang baz\n<script>\n"
        @diff = Diffy::Diff.new(@string1, @string2)
        html = <<-HTML
<div class="diff">
  <ul>
    <li class="unchanged"><span>hahaha</span></li>
    <li class="del"><del><strong>time</strong> flies like a<strong>n arrow</strong></del></li>
    <li class="del"><del><strong>foo bar</strong></del></li>
    <li class="ins"><ins><strong>fruit</strong> flies like a<strong> banana</strong></ins></li>
    <li class="unchanged"><span>bang baz</span></li>
    <li class="unchanged"><span>&lt;script&gt;</span></li>
  </ul>
</div>
        HTML
        @diff.to_s(:html).should ==  html
      end

      it "should highlight the changes within the line" do
        @string1 = "hahaha\ntime flies like an arrow\nfoo bar\nbang baz\n"
        @string2 = "hahaha\nfruit flies like a banana\nbang baz\n"
        @diff = Diffy::Diff.new(@string1, @string2)
        html = <<-HTML
<div class="diff">
  <ul>
    <li class="unchanged"><span>hahaha</span></li>
    <li class="del"><del><strong>time</strong> flies like a<strong>n arrow</strong></del></li>
    <li class="del"><del><strong>foo bar</strong></del></li>
    <li class="ins"><ins><strong>fruit</strong> flies like a<strong> banana</strong></ins></li>
    <li class="unchanged"><span>bang baz</span></li>
  </ul>
</div>
        HTML
        @diff.to_s(:html).should ==  html
      end

      it "should not duplicate some lines" do
        @string1 = "hahaha\ntime flies like an arrow\n"
        @string2 = "hahaha\nfruit flies like a banana\nbang baz"
        @diff = Diffy::Diff.new(@string1, @string2)
        html = <<-HTML
<div class="diff">
  <ul>
    <li class="unchanged"><span>hahaha</span></li>
    <li class="del"><del><strong>time</strong> flies like a<strong>n arrow</strong></del></li>
    <li class="ins"><ins><strong>fruit</strong> flies like a<strong> banana</strong></ins></li>
    <li class="ins"><ins><strong>bang baz</strong></ins></li>
  </ul>
</div>
        HTML
        @diff.to_s(:html).should ==  html
      end

      it "should escape html" do
        @string1 = "ha<br>haha\ntime flies like an arrow\n"
        @string2 = "ha<br>haha\nfruit flies like a banana\nbang baz"
        @diff = Diffy::Diff.new(@string1, @string2)
        html = <<-HTML
<div class="diff">
  <ul>
    <li class="unchanged"><span>ha&lt;br&gt;haha</span></li>
    <li class="del"><del><strong>time</strong> flies like a<strong>n arrow</strong></del></li>
    <li class="ins"><ins><strong>fruit</strong> flies like a<strong> banana</strong></ins></li>
    <li class="ins"><ins><strong>bang baz</strong></ins></li>
  </ul>
</div>
        HTML
        @diff.to_s(:html).should ==  html
      end

      it "should highlight the changes within the line with windows style line breaks" do
        @string1 = "hahaha\r\ntime flies like an arrow\r\nfoo bar\r\nbang baz\n"
        @string2 = "hahaha\r\nfruit flies like a banana\r\nbang baz\n"
        @diff = Diffy::Diff.new(@string1, @string2)
        html = <<-HTML
<div class="diff">
  <ul>
    <li class="unchanged"><span>hahaha</span></li>
    <li class="del"><del><strong>time</strong> flies like a<strong>n arrow</strong></del></li>
    <li class="del"><del><strong>foo bar</strong></del></li>
    <li class="ins"><ins><strong>fruit</strong> flies like a<strong> banana</strong></ins></li>
    <li class="unchanged"><span>bang baz</span></li>
  </ul>
</div>
        HTML
        @diff.to_s(:html).should ==  html
      end
    end

    it "should escape diffed html in html output" do
      diff = Diffy::Diff.new("<script>alert('bar')</script>", "<script>alert('foo')</script>").to_s(:html)
      diff.should include('&lt;script&gt;')
      diff.should_not include('<script>')
    end

    it "should be easy to generate custom format" do
      Diffy::Diff.new("foo\nbar\n", "foo\nbar\nbaz\n").map do |line|
        case line
        when /^\+/ then "line #{line.chomp} added"
        when /^-/ then "line #{line.chomp} removed"
        end
      end.compact.join.should == "line +baz added"
    end

    it "should let you iterate over chunks instead of lines" do
      Diffy::Diff.new("foo\nbar\n", "foo\nbar\nbaz\n").each_chunk.map do |chunk|
        chunk
      end.should == [" foo\n bar\n", "+baz\n"]
    end

    it "should allow chaining enumerable methods" do
      Diffy::Diff.new("foo\nbar\n", "foo\nbar\nbaz\n").each.map do |line|
        line
      end.should == [" foo\n", " bar\n", "+baz\n"]
    end
  end
end

