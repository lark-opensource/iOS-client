//
//  BDPSocketConnectionTip.h
//  Timor
//
//  Created by tujinqiu on 2020/4/8.
//

// 真机调试socket连接的提示

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, BDPSocketDebugTipStatus) {
    BDPSocketDebugTipStatusConnecting = 0,   // 连接中
    BDPSocketDebugTipStatusConnected, // 已连接
    BDPSocketDebugTipStatusConnectFailed, // 连接失败
    BDPSocketDebugTipStatusHitDebugPoint, // 断点命中
};

typedef NS_ENUM(NSUInteger, BDPSocketDebugType) {
    BDPSocketDebugTypeRealDevice = 0,   // 真机调试
    BDPSocketDebugTypePerformanceProfile // 性能调试
};


@protocol BDPSocketConnectionTipDelegate<NSObject>
- (void)finishDebugButtonPressedWithType:(BDPSocketDebugType)type;
- (void)realDeviceDebugMaskVisibleChangedTo:(BOOL) visible;
@end


@interface BDPSocketConnectionTip : UIView
@property (nonatomic, weak, nullable) id<BDPSocketConnectionTipDelegate> delegate;

- (void)setSocketDebugType:(BDPSocketDebugType)type;
- (void)setStatus:(BDPSocketDebugTipStatus)status;

@end

NS_ASSUME_NONNULL_END
