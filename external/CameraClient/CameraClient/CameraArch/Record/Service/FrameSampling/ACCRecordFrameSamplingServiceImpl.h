//
//  ACCRecordFrameSamplingServiceImpl.h
//  CameraClient
//
//  Created by limeng on 2020/5/11.
//

#import <Foundation/Foundation.h>
#import "ACCRecordFrameSamplingServiceProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCRecordFrameSamplingServiceImpl : NSObject <ACCRecordFrameSamplingServiceProtocol>

/// 绿幕道具背景照片（单图）
@property (nonatomic, strong, nullable) UIImage *bgPhoto;

/// 绿幕道具背景照片（多图）
@property (nonatomic, copy, nullable) NSArray<UIImage *> *bgPhotos;

- (instancetype)initWithPublishModel:(AWEVideoPublishViewModel *)publishModel;

@end

NS_ASSUME_NONNULL_END
