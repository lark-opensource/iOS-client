//
//  UIPasteboard+SCPasteProtect.h
//  LarkEMM
//
//  Created by ByteDance on 2023/12/22.
//

#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface UIPasteboard (SCPasteProtect)

+ (void)scReplacePasteboardMethod;

+ (BOOL)generalHasNewValue;

+ (BOOL)generalHasStrings;

+ (BOOL)generalHasColors;

+ (BOOL)generalHasImages;

+ (BOOL)generalHasUrls;

@end

NS_ASSUME_NONNULL_END
