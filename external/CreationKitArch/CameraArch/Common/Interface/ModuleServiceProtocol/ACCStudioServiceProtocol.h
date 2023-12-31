//
//  ACCStudioServiceProtocol.h
//  Pods
//
//  Created by chengfei xiao on 2019/9/4.
//

#import <Foundation/Foundation.h>
#import <CreationKitInfra/ACCCommonDefine.h>
#import "ACCRecodInputDataProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCStudioServiceProtocol <NSObject>

- (void)preloadInitializationEffectPlatformManager;

- (BOOL)shouldUploadUseOriginPublishModel:(id<ACCRecodInputDataProtocol>)inputData;

#pragma mark - class name of page
- (Class)classOfPageType:(AWEStuioPageType)pageType;


@end

NS_ASSUME_NONNULL_END
