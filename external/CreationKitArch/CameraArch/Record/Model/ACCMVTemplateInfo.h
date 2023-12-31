//
//  ACCMVTemplateInfo.h
//  CameraClient-Pods-Aweme
//
// Created by Li Hui on April 16, 2020
//

#import <Foundation/Foundation.h>
#import <EffectPlatformSDK/IESEffectModel.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, AWEMVTemplateType) {
    AWEMVTemplateTypeNormal = 0, // common mv
    AWEMVTemplateTypeMusicEffect = 1, // music and dynamic effect mv
};

@interface ACCMVTemplateInfo : NSObject

@property (nonatomic, copy) NSArray<NSString *> *videoCoverURLs;
@property (nonatomic, copy) NSArray<NSString *> *photoCoverURLs;

@property (nonatomic, assign) NSInteger minMaterial;
@property (nonatomic, assign) NSInteger maxMaterial;
@property (nonatomic, assign) NSInteger photoInputWidth;
@property (nonatomic, assign) NSInteger photoInputHeight;
@property (nonatomic, copy) NSString *photoFillMode;
@property (nonatomic, assign) AWEMVTemplateType templateType;

+ (ACCMVTemplateInfo *)MVTemplateInfoFromEffect:(IESEffectModel *)effect coverURLPrefixs:(nullable NSArray<NSString *> *)coverURLPrefixs;

@end

NS_ASSUME_NONNULL_END
