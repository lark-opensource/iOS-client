// Copyright 2019 The Lynx Authors. All rights reserved

#ifndef VMSDK_DEVTOOL_PROFILE_TREE_H
#define VMSDK_DEVTOOL_PROFILE_TREE_H

#include <unordered_map>
#include <vector>

#ifdef __cplusplus
extern "C" {
#endif
#include "quickjs/include/quickjs.h"
#ifdef __cplusplus
}
#endif

namespace VMSDK {
namespace CpuProfiler {

class ProfileTree;
class CodeEntry;
struct CodeEntryAndLineNumber;

class ProfileNode {
 public:
  inline ProfileNode(ProfileTree*, std::shared_ptr<CodeEntry>&, ProfileNode*);

  ProfileNode* FindOrAddChild(std::shared_ptr<CodeEntry>&,
                              int32_t line_number = 0);
  void IncrementSelfTicks();
  void IncrementLineTicks(int32_t);

  std::shared_ptr<CodeEntry> entry() const;
  int64_t self_ticks() const;
  const std::vector<ProfileNode*>* children_list() const;
  int32_t node_id() const;
  ProfileNode* parent() const;
  std::unordered_map<int32_t, uint64_t> line_ticks() const;
  LEPUSContext* context() const;

 private:
  struct Equals {
    bool operator()(const CodeEntryAndLineNumber&,
                    const CodeEntryAndLineNumber&) const;
  };
  struct Hasher {
    std::size_t operator()(const CodeEntryAndLineNumber&) const;
  };

  ProfileTree* tree_;
  std::shared_ptr<CodeEntry> entry_;
  int64_t self_ticks_;
  std::unordered_map<CodeEntryAndLineNumber, ProfileNode*, Hasher, Equals>
      children_;
  std::vector<ProfileNode*> children_list_;
  ProfileNode* parent_;
  int32_t node_id_;
  std::unordered_map<int32_t, uint64_t> line_ticks_;
};

class ProfileTree {
 public:
  ProfileTree(LEPUSContext*);
  ~ProfileTree();
  ProfileNode* root() const;
  unsigned NextNodeId();
  unsigned GetFunctionId(const ProfileNode*);
  LEPUSContext* context() const;

  void EnqueueNode(const ProfileNode*);
  size_t PendingNodesCount() const;
  std::vector<const ProfileNode*> TakePendingNodes();

 private:
  template <typename Callback>
  void TraverseDepthFirst(Callback*);
  std::vector<const ProfileNode*> pending_nodes_;
  std::shared_ptr<CodeEntry> root_entry_;
  unsigned next_node_id_;
  ProfileNode* root_;
  LEPUSContext* ctx_;
  unsigned next_function_id_;
  std::unordered_map<std::shared_ptr<CodeEntry>, unsigned> function_ids_;
};

class Position {
 public:
  explicit Position(ProfileNode* node) : node_(node), child_idx_(0) {}
  ProfileNode* GetCurrentChild() const;
  bool HasCurrentChild() const;
  void GetNextChild();
  ProfileNode* node() const;

 private:
  ProfileNode* node_;
  int32_t child_idx_;
};

class DeleteNodesCallback {
 public:
  void BeforeTraversingChild(ProfileNode*, ProfileNode*) {}
  void AfterAllChildrenTraversed(ProfileNode* node) { delete node; }
  void AfterChildTraversed(ProfileNode*, ProfileNode*) {}
};

}  // namespace CpuProfiler
}  // namespace VMSDK
#endif