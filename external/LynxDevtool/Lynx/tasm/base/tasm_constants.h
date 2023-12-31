// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef LYNX_TASM_BASE_TASM_CONSTANTS_H_
#define LYNX_TASM_BASE_TASM_CONSTANTS_H_

#include "base/base_export.h"

namespace lynx {
namespace tasm {

BASE_EXPORT_FOR_DEVTOOL static constexpr const char* kOnDocumentUpdated =
    "OnDocumentUpdated";
static constexpr const char* kReporter = "Reporter";
static constexpr const char* kSendError = "sendError";

// Constant string associated with LepusRuntime
static constexpr const char* kGetPageData = "getPageData";

// Constant string associated with Element Template
static constexpr const char* kElementID = "id";
static constexpr const char* kElementTempID = "tempID";
static constexpr const char* kElementIdSelector = "idSelector";
static constexpr const char* kElementType = "type";
static constexpr const char* kElementChildren = "children";
static constexpr const char* kElementClass = "class";
static constexpr const char* kElementStyles = "styles";
static constexpr const char* kElementAttributes = "attributes";
static constexpr const char* kElementEvents = "events";
static constexpr const char* kElementDataset = "dataset";
static constexpr const char* kElementIsComponent = "isComponent";
static constexpr const char* kElementParsedStyleKey = "parsedStyleKey";
static constexpr const char* kElementConfig = "config";
static constexpr const char* kElementParsedStyle = "parsedStyle";
static constexpr const char* kElementViewTag = "view";
static constexpr const char* kElementComponentTag = "component";
static constexpr const char* kElementPageTag = "page";
static constexpr const char* kElementImageTag = "image";
static constexpr const char* kElementTextTag = "text";
static constexpr const char* kElementRawTextTag = "raw-text";
static constexpr const char* kElementScrollViewTag = "scroll-view";
static constexpr const char* kElementListTag = "list";
static constexpr const char* kElementNoneElementTag = "none-element";
static constexpr const char* kElementWrapperElementTag = "wrapper-element";

// Constant string associated with tasm
static constexpr const char* kRemoveComponents = "removeComponents";
static constexpr const char* kUpdatePage = "updatePage";

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_BASE_TASM_CONSTANTS_H_
