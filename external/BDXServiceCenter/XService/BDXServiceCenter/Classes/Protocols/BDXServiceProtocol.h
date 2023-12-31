//
//  BDXServiceProtocol.h
//  BDXServiceCenter-Pods-Aweme
//
//  Created by bill on 2021/3/3.
//

//#ifndef BDXServiceProtocol_h
//#define BDXServiceProtocol_h

#import <Foundation/Foundation.h>
#import "BDXServiceDefines.h"

@protocol BDXServiceProtocol <NSObject>

/// Service Scope type
+ (BDXServiceScope)serviceScope;

/// The type of current service
+ (BDXServiceType)serviceType;

/// The biz tag of current service.
+ (NSString *)serviceBizID;

@end

//#endif /* BDXServiceProtocol_h */
