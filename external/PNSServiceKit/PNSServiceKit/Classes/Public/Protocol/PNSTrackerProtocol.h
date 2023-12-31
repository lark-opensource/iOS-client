//
//  PNSTrackerProtocol.h
//  PNSServiceKit
//
//  Created by chirenhua on 2022/6/15.
//

#import "PNSServiceCenter.h"

#ifndef PNSTrackerProtocol_h
#define PNSTrackerProtocol_h

#define PNSTracker PNS_GET_INSTANCE(PNSTrackerProtocol)

@protocol PNSTrackerProtocol <NSObject>

- (void)event:(NSString * _Nonnull)event
       params:(NSDictionary * _Nullable)params;

@end

#endif /* PNSTrackerProtocol_h */
