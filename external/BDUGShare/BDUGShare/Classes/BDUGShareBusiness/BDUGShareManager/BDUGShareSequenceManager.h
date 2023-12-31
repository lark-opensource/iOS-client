//
//  BDUGShareSequenceManager.h
//  AFgzipRequestSerializer
//
//  Created by 杨阳 on 2019/3/22.
//

#import <Foundation/Foundation.h>
#import "BDUGActivityProtocol.h"
#import "BDUGShareConfiguration.h"

typedef void(^BDUGInitializeRequestHandler)(BOOL succeed);

NS_ASSUME_NONNULL_BEGIN

@interface BDUGShareInitializeModel : NSObject

/// 渠道列表，字符串
@property (nonatomic, strong, nullable) NSArray *channelList;

/// 过滤渠道列表，即该列表中的渠道，在展示在面板上之前需要检测是否安装，如果未安装则不展示在面板上。
@property (nonatomic, strong, nullable) NSArray *filteredChannelList;

/// 面板ID
@property (nonatomic, copy, nullable) NSString *panelID;

@end

@interface BDUGShareSequenceManager : NSObject

@property (nonatomic, strong, nullable) BDUGShareConfiguration *configuration;

+ (instancetype)sharedInstance;

- (void)requestShareSequence;

- (void)requestShareSequenceWithCompletion:(BDUGInitializeRequestHandler _Nullable)completion;

- (NSArray * _Nullable)resortActivityItems:(NSArray *)activityItems
                         panelId:(NSString *)panelId;

+ (NSArray * _Nullable)validContentItemsWithPanelId:(NSString *)panelId;

+ (NSArray * _Nullable)hiddenContentItemsWhenNotInstalledWithPanelId:(NSString *)panelId;

#pragma mark - tricky

- (void)configInitlizeDataWithItemModel:(BDUGShareInitializeModel *)model;

#pragma mark - clean

- (void)cleanCache;

@end

NS_ASSUME_NONNULL_END
