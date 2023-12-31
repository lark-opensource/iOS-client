//
//  ACCPublishShareModel.h
//  CameraClient
//
//  Created by chengfei xiao on 2019/12/30.
//

#import <Foundation/Foundation.h>
#import "AWEStudioSpringDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCPublishShareModel : NSObject<NSCopying>

@property (nonatomic, copy) AWEPublishShareCompletionBlock shareCompletion;

@end

NS_ASSUME_NONNULL_END
