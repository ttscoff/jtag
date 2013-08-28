# encoding: utf-8
class String
  # convert "WikiLink" to "Wiki link"
  def break_camel
    return downcase if match(/\A[A-Z]+\z/)
    gsub(/([A-Z]+)([A-Z][a-z])/, '\1 \2').
    gsub(/([a-z])([A-Z])/, '\1 \2').
    downcase
  end

  def strip_markdown
    # strip all Markdown and Liquid tags
    gsub(/\{%.*?%\}/,'').
    gsub(/\[\^.+?\](\: .*?$)?/,'').
    gsub(/\s{0,2}\[.*?\]: .*?$/,'').
    gsub(/\!\[.*?\][\[\(].*?[\]\)]/,"").
    gsub(/\[(.*?)\][\[\(].*?[\]\)]/,"\\1").
    gsub(/^\s{1,2}\[(.*?)\]: (\S+)( ".*?")?\s*$/,'').
    gsub(/^\#{1,6}\s*/,'').
    gsub(/(\*{1,2})(\S.*?\S)\1/,"\\2").
    gsub(/(`{3,})(.*?)\1/m,"\\2").
    gsub(/^-{3,}\s*$/,"").
    gsub(/`(.+)`/,"\\1").
    gsub(/\n{2,}/,"\n\n")
  end

  def strip_tags
    return CGI.unescapeHTML(
        gsub(/<(script|style|pre|code|figure).*?>.*?<\/\1>/im, '').
        gsub(/<!--.*?-->/m, '').
        gsub(/<(img|hr|br).*?>/i, " ").
        gsub(/<(dd|a|h\d|p|small|b|i|blockquote|li)( [^>]*?)?>(.*?)<\/\1>/i, " \\3 ").
        gsub(/<\/?(dt|a|ul|ol)( [^>]+)?>/i, " ").
        gsub(/<[^>]+?>/, '').
        gsub(/\[\d+\]/, '').
        gsub(/&#8217;/,"'").gsub(/&.*?;/,' ').gsub(/;/,' ')
    ).lstrip.gsub("\xE2\x80\x98","'").gsub("\xE2\x80\x99","'").gsub("\xCA\xBC","'").gsub("\xE2\x80\x9C",'"').gsub("\xE2\x80\x9D",'"').gsub("\xCB\xAE",'"').squeeze(" ")
  end

  def strip_urls
    gsub(/(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?/i,"")
  end

  def strip_all
    strip_tags.strip_markdown.strip
  end

end
