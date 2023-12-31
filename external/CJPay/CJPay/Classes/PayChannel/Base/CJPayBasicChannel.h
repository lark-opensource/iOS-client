//
//  CJPayBasicChannel.h
//  CJPay
//
//  Created by jiangzhongping on 2018/8/29.
//

#import <Foundation/Foundation.h>
#import "CJPaySDKDefine.h"
#import <JSONModel/JSONModel.h>

typedef void (^CJPayCompletion) (CJPayChannelType channelType, CJPayResultType resultType, NSString *errorCode);

#pragma mark - CJPayChannelProtocol
@protocol CJPayChannelProtocol<NSObject>

- (void)payActionWithDataDict:(NSDictionary *)dataDict completionBlock:(CJPayCompletion) completionBlock;
- (void)trackWithEvent:(NSString *)eventName trackParam:(NSDictionary *)trackDic;

- (BOOL)canProcessWithURL:(NSURL *)URL;
- (BOOL)canProcessUserActivity:(NSUserActivity *)activity;

@end

@protocol CJPayQRCodeChannelProtocol <NSObject>

@optional
- (void)queryQROrderResult:(void(^)(BOOL))completionBlock;//查单
- (void)trackWithName:(NSString*)name params:(NSDictionary*)dic;//埋点
- (void)pushViewController:(UIViewController *)vc;
@end

#pragma mark - CJPayBasicChannel
@interface CJPayBasicChannel : JSONModel <CJPayChannelProtocol>

@property (nonatomic, assign) CJPayChannelType channelType;
@property (nonatomic, copy) NSDictionary *dataDict;
@property (nonatomic, copy) NSDictionary *trackParam;
@property (nonatomic, copy) CJPayCompletion completionBlock;

+ (BOOL)isAvailableUse;

@end
