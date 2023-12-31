//
//  public.h
//  Pods
//
//  Created by qihongye on 2021/4/4.
//

#pragma once

/// Other public headers
#include <stdlib.h>
#include "Macros.h"
#include "Types.h"

TL_EXTERN_C_BEGIN

/// 获取默认Node初始化的Options配置
TL_EXPORT const TLNodeOptionsRef TLGetDefaultOptions(void);
TL_EXPORT
const float TLOptionsGetPointScaleFactor(const TLNodeOptionsRef options);
TL_EXPORT
void TLOptionsSetPointScaleFactor(const TLNodeOptionsRef options, const float pointScaleFactor);
TL_EXPORT
const TLNodeOptionsRef TLOptionsNew(const float pointScaleFactor,
                                    const TLLogger info,
                                    const TLLogger warning,
                                    const TLLogger error,
                                    const TLLogger fatal);
TL_EXPORT
int TLNodeGetGlobalCounter();
TL_EXPORT
void TLNodeOptionsFree(const TLNodeOptionsRef options);

TL_EXPORT
const TLNodeRef TLNodeNew(void);
TL_EXPORT
const TLNodeRef TLNodeNewWithOptions(const TLNodeOptionsRef options);
TL_EXPORT
const TLNodeRef TLNodeClone(const TLNodeRef node);
TL_EXPORT
const TLNodeRef TLNodeCloneWithOptions(const TLNodeRef node, const TLNodeOptionsRef options);
TL_EXPORT
const TLNodeRef TLNodeDeepClone(const TLNodeRef node);
TL_EXPORT
void TLNodeSetContext(const TLNodeRef node, void* context);
TL_EXPORT
void* TLNodeGetContext(const TLNodeRef node);
TL_EXPORT
void TLNodeSetLayoutFunc(const TLNodeRef node, TLLayoutFunc);
TL_EXPORT
void TLNodeSetBaselineFunc(const TLNodeRef node, TLBaselineFunc);
TL_EXPORT
const TLNodeOptionsRef TLNodeGetOptions(const TLNodeRef node);

TL_EXPORT
void TLNodeFree(const TLNodeRef node);

TL_EXPORT
void TLNodeDeepFree(const TLNodeRef node);

TL_EXPORT
void TLNodeMarkDirty(const TLNodeRef node);

/// TLCaculateLayout, 计算一个节点的布局
/// @param node TLNode instance.
/// @param containerWidth Container width.
/// @param containerHeight Container height.
/// @param context Layout context.
/// @result TLSize with width and height.
TL_EXPORT TLSize TLCaculateLayout(const TLNodeRef node,
                                  const float containerWidth,
                                  const float containerHeight,
                                  void* context);

/// Create linear layout node instance with options
/// @param options TLNodeOptions instance.
TL_EXPORT
const LinearLayoutNodeRef TLLinearLayoutNodeNewWithOptions(const TLNodeOptionsRef options);

/// Creat linear layout node instance with default `TLNodeOptions`.
TL_EXPORT
const LinearLayoutNodeRef TLLinearLayoutNodeNew(void);

/// create flex layout node instance with default `TLNodeOptions`.
TL_EXPORT
const FlexLayoutNodeRef TLFlexLayoutNodeNew(void);

TL_EXPORT
const FlexLayoutNodeRef TLFlexLayoutNodeNewithOptions(const TLNodeOptionsRef options);

TL_EXPORT
const TLNodeRef TLNodeGetParent(const TLNodeRef node);

TL_EXPORT
const size_t TLNodeGetChildrenCount(const TLNodeRef node);

TL_EXPORT
const TLNodeRef TLNodeGetChild(const TLNodeRef node, const size_t index);

/// Set children for one TLNode instance.
/// @param node TLNode instance.
/// @param children TLNode children.
/// @param count Children count.
TL_EXPORT
void TLNodeSetChildren(const TLNodeRef node,
                       const TLNodeRef children[],
                       uint32_t count);

TL_EXPORT
const TLRect TLNodeGetFrame(const TLNodeRef node);

/// MARK: TLStyle getters and setters.
TL_EXPORT
const enum TLDisplay TLNodeGetStyleDisplay(const TLNodeRef node);
TL_EXPORT
void TLNodeSetStyleDisplay(const TLNodeRef node, const enum TLDisplay display);
TL_EXPORT
const int32_t TLNodeGetStyleGrowWeight(const TLNodeRef node);
TL_EXPORT
void TLNodeSetStyleGrowWeight(const TLNodeRef node, const int32_t value);

TL_EXPORT
const int32_t TLNodeGetStyleShrinkWeight(const TLNodeRef node);
TL_EXPORT
void TLNodeSetStyleShrinkWeight(const TLNodeRef node, const int32_t value);

TL_EXPORT
const TLValue TLNodeGetStyleWidth(const TLNodeRef node);
TL_EXPORT
void TLNodeSetStyleWidth(const TLNodeRef node, const TLValue value);

TL_EXPORT
const TLValue TLNodeGetStyleHeight(const TLNodeRef node);
TL_EXPORT
void TLNodeSetStyleHeight(const TLNodeRef node, const TLValue value);

TL_EXPORT
const TLValue TLNodeGetStyleMaxWidth(const TLNodeRef node);
TL_EXPORT
void TLNodeSetStyleMaxWidth(const TLNodeRef node, const TLValue value);

TL_EXPORT
const TLValue TLNodeGetStyleMaxHeight(const TLNodeRef node);
TL_EXPORT
void TLNodeSetStyleMaxHeight(const TLNodeRef node, const TLValue value);

TL_EXPORT
const TLValue TLNodeGetStyleMinWidth(const TLNodeRef node);
TL_EXPORT
void TLNodeSetStyleMinWidth(const TLNodeRef node, const TLValue value);

TL_EXPORT
const TLValue TLNodeGetStyleMinHeight(const TLNodeRef node);
TL_EXPORT
void TLNodeSetStyleMinHeight(const TLNodeRef node, const TLValue value);

TL_EXPORT
const enum TLAlign TLNodeGetStyleAlignSelf(const TLNodeRef node);
TL_EXPORT
void TLNodeSetStyleAlignSelf(const TLNodeRef node, const enum TLAlign alignSelf);

TL_EXPORT
const float TLNodeGetStyleAspectRatio(const TLNodeRef node);
TL_EXPORT
void TLNodeSetStyleAspectRatio(const TLNodeRef node, const float value);
/// MARK: TLStyle getters and setters end.

/// MARK: LinearLayoutProps getters and setters.
TL_EXPORT
const enum TLDirection TLNodeGetLinearLayoutPropsDirection(const LinearLayoutNodeRef);
TL_EXPORT
void TLNodeSetLinearLayoutPropsDirection(const LinearLayoutNodeRef node,
                                         const enum TLDirection direction);

TL_EXPORT
const enum TLOrientation TLNodeGetLinearLayoutPropsOrientation(const LinearLayoutNodeRef);
TL_EXPORT
void TLNodeSetLinearLayoutPropsOrientation(const LinearLayoutNodeRef node,
                                           const enum TLOrientation orientation);

TL_EXPORT
const enum TLJustify TLNodeGetLinearLayoutPropsMainAxisJustify(const LinearLayoutNodeRef);
TL_EXPORT
void TLNodeSetLinearLayoutPropsMainAxisJustify(const LinearLayoutNodeRef node,
                                               const enum TLJustify justify);

TL_EXPORT
const enum TLAlign TLNodeGetLinearLayoutPropsCrossAxisAlign(const LinearLayoutNodeRef);
TL_EXPORT
void TLNodeSetLinearLayoutPropsCrossAxisAlign(const LinearLayoutNodeRef node,
                                              const enum TLAlign align);

TL_EXPORT
const float TLNodeGetLinearLayoutPropsPaddingOfSide(const LinearLayoutNodeRef node, const enum TLSide side);
TL_EXPORT
const TLEdges TLNodeGetLinearLayoutPropsPadding(const LinearLayoutNodeRef node);
TL_EXPORT
void TLNodeSetLinearLayoutPropsPaddingOfSide(const LinearLayoutNodeRef node, const float padding, const enum TLSide side);
TL_EXPORT
void TLNodeSetLinearLayoutPropsPadding(const LinearLayoutNodeRef node, const TLEdges padding);

TL_EXPORT
const float TLNodeGetLinearLayoutPropsWrapWidth(const LinearLayoutNodeRef);
TL_EXPORT
void TLNodeSetLinearLayoutPropsWrapWidth(const LinearLayoutNodeRef node, const float wrapWidth);

TL_EXPORT
const float TLNodeGetLinearLayoutPropsSpacing(const LinearLayoutNodeRef);
TL_EXPORT
void TLNodeSetLinearLayoutPropsSpacing(const LinearLayoutNodeRef node, const float spacing);
/// MARK: LinearLayoutProps getters and setters end.

/// MARK: FlexLayoutProps getters and setters.
TL_EXPORT
const enum TLOrientation TLNodeGetFlexLayoutPropsOrientation(const FlexLayoutNodeRef node);
TL_EXPORT
void TLNodeSetFlexLayoutPropsOrientation(const FlexLayoutNodeRef node,
                                         const enum TLOrientation orientation);

TL_EXPORT
const enum TLJustify TLNodeGetFlexLayoutPropsMainAxisJustify(const FlexLayoutNodeRef);
TL_EXPORT
void TLNodeSetFlexLayoutPropsMainAxisJustify(const FlexLayoutNodeRef node,
                                             const enum TLJustify justify);

TL_EXPORT
const enum TLAlign TLNodeGetFlexLayoutPropsCrossAxisAlign(const FlexLayoutNodeRef);
TL_EXPORT
void TLNodeSetFlexLayoutPropsCrossAxisAlign(const FlexLayoutNodeRef node,
                                            const enum TLAlign align);

TL_EXPORT
const enum TLFlexWrap TLNodeGetFlexLayoutPropsFlexWrap(const FlexLayoutNodeRef);
TL_EXPORT
void TLNodeSetFlexLayoutPropsFlexWrap(const FlexLayoutNodeRef node,
                                      const enum TLFlexWrap flexWrap);

TL_EXPORT
const float TLNodeGetFlexLayoutPropsPaddingOfSide(const FlexLayoutNodeRef node, const enum TLSide side);
TL_EXPORT
void TLNodeSetFlexLayoutPropsPaddingOfSide(const FlexLayoutNodeRef node, const float padding, const enum TLSide side);
TL_EXPORT
const TLEdges TLNodeGetFlexLayoutPropsPadding(const FlexLayoutNodeRef node);
TL_EXPORT
void TLNodeSetFlexLayoutPropsPadding(const FlexLayoutNodeRef node, const TLEdges padding);

TL_EXPORT
const float TLNodeGetFlexLayoutPropsMainAxisSpacing(const FlexLayoutNodeRef);
TL_EXPORT
void TLNodeSetFlexLayoutPropsMainAxisSpacing(const FlexLayoutNodeRef node, const float mainAxisSpacing);

TL_EXPORT
const float TLNodeGetFlexLayoutPropsCrossAxisSpacing(const FlexLayoutNodeRef);
TL_EXPORT
void TLNodeSetFlexLayoutPropsCrossAxisSpacing(const FlexLayoutNodeRef node, const float crossAxisSpacing);
/// MARK: FlexLayoutProps getters and setters end

TL_EXTERN_C_END

#ifdef __cpluscplus
#include <vector>

void TLNodeSetChildren(const TLNodeRef node,
                       const std::vector<TLNodeRef>& chilren);
#endif
