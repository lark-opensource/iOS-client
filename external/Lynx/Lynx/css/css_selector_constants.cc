// Copyright 2019 The Lynx Authors. All rights reserved.

#include "css/css_selector_constants.h"

namespace lynx {
namespace tasm {

/*
 * https://developer.toutiao.com/docs/framework/ttss.html
 * 对应小程序css选择器
 *  选择器                      样例                  样例描述
 *  .class                  .intro              选择所有拥有 class="intro"
 * 的组件 #id                  #firstname         选择拥有 id="firstname"
 * 的组件 element                    view             选择所有 view 组件
 *  element, element      view, checkbox      选择所有文档的 view
 * 组件和所有的 checkbox 组件
 *   ::after              view::after         在 view 组件后边插入内容
 *   ::before             view::before      在 view 组件前边插入内容
 *   ::placeholder        view::placeholder   input组件的placeholder text样式
 *   ::selection          text::selection    text组件选中高亮样式
 *  更多的选择器待扩充
 */

const char* kCSSSelectorClass = ".";
const char* kCSSSelectorID = "#";
const char* kCSSSelectorBefore = "::before";
const char* kCSSSelectorAfter = "::after";
const char* kCSSSelectorSelection = "::selection";
const char* kCSSSelectorNot = ":not";
const char* kCSSSelectorPlaceholder = "::placeholder";
const char* kCSSSelectorAll = "*";
const char* kCSSSelectorFirstChild = ":first-child";
const char* kCSSSelectorLastChild = ":last-child";
const char* kCSSSelectorPseudoFocus = ":focus";
const char* kCSSSelectorPseudoActive = ":active";
const char* kCSSSelectorPseudoHover = ":hover";

}  // namespace tasm
}  // namespace lynx
