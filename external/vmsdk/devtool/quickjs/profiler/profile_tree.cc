// Copyright 2019 The Lynx Authors. All rights reserved

#include "devtool/quickjs/profiler/profile_tree.h"

#include <assert.h>

#include "devtool/quickjs/profiler/profile_generator.h"

namespace VMSDK {
namespace CpuProfiler {

// ProfileTree
ProfileTree::ProfileTree(LEPUSContext* ctx)
    : root_entry_(std::make_shared<CodeEntry>("(root)")),
      next_node_id_(1),
      root_(new ProfileNode(this, root_entry_, nullptr)),
      ctx_(ctx),
      next_function_id_(1) {}

ProfileTree::~ProfileTree() {
  DeleteNodesCallback cb;
  TraverseDepthFirst(&cb);
}

unsigned ProfileTree::GetFunctionId(const ProfileNode* node) {
  std::shared_ptr<CodeEntry> code_entry = node->entry();
  auto map_entry = function_ids_.find(code_entry);
  if (map_entry == function_ids_.end()) {
    return function_ids_[code_entry] = next_function_id_++;
  }
  return function_ids_[code_entry];
}

template <typename Callback>
void ProfileTree::TraverseDepthFirst(Callback* callback) {
  // tranverse the node and delete them
  std::vector<Position> stack;
  stack.emplace_back(root_);
  while (!stack.empty()) {
    Position& current = stack.back();
    if (current.HasCurrentChild()) {
      callback->BeforeTraversingChild(current.node(),
                                      current.GetCurrentChild());
      stack.emplace_back(current.GetCurrentChild());
    } else {
      callback->AfterAllChildrenTraversed(current.node());
      if (stack.size() > 1) {
        Position& parent = stack[stack.size() - 2];
        callback->AfterChildTraversed(parent.node(), current.node());
        parent.GetNextChild();
      }
      stack.pop_back();
    }
  }
}

ProfileNode* ProfileTree::root() const { return root_; }

unsigned ProfileTree::NextNodeId() { return next_node_id_++; }

LEPUSContext* ProfileTree::context() const { return ctx_; }

void ProfileTree::EnqueueNode(const ProfileNode* node) {
  pending_nodes_.emplace_back(node);
}

size_t ProfileTree::PendingNodesCount() const { return pending_nodes_.size(); }
std::vector<const ProfileNode*> ProfileTree::TakePendingNodes() {
  return std::move(pending_nodes_);
}

// ProfileNode
ProfileNode::ProfileNode(ProfileTree* tree, std::shared_ptr<CodeEntry>& entry,
                         ProfileNode* parent)
    : tree_(tree),
      entry_(entry),
      self_ticks_(0),
      parent_(parent),
      node_id_(tree->NextNodeId()) {
  tree_->EnqueueNode(this);
}

LEPUSContext* ProfileNode::context() const { return tree_->context(); }

ProfileNode* ProfileNode::FindOrAddChild(std::shared_ptr<CodeEntry>& entry,
                                         int32_t line_number) {
  auto map_entry = children_.find({entry, line_number});
  if (map_entry == children_.end()) {
    auto* node = new ProfileNode(tree_, entry, this);
    children_[{entry, line_number}] = node;
    children_list_.emplace_back(node);
    return node;
  } else {
    return map_entry->second;
  }
}

void ProfileNode::IncrementLineTicks(int32_t src_line) {
  assert(src_line > 0);
  // Increment a hit counter of a certain source line.
  // Add a new source line if not found.
  auto map_entry = line_ticks_.find(src_line);
  if (map_entry == line_ticks_.end()) {
    line_ticks_[src_line] = 1;
  } else {
    line_ticks_[src_line]++;
  }
}

void ProfileNode::IncrementSelfTicks() { ++self_ticks_; }

bool ProfileNode::Equals::operator()(const CodeEntryAndLineNumber& lhs,
                                     const CodeEntryAndLineNumber& rhs) const {
  return lhs.code_entry->IsSameFunctionAs(rhs.code_entry) &&
         lhs.line_number == rhs.line_number;
}

std::size_t ProfileNode::Hasher::operator()(
    const CodeEntryAndLineNumber& pair) const {
  auto code_entry_hash = pair.code_entry->GetHash();
  auto line_number_hash =
      ComputedHashUint64(static_cast<uint64_t>(pair.line_number));
  return code_entry_hash ^ line_number_hash;
}

std::shared_ptr<CodeEntry> ProfileNode::entry() const { return entry_; }
int64_t ProfileNode::self_ticks() const { return self_ticks_; }
const std::vector<ProfileNode*>* ProfileNode::children_list() const {
  return &children_list_;
}
int32_t ProfileNode::node_id() const { return node_id_; }
ProfileNode* ProfileNode::parent() const { return parent_; }
std::unordered_map<int32_t, uint64_t> ProfileNode::line_ticks() const {
  return line_ticks_;
}

// Position
ProfileNode* Position::GetCurrentChild() const {
  return node_->children_list()->at(child_idx_);
}

bool Position::HasCurrentChild() const {
  return child_idx_ < static_cast<int32_t>(node_->children_list()->size());
}

void Position::GetNextChild() { ++child_idx_; }
ProfileNode* Position::node() const { return node_; }
}  // namespace CpuProfiler
}  // namespace VMSDK