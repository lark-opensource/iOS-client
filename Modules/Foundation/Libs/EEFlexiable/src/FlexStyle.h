//
//  FlexStyle.h
//  EEFlexiable
//
//  Created by qihongye on 2019/3/22.
//

#import <Foundation/Foundation.h>
#import "types.h"

@interface FlexStyle : NSObject<NSCopying>

@property (nonatomic, assign, readonly) YGNodeRef node;

/// default: inherite
@property (nonatomic, readwrite, assign) CSSDirection direction;
/// default: row
@property (nonatomic, readwrite, assign) CSSFlexDirection flexDirection;
/// default: flexStart
@property (nonatomic, readwrite, assign) CSSJustify justifyContent;
/// default: flexStart
@property (nonatomic, readwrite, assign) CSSAlign alignContent;
/// default: stretch
@property (nonatomic, readwrite, assign) CSSAlign alignItems;
/// default: auto
@property (nonatomic, readwrite, assign) CSSAlign alignSelf;
/// default: relative
@property (nonatomic, readwrite, assign) CSSPosition position;
/// default: noWrap
@property (nonatomic, readwrite, assign) CSSWrap flexWrap;
/// default: hidden
@property (nonatomic, readwrite, assign) CSSOverflow overflow;
/// default: flex
@property (nonatomic, readwrite, assign) CSSDisplay display;

/// default: 0
@property (nonatomic, readwrite, assign) CGFloat flexGrow;
/// default: 1
@property (nonatomic, readwrite, assign) CGFloat flexShrink;
/// default: auto
@property (nonatomic, readwrite, assign) CSSValue flexBasis;

/// default: undefined
@property (nonatomic, readwrite, assign) CSSValue left;
/// default: undefined
@property (nonatomic, readwrite, assign) CSSValue top;
/// default: undefined
@property (nonatomic, readwrite, assign) CSSValue right;
/// default: undefined
@property (nonatomic, readwrite, assign) CSSValue bottom;
/// default: undefined
@property (nonatomic, readwrite, assign) CSSValue start;
/// default: undefined
@property (nonatomic, readwrite, assign) CSSValue end;

/// default: undefined
@property (nonatomic, readwrite, assign) CSSValue marginLeft;
/// default: undefined
@property (nonatomic, readwrite, assign) CSSValue marginTop;
/// default: undefined
@property (nonatomic, readwrite, assign) CSSValue marginRight;
/// default: undefined
@property (nonatomic, readwrite, assign) CSSValue marginBottom;
/// default: undefined
@property (nonatomic, readwrite, assign) CSSValue marginStart;
/// default: undefined
@property (nonatomic, readwrite, assign) CSSValue marginEnd;
/// default: undefined
@property (nonatomic, readwrite, assign) CSSValue marginHorizontal;
/// default: undefined
@property (nonatomic, readwrite, assign) CSSValue marginVertical;
/// default: undefined
@property (nonatomic, readwrite, assign) CSSValue margin;

/// default: undefined
@property (nonatomic, readwrite, assign) CSSValue paddingLeft;
/// default: undefined
@property (nonatomic, readwrite, assign) CSSValue paddingTop;
/// default: undefined
@property (nonatomic, readwrite, assign) CSSValue paddingRight;
/// default: undefined
@property (nonatomic, readwrite, assign) CSSValue paddingBottom;
/// default: undefined
@property (nonatomic, readwrite, assign) CSSValue paddingStart;
/// default: undefined
@property (nonatomic, readwrite, assign) CSSValue paddingEnd;
/// default: undefined
@property (nonatomic, readwrite, assign) CSSValue paddingHorizontal;
/// default: undefined
@property (nonatomic, readwrite, assign) CSSValue paddingVertical;
/// default: undefined
@property (nonatomic, readwrite, assign) CSSValue padding;

/// default: undefined
@property (nonatomic, readwrite, assign) CGFloat borderLeftWidth;
/// default: undefined
@property (nonatomic, readwrite, assign) CGFloat borderTopWidth;
/// default: undefined
@property (nonatomic, readwrite, assign) CGFloat borderRightWidth;
/// default: undefined
@property (nonatomic, readwrite, assign) CGFloat borderBottomWidth;
/// default: undefined
@property (nonatomic, readwrite, assign) CGFloat borderStartWidth;
/// default: undefined
@property (nonatomic, readwrite, assign) CGFloat borderEndWidth;
/// default: undefined
@property (nonatomic, readwrite, assign) CGFloat borderWidth;

/// default: auto
@property (nonatomic, readwrite, assign) CSSValue width;
/// default: auto
@property (nonatomic, readwrite, assign) CSSValue height;
/// default: undefined
@property (nonatomic, readwrite, assign) CSSValue minWidth;
/// default: undefined
@property (nonatomic, readwrite, assign) CSSValue minHeight;
/// default: undefined
@property (nonatomic, readwrite, assign) CSSValue maxWidth;
/// default: undefined
@property (nonatomic, readwrite, assign) CSSValue maxHeight;

/// default: undefined
@property (nonatomic, readwrite, assign) CGFloat aspectRatio;

/**
 Get the resolved direction of this node. This won't be CSSDirectionInherit
 */
@property (nonatomic, readwrite, assign) CSSDirection resolvedDirection;

@end
