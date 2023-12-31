//
//  ACCMigrateContextModel.h
//  CameraClient-Pods-Aweme
//
//  Created by fangxiaomin on 2021/3/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// TODO: NLE-未适配
@class HTSVideoData;

@interface ACCMigrateContextModel : NSObject

@property (nonatomic, assign) BOOL isSameSys;

@property (nonatomic, strong, nullable) HTSVideoData *video;

@end

NS_ASSUME_NONNULL_END
