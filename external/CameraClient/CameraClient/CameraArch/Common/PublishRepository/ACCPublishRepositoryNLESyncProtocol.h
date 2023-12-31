//
//  ACCPublishRepositoryNLESyncProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by fangxiaomin on 2021/2/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kNLEExtraKey;

@class NLEModel_OC;

@protocol ACCPublishRepositoryNLESyncProtocol <NSObject>

- (void)updateToNLEModel:(NLEModel_OC *)nleModel;
- (void)restoreFromNLEModel:(NLEModel_OC *)nleModel;

@end

NS_ASSUME_NONNULL_END
