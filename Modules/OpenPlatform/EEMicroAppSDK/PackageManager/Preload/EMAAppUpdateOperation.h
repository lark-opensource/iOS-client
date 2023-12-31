//
//  EMAAppUpdateOperation.h
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/11/14.
//

#import <Foundation/Foundation.h>
#import <OPFoundation/BDPUniqueID.h>
@class EMAAppUpdateManagerV2;

NS_ASSUME_NONNULL_BEGIN

@interface EMAAppUpdateOperation : NSOperation

- (instancetype)initWithUniqueID:(BDPUniqueID *)uniqueID updateManager:(EMAAppUpdateManagerV2 *)updateManager;

@end

NS_ASSUME_NONNULL_END
