//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_RADON_NODE_PATH_INFO_H_
#define LYNX_TASM_RADON_NODE_PATH_INFO_H_

#include <string>
#include <vector>

#include "lepus/value.h"
#include "tasm/radon/radon_node.h"

namespace lynx {
namespace tasm {

class RadonPathInfo {
 public:
  RadonPathInfo() = delete;
  ~RadonPathInfo() = delete;

  // returns {"tag", "id", "dataSet", "index", "class"} of the given nodes.
  // this is used by SelectorQuery Path() ability.
  static lepus::Value GetNodesInfo(const std::vector<RadonNode *> &nodes);
  static lepus::Value GetNodeInfo(RadonNode *node,
                                  const std::vector<std::string> &fields);
  static std::vector<RadonNode *> PathToRoot(RadonBase *base);
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_RADON_NODE_PATH_INFO_H_
