//
//  ACCBaseInformationStickerDataManager.h
//  AWEStudio
//
//  Created by guochenxiang on 2018/9/20.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/ACCUserServiceProtocol.h>
#import "ACCStickerPannelLogger.h"

NS_ASSUME_NONNULL_BEGIN

@class IESCategoryModel;
@class IESEffectModel;

@interface ACCBaseInformationStickerDataManager : NSObject<ACCUserServiceMessage>

@property (nonatomic, copy) NSString *pannelName;

// 信息化贴纸（贴图）面板 infostickerv2
@property (nonatomic, copy, readonly) NSArray<IESCategoryModel *> *stickerCategories;
@property (nonatomic, copy, readonly) NSArray<IESEffectModel *> *stickerEffects;
@property (nonatomic, copy) NSDictionary *trackExtraDic;
@property (nonatomic, copy) NSString *requestID;
           
@property (nonatomic, weak) id<ACCStickerPannelLogger> logger;

- (void)downloadStickersWithCompletion:(void(^)(BOOL downloadSuccess))completion;

@end

NS_ASSUME_NONNULL_END
