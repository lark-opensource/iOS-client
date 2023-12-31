//
//  NSAttributedString+ACCUIDynamicColor.h
//  CreativeKit-Pods-Aweme
//
//  Created by xiangpeng on 2021/9/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSAttributedString (ACCUIDynamicColor)

- (BOOL)acc_attributeContainsDynamicColor;
- (NSAttributedString *)acc_invalidateAttributedTextForegroundColor;

@end

NS_ASSUME_NONNULL_END
