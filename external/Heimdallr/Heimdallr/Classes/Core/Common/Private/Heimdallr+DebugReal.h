//
//  Heimdallr+DebugReal.h
//  Heimdallr
//
//  Created by joy on 2018/8/13.
//


#import "Heimdallr.h"

@interface Heimdallr (DebugReal)

+ (void)uploadDebugRealDataWithStartTime:(NSTimeInterval)fetchStartTime endTime:(NSTimeInterval)fetchEndTime wifiOnly:(BOOL)wifiOnly __attribute__((deprecated("deprecated. The new version does not need to invoke it")));
+ (void)uploadDebugRealDataWithLocalConfig __attribute__((deprecated("deprecated. The new version does not need to invoke it")));

@end
