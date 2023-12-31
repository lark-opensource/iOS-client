def incTag(currentTag)
    @tag = currentTag[0]
    @tail = (/[\d]+$/.match(@tag).to_s.to_i + 1).to_s
    @nextTag = @tag.dup
    @nextTag.gsub!(/[\d]+$/, @tail)
    puts @nextTag
end

incTag(ARGV)