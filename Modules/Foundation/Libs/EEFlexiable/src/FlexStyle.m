//
//  FlexStyle.m
//  EEFlexiable
//
//  Created by qihongye on 2019/3/22.
//

#import "FlexStyle.h"
#import "macros.h"
#import <UIKit/UIKit.h>

static YGConfigRef globalConfig;

@implementation FlexStyle

@synthesize node=_node;

+ (void)initialize
{
    globalConfig = YGConfigNew();
    YGConfigSetExperimentalFeatureEnabled(globalConfig, YGExperimentalFeatureWebFlexBasis, true);
    YGConfigSetPointScaleFactor(globalConfig, [UIScreen mainScreen].scale);
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _node = YGNodeNewWithConfig(globalConfig);
        [self defaultStyle];
    }
    return self;
}

- (instancetype)initWith:(YGNodeRef)node
{
    self = [super init];
    if (self) {
        _node = node;
    }
    return self;
}

- (void)defaultStyle
{
    YGNodeStyleSetFlexDirection(_node, YGFlexDirectionRow);
    YGNodeStyleSetOverflow(_node, YGOverflowHidden);
    YGNodeStyleSetFlexGrow(_node, 0);
    YGNodeStyleSetFlexShrink(_node, 1);
}

- (void)dealloc
{
    YGNodeFree(_node);
}

- (id)copy
{
    return [self copyWithZone:NULL];
}

- (id)copyWithZone:(NSZone *)zone
{
    YGNodeRef newNode = YGNodeClone(_node);
    YGNodeRemoveAllChildren(newNode);
    return [[FlexStyle alloc] initWith:newNode];
}

#pragma mark sync Style

- (CSSPosition)position
{
    return (CSSPosition)YGNodeStyleGetPositionType(self.node);
}

- (void)setPosition:(CSSPosition)position
{
    YGNodeStyleSetPositionType(self.node, (YGPositionType)position);
}

- (CSSValue)flexBasis
{
    YGValue value = YGNodeStyleGetFlexBasis(self.node);
    return *((CSSValue *) &value);
}

- (void)setFlexBasis:(CSSValue)flexBasis
{
    switch (flexBasis.unit) {
        case CSSUnitPoint:
            YGNodeStyleSetFlexBasis(self.node, flexBasis.value);
            break;
        case CSSUnitPercent:
            YGNodeStyleSetFlexBasisPercent(self.node, flexBasis.value);
            break;
        case CSSUnitAuto:
            YGNodeStyleSetFlexBasisAuto(self.node);
            break;
        default:
            NSAssert(NO, @"Not implemented");
    }
}

CSS_PROPERTY(CSSDirection, YGDirection, direction, Direction)
CSS_PROPERTY(CSSFlexDirection, YGFlexDirection, flexDirection, FlexDirection)
CSS_PROPERTY(CSSJustify, YGJustify, justifyContent, JustifyContent)
CSS_PROPERTY(CSSAlign, YGAlign, alignContent, AlignContent)
CSS_PROPERTY(CSSAlign, YGAlign, alignItems, AlignItems)
CSS_PROPERTY(CSSAlign, YGAlign, alignSelf, AlignSelf)
CSS_PROPERTY(CSSWrap, YGWrap, flexWrap, FlexWrap)
CSS_PROPERTY(CSSOverflow, YGOverflow, overflow, Overflow)
CSS_PROPERTY(CSSDisplay, YGDisplay, display, Display)

CSS_PROPERTY(CGFloat, CGFloat, flexGrow, FlexGrow)
CSS_PROPERTY(CGFloat, CGFloat, flexShrink, FlexShrink)

CSS_VALUE_EDGE_PROPERTY(left, Left, Position, EdgeLeft)
CSS_VALUE_EDGE_PROPERTY(top, Top, Position, EdgeTop)
CSS_VALUE_EDGE_PROPERTY(right, Right, Position, EdgeRight)
CSS_VALUE_EDGE_PROPERTY(bottom, Bottom, Position, EdgeBottom)
CSS_VALUE_EDGE_PROPERTY(start, Start, Position, EdgeStart)
CSS_VALUE_EDGE_PROPERTY(end, End, Position, EdgeEnd)
CSS_VALUE_EDGES_PROPERTIES(margin, Margin)
CSS_VALUE_EDGES_PROPERTIES(padding, Padding)

CSS_EDGE_PROPERTY(borderLeftWidth, BorderLeftWidth, Border, EdgeLeft)
CSS_EDGE_PROPERTY(borderTopWidth, BorderTopWidth, Border, EdgeTop)
CSS_EDGE_PROPERTY(borderRightWidth, BorderRightWidth, Border, EdgeRight)
CSS_EDGE_PROPERTY(borderBottomWidth, BorderBottomWidth, Border, EdgeBottom)
CSS_EDGE_PROPERTY(borderStartWidth, BorderStartWidth, Border, EdgeStart)
CSS_EDGE_PROPERTY(borderEndWidth, BorderEndWidth, Border, EdgeEnd)
CSS_EDGE_PROPERTY(borderWidth, BorderWidth, Border, EdgeAll)

CSS_AUTO_VALUE_PROPERTY(width, Width)
CSS_AUTO_VALUE_PROPERTY(height, Height)
CSS_VALUE_PROPERTY(minWidth, MinWidth)
CSS_VALUE_PROPERTY(minHeight, MinHeight)
CSS_VALUE_PROPERTY(maxWidth, MaxWidth)
CSS_VALUE_PROPERTY(maxHeight, MaxHeight)
CSS_PROPERTY(CGFloat, CGFloat, aspectRatio, AspectRatio)

@end
