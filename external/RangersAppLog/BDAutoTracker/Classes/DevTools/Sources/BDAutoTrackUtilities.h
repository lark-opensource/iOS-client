//
//  BDAutoTrackUtilities.h
//  RangersAppLog-RangersAppLogDevTools
//
//  Created by bytedance on 6/28/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDAutoTrackUtilities : NSObject

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)size;

+ (void)ignoreAutoTrack:(UIButton *)btn;

@end

NS_ASSUME_NONNULL_END
