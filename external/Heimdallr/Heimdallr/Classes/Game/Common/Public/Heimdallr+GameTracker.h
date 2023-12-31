//
//  Heimdallr+GameTracker.h
//  Heimdallr
//
//  Created by 谢俊逸 on 2019/06/13.
//

#import "Heimdallr.h"

@interface Heimdallr (GameTracker)

+ (void)recordGameErrorWithName:(nullable NSString *)name reason:(nullable NSString *)reason stackTrace:(nullable NSString *)stackTrace;

@end
