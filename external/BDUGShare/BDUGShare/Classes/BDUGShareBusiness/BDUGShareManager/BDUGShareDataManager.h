//
//  BDUGShareDataManager.h
//  AFgzipRequestSerializer
//
//  Created by 杨阳 on 2019/4/8.
//

#import <Foundation/Foundation.h>
#import "BDUGShareDataModel.h"

typedef void (^BDUGShareDataRequestFinishBlock)(NSInteger errCode, NSString *errTip, BDUGShareDataModel *dataModel);

typedef NS_ENUM(NSInteger, BDUGShareDataRequestStatus) {
    BDUGShareDataRequestStatusDefault = 0,
    BDUGShareDataRequestStatusRequesting,
    BDUGShareDataRequestStatusFinish,
};

@class BDUGShareConfiguration;

@interface BDUGShareDataManager : NSObject

@property (nonatomic, strong) BDUGShareConfiguration *config;

#pragma mark - data request & get

//默认使用memoryCache，只有外露类型的，不使用。因为各平台都是单独请求的。
- (void)requestShareInfoWithPanelID:(NSString *)panelID
                            groupID:(NSString *)groupID
                          extroData:(NSDictionary *)extroData
                         completion:(BDUGShareDataRequestFinishBlock)completion;

- (void)requestShareInfoWithPanelID:(NSString *)panelID
                            groupID:(NSString *)groupID
                          extroData:(NSDictionary *)extroData
                     useMemeryCache:(BOOL)useCache
                         completion:(BDUGShareDataRequestFinishBlock)completion;

- (BDUGShareDataItemModel *)itemModelWithPlatform:(NSString *)platform
                                          panelId:(NSString *)panelID
                                       resourceID:(NSString *)resourceID;

- (BDUGShareDataRequestStatus)requestStatusWithPanelId:(NSString *)panelId resourceId:(NSString *)resourceId;

- (void)cleanCache;

@end
