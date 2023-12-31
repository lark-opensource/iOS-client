// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_REACT_FIBER_FIBER_NODE_INFO_H_
#define LYNX_TASM_REACT_FIBER_FIBER_NODE_INFO_H_

#include <string>
#include <vector>

#include "lepus/value.h"
#include "tasm/react/fiber/fiber_element.h"

namespace lynx {
namespace tasm {
/*
 * `FiberNodeInfo` contains some utility functions to get some attributes of a
 * fiber node.
 */
class FiberNodeInfo {
 public:
  FiberNodeInfo() = delete;
  ~FiberNodeInfo() = delete;

  /**
   * Used by path() of SelectorQuery to get the nodes' required info.
   * @param nodes The nodes to get info.
   * @return The info of the nodes as lepus value.
   */
  static lepus::Value GetNodesInfo(const std::vector<FiberElement *> &nodes,
                                   const std::vector<std::string> &fields);

  /**
   * Get node info by fields. Required info will be returned as lepus
   * dictionary.
   * @param node The node to get info.
   * @param fields fields to get.
   * @return A dictionary contains the information of the node as lepus value.
   */
  static lepus::Value GetNodeInfo(FiberElement *node,
                                  const std::vector<std::string> &fields);

  static std::vector<FiberElement *> PathToRoot(FiberElement *base);
};
}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_REACT_FIBER_FIBER_NODE_INFO_H_
