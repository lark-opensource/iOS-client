//  Heimdallr
//
//  Created by 谢俊逸 on 2019/06/13.
//


#import "Heimdallr+GameTracker.h"
#import "HMDGameTracker.h"

@implementation Heimdallr (GameTracker)
+ (void)recordGameErrorWithName:(NSString *)name reason:(NSString *)reason stackTrace:(NSString *)stackTrace {
    [[HMDGameTracker sharedTracker] recordGameErrorWithTraceStack:stackTrace name:name reason:reason];
}
@end
