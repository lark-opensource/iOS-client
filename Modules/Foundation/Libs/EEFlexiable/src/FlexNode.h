//
//  Header.h
//  EEFlexiable
//
//  Created by qihongye on 2018/11/25.
//

#import "types.h"
#import "FlexStyle.h"

YG_EXTERN_C_BEGIN

extern CSSValue CSSPointValue(CGFloat value)
NS_SWIFT_UNAVAILABLE("Use the swift Int and FloatingPoint extensions instead");
extern CSSValue CSSPercentValue(CGFloat value)
NS_SWIFT_UNAVAILABLE("Use the swift Int and FloatingPoint extensions instead");

#define FLEX_NODE_PROPERTY(type, lowercased_name, capitalized_name) \
- (type)lowercased_name\
{\
    return _flexStyle.lowercased_name;\
}\
- (void)set##capitalized_name:(type)lowercased_name\
{\
    [_flexStyle set##capitalized_name: lowercased_name];\
}\

#define FLEX_NODE_EDGE_PROPERTY(lowercased_name, capitalized_name)\
FLEX_NODE_PROPERTY(CSSValue, lowercased_name, capitalized_name)\
FLEX_NODE_PROPERTY(CSSValue, lowercased_name##Left, capitalized_name##Left)\
FLEX_NODE_PROPERTY(CSSValue, lowercased_name##Top, capitalized_name##Top)\
FLEX_NODE_PROPERTY(CSSValue, lowercased_name##Right, capitalized_name##Right)\
FLEX_NODE_PROPERTY(CSSValue, lowercased_name##Bottom, capitalized_name##Bottom)\
FLEX_NODE_PROPERTY(CSSValue, lowercased_name##Start, capitalized_name##Start)\
FLEX_NODE_PROPERTY(CSSValue, lowercased_name##End, capitalized_name##End)\
FLEX_NODE_PROPERTY(CSSValue, lowercased_name##Horizontal, capitalized_name##Horizontal)\
FLEX_NODE_PROPERTY(CSSValue, lowercased_name##Vertical, capitalized_name##Vertical)\

YG_EXTERN_C_END

@interface FlexNode : NSObject<NSCopying>

/**
 The property that decides if we should include this view when calculating
 layout. Defaults to YES.
 */
@property (nonatomic, readwrite, assign, setter=setIncludedInLayout:) BOOL isIncludedInLayout;

@property (nonatomic, copy, readonly) FlexStyle* _Nonnull flexStyle;
@property (nonatomic, assign, readonly, getter=flexNode) YGNodeRef _Nonnull node;

@property (nonatomic, readwrite, assign) CSSDirection direction;
@property (nonatomic, readwrite, assign) CSSFlexDirection flexDirection;
@property (nonatomic, readwrite, assign) CSSJustify justifyContent;
@property (nonatomic, readwrite, assign) CSSAlign alignContent;
@property (nonatomic, readwrite, assign) CSSAlign alignItems;
@property (nonatomic, readwrite, assign) CSSAlign alignSelf;
@property (nonatomic, readwrite, assign) CSSPosition position;
@property (nonatomic, readwrite, assign) CSSWrap flexWrap;
@property (nonatomic, readwrite, assign) CSSOverflow overflow;
@property (nonatomic, readwrite, assign) CSSDisplay display;

@property (nonatomic, readwrite, assign) CGFloat flexGrow;
@property (nonatomic, readwrite, assign) CGFloat flexShrink;
@property (nonatomic, readwrite, assign) CSSValue flexBasis;

@property (nonatomic, readwrite, assign) CSSValue left;
@property (nonatomic, readwrite, assign) CSSValue top;
@property (nonatomic, readwrite, assign) CSSValue right;
@property (nonatomic, readwrite, assign) CSSValue bottom;
@property (nonatomic, readwrite, assign) CSSValue start;
@property (nonatomic, readwrite, assign) CSSValue end;

@property (nonatomic, readwrite, assign) CSSValue marginLeft;
@property (nonatomic, readwrite, assign) CSSValue marginTop;
@property (nonatomic, readwrite, assign) CSSValue marginRight;
@property (nonatomic, readwrite, assign) CSSValue marginBottom;
@property (nonatomic, readwrite, assign) CSSValue marginStart;
@property (nonatomic, readwrite, assign) CSSValue marginEnd;
@property (nonatomic, readwrite, assign) CSSValue marginHorizontal;
@property (nonatomic, readwrite, assign) CSSValue marginVertical;
@property (nonatomic, readwrite, assign) CSSValue margin;

@property (nonatomic, readwrite, assign) CSSValue paddingLeft;
@property (nonatomic, readwrite, assign) CSSValue paddingTop;
@property (nonatomic, readwrite, assign) CSSValue paddingRight;
@property (nonatomic, readwrite, assign) CSSValue paddingBottom;
@property (nonatomic, readwrite, assign) CSSValue paddingStart;
@property (nonatomic, readwrite, assign) CSSValue paddingEnd;
@property (nonatomic, readwrite, assign) CSSValue paddingHorizontal;
@property (nonatomic, readwrite, assign) CSSValue paddingVertical;
@property (nonatomic, readwrite, assign) CSSValue padding;

@property (nonatomic, readwrite, assign) CGFloat borderLeftWidth;
@property (nonatomic, readwrite, assign) CGFloat borderTopWidth;
@property (nonatomic, readwrite, assign) CGFloat borderRightWidth;
@property (nonatomic, readwrite, assign) CGFloat borderBottomWidth;
@property (nonatomic, readwrite, assign) CGFloat borderStartWidth;
@property (nonatomic, readwrite, assign) CGFloat borderEndWidth;
@property (nonatomic, readwrite, assign) CGFloat borderWidth;

@property (nonatomic, readwrite, assign) CSSValue width;
@property (nonatomic, readwrite, assign) CSSValue height;
@property (nonatomic, readwrite, assign) CSSValue minWidth;
@property (nonatomic, readwrite, assign) CSSValue minHeight;
@property (nonatomic, readwrite, assign) CSSValue maxWidth;
@property (nonatomic, readwrite, assign) CSSValue maxHeight;

// Yoga specific properties, not compatible with flexbox specification
@property (nonatomic, readwrite, assign) CGFloat aspectRatio;

/**
 Get the resolved direction of this node. This won't be CSSDirectionInherit
 */
@property (nonatomic, readonly, assign) CSSDirection resolvedDirection;

@property (nonatomic, readwrite, nullable) NSString* key;

/**
 Returns a series of FlexNodes
 */
@property (nonatomic, readonly, copy) NSMutableArray<FlexNode*>* _Nonnull subNodes;

/**
 Returns the size of the view if no constraints were given. This could equivalent to calling [self
 sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
 */
@property (nonatomic, readonly, assign) CGSize intrinsicSize;


/**
 Returns current CGRect value. View can use this value directly
 */
@property (nonatomic, readonly, assign) CGRect frame;

/**
 Returns the size of the view based on provided constraints. Pass NaN for an unconstrained dimension.
 */
- (CGSize)calculateLayoutWithSize:(CGSize)size
NS_SWIFT_NAME(calculateLayout(with:));

/**
 Returns the number of children that are using Flexbox.
 */
@property (nonatomic, readonly, assign) NSUInteger numberOfChildren;

/**
 Return a BOOL indiciating whether or not we this node contains any subviews that are included in
 Yoga's layout.
 */
@property (nonatomic, readonly, assign) BOOL isLeaf;

/**
 Return a BOOL indicating if a flexNode can calculate size itself.
 */
@property (nonatomic, readwrite, assign) BOOL isSelfSizing;

/**
 Return's a BOOL indicating if a view is dirty. When a node is dirty
 it usually indicates that it will be remeasured on the next layout pass.
 */
@property (nonatomic, readonly, assign) BOOL isDirty;

/**
 Sync props from oldNode to newNode.
 */
+ (void)syncFlexNode:(nonnull FlexNode*)oldNode to: (nonnull FlexNode*)newNode;

- (nonnull id)initWith: (nullable FlexStyle*)style;
/**
 Mark that a view's layout needs to be recalculated. Only works for leaf views.
 */
- (void)markDirty;

- (nonnull FlexNode*)clone;

- (void)addSubFlexNode: (nonnull FlexNode *)subNode;

- (void)addSubFlexNode: (nonnull FlexNode *)subNode at:(uint32_t)index;

- (void)setSubFlexNodes: (nonnull NSArray *)subNodes;

- (void)removeFlexNode: (nonnull FlexNode *)subNode;

- (void)removeAllSubFlexNodes;

- (void)setMeasureFunc: (nonnull FlexMeasureFunc)measureFunc;

- (void)setBaselineFunc: (nonnull FlexBaselineFunc)baselineFunc;

- (void)reset;

@end

