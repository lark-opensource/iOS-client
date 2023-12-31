//
//  CJPayBridgeBioModel.h
//  CJPay
//
//  Created by liyu on 2020/2/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CJPayBioShowStyle) {
    CJPayBioShowStyleToast = 0, //默认为0
    CJPayBioShowStyleAlert = 1,
    CJPayBioShowStyleGoSettings = 2, //可跳转到设置页面的弹窗
};

@interface CJPayBioCheckSateModel : NSObject

@property (nonatomic, assign) BOOL isShow;
@property (nonatomic, assign) BOOL isOPen;
@property (nonatomic, copy) NSString *msg;
@property (nonatomic, copy) NSString *bioType;
@property (nonatomic, assign) CJPayBioShowStyle style; // 展示方式，0表示toast，1表示alert，2表示可跳转到设置的弹窗。默认为0

- (NSDictionary *)toJson;

@end

@interface CJPayBioSwitchStateModel : NSObject

@property (nonatomic, copy) NSString *code;
@property (nonatomic, assign) BOOL isOpen;
@property (nonatomic, copy) NSString *msg;
@property (nonatomic, assign) CJPayBioShowStyle style; // 展示方式，0表示toast，1表示alert，2表示可跳转到设置的弹窗。默认为0

- (NSDictionary *)toJson;

@end


NS_ASSUME_NONNULL_END
