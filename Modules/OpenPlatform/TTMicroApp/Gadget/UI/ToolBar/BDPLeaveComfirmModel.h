//
//  BDPLeaveComfirmModel.h
//  TTMicroApp
//
//  Created by bytedance on 2022/3/21.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    BDPLeaveComfirmStateNone,
    BDPLeaveComfirmStateValid,
    BDPLeaveComfirmStateConsumed,
    BDPLeaveComfirmStateCancel,
} BDPLeaveComfirmState;

typedef enum : NSUInteger {
    BDPLeaveComfirmActionBack  = 1 << 0,
    BDPLeaveComfirmActionClose = 1 << 1,
} BDPLeaveComfirmAction;

@protocol BDPNavLeaveComfirmHandler <NSObject>



/// 弹框二次确认代理方法
/// @param action 返回类型
/// @param callback 点击取消的回调
- (BOOL)handleLeaveComfirmAction:(BDPLeaveComfirmAction)action confirmCallback:(void (^)(void))callback;

@end

@interface BDPLeaveComfirmModel : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *content;
@property (nonatomic, copy) NSString *confirmText;
@property (nonatomic, copy) NSString *cancelText;
@property (nonatomic, copy) NSString *confirmColor;
@property (nonatomic, copy) NSString *cancelColor;

@property (nonatomic, assign, readonly) BDPLeaveComfirmAction effects;

@property (nonatomic, assign) BDPLeaveComfirmState state;

- (instancetype)initWithTitle:(NSString *)title
                      content:(NSString *)content
                  confirmText:(NSString *)confirmText
                   cancelText:(NSString *)cancelText
                       effect:(NSArray *)effect
                 confirmColor:(NSString *)confirmColor
                  cancelColor:(NSString *)cancelColor;

@end

NS_ASSUME_NONNULL_END
