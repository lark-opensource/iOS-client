//
//  FlexNode.m
//  EEFlexiable
//
//  Created by qihongye on 2018/11/25.
//

#import "FlexNode.h"
#import <UIKit/UIKit.h>

CSSValue CSSPointValue(CGFloat value)
{
    return (CSSValue) { .value = value, .unit = YGUnitPoint };
}

CSSValue CSSPercentValue(CGFloat value)
{
    return (CSSValue) { .value = value, .unit = YGUnitPoint };
}

@interface FlexLayoutContext : NSObject<NSCopying>

@property(nonatomic, nullable) FlexMeasureFunc measureFunc;

@property(nonatomic, nullable) FlexBaselineFunc baselineFunc;

@property(nonatomic, readonly) BOOL hasMeasureFunc;

@property(nonatomic, readonly) BOOL hasBaselineFunc;

@end

@implementation FlexLayoutContext

@synthesize measureFunc=_measureFunc;
@synthesize baselineFunc=_baselineFunc;

- (void)setMeasureFunc:(FlexMeasureFunc)measureFunc
{
    _measureFunc = measureFunc;
}

- (void)setBaselineFunc:(FlexBaselineFunc)baselineFunc
{
    _baselineFunc = baselineFunc;
}

- (BOOL)hasMeasureFunc
{
    return _measureFunc != NULL;
}

- (BOOL)hasBaselineFunc
{
    return _baselineFunc != NULL;
}

- (nonnull id)copyWithZone:(NSZone *)zone
{
    FlexLayoutContext* context = [[FlexLayoutContext alloc] init];
    [context setMeasureFunc:_measureFunc];
    [context setBaselineFunc:_baselineFunc];
    return context;
}

@end

@interface FlexNode ()

@property (nonatomic, readonly, strong) FlexLayoutContext* layoutContext;

@end

@implementation FlexNode

@synthesize flexStyle = _flexStyle;
@synthesize isIncludedInLayout=_isIncludedInLayout;
@synthesize layoutContext=_layoutContext;
@synthesize subNodes=_subNodes;

+ (void)syncFlexNode:(FlexNode*)oldNode to: (FlexNode*)newNode
{
    [newNode setKey:oldNode.key];
    [newNode setFlexStyle:(FlexStyle*)[oldNode.flexStyle copy]];
    [newNode setLayoutContext:(FlexLayoutContext*)[oldNode.layoutContext copy]];
    [newNode setIncludedInLayout:oldNode.isIncludedInLayout];
}

- (id)init
{
    return [self initWith:NULL];
}

- (id)initWith:(nullable FlexStyle *)style
{
    self = [super init];
    if (self) {
        if (style) {
            _flexStyle = style;
        } else {
            _flexStyle = [[FlexStyle alloc] init];
        }
        _isSelfSizing = NO;
        _layoutContext = [[FlexLayoutContext alloc] init];
        _isIncludedInLayout = YES;
        _subNodes = [[NSMutableArray new] init];
    }
    return self;
}

- (YGNodeRef)flexNode
{
    return _flexStyle.node;
}

- (void)setFlexStyle:(FlexStyle*)style
{
    _flexStyle = style;
}

- (void)setLayoutContext:(FlexLayoutContext *)layoutContext
{
    _layoutContext = layoutContext;
    YGNodeSetContext(self.node, (__bridge void*)_layoutContext);
    if (layoutContext.hasMeasureFunc) {
        YGNodeSetMeasureFunc(self.node, FlexToYGMeasureFunc);
    } else {
        YGNodeSetMeasureFunc(self.node, NULL);
    }
    if (layoutContext.hasBaselineFunc) {
        YGNodeSetBaselineFunc(self.node, FlexToYGBaselineFunc);
    } else {
        YGNodeSetBaselineFunc(self.node, NULL);
    }
}

- (nonnull id)copy
{
    return [self copyWithZone:NULL];
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    FlexNode* newNode = [[FlexNode alloc] init];
    [newNode setKey:_key];
    FlexStyle* newStyle = [_flexStyle copy];
    [newNode setFlexStyle:newStyle];
    FlexLayoutContext* layoutContext = [_layoutContext copy];
    [newNode setLayoutContext:layoutContext];
    [newNode setIncludedInLayout:_isIncludedInLayout];
    return newNode;
}

- (nonnull FlexNode*)clone
{
    return (FlexNode*)[self copy];
}

#pragma childNode

- (NSUInteger) numberOfChildren
{
    return YGNodeGetChildCount(self.node);
}

- (BOOL)isDirty
{
    return YGNodeIsDirty(self.node);
}

- (void)markDirty
{
    if ([self isLeaf]) {
        YGNodeMarkDirty(self.node);
    }
}

-(BOOL)isLeaf
{
    return YGNodeGetChildCount(self.node) == 0;
}

- (void)addSubFlexNode:(FlexNode *)subNode {
    [_subNodes addObject:subNode];
    YGNodeInsertChild(self.node, subNode.node, YGNodeGetChildCount(self.node));
}

- (void)addSubFlexNode:(FlexNode *)subNode at:(uint32_t)index {
    [_subNodes insertObject:subNode atIndex:index];
    YGNodeInsertChild(self.node, subNode.node, index);
}

- (void)removeFlexNode:(FlexNode *)subNode
{
    [_subNodes removeObject:subNode];
    YGNodeRemoveChild(self.node, subNode.node);
}

- (void)removeAllSubFlexNodes
{
    [_subNodes removeAllObjects];
    YGNodeRemoveAllChildren(self.node);
}

- (void)setSubFlexNodes:(NSArray *)subNodes {
    if ([self numberOfChildren] != 0) {
        [self removeAllSubFlexNodes];
    }
    NSInteger count = [subNodes count];
    for (int i = 0; i < count; i++) {
        if ([subNodes[i] isKindOfClass:[FlexNode class]]) {
            FlexNode* subNode = subNodes[i];
            YGNodeRef parent = YGNodeGetParent(subNode.node);
            if (parent != NULL) {
                YGNodeRemoveChild(parent, subNode.node);
            }
            [self addSubFlexNode:subNodes[i] at:i];
        }
    }
}

#pragma mark calculate layout

- (CGSize)intrinsicSize
{
    return [self calculateLayoutWithSize:(CGSize) {
        .width = YGUndefined,
        .height = YGUndefined,
    }];
}

- (CGSize)calculateLayoutWithSize:(CGSize)size
{
    const YGNodeRef node = self.node;
    YGNodeCalculateLayout(node, size.width, size.height, YGNodeStyleGetDirection(node));

    return (CGSize) {
        .width = YGNodeLayoutGetWidth(node),
        .height = YGNodeLayoutGetHeight(node),
    };
}

- (CGRect)frame
{
    const YGNodeRef node = self.node;
    return (CGRect) {
        .origin = {
            .x = YGNodeLayoutGetLeft(node),
            .y = YGNodeLayoutGetTop(node),
        },
        .size = {
            .width = YGNodeLayoutGetWidth(node),
            .height = YGNodeLayoutGetHeight(node),
        }
    };
}

- (void)setMeasureFunc:(FlexMeasureFunc)measureFunc
{
    _layoutContext.measureFunc = measureFunc;
    YGNodeSetContext(self.node, (__bridge void*)_layoutContext);
    YGNodeSetMeasureFunc(self.node, FlexToYGMeasureFunc);
}

- (void)setBaselineFunc:(FlexBaselineFunc)baselineFunc
{
    _layoutContext.baselineFunc = baselineFunc;
    YGNodeSetContext(self.node, (__bridge void*)_layoutContext);
    YGNodeSetBaselineFunc(self.node, FlexToYGBaselineFunc);
}

- (void)reset
{
    YGNodeRef parent = YGNodeGetParent(self.node);
    if (parent != NULL) {
        YGNodeRemoveAllChildren(parent);
    }
    YGNodeRef owner = YGNodeGetOwner(self.node);
    if (owner != NULL) {
        YGNodeRemoveAllChildren(owner);
    }
    YGNodeRemoveAllChildren(self.node);
    [_subNodes removeAllObjects];
    YGNodeReset(self.node);
}

#pragma mark sync Style

FLEX_NODE_PROPERTY(CSSPosition, position, Position)
FLEX_NODE_PROPERTY(CSSDirection, resolvedDirection, ResolvedDirection)
FLEX_NODE_PROPERTY(CSSValue, flexBasis, FlexBasis)
FLEX_NODE_PROPERTY(CSSDirection, direction, Direction)
FLEX_NODE_PROPERTY(CSSFlexDirection, flexDirection, FlexDirection)
FLEX_NODE_PROPERTY(CSSJustify, justifyContent, JustifyContent)
FLEX_NODE_PROPERTY(CSSAlign, alignContent, AlignContent)
FLEX_NODE_PROPERTY(CSSAlign, alignItems, AlignItems)
FLEX_NODE_PROPERTY(CSSAlign, alignSelf, AlignSelf)
FLEX_NODE_PROPERTY(CSSWrap, flexWrap, FlexWrap)
FLEX_NODE_PROPERTY(CSSOverflow, overflow, Overflow)
FLEX_NODE_PROPERTY(CSSDisplay, display, Display)
FLEX_NODE_PROPERTY(CGFloat, flexGrow, FlexGrow)
FLEX_NODE_PROPERTY(CGFloat, flexShrink, FlexShrink)
FLEX_NODE_PROPERTY(CSSValue, left, Left)
FLEX_NODE_PROPERTY(CSSValue, top, Top)
FLEX_NODE_PROPERTY(CSSValue, right, Right)
FLEX_NODE_PROPERTY(CSSValue, bottom, Bottom)
FLEX_NODE_PROPERTY(CSSValue, start, Start)
FLEX_NODE_PROPERTY(CSSValue, end, End)

FLEX_NODE_EDGE_PROPERTY(margin, Margin)
FLEX_NODE_EDGE_PROPERTY(padding, Padding)

FLEX_NODE_PROPERTY(CGFloat, borderWidth, BorderWidth)
FLEX_NODE_PROPERTY(CGFloat, borderLeftWidth, BorderLeftWidth)
FLEX_NODE_PROPERTY(CGFloat, borderTopWidth, BorderTopWidth)
FLEX_NODE_PROPERTY(CGFloat, borderRightWidth, BorderRightWidth)
FLEX_NODE_PROPERTY(CGFloat, borderBottomWidth, BorderBottomWidth)
FLEX_NODE_PROPERTY(CGFloat, borderStartWidth, BorderStartWidth)
FLEX_NODE_PROPERTY(CGFloat, borderEndWidth, BorderEndWidth)
FLEX_NODE_PROPERTY(CSSValue, width, Width)
FLEX_NODE_PROPERTY(CSSValue, minWidth, MinWidth)
FLEX_NODE_PROPERTY(CSSValue, maxWidth, MaxWidth)
FLEX_NODE_PROPERTY(CSSValue, height, Height)
FLEX_NODE_PROPERTY(CSSValue, minHeight, MinHeight)
FLEX_NODE_PROPERTY(CSSValue, maxHeight, MaxHeight)
FLEX_NODE_PROPERTY(CGFloat, aspectRatio, AspectRatio)


#pragma mark - Private

static YGSize FlexToYGMeasureFunc(
                            YGNodeRef node,
                            float width,
                            YGMeasureMode widthMode,
                            float height,
                            YGMeasureMode heightMode)
{
    FlexLayoutContext *context = (__bridge FlexLayoutContext*)YGNodeGetContext(node);
    YGAssert(context.hasMeasureFunc, "Already set YGMeasureFunc but context.measureFunc is NULL.");

    const CGFloat constrainedWidth = (widthMode == YGMeasureModeUndefined) ? CGFLOAT_MAX : width;
    const CGFloat constrainedHeight = (heightMode == YGMeasureModeUndefined) ? CGFLOAT_MAX: height;
    CGSize measureSize = CGSizeZero;

    if (context.hasMeasureFunc) {
        measureSize = context.measureFunc(constrainedWidth, constrainedHeight);
    }

    return (YGSize) {
        .width = measureSize.width,
        .height = measureSize.height,
    };
}

static float FlexToYGBaselineFunc(YGNodeRef node, const float width, const float height)
{
    FlexLayoutContext *context = (__bridge FlexLayoutContext*)YGNodeGetContext(node);
    YGAssert(context.hasBaselineFunc, "Already set YGBaselineFunc but context.baselineFunc is NULL.");

    if (context.hasBaselineFunc) {
        return context.baselineFunc(width, height);
    }
    return 0;
}

@end
