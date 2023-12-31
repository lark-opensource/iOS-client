//
//  BDASplashShakeModel.h
//  TTAdSplashSDK
//
//  Created by boolchow on 2021/1/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** 摇一摇广告类型 */
typedef NS_ENUM(NSInteger, BDASplashShakeType) {
    BDASplashShakeTypeNormal = 1,      ///< 普通版
    BDASplashShakeTypeAdvanced = 2     ///< 旗舰版
};

/// 摇一摇创意数据 model
@interface BDASplashShakeModel : NSObject
@property (nonatomic, assign, readonly) BDASplashShakeType type;      ///< 摇一摇创意类型
@property (nonatomic, copy, readonly) NSString *tipsText;             ///< 摇一摇提示文案
@property (nonatomic, copy, readonly) NSString *buttonText;           ///< 旗舰版底部按钮文案
@property (nonatomic, copy, readonly) NSString *buttonColor;          ///< 旗舰版底部按钮颜色
@property (nonatomic, copy, readonly) NSNumber *openWebTime;          ///< 普通版摇一摇，自动打开落地页时间
@property (nonatomic, copy, readonly) NSDictionary *videoInfo;        ///< 旗舰版第二段视频信息
@property (nonatomic, copy, readonly) NSDictionary *imageInfo;        ///< 普通版第二段动图信息
@property (nonatomic, copy, readonly) NSDictionary *shakeImageInfo;   ///< 摇一摇手势动图
@property (nonatomic, copy, readonly) NSDictionary *borderLightInfo;  ///< 旗舰版摇一摇进度第二段时过度图

- (instancetype)initWithDictionary:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
