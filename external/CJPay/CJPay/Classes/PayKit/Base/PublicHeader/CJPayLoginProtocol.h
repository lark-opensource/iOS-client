//
//  CJPayLoginProtocol.h
//  Pods
//
//  Created by 尚怀军 on 2020/11/13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CJPayLoginBackCode) {
    CJPayLoginBackCodeSuccess,       // 登录成功
    CJPayLoginBackCodeFailure,       // 登录失败
    CJPayLoginBackCodeCloseDesk,     // 关闭收银台
};


@protocol CJPayLoginProtocol <NSObject>

/**
 宿主实现该协议提供登录能力
 
 @param callback 宿主通过callback回调登录结果

 */
- (void)needLogin:(void(^)(CJPayLoginBackCode))callback;

@end

NS_ASSUME_NONNULL_END
