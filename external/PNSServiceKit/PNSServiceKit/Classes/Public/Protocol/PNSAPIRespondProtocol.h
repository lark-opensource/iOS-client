//
//  PNSAPIRespondProtocol.h
//  PNSServiceKit
//
//  Created by ByteDance on 2022/11/22.
//

#import "PNSServiceCenter.h"

@protocol PNSAPIRespondProtocol <NSObject>

- (BOOL)respondToEntryToken:(NSString *_Nullable)entryToken context:(NSDictionary *_Nullable)context;

@end
