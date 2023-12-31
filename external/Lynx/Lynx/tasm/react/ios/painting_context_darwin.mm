// Copyright 2019 The Lynx Authors. All rights reserved.
#import <objc/message.h>

#import "AbsLynxUIScroller.h"
#import "LynxError.h"
#import "LynxEventHandler.h"
#import "LynxLog.h"
#import "LynxShadowNodeOwner.h"
#import "LynxTemplateData+Converter.h"
#import "LynxTimingHandler.h"
#import "LynxTouchHandler+Internal.h"
#import "LynxUI+Internal.h"
#import "LynxUIMethodProcessor.h"
#import "LynxViewCurrentIndexHelper.h"
#import "LynxViewVisibleHelper.h"
#import "UIDevice+Lynx.h"
#include "base/debug/lynx_assert.h"
#include "config/config.h"
#include "jsbridge/ios/piper/lynx_module_darwin.h"
#include "lepus/array.h"
#include "lepus/table.h"
#include "lepus_value_converter.h"
#include "shell/lynx_shell.h"
#include "starlight/style/css_style_utils.h"
#include "tasm/react/ios/painting_context_darwin.h"
#include "tasm/react/ios/platform_extra_bundle_darwin.h"
#include "tasm/react/ios/prop_bundle_darwin.h"

namespace lynx {
namespace tasm {

// LEFT,TOP,RIGHT,BOTTOM

enum BoxModelOffset {
  PAD_LEFT = 0,
  PAD_TOP,
  PAD_RIGHT,
  PAD_BOTTOM,
  BORDER_LEFT,
  BORDER_TOP,
  BORDER_RIGHT,
  BORDER_BOTTOM,
  MARGIN_LEFT,
  MARGIN_TOP,
  MARGIN_RIGHT,
  MARGIN_BOTTOM,
  LAYOUT_LEFT,
  LAYOUT_TOP,
  LAYOUT_RIGHT,
  LAYOUT_BOTTOM
};

namespace {

template <typename F>
void ExecuteSafely(const F& func) {
  @try {
    func();
  } @catch (NSException* e) {
    LErrWarn(false, LynxErrorCodeException,
             [NSString stringWithFormat:@"%@:%@", [e name], [e reason]]);
  }
}

}  // namespace

void PaintingContextDarwin::SetKeyframes(PropBundle* keyframes_data) {
  Enqueue([this, keyframesDict = static_cast<PropBundleDarwin*>(keyframes_data)->dictionary()]() {
    [uiOwner updateAnimationKeyframes:keyframesDict];
  });
}

void PaintingContextDarwin::SetUIOperationQueue(
    const std::shared_ptr<shell::DynamicUIOperationQueue>& queue) {
  queue_ = queue;
  queue_->SetEnableFlush(enable_flush_);
}

PaintingContextDarwin::PaintingContextDarwin(LynxUIOwner* owner, bool enable_flush)
    : uiOwner(owner), enable_flush_(enable_flush) {}

PaintingContextDarwin::~PaintingContextDarwin() {}

void PaintingContextDarwin::CreatePaintingNode(int sign, PropBundle* painting_data, bool flatten) {
  PropBundleDarwin* pda = static_cast<PropBundleDarwin*>(painting_data);
  NSString* tagName = [[NSString alloc] initWithUTF8String:pda->tag().c_str()];
  NSDictionary* props = pda->dictionary();
  // hack, use user defined component instead of list.
  if ([tagName isEqualToString:@"list"] && [props objectForKey:@"custom-list-name"]) {
    tagName = [props objectForKey:@"custom-list-name"];
  }

  Enqueue([this, sign, tagName, eventSet = pda->event_set(), lepusEventSet = pda->lepus_event_set(),
           props]() {
    [uiOwner createUIWithSign:sign
                      tagName:tagName
                     eventSet:eventSet
                lepusEventSet:lepusEventSet
                        props:props];
  });
}

void PaintingContextDarwin::InsertPaintingNode(int parent, int child, int index) {
  Enqueue(
      [this, parent, child, index]() { [uiOwner insertNode:child toParent:parent atIndex:index]; });
}

void PaintingContextDarwin::RemovePaintingNode(int parent, int child, int index) {
  Enqueue([this, child]() { [uiOwner detachNode:child]; });
}

void PaintingContextDarwin::DestroyPaintingNode(int parent, int child, int index) {
  Enqueue([this, child]() { [uiOwner recycleNode:child]; });
}

void PaintingContextDarwin::UpdatePaintingNode(int id, bool tend_to_flatten,
                                               PropBundle* painting_data) {
  PropBundleDarwin* pda = static_cast<PropBundleDarwin*>(painting_data);
  Enqueue([this, id, props = pda->dictionary(), eventSet = pda->event_set(),
           lepusEventSet = pda->lepus_event_set()]() {
    [uiOwner updateUIWithSign:id props:props eventSet:eventSet lepusEventSet:lepusEventSet];
  });
}

void PaintingContextDarwin::ListReusePaintingNode(int sign, const lepus::String& item_key) {
  Enqueue([this, sign, itemKey = [NSString stringWithUTF8String:item_key.c_str()]]() {
    [uiOwner listWillReuseNode:sign withItemKey:itemKey];
  });
}

void PaintingContextDarwin::UpdateLayout(int sign, float x, float y, float width, float height,
                                         const float* paddings, const float* margins,
                                         const float* borders, const float* flatten_bounds,
                                         const float* sticky, float max_height) {
  // top left right bottom for UIEdgeInset
#define UI_EDGE_INSETS(array) \
  array != nullptr ? UIEdgeInsetsMake(array[1], array[0], array[3], array[2]) : UIEdgeInsetsZero
  NSMutableArray* stickyArr;
  if (sticky != nil) {
    stickyArr = [[NSMutableArray alloc] init];
    for (int i = 0; i < 4; i++) {
      [stickyArr addObject:[NSNumber numberWithFloat:sticky[i]]];
    }
  }

  Enqueue([this, sign, x, y, width, height, padding = UI_EDGE_INSETS(paddings),
           border = UI_EDGE_INSETS(borders), margin = UI_EDGE_INSETS(margins), stickyArr]() {
    [uiOwner updateUI:sign
           layoutLeft:x
                  top:y
                width:width
               height:height
              padding:padding
               border:border
               margin:margin
               sticky:stickyArr];
  });
#undef UI_EDGE_INSETS
}

void PaintingContextDarwin::SetEnableFlush(bool enable_flush) {
  enable_flush_ = enable_flush;
  queue_->SetEnableFlush(enable_flush);
}

void PaintingContextDarwin::Flush() { queue_->Flush(); }

void PaintingContextDarwin::MarkUIOperationQueueFlushTiming(tasm::TimingKey key,
                                                            const std::string& timing_flag) {
  if (key >= tasm::TimingKey::SETUP_DIVIDE && timing_flag.empty()) {
    return;
  }
  Enqueue([this, key, timing_flag]() {
    NSString* flag = nil;
    if (!timing_flag.empty()) {
      flag = [NSString stringWithUTF8String:timing_flag.c_str()];
    }
    [uiOwner.uiContext.timingHandler
        markTiming:[NSString stringWithUTF8String:TimingKeyToString(key).c_str()]
        updateFlag:flag];
  });
}

void PaintingContextDarwin::UpdateEventInfo(bool has_touch_pseudo) {
  queue_->EnqueueUIOperation([this, has_touch_pseudo]() {
    [uiOwner.uiContext.eventHandler.touchRecognizer setEnableTouchPseudo:has_touch_pseudo];
  });
}

std::vector<float> PaintingContextDarwin::getBoundingClientOrigin(int id) {
  std::vector<float> res;
  LynxUI* ui = [uiOwner findUIBySign:id];
  if (ui != NULL) {
    CGRect re = [ui getBoundingClientRect];
    res.push_back(re.origin.x);
    res.push_back(re.origin.y);
  }
  return res;
}

std::vector<float> PaintingContextDarwin::getTransformValue(
    int id, std::vector<float> pad_border_margin_layout) {
  std::vector<float> res;
  LynxUI* ui = [uiOwner findUIBySign:id];
  if (ui != NULL) {
    for (int i = 0; i < 4; i++) {
      TransOffset arr;
      if (i == 0) {
        arr = [ui getTransformValueWithLeft:pad_border_margin_layout[PAD_LEFT] +
                                            pad_border_margin_layout[BORDER_LEFT] +
                                            pad_border_margin_layout[LAYOUT_LEFT]
                                      right:-pad_border_margin_layout[PAD_RIGHT] -
                                            pad_border_margin_layout[BORDER_RIGHT] -
                                            pad_border_margin_layout[LAYOUT_RIGHT]
                                        top:pad_border_margin_layout[PAD_TOP] +
                                            pad_border_margin_layout[BORDER_TOP] +
                                            pad_border_margin_layout[LAYOUT_TOP]
                                     bottom:-pad_border_margin_layout[PAD_BOTTOM] -
                                            pad_border_margin_layout[BORDER_BOTTOM] -
                                            pad_border_margin_layout[LAYOUT_BOTTOM]];
      } else if (i == 1) {
        arr = [ui getTransformValueWithLeft:pad_border_margin_layout[BORDER_LEFT] +
                                            pad_border_margin_layout[LAYOUT_LEFT]
                                      right:-pad_border_margin_layout[BORDER_RIGHT] -
                                            pad_border_margin_layout[LAYOUT_RIGHT]
                                        top:pad_border_margin_layout[BORDER_TOP] +
                                            pad_border_margin_layout[LAYOUT_TOP]
                                     bottom:-pad_border_margin_layout[BORDER_BOTTOM] -
                                            pad_border_margin_layout[LAYOUT_BOTTOM]];
      } else if (i == 2) {
        arr = [ui getTransformValueWithLeft:pad_border_margin_layout[LAYOUT_LEFT]
                                      right:-pad_border_margin_layout[LAYOUT_RIGHT]
                                        top:pad_border_margin_layout[LAYOUT_TOP]
                                     bottom:-pad_border_margin_layout[LAYOUT_BOTTOM]];
      } else {
        arr = [ui getTransformValueWithLeft:-pad_border_margin_layout[MARGIN_LEFT] +
                                            pad_border_margin_layout[LAYOUT_LEFT]
                                      right:pad_border_margin_layout[MARGIN_RIGHT] -
                                            pad_border_margin_layout[LAYOUT_RIGHT]
                                        top:-pad_border_margin_layout[MARGIN_TOP] +
                                            pad_border_margin_layout[LAYOUT_TOP]
                                     bottom:pad_border_margin_layout[MARGIN_BOTTOM] -
                                            pad_border_margin_layout[LAYOUT_BOTTOM]];
      }
      res.push_back(arr.left_top.x);
      res.push_back(arr.left_top.y);
      res.push_back(arr.right_top.x);
      res.push_back(arr.right_top.y);
      res.push_back(arr.right_bottom.x);
      res.push_back(arr.right_bottom.y);
      res.push_back(arr.left_bottom.x);
      res.push_back(arr.left_bottom.y);
    }
  }
  return res;
}

void PaintingContextDarwin::ScrollIntoView(int id) {
  LynxUI* ui = [uiOwner findUIBySign:id];
  if (ui == NULL) {
    return;
  }
  [ui scrollIntoViewWithSmooth:false blockType:@"center" inlineType:@"center"];
}

std::vector<float> PaintingContextDarwin::getWindowSize(int id) {
  std::vector<float> res;
  CGSize size = UIScreen.mainScreen.bounds.size;
  res.push_back(size.width);
  res.push_back(size.height);
  return res;
}

#if ENABLE_ARK_REPLAY
lepus::Value PaintingContextDarwin::GetUITreeRecursive(LynxUI* ui) {
  CGRect re = [ui getBoundingClientRect];
  auto node_json = lepus::Dictionary::Create();

  node_json->SetValue("width", lepus::Value(re.size.width));
  node_json->SetValue("height", lepus::Value(re.size.height));
  node_json->SetValue("left", lepus::Value(re.origin.x));
  node_json->SetValue("top", lepus::Value(re.origin.y));

  // children
  auto children = lepus::CArray::Create();
  for (LynxUI* child in [ui.children reverseObjectEnumerator]) {
    children->push_back(GetUITreeRecursive(child));
  }
  node_json->SetValue("children", lepus::Value(children));

  return lepus::Value(node_json);
}
#endif

std::vector<float> PaintingContextDarwin::GetRectToWindow(int id) {
  std::vector<float> res;
  LynxUI* ui = [uiOwner findUIBySign:id];
  if (ui != NULL) {
    CGRect re = [ui getRectToWindow];
    int scale = UIScreen.mainScreen.scale;
    res.push_back(re.origin.x * scale);
    res.push_back(re.origin.y * scale);
    res.push_back(re.size.width * scale);
    res.push_back(re.size.height * scale);
  }
  return res;
}

std::vector<int> PaintingContextDarwin::getVisibleOverlayView() {
  std::vector<int> res;
  Class overlay_global_manager = NSClassFromString(@"BDXLynxOverlayGlobalManager");
  SEL getAllVisibleOverlaySel = NSSelectorFromString(@"getAllVisibleOverlay");
  if (overlay_global_manager && getAllVisibleOverlaySel &&
      [overlay_global_manager respondsToSelector:getAllVisibleOverlaySel]) {
    NSMutableArray* (*getAllVisibleOverlay)(Class, SEL) =
        (NSMutableArray * (*)(Class, SEL)) objc_msgSend;
    NSMutableArray* array = getAllVisibleOverlay(overlay_global_manager, getAllVisibleOverlaySel);
    for (NSNumber* num in array) {
      res.push_back([num intValue]);
    }
  }
  return res;
}

std::vector<float> PaintingContextDarwin::GetRectToLynxView(int64_t id) {
  // x y width height
  std::vector<float> res;
  LynxUI* ui = [uiOwner findUIBySign:(int)id];
  if (ui != NULL) {
    CGRect re = [ui getBoundingClientRect];
    res.push_back(re.origin.x);
    res.push_back(re.origin.y);
    res.push_back(re.size.width);
    res.push_back(re.size.height);
  }
  return res;
}

std::vector<float> PaintingContextDarwin::ScrollBy(int64_t id, float width, float height) {
  LynxUI* ui = [uiOwner findUIBySign:(int)id];
  CGPoint preOffset = ui.contentOffset;
  ui.contentOffset = CGPointMake(width + preOffset.x, height + preOffset.y);
  CGPoint currentOffset = ui.contentOffset;
  float consumed_x = currentOffset.x - preOffset.x;
  float consumed_y = currentOffset.y - preOffset.y;
  float unconsumed_x = width - consumed_x;
  float unconsumed_y = height - consumed_y;
  return std::vector<float>{consumed_x, consumed_y, unconsumed_x, unconsumed_y};
}

int PaintingContextDarwin::GetCurrentIndex(int idx) {
  int res = 0;
  LynxUI* ui = [uiOwner findUIBySign:idx];
  if ([ui conformsToProtocol:@protocol(LynxViewCurrentIndexHelper)]) {
    res = [(id<LynxViewCurrentIndexHelper>)ui getCurrentIndex];
  }
  return res;
}

bool PaintingContextDarwin::IsViewVisible(int idx) {
  bool res = true;
  LynxUI* ui = [uiOwner findUIBySign:idx];
  if ([ui conformsToProtocol:@protocol(LynxViewVisibleHelper)]) {
    res = [(id<LynxViewVisibleHelper>)ui IsViewVisible];
  }
  return res;
}

bool PaintingContextDarwin::IsTagVirtual(const std::string& tag_name) {
  return [uiOwner isTagVirtual:[[NSString alloc] initWithUTF8String:tag_name.c_str()]];
}

void PaintingContextDarwin::Invoke(
    int64_t element_id, const std::string& method, const lepus::Value& params,
    const std::function<void(int32_t code, const lepus::Value& data)>& callback) {
  LynxUI* ui = [uiOwner findUIBySign:(int)element_id];
  [LynxUIMethodProcessor
      invokeMethod:[[NSString alloc] initWithUTF8String:method.c_str()]
        withParams:convertLepusValueToNSObject(params)
        withResult:^(int code, id _Nullable data) {
          // exec the following block on main thread.
          auto block = ^{
            LynxUIOwner* owner = uiOwner;
            if (owner == nil) {
              return;
            }
            const auto& raw_ptr = owner.uiContext.shellPtr;
            if (raw_ptr == 0) {
              return;
            }
            reinterpret_cast<shell::LynxShell*>(raw_ptr)->RunOnTasmThread([code, data, callback]() {
              // exec the callback on tasm thread.
              callback(code, LynxConvertToLepusValue(data));
            });
          };
          if ([NSThread isMainThread]) {
            block();
          } else {
            dispatch_async(dispatch_get_main_queue(), block);
          }
        }
             forUI:ui];
}

void PaintingContextDarwin::OnAnimatedNodeReady(int tag) {
  Enqueue([this, tag]() { [uiOwner onAnimatedNodeReady:tag]; });
}

void PaintingContextDarwin::OnNodeReady(int tag) { patching_node_ready_ids_.emplace_back(tag); }

void PaintingContextDarwin::UpdateNodeReadyPatching() {
  if (patching_node_ready_ids_.empty()) {
    return;
  }

  Enqueue([this, patching_node_ready_ids = std::move(patching_node_ready_ids_)]() {
    for (const auto& tag : patching_node_ready_ids) {
      [uiOwner onNodeReady:tag];
    }
  });
}

void PaintingContextDarwin::UpdatePlatformExtraBundle(int32_t signature,
                                                      PlatformExtraBundle* bundle) {
  if (!bundle) {
    return;
  }

  auto platform_bundle = static_cast<PlatformExtraBundleDarwin*>(bundle);

  Enqueue([this, signature, value = platform_bundle->PlatformBundle()]() {
    [uiOwner onReceiveUIOperation:value onUI:signature];
  });
}

void PaintingContextDarwin::FinishLayoutOperation(const PipelineOptions& options) {
  is_layout_finish_ = true;
  Enqueue([this, options]() {
    [uiOwner finishLayoutOperation:options.operation_id componentID:options.list_comp_id];
    if (options.has_layout) {
      [uiOwner layoutDidFinish];
    }
    queue_->UpdateStatus(shell::UIOperationStatus::ALL_FINISH);
  });
  queue_->UpdateStatus(shell::UIOperationStatus::LAYOUT_FINISH);
}

void PaintingContextDarwin::FinishTasmOperation(const PipelineOptions& options) {
  queue_->UpdateStatus(shell::UIOperationStatus::TASM_FINISH);
}

void PaintingContextDarwin::SetNeedMarkDrawEndTiming(bool is_first_screen,
                                                     const std::string& timing_flag) {
  Enqueue([this, is_first_screen, timing_flag]() {
    if (is_first_screen) {
      __weak typeof(LynxTimingHandler*) handler = uiOwner.uiContext.timingHandler;
      dispatch_async(dispatch_get_main_queue(), ^{
        [handler markTiming:OC_SETUP_DRAW_END updateFlag:nil];
      });
    } else if (!timing_flag.empty()) {
      NSString* flag = [NSString stringWithUTF8String:timing_flag.c_str()];
      __weak typeof(LynxTimingHandler*) handler = uiOwner.uiContext.timingHandler;
      dispatch_async(dispatch_get_main_queue(), ^{
        [handler markTiming:OC_UPDATE_DRAW_END updateFlag:flag];
      });
    }
  });
}

bool PaintingContextDarwin::IsLayoutFinish() { return is_layout_finish_; }

void PaintingContextDarwin::ResetLayoutStatus() { is_layout_finish_ = false; }

// TODO(heshan):remove related invocation
void PaintingContextDarwin::LayoutDidFinish() {}

void PaintingContextDarwin::ForceFlush() {
  SetEnableFlush(true);
  queue_->ForceFlush();
}

template <typename F>
void PaintingContextDarwin::Enqueue(F&& func) {
  queue_->EnqueueUIOperation([func = std::move(func)]() {
    @autoreleasepool {
      ExecuteSafely(func);
    }
  });
}

}  // namespace tasm
}  // namespace lynx
