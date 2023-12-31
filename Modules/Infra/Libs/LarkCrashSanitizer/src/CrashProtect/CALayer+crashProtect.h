//
//  CALayer+crashProtect.h
//  LarkCrashSanitizer
//
//  Created by sniperj on 2020/5/19.
//

#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

extern bool lark_optimize_calayer_crash;

@interface CALayer (crashProtect)

@end

NS_ASSUME_NONNULL_END
