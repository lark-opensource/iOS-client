//
//  PNSQueryIdProtocol.h
//  Musically
//
//  Created by ByteDance on 2023/2/17.
//

#import "PNSServiceCenter.h"

@protocol PNSQueryIdProtocol <NSObject>

- (NSNumber *_Nullable)queryIdWithToken:(NSString *_Nullable)token;

@end
