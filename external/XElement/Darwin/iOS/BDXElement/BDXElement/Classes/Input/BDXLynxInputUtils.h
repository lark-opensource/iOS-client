//  Copyright 2023 The Lynx Authors. All rights reserved.

@interface BDXLynxInputUtils : NSObject

/**
 * This function returns the size of the attributedString under the given constraints.
 * 
 * The function takes the following parameters:
 *  attributedString: The attributed string that is to be calculated.
 *  constraints: The constraints that must be met when calculating the size of the attributedString.
 *
 * The function returns the size of the attributed string
 */
+ (CGSize)getAttributedStringSize:(NSAttributedString *)attributedString
                      constraints:(CGSize)constraints;
@end

