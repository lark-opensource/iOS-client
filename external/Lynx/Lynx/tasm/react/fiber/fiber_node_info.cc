// Copyright 2022 The Lynx Authors. All rights reserved.

#include "tasm/react/fiber/fiber_node_info.h"

namespace lynx {
namespace tasm {
lepus::Value FiberNodeInfo::GetNodesInfo(
    const std::vector<FiberElement *> &nodes,
    const std::vector<std::string> &fields) {
  auto ret = lepus::CArray::Create();
  for (auto node : nodes) {
    ret->push_back(GetNodeInfo(node, fields));
  }
  return lepus::Value(ret);
}

lepus::Value FiberNodeInfo::GetNodeInfo(
    FiberElement *node, const std::vector<std::string> &fields) {
  auto ret = lepus::Dictionary::Create();
  if (node == nullptr) {
    return lepus::Value(ret);
  }

  for (auto &field : fields) {
    if (field == "id") {
      auto id_selector_impl = node->GetIdSelector().impl();
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
      ret->SetValue("tag", lepus::Value(node->GetTag()));
    } else if (field == "unique_id") {
      ret->SetValue("unique_id", lepus::Value(node->impl_id()));
    } else if (field == "name") {
      auto iter = node->data_model()->attributes().find("name");
      if (iter == node->data_model()->attributes().end()) {
        ret->SetValue("name", lepus::Value(""));
      } else {
        ret->SetValue("name", lepus::Value(iter->second.first));
      }
    } else if (field == "index") {
      auto index =
          node->parent()
              ? static_cast<FiberElement *>(node->parent())->IndexOf(node)
              : 0;
      ret->SetValue("index", lepus::Value::MakeInt(index));
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

std::vector<FiberElement *> FiberNodeInfo::PathToRoot(FiberElement *base) {
  std::vector<FiberElement *> path;
  while (base) {
    path.push_back(base);
    base = static_cast<FiberElement *>(base->parent());
  }
  return path;
}
}  // namespace tasm
}  // namespace lynx
