//
//  BDTuringService.h
//  BDTuring
//
//  Created by bob on 2019/9/18.
//

#import <Foundation/Foundation.h>
#import "BDTuringDefine.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BDTuringService <NSObject>

@property (nonatomic, copy, readonly) NSString *appID;
@property (nonatomic, copy, readonly) NSString *serviceName;

@end

@protocol BDTuringVerifyService <BDTuringService, BDTuringVerifyHandler>

@end

@interface BDTuringService : NSObject<BDTuringService>

@property (nonatomic, copy, readonly) NSString *appID;
@property (nonatomic, copy, readonly) NSString *serviceName;

- (instancetype)initWithAppID:(NSString *)appID;
- (void)registerService;
- (void)unregisterService;
- (BOOL)serviceAvailable;

@end



NS_ASSUME_NONNULL_END
