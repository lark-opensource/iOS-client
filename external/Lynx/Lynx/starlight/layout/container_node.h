// Copyright 2017 The Lynx Authors. All rights reserved.

#ifndef LYNX_STARLIGHT_LAYOUT_CONTAINER_NODE_H_
#define LYNX_STARLIGHT_LAYOUT_CONTAINER_NODE_H_

#include "starlight/layout/node.h"

namespace lynx {
namespace starlight {
class ContainerNode : public Node {
 public:
  ContainerNode()
      : parent_(NULL), first_child_(NULL), last_child_(NULL), child_count_(0) {}
  virtual ~ContainerNode();
  /**
   *  Insert a layout node after a node.
   *  @param child the node will be inserted
   *  @param node before which child will be inserted
   */
  void InsertChildBefore(ContainerNode* child, ContainerNode* node);
  void AppendChild(ContainerNode* child);

  void RemoveChild(ContainerNode* child);

  Node* FirstChild() const { return first_child_; }
  Node* LastChild() const { return last_child_; }

  Node* Find(int n);

  int GetChildCount() { return child_count_; }

  ContainerNode* parent() { return parent_; }

 protected:
  ContainerNode* parent_;

 private:
  Node* first_child_;
  Node* last_child_;

  int child_count_;
};
}  // namespace starlight
}  // namespace lynx

#endif  // LYNX_STARLIGHT_LAYOUT_CONTAINER_NODE_H_
