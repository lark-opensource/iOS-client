//
//  BDASplashVideoView.h
//  TTAdSplashSDK
//
//  Created by boolchow on 2020/4/27.
//

#import <UIKit/UIKit.h>
#import "BDASplashVideoContainer.h"

typedef NS_ENUM(NSUInteger, BDASRErrorCode) {
    BDASRErrorCodeUnknown = 0,                // 未知错误
    BDASRErrorCodeDisable = 1,                // 开关关闭
    BDASRErrorCodeLowBattery = 2,             // 低电量
    BDASRErrorCodeNotTTPlayer = 3,            // 非自研播放器
    BDASRErrorCodeLowSystem = 4,              // 系统版本过低
    BDASRErrorCodeSuccess = 100,              // 超分成功
};

NS_ASSUME_NONNULL_BEGIN
/** 使用公司自研播放器初始化的一个 view，公司自研播放器可以播放加密视频，以及一些额外功能 */
@interface BDASplashVideoView : UIView <BDASplashVideoProtocol>

- (instancetype)initWithModel:(TTAdSplashModel *)model;

@property (nonatomic, weak) id<BDASplashVideoViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
