#include <cstring>
#include <lxml.hpp>

namespace lxml {

static bool is_alpha(char c) {
  return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z');
}

static bool is_number(char c) { return (c >= '0' && c <= '9'); }

enum class TokenType {
  LEFT_TAG,      // <
  RIGHT_TAG,     // >
  SLASH,         // /
  QUES_MARK,     // ?
  MINS,          // -
  DOUBLE_QUOTE,  // "
};

bool XMLReader::Read(XMLReader::ReaderDelegate* delegate) {
  m_delegate = delegate;
  return ReadInternal();
}

bool XMLReader::ReachEnd() { return m_current > m_length; }

bool XMLReader::ReadInternal() {
  if (m_delegate == nullptr) {
    return false;
  }

  if (m_length == 0 || m_content == nullptr) {
    m_delegate->HandleEnd();
    return false;
  }

  while (!ReachEnd()) {
    if (!ParseNode()) {
      break;
    }
  }

  m_delegate->HandleEnd();
  return true;
}

bool XMLReader::ParseNode() {
  SkipAll();
  SkipComment();

  if (ReachEnd()) {
    HandleError();
    return false;
  }

  if (Peek() == '<' && PeekNext() == '/') {
    // this is reach a </ end
    return false;
  }

  if (m_current == m_length) {
    // end of all tag
    return false;
  }

  if (Peek() != '<') {
    // some thing is error
    HandleError();
    return false;
  }

  if (!MoveCursor()) {
    HandleError();
    return false;
  }

  if (Peek() == '?') {
    return SkipTag();
  }

  if (!is_alpha(Peek())) {
    HandleError();
    return false;
  }

  size_t tag_name_len = TagName();

  if (tag_name_len == 0) {
    HandleError();
    return false;
  }

  const char* tag_name = CurrCursor();
  m_delegate->HandleBeginTag(tag_name, tag_name_len);

  AdvanceCursor(tag_name_len);

  while (ParseAttr()) {
    SkipAll();
  }

  SkipAll();

  if (ReachEnd()) {
    HandleError();
    return false;
  }

  if (Peek() == '>') {
    MoveCursor();
    // need to handle content or child node
    while (!ReachEnd()) {
      SkipAll();
      if (Peek() == '<' && PeekNext() == '/') {
        break;
      } else if (Peek() == '<') {
        ParseNode();
      } else {
        ParseContent();
      }
    }
  }

  if (Peek() == '/' && PeekNext() == '>') {
    m_delegate->HandleEndTag(tag_name, tag_name_len);
    MoveCursor();
    MoveCursor();
    return true;

  } else if (Peek() == '<' && PeekNext() == '/') {
    // handle tag end
    MoveCursor();
    MoveCursor();
    KeepSkipUntil(">");

    if (ReachEnd()) {
      HandleError();
      return false;
    }

    m_delegate->HandleEndTag(tag_name, tag_name_len);
    return true;
  } else {
    HandleError();
    return false;
  }

  return true;
}

bool XMLReader::ParseAttr() {
  SkipWhiteSpace();

  if (ReachEnd()) {
    return false;
  }

  if (Peek() == '>') {
    // no attribute
    return false;
  }

  if (!is_alpha(Peek())) {
    return false;
  }

  const char* attr_name = CurrCursor();
  size_t attr_name_len = ScanNextString();

  if (attr_name_len == 0) {
    return false;
  }

  AdvanceCursor(attr_name_len);

  if (Peek() != '=') {
    return false;
  }

  // walk through =
  MoveCursor();

  char col = 0;
  if (Peek() == '\'') {
    col = '\'';
  } else if (Peek() == '\"') {
    col = '\"';
  } else {
    return false;
  }

  // walk through "
  MoveCursor();

  const char* attr_content = CurrCursor();
  while (!ReachEnd() && Peek() != col) {
    MoveCursor();
  }

  if (ReachEnd()) {
    return false;
  }

  size_t attr_content_len = CurrCursor() - attr_content;

  if (attr_content_len == 0) {
    return false;
  }

  if (Peek() != col) {
    return false;
  }

  // walk through "
  MoveCursor();

  m_delegate->HandleAttribute(attr_name, attr_name_len, attr_content,
                              attr_content_len);

  return true;
}

bool XMLReader::ParseContent() {
  if (ReachEnd()) {
    return false;
  }

  const char* p_content = CurrCursor();
  if (!KeepSkipUntil("<")) {
    return false;
  }

  // fixme to make content right
  m_current--;

  size_t len = CurrCursor() - p_content;

  if (len == 0) {
    return false;
  }

  m_delegate->HandleContent(p_content, len);

  return true;
}

void XMLReader::HandleError() {
  auto current = CurrCursor();
  m_delegate->HandleError(current, current - m_content, m_length);
}

void XMLReader::SkipAll() {
  for (;;) {
    char c = Peek();
    switch (c) {
      case ' ':
      case '\t':
      case '\n':
      case '\r':
        MoveCursor();
        break;
      default:
        return;
    }
  }
}

void XMLReader::SkipWhiteSpace() {
  for (;;) {
    char c = Peek();
    if (c != ' ') {
      return;
    }

    MoveCursor();
  }
}

void XMLReader::SkipComment() {
  if (std::memcmp(m_content + m_current, "<!--", 4) != 0) {
    // not a comment tag
    return;
  }

  if (!KeepSkipUntil("-->")) {
    // some thing is wrong
    HandleError();
    return;
  }

  if (ReachEnd()) {
    return;
  }

  if (std::memcmp(m_content + m_current, "-->", 3) == 0) {
    MoveCursor();
    MoveCursor();
    MoveCursor();
  }
}

bool XMLReader::SkipTag() { return KeepSkipUntil(">"); }

bool XMLReader::MoveCursor() {
  m_current++;
  return m_current <= m_length;
}

bool XMLReader::AdvanceCursor(size_t advance) {
  if (m_current + advance > m_length) {
    m_current = m_length;
    return false;
  }

  m_current += advance;
  return true;
}

char XMLReader::Peek() {
  if (ReachEnd()) {
    return '\0';
  }

  return m_content[m_current];
}

char XMLReader::PeekNext() {
  if (m_current + 1 > m_length) {
    return '\0';
  }

  return m_content[m_current + 1];
}

char XMLReader::PeekNextNext() {
  if (m_current + 2 > m_length) {
    return '\0';
  }

  return m_content[m_current + 2];
}

char XMLReader::PeekNextNextNext() {
  if (m_current + 3 > m_length) {
    return '\0';
  }

  return m_content[m_current + 3];
}

size_t XMLReader::TagName() {
  size_t cursor = m_current;
  while (is_alpha(m_content[cursor]) || is_number(m_content[cursor])) {
    cursor++;
  }

  return cursor - m_current;
}

size_t XMLReader::ScanNextString() {
  size_t cursor = m_current;

  while (is_alpha(m_content[cursor])) {
    cursor++;
  }

  return cursor - m_current;
}

bool XMLReader::KeepSkipUntil(const char* end_with) {
  size_t len = std::strlen(end_with);

  bool double_quote = false;
  while (!ReachEnd()) {
    // move cursor untile next quote
    if (double_quote) {
      while (!ReachEnd() && Peek() != '"') {
        MoveCursor();
      }

      if (ReachEnd()) {
        return false;
      }

      MoveCursor();
      double_quote = false;
    } else {
      if (Peek() == '"') {
        double_quote = true;
        MoveCursor();
        continue;
      }

      if (LeftLength() < len) {
        return false;
      }

      if (std::memcmp(CurrCursor(), end_with, len) == 0) {
        while (len > 0) {
          MoveCursor();
          len--;
        }
        return true;
      }

      MoveCursor();
    }
  }

  return !ReachEnd();
}

}  // namespace lxml
