// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_CSS_CSS_SELECTOR_CONSTANTS_H_
#define LYNX_CSS_CSS_SELECTOR_CONSTANTS_H_

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
 *   :not                 #foo:not(.bar)      选择所有 id="foo"
 *   ::placeholder        input::placeholder   input组件的placeholder text样式
 * 但是class不为bar的组件
 *
 *  更多的选择器待扩充
 */

extern const char* kCSSSelectorClass;
extern const char* kCSSSelectorID;
extern const char* kCSSSelectorBefore;
extern const char* kCSSSelectorAfter;
extern const char* kCSSSelectorSelection;
extern const char* kCSSSelectorNot;
extern const char* kCSSSelectorPlaceholder;
extern const char* kCSSSelectorAll;
extern const char* kCSSSelectorFirstChild;
extern const char* kCSSSelectorLastChild;
extern const char* kCSSSelectorPseudoFocus;
extern const char* kCSSSelectorPseudoActive;
extern const char* kCSSSelectorPseudoHover;

// TODO: add more

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_CSS_CSS_SELECTOR_CONSTANTS_H_
