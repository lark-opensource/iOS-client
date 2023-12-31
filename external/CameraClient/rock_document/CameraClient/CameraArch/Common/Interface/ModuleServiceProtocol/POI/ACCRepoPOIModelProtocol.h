//
//  ACCRepoPOIModelProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by ruiyuan on 2020/12/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCRepoPOIModelProtocol <NSObject>

- (NSString *)acc_poiID;

- (NSDictionary *)acc_vagueStatusParam;

@end

NS_ASSUME_NONNULL_END
