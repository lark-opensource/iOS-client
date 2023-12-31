// Copyright 2021 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface LynxTextUtils : NSObject
/*
 * Resolve NSTextAlignNatural to physical alignment according to the inferred languange of given
 * attributed string. The resolved alignment will be applied to the paragraph style of the given
 * attirbuted string. If attributed string has a explictly assigned physical alignment, this
 * function won't do anything
 *
 * @param attrString the attributed string to infer from and apply physical alignment.
 * @return the applied alignment.
 */
+ (NSTextAlignment)applyNaturalAlignmentAccordingToTextLanguage:
                       (nonnull NSMutableAttributedString *)attrString
                                                       refactor:(BOOL)enableRefactor;

/*
 * Get ellipsis string with unicode direction marker to controll the direction of ellipsis
 *
 * @param direction of the ellipsis
 * @return the ellipsis string.
 */
+ (nonnull NSString *)getEllpsisStringAccordingToWritingDirection:(NSWritingDirection)direction;

@end
