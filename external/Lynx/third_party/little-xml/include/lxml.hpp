#ifndef LITTLE_XML_INCLUDE_LXML_HPP
#define LITTLE_XML_INCLUDE_LXML_HPP

#include <cstddef>
#include <cstdint>
#include <map>
#include <memory>
#include <sstream>
#include <vector>

namespace lxml {

class XMLReader final {
 public:
  class ReaderDelegate {
   public:
    virtual ~ReaderDelegate() = default;

    virtual void HandleBeginTag(const char* name, size_t len) = 0;

    virtual void HandleEndTag(const char* name, size_t len) = 0;

    virtual void HandleAttribute(const char* name, size_t n_len,
                                 const char* value, size_t v_len) = 0;

    virtual void HandleContent(const char* content, size_t len) = 0;

    virtual void HandleError(const char* index, size_t offset,
                             size_t total) = 0;

    virtual void HandleEnd() = 0;
  };

  XMLReader(const char* content, size_t length)
      : m_content(content), m_length(length), m_current(0) {}

  ~XMLReader() = default;

  bool Read(XMLReader::ReaderDelegate* delegate);

 private:
  bool ReachEnd();

  bool ReadInternal();

  bool ParseNode();
  bool ParseAttr();
  bool ParseContent();

  void HandleError();
  // skip empty space , \t \n ...
  void SkipAll();
  // only skip empty space
  void SkipWhiteSpace();
  // skip <!--   -->
  void SkipComment();
  bool SkipTag();
  bool MoveCursor();
  bool AdvanceCursor(size_t advance);

  char Peek();
  char PeekNext();
  char PeekNextNext();
  char PeekNextNextNext();

  size_t TagName();

  size_t ScanNextString();

  bool KeepSkipUntil(const char* end_with);

  const char* CurrCursor() const { return m_content + m_current; }

  size_t LeftLength() const { return m_length - m_current; }

 private:
  const char* m_content;
  size_t m_length;
  size_t m_current;
  ReaderDelegate* m_delegate = nullptr;
};

class XMLWriter {
  struct Node {
    Node() = default;
    virtual ~Node() = default;

    virtual void to_string(std::stringstream& ss) = 0;

    virtual void add_child(std::unique_ptr<Node> child) = 0;

    virtual void add_attr(std::string const& name,
                          const std::string& content) = 0;

    void set_parent(Node* parent) { m_parent = parent; }

    Node* parent() const { return m_parent; }

   private:
    Node* m_parent = nullptr;
  };

  struct NormalNode : public Node {
   public:
    NormalNode(std::string name) : Node(), m_name(std::move(name)) {}

    ~NormalNode() override = default;

    void to_string(std::stringstream& ss) override;

    void add_child(std::unique_ptr<Node> child) override;

    void add_attr(std::string const& name, const std::string& content) override;

   private:
    void end_begin_tag(std::stringstream& ss) { ss << ">"; }

    void end_tag(std::stringstream& ss) { ss << "</" << m_name << ">"; }

   private:
    std::string m_name;
    std::map<std::string, std::string> m_attr = {};
    std::vector<std::unique_ptr<Node>> m_children = {};
  };

  struct ContentNode : public Node {
   public:
    ContentNode(std::string content) : Node(), m_content(std::move(content)) {}

    ~ContentNode() override = default;

    void to_string(std::stringstream& ss) override;

    void add_child(std::unique_ptr<Node> child) override;

    void add_attr(std::string const& name,
                  const std::string& content) override {}

   private:
    std::string m_content;
  };

 public:
  XMLWriter() = default;
  ~XMLWriter() = default;

  void begin_tag(const std::string& name);

  void add_attribute(const std::string& name, const std::string& content);

  void add_content(const std::string& content);

  void end_tag(const std::string& name);

  std::string to_string();

 private:
  void begin_tag_internal(const std::string& name);

 private:
  std::stringstream m_ss;
  std::vector<std::unique_ptr<Node>> m_nodes = {};
  Node* m_current = nullptr;
};

}  // namespace lxml

#endif  // LITTLE_XML_INCLUDE_LXML_HPP