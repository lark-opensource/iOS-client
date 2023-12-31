//
//  AVMDLHttpDNSInterface.h
//  MediaLoader
//
//  Created by bytedance on 2021/5/27.
//  Copyright © 2021 thq. All rights reserved.
//

#ifndef AVMDLHttpDNSInterface_h
#define AVMDLHttpDNSInterface_h

@protocol AVMDLCustomHttpDNSParser <NSObject>

- (NSDictionary*)parse:(NSString *)host;

@end

#endif /* AVMDLHttpDNSInterface_h */
