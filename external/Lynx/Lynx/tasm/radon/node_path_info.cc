// Copyright 2022 The Lynx Authors. All rights reserved.

#include "tasm/radon/node_path_info.h"

#include "lepus/array.h"
#include "tasm/radon/radon_page.h"

namespace lynx {
namespace tasm {

lepus::Value RadonPathInfo::GetNodesInfo(
    const std::vector<RadonNode *> &nodes) {
  auto ret = lepus::CArray::Create();
  for (auto node : nodes) {
    ret->push_back(
        GetNodeInfo(node, {"tag", "id", "dataSet", "index", "class"}));
  }
  return lepus::Value(ret);
}

lepus::Value RadonPathInfo::GetNodeInfo(
    RadonNode *node, const std::vector<std::string> &fields) {
  auto ret = lepus::Dictionary::Create();
  if (node == nullptr) {
    return lepus::Value(ret);
  }

  for (auto &field : fields) {
    if (field == "id") {
      auto id_selector_impl = node->idSelector().impl();
      auto id =
          id_selector_impl ? id_selector_impl : lepus::StringImpl::Create("");
      ret->SetValue("id", lepus::Value(id));
    } else if (field == "dataset" || field == "dataSet") {
      auto dataset_value = lepus::Dictionary::Create();
      for (const auto &[key, value] : node->dataset()) {
        dataset_value->SetValue(key, value);
      }
      ret->SetValue(field, lepus::Value(dataset_value));
    } else if (field == "tag") {
      ret->SetValue("tag", lepus::Value(node->tag().impl()));
    } else if (field == "unique_id") {
      ret->SetValue("unique_id", lepus::Value(node->ImplId()));
    } else if (field == "name") {
      auto iter = node->attributes().find("name");
      if (iter == node->attributes().end()) {
        ret->SetValue("name", lepus::Value(""));
      } else {
        ret->SetValue("name", lepus::Value(iter->second.first));
      }
    } else if (field == "index") {
      ret->SetValue("index", lepus::Value(node->IndexInSiblings()));
    } else if (field == "class") {
      auto classes_value = lepus::CArray::Create();
      for (const auto &v : node->classes()) {
        classes_value->push_back(lepus::Value(v.impl()));
      }
      ret->SetValue("class", lepus::Value(classes_value));
    }
  }
  return lepus::Value(ret);
}

std::vector<RadonNode *> RadonPathInfo::PathToRoot(RadonBase *base) {
  std::vector<RadonNode *> path;
  while (base) {
    if (base->IsRadonNode()) {
      path.push_back(static_cast<RadonNode *>(base));
    }
    base = base->Parent();
  }
  return path;
}

}  // namespace tasm
}  // namespace lynx
