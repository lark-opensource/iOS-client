// Copyright 2017 The Lynx Authors. All rights reserved.

#ifndef LYNX_STARLIGHT_LAYOUT_NODE_H_
#define LYNX_STARLIGHT_LAYOUT_NODE_H_

#include <stddef.h>

namespace lynx {
namespace starlight {
class Node {
 public:
  Node() : previous_(NULL), next_(NULL) {}
  virtual ~Node() {}
  inline Node* Next() { return next_; }
  inline Node* Previous() { return previous_; }
  friend class ContainerNode;

 private:
  Node* previous_;
  Node* next_;
};
}  // namespace starlight
}  // namespace lynx

#endif  // LYNX_STARLIGHT_LAYOUT_NODE_H_
