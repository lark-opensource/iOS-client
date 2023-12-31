// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_REACT_TESTING_MOCK_PAINTING_CONTEXT_H_
#define LYNX_TASM_REACT_TESTING_MOCK_PAINTING_CONTEXT_H_

#define private public

#include <map>
#include <memory>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

#include "tasm/react/painting_context_implementation.h"
#include "tasm/react/testing/prop_bundle_mock.h"

namespace lynx {
namespace tasm {

struct MockNode {
  MockNode(int id) : id_(id) {}
  int id_;
  std::vector<MockNode*> children_;
  MockNode* parent_;
  std::map<std::string, lepus::Value> props_;
};

class MockPaintingContext : public PaintingContextPlatformImpl {
  virtual void CreatePaintingNode(int id, PropBundle* painting_data,
                                  bool flatten) override {
    auto node = std::make_unique<MockNode>(id);
    if (painting_data) {
      node->props_ = static_cast<PropBundleMock*>(painting_data)->props_;
    }
    node_map_.insert(std::make_pair(id, std::move(node)));
  }
  virtual void InsertPaintingNode(int parent, int child, int index) override {
    auto* parent_node = node_map_.at(parent).get();
    auto* child_node = node_map_.at(child).get();
    if (index == -1) {
      parent_node->children_.push_back(child_node);
    } else {
      parent_node->children_.insert((parent_node->children_).begin() + index,
                                    child_node);
    }
    child_node->parent_ = parent_node;
  }
  virtual void RemovePaintingNode(int parent, int child, int index) override {
    auto* parent_node = node_map_.at(parent).get();
    auto* child_node = node_map_.at(child).get();

    auto it_child = std::find(parent_node->children_.begin(),
                              parent_node->children_.end(), child_node);
    if (it_child != parent_node->children_.end()) {
      child_node->parent_ = nullptr;

      parent_node->children_.erase(it_child);
    }
  }
  virtual void DestroyPaintingNode(int parent, int child, int index) override {
    auto* child_node = node_map_.at(child).get();
    child_node->parent_ = nullptr;
    if (node_map_.find(parent) != node_map_.end()) {
      auto* parent_node = node_map_.at(parent).get();
      auto it_child = std::find(parent_node->children_.begin(),
                                parent_node->children_.end(), child_node);
      if (it_child != parent_node->children_.end()) {
        parent_node->children_.erase(it_child);
      }
    }

    auto it = node_map_.find(child);
    if (it != node_map_.end()) {
      node_map_.erase(it);
    }
  }
  virtual void UpdatePaintingNode(int id, bool tend_to_flatten,
                                  PropBundle* painting_data) override {
    if (!painting_data) {
      return;
    }
    auto* node = node_map_.at(id).get();
    for (const auto& update :
         static_cast<PropBundleMock*>(painting_data)->props_) {
      node->props_[update.first] = update.second;
    }
  }

  void SetKeyframes(PropBundle* keyframes_data) override {
    for (const auto& item :
         static_cast<PropBundleMock*>(keyframes_data)->props_) {
      keyframes_[item.first] = item.second;
    }
  }

  virtual bool IsTagVirtual(const std::string& tag_name) override {
    auto it = mock_virtuality_map.find(tag_name);
    if (it != mock_virtuality_map.end()) {
      return it->second;
    } else {
      return false;
    }
  }

 private:
  std::unordered_map<int, std::unique_ptr<MockNode>> node_map_;
  std::unordered_map<std::string, lepus::Value> keyframes_;
  std::unordered_map<std::string, bool> mock_virtuality_map = {
      {"inline-text", true},
      {"view", false},
      {"inline-image", true},
      {"raw-text", true}};
};
}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_REACT_TESTING_MOCK_PAINTING_CONTEXT_H_
