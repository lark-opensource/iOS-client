#include <lxml.hpp>

namespace lxml {

void XMLWriter::NormalNode::to_string(std::stringstream& ss) {
  ss << "<" << m_name;

  if (!m_attr.empty()) {
    ss << " ";
    for (auto const& it : m_attr) {
      ss << it.first << "=\"" << it.second << "\" ";
    }
  }

  end_begin_tag(ss);

  if (!m_children.empty()) {
    for (auto const& child : m_children) {
      child->to_string(ss);
    }
  }

  end_tag(ss);
}

void XMLWriter::NormalNode::add_child(std::unique_ptr<Node> child) {
  m_children.emplace_back(std::move(child));
}

void XMLWriter::NormalNode::add_attr(const std::string& name,
                                     const std::string& content) {
  m_attr[name] = content;
}

void XMLWriter::ContentNode::to_string(std::stringstream& ss) {
  ss << m_content;
}

void XMLWriter::ContentNode::add_child(std::unique_ptr<Node> child) {
  parent()->add_child(std::move(child));
}

void XMLWriter::begin_tag(const std::string& name) {
  auto parent = m_current;

  auto node = std::make_unique<NormalNode>(name);

  bool need_insert = m_current == nullptr;

  node->set_parent(m_current);

  m_current = node.get();

  if (need_insert) {
    m_nodes.emplace_back(std::move(node));
  } else {
    parent->add_child(std::move(node));
  }
}

void XMLWriter::add_attribute(const std::string& name,
                              const std::string& content) {
  if (!m_current) {
    return;
  }

  m_current->add_attr(name, content);
}

void XMLWriter::add_content(const std::string& content) {
  if (!m_current) {
    return;
  }

  auto c_node = std::make_unique<ContentNode>(content);

  c_node->set_parent(m_current);

  m_current->add_child(std::move(c_node));
}

void XMLWriter::end_tag(const std::string& name) {
  if (!m_current) {
    return;
  }

  m_current = m_current->parent();
}

std::string XMLWriter::to_string() {
  std::stringstream ss;

  for (auto const& node : m_nodes) {
    node->to_string(ss);
  }

  return ss.str();
}

}  // namespace lxml