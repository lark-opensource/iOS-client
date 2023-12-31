//
//  BDUGShareManager.m
//  Pods
//
//  Created by 延晋 张 on 16/6/1.
//
//

#import "BDUGShareManager.h"
#import "BDUGActivitiesManager.h"
#import "BDUGShareAdapterSetting.h"
#import "BDUGShareSequenceManager.h"
#import "BDUGShareDataManager.h"
#import "BDUGShareError.h"
#import "BDUGShareAdapterSetting.h"
#import "BDUGVideoImageShare.h"
#import "BDUGShareEvent.h"
#import <Gaia/GAIAEngine.h>
#import <BDUGShare/BDUGShareMacros.h>

@interface BSUGShareWaitingActivityInfo : NSObject

@property (nonatomic, copy) BDUGShareActivityDataReadyHandler dataReadyHandler;
@property (nonatomic, strong) id <BDUGActivityProtocol> activity;

@end

@implementation BSUGShareWaitingActivityInfo

+ (instancetype)activityInfoWithActivity:(id <BDUGActivityProtocol>)activity
                        dataReadyHandler:(BDUGShareActivityDataReadyHandler)dataReadyHandler {
    BSUGShareWaitingActivityInfo *info = [[BSUGShareWaitingActivityInfo alloc] init];
    info.activity = activity;
    info.dataReadyHandler = dataReadyHandler;
    return info;
}
@end

@interface BDUGShareManager() <BDUGActivityPanelDelegate, BDUGActivityDataSource>

@property (nonatomic, strong) id<BDUGActivityPanelControllerProtocol> panelController;
@property (nonatomic, copy) NSString *panelClassName;
@property (nonatomic, strong) BDUGShareDataManager *dataManager;

@property (nonatomic, strong) BSUGShareWaitingActivityInfo *currentActivityInfo;

//外露平台manager持有一下activity，避免还没收到回调就被提前释放。
@property (nonatomic, strong) id <BDUGActivityProtocol> retainActivity;

//todo看下这里的引用，看下是否可以扔在全局里。
@property (nonatomic, strong) BDUGSharePanelContent *currentPanelContent;

//about tracker
@property (nonatomic, copy) NSString *currentPanelType;

@end

@implementation BDUGShareManager

- (void)dealloc
{
    if (self.panelController) {
        [self.panelController hide];
    }
}

+ (void)addUserDefinedActivitiesFromArray:(NSArray *)activities
{
    BDUGActivitiesManager *manager = [BDUGActivitiesManager sharedInstance];
    [manager addValidActivitiesFromArray:[activities copy]];
}

+ (void)addUserDefinedActivity:(id <BDUGActivityProtocol>)activity
{
    BDUGActivitiesManager *manager = [BDUGActivitiesManager sharedInstance];
    [manager addValidActivity:activity];
}

#pragma mark - init

+ (void)initializeShareSDK
{
    BDUGShareConfiguration *defaultConfiguration = [BDUGShareConfiguration defaultConfiguration];
    [self initializeShareSDKWithConfiguration:defaultConfiguration];
}

+ (void)initializeShareSDKWithConfiguration:(BDUGShareConfiguration *)configuration
{
    [BDUGShareSequenceManager sharedInstance].configuration = configuration;
    [[BDUGShareSequenceManager sharedInstance] requestShareSequence];
    [GAIAEngine startTasksForKey:@BDUGShareInitializeGaiaKey];
}

- (void)setPanelClassName:(NSString *)panelClassName {
    _panelClassName = panelClassName;
}

- (void)hideSharePanel
{
    [self.panelController hide];
}

#pragma mark - dispaly content

- (void)_displayPanelWithActivities:(NSArray *)activities panelContent:(BDUGSharePanelContent *)panelContent
{
    if (activities.count == 0) {
        NSString *desc = @"该面板中没有可用分享平台";
        NSError *error = [BDUGShareError errorWithDomain:@"ShareNoActivity" code:BDUGShareErrorTypeNoValidItemInPanel userInfo:@{NSLocalizedDescriptionKey : desc}];
        [[BDUGShareAdapterSetting sharedService] activityHasSharedWith:nil error:error desc:desc];
        [BDUGShareEventManager trackService:kShareMonitorDisplayPanel attributes:@{@"status" : @(1)}];
        return;
    }
    if (![[activities firstObject] isKindOfClass:[NSArray class]]) {
        activities = @[activities];
    }
    
    //设置activities.datasource = self
    [self configActivitiesDatasource:activities];
    
    //开始请求分享数据。
    [self beginRequestShareDataWithActivities:activities panelContent:panelContent];
    
    Class panelClass = NSClassFromString(panelContent.panelClassString);
    if (Nil == panelClass) {
        panelClass = NSClassFromString([[BDUGShareAdapterSetting sharedService] getPanelClassName]);
    }
    NSNumber *status;
    if (panelClass && [panelClass conformsToProtocol:@protocol(BDUGActivityPanelControllerProtocol)]) {
        id<BDUGActivityPanelControllerProtocol> panelC = [panelClass alloc];
        if (panelContent.cancelBtnText.length == 0) {
            panelContent.cancelBtnText = @"取消";
        }
        if ([panelC respondsToSelector:@selector(initWithItems:panelContent:)]) {
            panelC = [panelC initWithItems:[activities copy] panelContent:panelContent];
        } else if ([panelC respondsToSelector:@selector(initWithItems:cancelTitle:)]) {
            panelC = [panelC initWithItems:[activities copy] cancelTitle:panelContent.cancelBtnText];
        }
        
        self.panelController = panelC;
        panelC.delegate = self;
        [panelC show];
        status = @(0);
        [BDUGShareEventManager event:kShareTrackerDisplayPanel
                              params:@{@"panel_type" : (self.currentPanelType ?: @""),
                                       @"panel_id" : (panelContent.panelID ?: @""),
                                       @"resoutce_id" : (panelContent.resourceID ?: @""),
                    }];
    } else {
        NSAssert(0, @"无可用的ui组件");
        status = @(1);
    }
    [BDUGShareEventManager trackService:kShareMonitorDisplayPanel attributes:@{@"status" : status}];
}

- (void)configActivitiesDatasource:(NSArray *)activities {
    __weak typeof(self) weakSelf = self;
    [activities enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[NSArray class]]) {
            [self configActivitiesDatasource:obj];
        }
        if ([obj conformsToProtocol:@protocol(BDUGActivityProtocol)]) {
            id <BDUGActivityProtocol> activity = obj;
            if ([activity respondsToSelector:@selector(setDataSource:)]) {
                [activity setDataSource:self];
            }
            if ([obj respondsToSelector:@selector(setTokenDialogDidShowBlock:)]) {
                __weak typeof(activity) weakActivity = activity;
                activity.tokenDialogDidShowBlock = ^{
                    if ([weakSelf.delegate respondsToSelector:@selector(shareManager:tokenShareDialogDidShowWith:)]) {
                        [weakSelf.delegate shareManager:weakSelf tokenShareDialogDidShowWith:weakActivity];
                    }
                };
            }
        }
    }];
}

#pragma mark - 2.0 display

- (void)displayPanelWithContent:(BDUGSharePanelContent *)panelContent
{
    [self preConfigManagerData:panelContent exposePanel:NO];
    NSArray *originActivities = [self originActicitiesWithPanelContent:panelContent];
    if (originActivities.count == 0) {
        [[BDUGShareSequenceManager sharedInstance] requestShareSequenceWithCompletion:^(BOOL succeed) {
            NSArray *requestActivities = [self originActicitiesWithPanelContent:panelContent];
            [self displayPanelWithOriginActivites:requestActivities panelContent:panelContent];
        }];
    } else {
        [self displayPanelWithOriginActivites:originActivities panelContent:panelContent];
    }
}

- (void)displayPanelWithOriginActivites:(NSArray *)originActivities
                           panelContent:(BDUGSharePanelContent *)panelContent
{
    [self _displayPanelWithActivities:originActivities panelContent:panelContent];
}

- (NSArray *)originActicitiesWithPanelContent:(BDUGSharePanelContent *)content
{
    NSArray *valideContentItems = [BDUGShareSequenceManager validContentItemsWithPanelId:content.panelID];
    NSArray *hiddenContentItems = [BDUGShareSequenceManager hiddenContentItemsWhenNotInstalledWithPanelId:content.panelID];
    NSMutableArray *processedContentItems = [[NSMutableArray alloc] init];
    for (NSString *contentItemString in valideContentItems) {
        if (!NSClassFromString(contentItemString)) {
            continue;
        }
        id contentItem = [[NSClassFromString(contentItemString) alloc] init];
        if ([contentItem isKindOfClass:[BDUGShareBaseContentItem class]]) {
            BDUGShareBaseContentItem *baseItem = (BDUGShareBaseContentItem *)contentItem;
            [baseItem convertFromAnotherContentItem:content.shareContentItem];
            [self convertDataToContentItem:baseItem fromPanelContent:content];
            [processedContentItems addObject:baseItem];
        } else {
            NSAssert(0, @"该类不是base content item %@", contentItem);
        }
    }
    
    if ([self.dataSource respondsToSelector:@selector(resetPanelItems:panelContent:)]) {
        //允许业务方重新排序。
        processedContentItems = [self.dataSource resetPanelItems:processedContentItems panelContent:content].mutableCopy;
    }
    
    NSArray *activities = [[BDUGActivitiesManager sharedInstance] validActivitiesForContent:processedContentItems hiddenContentArray:hiddenContentItems panelId:content.panelID];
    return activities;
}

#pragma mark - 1.0 display

//todo: 格式规范化。
- (void)displayActivitySheetWithContentItemArray:(NSArray <id<BDUGActivityContentItemProtocol>> *)contentItemArray panelId:(NSString *)panelId panelClassName:(NSString *)panelClassName
{
    //直接走SDK控制好的这些东西。
    if (!self.dataSource ||
        ![self.dataSource respondsToSelector:@selector(originModelWithPanelId:)] ||
        ![self.dataSource respondsToSelector:@selector(shareContentItemProcess:)]) {
        NSAssert(0, @"业务方没有提供初始数据，无法触发面板展示，请实现dataSource中的required方法");
        return;
    }
    NSArray *originActivities = [self originActicitiesWithPanelId:panelId];
    if (originActivities.count == 0) {
        [[BDUGShareSequenceManager sharedInstance] requestShareSequenceWithCompletion:^(BOOL succeed) {
            NSArray *requestActivities = [self originActicitiesWithPanelId:panelId];
            [self displayPanelWithOriginActivites:requestActivities customComtentItemArray:contentItemArray panelID:panelId panelClassName:panelClassName];
        }];
    } else {
        [self displayPanelWithOriginActivites:originActivities customComtentItemArray:contentItemArray panelID:panelId panelClassName:panelClassName];
    }
}

- (void)displayPanelWithOriginActivites:(NSArray *)originActivities
                 customComtentItemArray:(NSArray *)contentItemArray
                                panelID:(NSString *)panelId
                         panelClassName:(NSString *)panelClassName
{
    NSArray *customActivies = [self customActivitiesWithContentItemrray:contentItemArray panelId:panelId];
    NSMutableArray *result = [[NSMutableArray alloc] init];
    originActivities.count == 0 ?: [result addObject:originActivities];
    customActivies.count == 0 ?: [result addObject:customActivies];
    
    [self _displayPanelWithActivities:result panelId:panelId panelClassName:panelClassName];
}

- (NSArray *)originActicitiesWithPanelId:(NSString *)panelId {
    BDUGShareActivityOriginDataModel *originModel;
    if ([self.dataSource respondsToSelector:@selector(originModelWithPanelId:)]) {
        originModel = [self.dataSource originModelWithPanelId:panelId];
    }
    
    BDUGSharePanelContent *panelContent = [[BDUGSharePanelContent alloc] init];
    panelContent.panelID = originModel.panelId;
    panelContent.resourceID = originModel.resourceId;
    NSMutableDictionary *mutableExtra;
    if (originModel.extroData) {
        mutableExtra = [[NSMutableDictionary alloc] initWithDictionary:originModel.extroData];
    } else {
        mutableExtra = [[NSMutableDictionary alloc] init];
    }
    mutableExtra[@"share_url"] = originModel.shareUrl;
    panelContent.requestExtraData = mutableExtra.copy;
    self.currentPanelContent = panelContent;
    
    NSArray *valideContentItems = [BDUGShareSequenceManager validContentItemsWithPanelId:panelId];
    NSArray *hiddenContentItems = [BDUGShareSequenceManager hiddenContentItemsWhenNotInstalledWithPanelId:panelId];
    NSMutableArray *processedContentItems = [[NSMutableArray alloc] init];
    for (NSString *contentItemString in valideContentItems) {
        if (!NSClassFromString(contentItemString)) {
            continue;
        }
        id contentItem = [[NSClassFromString(contentItemString) alloc] init];
        if ([contentItem isKindOfClass:[BDUGShareBaseContentItem class]]) {
            BDUGShareBaseContentItem *baseItem = (BDUGShareBaseContentItem *)contentItem;
            baseItem.groupID = originModel.resourceId;
            baseItem.webPageUrl = originModel.shareUrl;
            if ([self.dataSource respondsToSelector:@selector(shareContentItemProcess:)]) {
                [self.dataSource shareContentItemProcess:baseItem];
            }
            [processedContentItems addObject:baseItem];
        } else {
            NSAssert(0, @"该类不是base content item %@", contentItem);
        }
    }
    NSArray *activities = [[BDUGActivitiesManager sharedInstance] validActivitiesForContent:processedContentItems hiddenContentArray:hiddenContentItems panelId:panelId];
    return activities;
}

- (NSArray *)customActivitiesWithContentItemrray:(NSArray *)contentItemArray panelId:(NSString *)panelId {
    //todo： condition check/after condition check。
    if (contentItemArray.count > 0) {
        //外部有自定义item需求。
        NSArray *customActivities = [[BDUGActivitiesManager sharedInstance] validActivitiesForContent:contentItemArray hiddenContentArray:nil panelId:panelId];
        return customActivities;
    }
    return nil;
}

- (void)_displayPanelWithActivities:(NSArray *)activities panelId:(NSString *)panelId panelClassName:(NSString *)panelClassName
{
    if (activities.count == 0) {
        NSString *desc = @"该面板中没有可用分享平台";
        NSError *error = [BDUGShareError errorWithDomain:@"ShareNoActivity" code:BDUGShareErrorTypeNoValidItemInPanel userInfo:@{NSLocalizedDescriptionKey : desc}];
        [[BDUGShareAdapterSetting sharedService] activityHasSharedWith:nil error:error desc:desc];
        return;
    }
    if (![[activities firstObject] isKindOfClass:[NSArray class]]) {
        activities = @[activities];
    }
    if ([self.dataSource respondsToSelector:@selector(resortContentItemOrderWithCurrentArray:)]) {
        //允许业务方重新排序。
        activities = [self.dataSource resortContentItemOrderWithCurrentArray:activities];
    }
    
    //设置activities.datasource = self
    [self configActivitiesDatasource:activities];
    
    //开始请求分享数据。
    [self beginRequestShareDataWithActivities:activities panelContent:self.currentPanelContent];
    
    Class panelClass = NSClassFromString(panelClassName);
    if (Nil == panelClass) {
        panelClass = NSClassFromString([[BDUGShareAdapterSetting sharedService] getPanelClassName]);
    }
    if (panelClass && [panelClass conformsToProtocol:@protocol(BDUGActivityPanelControllerProtocol)]) {
        if ([panelClass respondsToSelector:@selector(initWithItems:cancelTitle:)]) {
            id<BDUGActivityPanelControllerProtocol> panelC = [[panelClass alloc] initWithItems:[activities copy] cancelTitle:@"取消"];
            self.panelController = panelC;
            panelC.delegate = self;
            [panelC show];
        } else {
            NSAssert(0, @"请使用displayPanelWithContent:调起面板");
        }
    } else {
        NSAssert(0, @"无可用的ui组件");
    }
}

- (void)shareToActivity:(id <BDUGActivityContentItemProtocol>)contentItem presentingViewController:(UIViewController *)presentingViewController panelId:(NSString *)panelId {
    [self shareToActivity:contentItem presentingViewController:presentingViewController panelId:panelId usePreRequestData:YES];
}

//todo: 数据请求等待做完之后暴露该接口，主要是usePreRequestData。
- (void)shareToActivity:(id <BDUGActivityContentItemProtocol>)contentItem presentingViewController:(UIViewController *)presentingViewController panelId:(NSString *)panelId usePreRequestData:(BOOL)usePreRequestData {
    UIViewController *tmpVC = presentingViewController;
    while (tmpVC.presentedViewController) {
        tmpVC = tmpVC.presentedViewController;
    }
    
    BDUGShareActivityOriginDataModel *originModel;
    if ([self.dataSource respondsToSelector:@selector(originModelWithPanelId:)]) {
        originModel = [self.dataSource originModelWithPanelId:panelId];
    }
    BDUGSharePanelContent *panelContent = [[BDUGSharePanelContent alloc] init];
    panelContent.panelID = originModel.panelId;
    panelContent.resourceID = originModel.resourceId;
    NSMutableDictionary *mutableExtra = [[NSMutableDictionary alloc] initWithDictionary:originModel.extroData];
    mutableExtra[@"share_url"] = originModel.shareUrl;
    panelContent.requestExtraData = mutableExtra.copy;
    self.currentPanelContent = panelContent;

    id <BDUGActivityProtocol> activity = [[BDUGActivitiesManager sharedInstance] getActivityByItem:contentItem panelId:panelId];
    [self configActivitiesDatasource:@[activity]];
    if ([self.delegate respondsToSelector:@selector(shareManager:clickedWith:sharePanel:)]) {
        [self.delegate shareManager:self clickedWith:activity sharePanel:nil];
    }
    
    if (!usePreRequestData) {
        //没有预请求的，全部不使用缓存，每次触发都请求。
        [self beginRequestShareDataWithActivities:@[activity] panelContent:self.currentPanelContent];
    }
    self.retainActivity = activity;
    [activity shareWithContentItem:contentItem presentingViewController:tmpVC onComplete:^(id<BDUGActivityProtocol> activity, NSError *error, NSString *desc) {
        if ([self.delegate respondsToSelector:@selector(shareManager:completedWith:sharePanel:error:desc:)]) {
            [self.delegate shareManager:self completedWith:activity sharePanel:nil error:error desc:desc];
        }
    }];
}

#pragma mark - pre config data

- (void)preConfigManagerData:(BDUGSharePanelContent *)panelContent exposePanel:(BOOL)isExposePanel
{
    _currentPanelContent = panelContent;
    if (isExposePanel) {
        _currentPanelType = @"exposed";
    } else if (!NSClassFromString(panelContent.panelClassString) || [panelContent.panelClassString isEqualToString:@"BDUGActivityPanelController"]) {
        //这里是hard code，希望有更好的解法。
        _currentPanelType = @"default";
    } else {
        _currentPanelType = @"undefined";
    }
}

#pragma mark - data request

- (void)beginRequestShareDataWithPanelContent:(BDUGSharePanelContent *)panelContent
{
    NSArray *activities = [[BDUGActivitiesManager sharedInstance] validActivitiesForContent:@[panelContent.shareContentItem] hiddenContentArray:nil panelId:panelContent.panelID];
    if (![[activities firstObject] isKindOfClass:[NSArray class]]) {
        activities = @[activities];
    }
    [self configActivitiesDatasource:activities];
    [self beginRequestShareDataWithActivities:activities panelContent:panelContent];
}

- (void)beginRequestShareDataWithActivities:(NSArray *)acticities panelContent:(BDUGSharePanelContent *)panelContent
{
    BDUGShareDataRequestStatus status = [self.dataManager requestStatusWithPanelId:panelContent.panelID resourceId:panelContent.resourceID];
    if (panelContent.useRequestCache &&
        (status == BDUGShareDataRequestStatusFinish || status == BDUGShareDataRequestStatusRequesting)) {
        //已经请求结束或者正在请求。
        return;
    }

    __weak typeof(self) weakSelf = self;
    [self.dataManager requestShareInfoWithPanelID:panelContent.panelID groupID:panelContent.resourceID extroData:panelContent.requestExtraData useMemeryCache:panelContent.useRequestCache completion:^(NSInteger errCode, NSString *errTip, BDUGShareDataModel *dataModel) {
        [weakSelf shareDataDidReadyWithActivities:acticities panelContent:panelContent];
    }];
}

- (void)shareDataDidReadyWithActivities:(NSArray *)activities panelContent:(BDUGSharePanelContent *)panelContent {
    [activities enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[NSArray class]]) {
            [self shareDataDidReadyWithActivities:obj panelContent:panelContent];
        }
    }];
    
    //清空保存的info信息。
    if (self.currentActivityInfo) {
        //如果有waiting的说明正在loading，把loading干掉。
        [self hideLoading];
        if (self.currentActivityInfo.dataReadyHandler) {
            //执行waiting的handler
            BDUGShareDataItemModel *item = [self itemModelWithPlatform:NSStringFromClass(self.currentActivityInfo.activity.contentItem.class) panelId:self.currentActivityInfo.activity.panelId resourceID:panelContent.resourceID];
            [self activityServerDataDidReady:self.currentActivityInfo.activity activityHandler:self.currentActivityInfo.dataReadyHandler itemModel:item];
        }
        self.currentActivityInfo = nil;
    }
}

#pragma mark - async config

- (void)activityServerDataDidReady:(id <BDUGActivityProtocol>)activity
                   activityHandler:(BDUGShareActivityDataReadyHandler)dataReadyHandler
                         itemModel:(BDUGShareDataItemModel *)model
{
    void (^continueBlock)(void) = ^{
        !dataReadyHandler ?: dataReadyHandler(model);
    };
    if ([activity respondsToSelector:@selector(contentItem)] &&
        [activity.contentItem isKindOfClass:[BDUGShareBaseContentItem class]]) {
        BDUGShareBaseContentItem *baseContentItem = (BDUGShareBaseContentItem *)activity.contentItem;
        if ([self.dataSource respondsToSelector:@selector(resetContentItemOriginalData:)]) {
            //代理允许业务方修改 接口请求前数据
            [self.dataSource resetContentItemOriginalData:baseContentItem];
        }
        //convert服务端数据。
        [baseContentItem convertfromModel:model];
        if ([self.dataSource respondsToSelector:@selector(resetContentItemServerData:)]) {
            //代理允许业务方修改接口请求结束之后的数据。
            [self.dataSource resetContentItemServerData:baseContentItem];
        }
        //分享渠道点击，由于需要埋method，所以放在didReady这里。
        [BDUGShareEventManager event:kShareChannelClick
                    params:@{@"channel_type" : (baseContentItem.channelString ?: @""),
                             @"share_type" : (model.method ?: @""),
                             @"panel_type" : (self.currentPanelType ?: @""),
                             @"panel_id" : (self.currentPanelContent.panelID ?: @""),
                             @"resoutce_id" : (self.currentPanelContent.resourceID ?: @""),
                    }];
    }
    
    if ([self.delegate respondsToSelector:@selector(shareManager:willShareActivity:serverDataitem:continueBlock:)]) {
        [self.delegate shareManager:self willShareActivity:activity serverDataitem:model continueBlock:continueBlock];
    } else {
        continueBlock();
    }
}

#pragma mark - outside platform pattern

- (void)shareToContent:(BDUGSharePanelContent *)panelContent presentingViewController:(UIViewController *)presentingViewController
{
    [self preConfigManagerData:panelContent exposePanel:YES];
    
    [self convertDataToContentItem:panelContent.shareContentItem fromPanelContent:panelContent];
    
    UIViewController *tmpVC = presentingViewController;
    while (tmpVC.presentedViewController) {
        tmpVC = tmpVC.presentedViewController;
    }
    id <BDUGActivityProtocol> activity = [[BDUGActivitiesManager sharedInstance] getActivityByItem:panelContent.shareContentItem panelId:panelContent.panelID];
    if (!activity) {
        NSAssert(0, @"需要指定渠道contentItem（例：BDUGWechatContentItem），不能指定BDUGShareBaseContentItem");
    }
    [self configActivitiesDatasource:@[activity]];
    if ([self.delegate respondsToSelector:@selector(shareManager:clickedWith:sharePanel:)]) {
        [self.delegate shareManager:self clickedWith:activity sharePanel:nil];
    }
    
    if (!panelContent.useRequestCache) {
        //没有预请求的，全部不使用缓存，每次触发都请求。
        [self beginRequestShareDataWithActivities:@[activity] panelContent:panelContent];
    }
    self.retainActivity = activity;
    [activity shareWithContentItem:panelContent.shareContentItem presentingViewController:tmpVC onComplete:^(id<BDUGActivityProtocol> activity, NSError *error, NSString *desc) {
        if ([self.delegate respondsToSelector:@selector(shareManager:completedWith:sharePanel:error:desc:)]) {
            [self.delegate shareManager:self completedWith:activity sharePanel:nil error:error desc:desc];
        }
    }];
}

- (void)convertDataToContentItem:(BDUGShareBaseContentItem *)contentItem fromPanelContent:(BDUGSharePanelContent *)panelContent {
    contentItem.groupID = panelContent.resourceID;
    contentItem.panelType = self.currentPanelType;
}

#pragma mark - item model

- (BDUGShareDataItemModel *)itemModelWithPlatform:(NSString *)platform
                                          panelId:(NSString *)panelId
                                       resourceID:(NSString *)resourceID {
    return [self.dataManager itemModelWithPlatform:platform panelId:panelId resourceID:resourceID];
}

#pragma mark - BDUGActivityDataSource

- (void)acticity:(id<BDUGActivityProtocol>)acticity waitUntilDataIsReady:(BDUGShareActivityDataReadyHandler)dataIsReadyHandler {
    if (!dataIsReadyHandler) {
        NSAssert(0, @"需要实现回调");
//        nothing makes sense.
        return;
    }
    
    //只有实现了platform方法才能获取到平台信息。
    if ([acticity respondsToSelector:@selector(activityType)]) {
        NSString *groupID = self.currentPanelContent.resourceID;
        BDUGShareDataRequestStatus status = [self.dataManager requestStatusWithPanelId:acticity.panelId resourceId:groupID];
        BDUGShareBaseContentItem *contemtItem = (BDUGShareBaseContentItem *)acticity.contentItem;
        BDUGSharePlatformClickMode clickMode = [contemtItem clickMode];
        
        if (clickMode == BDUGSharePlatformClickModeUseDefaultStrategy) {
            //如果要使用默认strategy，则直接返回空的item。
            [self activityServerDataDidReady:acticity activityHandler:dataIsReadyHandler itemModel:nil];
            self.currentActivityInfo = nil;
            return;
        } else if (clickMode == BDUGSharePlatformClickModeSmooth) {
            //如果是smooth策略，则直接取itemModel，取不到拉倒。
            BDUGShareDataItemModel *item = [self itemModelWithPlatform:NSStringFromClass(acticity.contentItem.class) panelId:acticity.panelId resourceID:groupID];
            [self activityServerDataDidReady:acticity activityHandler:dataIsReadyHandler itemModel:item];
            self.currentActivityInfo = nil;
            return;
        }
        
        switch (status) {
            case BDUGShareDataRequestStatusFinish: {
                    //已经请求结束，直接返回。
                    BDUGShareDataItemModel *item = [self itemModelWithPlatform:NSStringFromClass(acticity.contentItem.class) panelId:acticity.panelId resourceID:groupID];
                    [self activityServerDataDidReady:acticity activityHandler:dataIsReadyHandler itemModel:item];
                    self.currentActivityInfo = nil;
                }
                break;
                case BDUGShareDataRequestStatusRequesting: {
                    //正在请求中。
                    if ([acticity.contentItem conformsToProtocol:@protocol(BDUGActivityContentItemShareProtocol)]) {
                        //策略：等待server请求结束使用server数据分享
                        //保存block，等待数据请求结束。
                        self.currentActivityInfo = [BSUGShareWaitingActivityInfo activityInfoWithActivity:acticity dataReadyHandler:dataIsReadyHandler];
                        
                        //弹出loading弹窗。
                        [self showLoading];
                    }
                }
                break;
            case BDUGShareDataRequestStatusDefault:
                {
                    //没有触发请求或上一次请求失败。
                    //其实应该重新触发一次请求。
                    self.currentActivityInfo = [BSUGShareWaitingActivityInfo activityInfoWithActivity:acticity dataReadyHandler:dataIsReadyHandler];
                    [self showLoading];
                    [self beginRequestShareDataWithActivities:@[acticity] panelContent:self.currentPanelContent];
                }
            default:
                break;
        }
        
    } else {
//        清空block
        dataIsReadyHandler(nil);
        self.currentActivityInfo = nil;
    }
    
}

#pragma mark - loading

- (void)showLoading
{
    if ([self.abilityDelegate respondsToSelector:@selector(shareAbilityShowLoading)]) {
        [self.abilityDelegate shareAbilityShowLoading];
    } else {
        [[BDUGShareAdapterSetting sharedService] shareAbilityShowLoading];
    }
}

- (void)hideLoading
{
    if ([self.abilityDelegate respondsToSelector:@selector(shareAbilityHideLoading)]) {
        [self.abilityDelegate shareAbilityHideLoading];
    } else {
        [[BDUGShareAdapterSetting sharedService] shareAbilityHideLoading];
    }
}

#pragma mark - BDUGActivityPanelDelegate

- (void)activityPanel:(id<BDUGActivityPanelControllerProtocol>)panel
          clickedWith:(id<BDUGActivityProtocol>)activity
{
    if ([self.delegate respondsToSelector:@selector(shareManager:clickedWith:sharePanel:)]) {
        [self.delegate shareManager:self clickedWith:activity sharePanel:panel];
    }
    if (activity) {
        //分享点击：0
        [BDUGShareEventManager trackService:kShareMonitorItemClick
                       attributes:@{
                           @"status" : @(0),
                       }];
    }
}

- (void)activityPanel:(id<BDUGActivityPanelControllerProtocol>)panel
        completedWith:(id<BDUGActivityProtocol>)activity
                error:(NSError *)error
                 desc:(NSString *)desc
{
    if ([self.delegate respondsToSelector:@selector(shareManager:completedWith:sharePanel:error:desc:)]) {
        [self.delegate shareManager:self completedWith:activity sharePanel:panel error:error desc:desc];
    }
    
    if (!error) {
        //分享成功：1
        [BDUGShareEventManager trackService:kShareMonitorItemClick
                       attributes:@{
                           @"status" : @(1),
                       }];
        if ([activity respondsToSelector:@selector(contentItem)] &&
        [activity.contentItem isKindOfClass:[BDUGShareBaseContentItem class]]) {
            BDUGShareBaseContentItem *baseContentItem = (BDUGShareBaseContentItem *)activity.contentItem;
            [BDUGShareEventManager event:kShareEventShareSuccess params:@{
                @"channel_type" : (baseContentItem.channelString ?: @""),
                @"share_type" : (baseContentItem.serverDataModel.method ?: @""),
                @"panel_type" : (self.currentPanelType ?: @""),
                @"panel_id" : (self.currentPanelContent.panelID ?: @""),
                @"resource_id" : (self.currentPanelContent.resourceID ?: @""),
            }];
        }
        
    } else if (error.code == BDUGShareErrorTypeUserCancel) {
        //分享取消：2
        [BDUGShareEventManager trackService:kShareMonitorItemClick
                       attributes:@{
                           @"status" : @(2),
                       }];
    } else {
        //分享错误：3
        [BDUGShareEventManager trackService:kShareMonitorItemClick
                       attributes:@{
                           @"status" : @(3),
                       }];
    }
}

- (void)activityPanelDidCancel:(id<BDUGActivityPanelControllerProtocol>)panel
{
    if ([self.delegate respondsToSelector:@selector(shareManager:sharePanelCancel:)]) {
        [self.delegate shareManager:self sharePanelCancel:panel];
    }
    //分享取消：2
    [BDUGShareEventManager trackService:kShareMonitorItemClick
                   attributes:@{
                       @"status" : @(2),
                   }];
}

#pragma mark - cancel share

+ (void)cancelShareProcess
{
    [BDUGVideoImageShare cancelShareProcess];
}

#pragma mark - tricky

+ (void)configInitlizeDataWithItemModel:(BDUGShareInitializeModel *)model
{
    [[BDUGShareSequenceManager sharedInstance] configInitlizeDataWithItemModel:model];
}

#pragma mark - clean cache

- (void)cleanSequenceCache
{
    [[BDUGShareSequenceManager sharedInstance] cleanCache];
}

- (void)cleanShareInfoCache
{
    [self.dataManager cleanCache];
}

#pragma mark - get

- (BDUGShareDataManager *)dataManager {
    if (!_dataManager) {
        _dataManager = [[BDUGShareDataManager alloc] init];
        _dataManager.config = [BDUGShareSequenceManager sharedInstance].configuration;
    }
    return _dataManager;
}

@end
