//
//  OPNoticeManager.h
//  TTMicroApp
//
//  Created by ChenMengqi on 2021/8/9.
//

#import <Foundation/Foundation.h>
#import <OPFoundation/BDPUniqueID.h>
#import "OPNoticeModel.h"

@protocol ECONetworkServiceContext;

NS_ASSUME_NONNULL_BEGIN

@interface OPNoticeManager : NSObject

+ (instancetype)sharedManager;

///是否需要展示notice view
-(BOOL)shouldShowNoticeViewForModel:(OPNoticeModel* )model;

///发送请求
-(void)requsetNoticeModelForAppID:(NSString *)appID context:(id<ECONetworkServiceContext>)context callback:(void(^)(OPNoticeModel * _Nullable))callback;


///记录显示弹窗
-(void)recordShowNoticeViewForModel:(OPNoticeModel* )model appID:(NSString *)appID;

///记录关闭弹窗
-(void)recordCloseNoticeViewForModel:(OPNoticeModel* _Nullable)model appID:(NSString * _Nullable)appID;;


@end

NS_ASSUME_NONNULL_END
