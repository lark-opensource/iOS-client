//
//  CJPaySafeFeatures.h
//  CJPaySandBox
//
//  Created by wangxinhua on 2023/5/20.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSUInteger, CJPaySafeFeatureType) {
    CJPaySafeFeatureTypeDevice,
    CJPaySafeFeatureTypeIntention,
    CJPaySafeFeatureTypeUser,
    CJPaySafeFeatureTypeApp,
};

@interface CJPayBaseSafeFeature : JSONModel

@property (nonatomic, copy) NSString *name; // 具体特征名称
@property (nonatomic, copy) NSString *value; // 具体特征value值
@property (nonatomic, copy) NSArray *valueList; // 具体特征value值
@property (nonatomic, assign) CJPaySafeFeatureType type; // 具体特征类型
@property (nonatomic, assign) BOOL needPersistence; // 是否需要持久化

@end

/// 设备特征
@interface CJPayDeviceFeature : CJPayBaseSafeFeature

@end


/// 意图特征
@interface CJPayIntentionFeature : CJPayBaseSafeFeature

@property (nonatomic, copy) NSString *page; // 发生事件的具体页面
@property (nonatomic, assign) NSTimeInterval timeStamp; // 发生事件的时间戳

@end

NS_ASSUME_NONNULL_END
