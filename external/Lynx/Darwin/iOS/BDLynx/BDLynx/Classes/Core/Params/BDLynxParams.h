//
//  BDLynxParams.h
//  BDLynx-Pods-Aweme
//
//  Created by bill on 2020/5/15.
//

#import <Foundation/Foundation.h>
@class BDLynxViewBaseParams;

NS_ASSUME_NONNULL_BEGIN

@interface BDLynxParams : NSObject

+ (BDLynxViewBaseParams *)getBaseParam:(NSString *)schema;

@end

NS_ASSUME_NONNULL_END
