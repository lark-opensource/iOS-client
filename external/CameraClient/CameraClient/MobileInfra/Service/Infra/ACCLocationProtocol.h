//
//  ACCLocationProtocol.h
//  Pods
//
//  Created by chengfei xiao on 2019/7/30.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <CreativeKit/ACCServiceLocator.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ACCLocationPermission) {
    ACCLocationPermissionAllowed,
    ACCLocationPermissionDenied,
    ACCLocationPermissionAlreadyDenied,
};

typedef NS_ENUM(NSUInteger, ACCLocationEncodeType) {
    ACCLocationEncodeTypeDefault = 0,
    ACCLocationEncodeTypeStandard = 1,
};

typedef NS_ENUM(NSUInteger, ACCLocationAccessStatus) {
    ACCLocationAccessUndefine = 0,
    ACCLocationAccessAllowed,
    ACCLocationAccessDenied,
    ACCLocationAccessOnlyInUsing,
    ACCLocationAccessRestricted,
    ACCLocationAuthorizationStatusDisabled
};

@protocol ACCLocationModel <NSObject>

@property (nonatomic, copy, readonly) NSString * _Nullable city;
@property (nonatomic, copy, readonly) NSString * _Nullable cityCode;
@property (nonatomic, strong, readonly) CLLocation * _Nullable location;
@property (nonatomic, copy, readonly) NSString * _Nullable country;
@property (nonatomic, copy, readonly) NSString * _Nullable countryCode;
@property (nonatomic, copy, readonly) NSString * _Nullable province;
@property (nonatomic, copy, readonly) NSString * _Nullable provinceCode;
@property (nonatomic, copy, readonly) NSString * _Nullable district;
@property (nonatomic, copy, readonly) NSString * _Nullable districtCode;
@property (nonatomic, copy, readonly) NSString * _Nullable address;

@end

typedef void(^ _Nullable ACCLocationRequestBlock)(id<ACCLocationModel> _Nullable locationModel, ACCLocationPermission permission, NSError * _Nullable error);

@protocol ACCLocationProtocol <NSObject>

/// 是否有访问权限
- (BOOL)hasPermission;

/// 当前访问权限
- (ACCLocationAccessStatus)locationAccessStatus;

/// 当前区域
- (NSString *)currentRegion;

// 当前选择的城市，同城位置
- (NSString *)currentSelectedCityCode;

/// 请求位置权限
/// @param certName 证书名称
/// @param block 回调
- (void)requestPermissionWithCertName:(NSString *)certName
                           completion:(nullable void(^)(ACCLocationPermission permission, NSError * _Nullable error))block;

/// 获取当前缓存的位置
/// @param certName 证书名称
/// @param type 编码类型
- (id<ACCLocationModel> _Nullable)getCurrentLocationWithCertName:(NSString *)certName
                                                      encodeType:(ACCLocationEncodeType)type;

/// 请求当前位置
/// @param certName 证书名称
/// @param completion 请求回调
- (void)requestCurrentLocationWithCertName:(NSString *)certName
                                completion:(nullable ACCLocationRequestBlock)completion;

/// 获取位置逆地址
/// @param location 输入位置
/// @param certName 证书名称
/// @param completion 完成回调
- (void)reverseGeoCode:(CLLocation * _Nullable)location
              certName:(NSString *)certName
            completion:(void(^ _Nullable)(id<ACCLocationModel> _Nullable locationModel, NSError * _Nullable error))completion;

/// 地址坐标准换
/// @param location 输入位置
/// @param encodeType 转换目标格式
- (CLLocation *)transformLocationWithCLLocation:(CLLocation *)location
                                     encodeType:(ACCLocationEncodeType)encodeType;

@end

FOUNDATION_STATIC_INLINE id<ACCLocationProtocol> ACCLocation() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCLocationProtocol)];
}

NS_ASSUME_NONNULL_END
