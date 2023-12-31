//
//  ACCWideAngleActionData.h
//  CameraClient
//
//  Created by ZhangYuanming on 2020/2/3.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, ACCWideAngleType) {
    ACCWideAngleTypeNormal,
    ACCWideAngleTypeWide
};

NS_ASSUME_NONNULL_BEGIN

/// 镜头切换来实现远焦切换的数据
@interface ACCWideAngleActionData : NSObject

@property (nonatomic, assign) CGFloat zoomFactor;
@property (nonatomic, assign) CGFloat rate;

@end

NS_ASSUME_NONNULL_END
