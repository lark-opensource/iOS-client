//
//  BDPLocationPluginModel.h
//  Timor
//
//  Created by MacPu on 2018/11/3.
//  Copyright © 2018 Bytedance.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "BDPBaseJSONModel.h"

static NSString *const kParamLatitude = @"latitude";
static NSString *const kParamLongitude = @"longitude";
static NSString *const kParamScale = @"scale";

static const double kLatitudeMax = 90.f;
static const double kLatitudeMin = -90.f;
static const double kLongitudeMax = 180.f;
static const double kLongitudeMin = -180.f;

/// 缩放比例最小值
static const int kScaleMin = 5;
/// 缩放比例最大值
static const int kScaleMax = 18;

NS_ASSUME_NONNULL_BEGIN

/**
 * 定位的数据模型
 */
@interface BDPLocationPluginModel : BDPBaseJSONModel
/// 纬度
@property (nonatomic, assign) CLLocationDegrees latitude;
/// 经度
@property (nonatomic, assign) CLLocationDegrees longitude;
/// 缩放比例 5 - 18
@property (nonatomic, assign) NSInteger scale;
/// 名称
@property (nonatomic, copy) NSString *name;
/// 地址
@property (nonatomic, copy) NSString *address;

@end

NS_ASSUME_NONNULL_END
