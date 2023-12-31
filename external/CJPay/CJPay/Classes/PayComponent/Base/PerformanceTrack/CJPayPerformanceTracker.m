//
//  CJPayPerformanceTracker.m
//  Pods
//
//  Created by 王新华 on 2021/10/11.
//

#import "CJPayPerformanceTracker.h"
#import "CJPayPerformanceStage.h"
#import "CJPayPerformanceUploadRule.h"
#import "CJPayUIMacro.h"
#import "UIViewController+CJPay.h"
#import "CJPaySettingsManager.h"
#import "CJPaySettings.h"
#import "CJPayPrivateServiceHeader.h"
#import "CJPayTracker.h"
#import "CJPayBaseRequest.h"

CJPayPerformanceAPISceneKey const CJPayPerformanceAPISceneStandardPayDeskKey = @"standard_pay_desk";// 标准收银台
CJPayPerformanceAPISceneKey const CJPayPerformanceAPISceneEcommercePayDeskKey = @"ecommerce_pay_desk";// 电商收银台
CJPayPerformanceAPISceneKey const CJPayPerformanceAPISceneBalanceWithdrawPayDeskKey = @"balance_withdraw"; // 余额提现
CJPayPerformanceAPISceneKey const CJPayPerformanceAPISceneBalanceRechargePayDeskKey = @"balance_recharge"; // 余额充值
CJPayPerformanceAPISceneKey const CJPayPerformanceAPISceneBindCardKey = @"bind_card"; // 绑卡
CJPayPerformanceAPISceneKey const CJPayPerformanceAPISceneOwnPayKey = @"own_pay"; // 自有支付
CJPayPerformanceAPISceneKey const CJPayPerformanceAPISceneBankCardList = @"bank_card_list"; // 银行卡列表
CJPayPerformanceAPISceneKey const CJPayPerformanceAPISceneOuterPay = @"outer_pay"; // 端外充值



@interface CJPayPerformanceTracker()

@property (nonatomic, copy) NSString *sdkProcessID;  // processid
@property (nonatomic, copy) NSString *curSceneKey;
@property (nonatomic, strong) NSMutableArray<NSString *> *sceneKeyStack;
@property (nonatomic, assign) CFAbsoluteTime startTime0; // 基准时间
@property (nonatomic, strong) NSMutableArray<CJPayPerformanceStage *> *globalStageList;
@property (nonatomic, strong) dispatch_queue_t processQueue;

@end

static BOOL CJPayPerformance_trackAllStages;
@implementation CJPayPerformanceTracker

@dynamic trackAllStages;
+ (void)setTrackAllStages:(BOOL)trackAllStages {
    CJPayPerformance_trackAllStages = trackAllStages;
}

+ (BOOL)trackAllStages {
    return CJPayPerformance_trackAllStages;
}

- (dispatch_queue_t)processQueue {
    if (!_processQueue) {
        _processQueue = dispatch_queue_create("cjpay.performance.process.queue", DISPATCH_QUEUE_SERIAL);
    }
    return _processQueue;
}

- (NSMutableArray<NSString *> *)sceneKeyStack {
    if (!_sceneKeyStack) {
        _sceneKeyStack = [NSMutableArray new];
    }
    return _sceneKeyStack;
}

- (void)p_addSceneKey:(NSString *)sceneKey {
    if ([self.sceneKeyStack containsObject:sceneKey] || !Check_ValidString(sceneKey)) {
        [self p_monitorException:@{@"add_scenekey": CJString(sceneKey)}];
        [self.globalStageList removeAllObjects];
        self.curSceneKey = sceneKey;
        self.sdkProcessID = [NSString stringWithFormat:@"%@%@_%@", CJString(self.sdkProcessID), sceneKey, @([[NSDate date] timeIntervalSince1970] * 1000).stringValue];
        // 这种情况重置整个日志记录
    } else {
        [self.sceneKeyStack addObject:sceneKey];
        if (Check_ValidString(self.sdkProcessID)) {
            self.sdkProcessID = [NSString stringWithFormat:@"%@&%@_%@", CJString(self.sdkProcessID), sceneKey, @([[NSDate date] timeIntervalSince1970] * 1000).stringValue];
        } else {
            self.sdkProcessID = [NSString stringWithFormat:@"%@%@_%@", CJString(self.sdkProcessID), sceneKey, @([[NSDate date] timeIntervalSince1970] * 1000).stringValue];
        }
    }
}

- (void)p_popSceneKey:(NSString *)sceneKey {
    if ([self.sceneKeyStack.lastObject isEqualToString:CJString(sceneKey)]) {
        [self.sceneKeyStack removeLastObject];
    } else {
        [self p_monitorException:@{@"pop_scenekey": CJString(sceneKey), @"msg": @"pop异常", @"cur_scenes": CJString(self.sceneKeyStack.description)}];
    }
    if (self.sceneKeyStack.count > 0) {
        NSMutableArray *processIds = [[self.sdkProcessID componentsSeparatedByString:@"&"] mutableCopy];
        [processIds removeLastObject];
        self.sdkProcessID = [processIds componentsJoinedByString:@"&"];
    } else {
        [[CJPayJsonParseTracker sharedInstance] syncModelParseTime];
        [self p_uploadEventList];
        // 清空相关的赋值信息
        [self.globalStageList removeAllObjects];
        self.sdkProcessID = nil;
        self.curSceneKey = nil;
    }
}

- (NSMutableArray<CJPayPerformanceStage *> *)globalStageList {
    if (!_globalStageList) {
        _globalStageList = [NSMutableArray new];
    }
    return _globalStageList;
}

- (CFAbsoluteTime)p_getCurrentTime {
    return CFAbsoluteTimeGetCurrent() - self.startTime0;
}

- (CJPayPerformanceStage *)p_buildStage {
    CJPayPerformanceStage *stage = [CJPayPerformanceStage new];
    stage.sdkProcessID = self.sdkProcessID;
    stage.curTime = [self p_getCurrentTime];
    return stage;
}

+ (CJPayPerformanceTracker * _Nullable)shared {
    static CJPayPerformanceTracker *tracker;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        tracker = [CJPayPerformanceTracker new];
        [[NSNotificationCenter defaultCenter] addObserver:tracker selector:@selector(p_requestStart:) name:CJPayRequestStartNotifictionName object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:tracker selector:@selector(p_requestFinish:) name:CJPayRequestFinishNotificationName object:nil];
    });
    // 支持setting 一键关闭
    if (![CJPaySettingsManager shared].currentSettings.performanceMonitorIsOpened) {
        return nil;
    }
    return tracker;
}

#pragma - mark 请求的通知
- (void)p_requestStart:(NSNotification *)noti {
    NSDictionary *dict = noti.object;
    if (dict && [dict isKindOfClass:NSDictionary.class]) {
        [self trackRequestStartWithAPIPath:[dict cj_stringValueForKey:@"url"] extra:@{}];
    }
}

- (void)p_requestFinish:(NSNotification *)noti {
    NSDictionary *dict = noti.object;
    if (dict && [dict isKindOfClass:NSDictionary.class]) {
        [self trackRequestEndWithAPIPath:[dict cj_stringValueForKey:@"url"] extra:@{}];
    }
}

- (void)trackAPIStartWithAPIScene:(CJPayPerformanceAPISceneKey)sceneKey extra:(NSDictionary *)extra {
    [self p_addSceneKey:sceneKey];
    CJPayPerformanceStage *stage = [self p_buildStage];
    stage.stageType = CJPayPerformanceStageTypeAPIStart;
    stage.name = sceneKey;
    stage.extra = extra;

    [self p_syncStageToList:stage];
}

- (void)trackAPIEndWithAPIScene:(CJPayPerformanceAPISceneKey)sceneKey extra:(NSDictionary *)extra {
    CJPayPerformanceStage *stage = [self p_buildStage];
    stage.stageType = CJPayPerformanceStageTypeAPIEnd;
    stage.name = sceneKey;
    stage.extra = extra;
    [self p_syncStageToList:stage];
    [self p_popSceneKey:sceneKey];
}

- (void)trackRequestStartWithAPIPath:(NSString *)apiPath extra:(NSDictionary *)extra {
    CJPayPerformanceStage *stage = [self p_buildStage];
    stage.stageType = CJPayPerformanceStageTypeRequestStart;
    stage.name = [apiPath cj_urlPath] ?: apiPath;
    stage.extra = extra;

    [self p_syncStageToList:stage];
}
- (void)trackRequestEndWithAPIPath:(NSString *)apiPath extra:(NSDictionary *)extra {
    CJPayPerformanceStage *stage = [self p_buildStage];
    stage.stageType = CJPayPerformanceStageTypeRequestEnd;
    stage.name = [apiPath cj_urlPath] ?: apiPath;
    stage.extra = extra;

    [self p_syncStageToList:stage];
}

- (void)trackPageInitWithVC:(UIViewController *)vc extra:(NSDictionary *)extra {
    CJPayPerformanceStage *stage = [self p_buildStage];
    stage.stageType = CJPayPerformanceStageTypePageInit;
    stage.name = [vc cj_performanceMonitorName];
    stage.pageName = NSStringFromClass([self class]);
    stage.extra = extra;

    [self p_syncStageToList:stage];
}

- (void)trackPageAppearWithVC:(UIViewController *)vc extra:(NSDictionary *)extra {
    CJPayPerformanceStage *stage = [self p_buildStage];
    stage.stageType = CJPayPerformanceStageTypePageInit;
    stage.name = [vc cj_performanceMonitorName];
    stage.pageName = NSStringFromClass([[UIViewController cj_foundTopViewControllerFrom:vc] class]);
    stage.extra = extra;

    [self p_syncStageToList:stage];
}
- (void)trackPageFinishRenderWithVC:(UIViewController *)vc name:(NSString *)name extra:(NSDictionary *)extra {
    CJPayPerformanceStage *stage = [self p_buildStage];
    stage.stageType = CJPayPerformanceStageTypePageFinishRender;
    stage.pageName = NSStringFromClass([[UIViewController cj_foundTopViewControllerFrom:vc] class]);
    stage.name = Check_ValidString(name) ? name : [vc cj_performanceMonitorName];
    stage.extra = extra;
    
    [self p_syncStageToList:stage];
}

- (void)trackPageDisappearWithVC:(UIViewController *)vc extra:(NSDictionary *)extra {
    CJPayPerformanceStage *stage = [self p_buildStage];
    stage.stageType = CJPayPerformanceStageTypePageDisappear;
    stage.name = [vc cj_performanceMonitorName];
    stage.pageName = NSStringFromClass([[UIViewController cj_foundTopViewControllerFrom:vc] class]);
    
    [self p_syncStageToList:stage];
}

- (void)trackPageDeallocWithVC:(UIViewController *)vc extra:(NSDictionary *)extra {
    CJPayPerformanceStage *stage = [self p_buildStage];
    stage.stageType = CJPayPerformanceStageTypePageDisappear;
    stage.name = [vc cj_performanceMonitorName];
    stage.pageName = NSStringFromClass([[UIViewController cj_foundTopViewControllerFrom:vc] class]);
    
    [self p_syncStageToList:stage];
}

- (void)trackBtnActionWithBtn:(UIButton *)btn target:(id)target extra:(NSDictionary *)extra {
    CJPayPerformanceStage *stage = [self p_buildStage];
    stage.stageType = CJPayPerformanceStageTypeActionBtn;
    UIViewController *vc = [btn cj_responseViewController];
    NSString *btnTitle = btn.currentTitle;
    if (!Check_ValidString(btnTitle)) { // btn上有文案的话，就用btn文案，没有的话，用selector代替
        NSString *selector = [btn actionsForTarget:target forControlEvent: UIControlEventTouchUpInside].firstObject;
        btnTitle = [NSString stringWithFormat:@"%@_%@", [target class], selector];
    }
    stage.name = [NSString stringWithFormat:@"%@_%@", [vc cj_performanceMonitorName], btnTitle];
    stage.pageName = NSStringFromClass([[UIViewController cj_foundTopViewControllerFrom:vc] class]);

    [self p_syncStageToList:stage];
}

- (void)trackCellActionWithTableViewCell:(UITableViewCell *)cell extra:(NSDictionary *)extra {
    CJPayPerformanceStage *stage = [self p_buildStage];
    stage.stageType = CJPayPerformanceStageTypeActionCell;
    UIViewController *vc = [cell cj_responseViewController];
    stage.name = [NSString stringWithFormat:@"%@_%@", [vc cj_performanceMonitorName], [cell class]];
    stage.pageName = NSStringFromClass([[UIViewController cj_foundTopViewControllerFrom:vc] class]);
    
    [self p_syncStageToList:stage];
}

- (void)trackGestureActionWithGesture:(UIGestureRecognizer *)gesture extra:(NSDictionary *)extra {
    CJPayPerformanceStage *stage = [self p_buildStage];
    stage.stageType = CJPayPerformanceStageTypeActionGesture;
//    stage.name = gestu
    
    [self p_syncStageToList:stage];
}

- (void)p_monitorException:(NSDictionary *)extra {
    [CJMonitor trackService:@"cjpay_performance_monitor" extra:extra];
}

@end

@implementation CJPayPerformanceTracker(Upload)

- (NSArray<CJPayPerformanceUploadRule *> *)currentRules {
    static NSArray<CJPayPerformanceUploadRule *> *rules;
    if (!rules) {
        NSDictionary *rulesDic = [CJ_OBJECT_WITH_PROTOCOL(CJPayGurdService) i_getPerformanceMonitorConfigDictionary];
        CJPayPerformanceMonitorModel *model = [[CJPayPerformanceMonitorModel alloc] initWithDictionary:rulesDic error:nil];
        rules = model.uploadRules;
    }
    return rules;
}

- (NSDictionary<NSNumber *, NSHashTable<CJPayPerformanceUploadNode *> *> *)currentRulesSplitToTypeAndNodeMap {
    static NSMutableDictionary<NSNumber *, NSHashTable<CJPayPerformanceUploadNode *> *> *typeAndUploadNodeMap;
    NSArray<CJPayPerformanceUploadRule *> *currentRules = [self currentRules];
    if (!typeAndUploadNodeMap && currentRules) {
        typeAndUploadNodeMap = [NSMutableDictionary new];
        [currentRules enumerateObjectsUsingBlock:^(CJPayPerformanceUploadRule * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (![obj isValid]) {
                return;
            }
            // 处理headNode
            NSHashTable *headNodeHashTable = typeAndUploadNodeMap[@([obj.headNode curType])] ?: [NSHashTable weakObjectsHashTable];
            [headNodeHashTable addObject:obj.headNode];
            typeAndUploadNodeMap[@([obj.headNode curType])] = headNodeHashTable;
            // 处理EndNode
            NSHashTable *endNodeHashTable = typeAndUploadNodeMap[@([obj.endNode curType])] ?: [NSHashTable weakObjectsHashTable];
            [endNodeHashTable addObject:obj.endNode];
            typeAndUploadNodeMap[@([obj.endNode curType])] = endNodeHashTable;
        }];
    }
    return typeAndUploadNodeMap;
}

- (void)p_syncStageToList:(CJPayPerformanceStage *)stage {
    if (!Check_ValidString(stage.sdkProcessID)) {
        return;
    }
    
    if ([CJPayPerformanceTracker trackAllStages]) {
        [self.globalStageList addObject:stage];
        return;
    }
    // 避免stage采集过多，导致占用内存过大，这里采用根据数据采集需要进行过滤能力。
    // 走过滤记录
    NSDictionary<NSNumber *, NSHashTable<CJPayPerformanceUploadNode *> *> *typeAndUploadNodeMap = [self currentRulesSplitToTypeAndNodeMap];
    
    __block BOOL shouldTrack = NO;
    NSArray<CJPayPerformanceUploadNode *>* curTypeUploadNodes = [typeAndUploadNodeMap[@(stage.stageType)] allObjects];
    [curTypeUploadNodes enumerateObjectsUsingBlock:^(CJPayPerformanceUploadNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj matchToPerformanceStage:stage]) {
            shouldTrack = YES;
            *stop = YES;
        }
    }];
    
    if (shouldTrack) {
        [self.globalStageList addObject:stage];
    }
    
    CJPayLogInfo(@"CJPayPerformanceTracker - %@", stage);
}

- (void)p_uploadEventList {
    NSArray<CJPayPerformanceStage *> *stageList = [self.globalStageList copy];
    [CJTracker event:@"wallet_performance_monitor" params:@{@"stages_count": @(stageList.count), @"scene": CJString(self.curSceneKey), @"rules_count": @([self currentRules].count)}];
    [self p_asyncUpload:stageList];
}

- (void)p_asyncUpload:(NSArray<CJPayPerformanceStage *> *)stageList {
    dispatch_async(self.processQueue, ^{
        
        __block NSMutableArray *headToEndRules = [NSMutableArray new];
        __block NSMutableArray *endToHeadRules = [NSMutableArray new];
        
        // 分离两种查找规则
        [[self currentRules] enumerateObjectsUsingBlock:^(CJPayPerformanceUploadRule * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isEndToHead]) {
                [endToHeadRules addObject:[obj copy]];
            } else if ([obj isHeadToEnd]) {
                [headToEndRules addObject:[obj copy]];
            } else {
                CJPayLogAssert(NO, @"查找规则不能处理");
            }
        }];
        
        for (CJPayPerformanceStage *stage in [[stageList reverseObjectEnumerator] allObjects]) {
            for (CJPayPerformanceUploadRule *rule in endToHeadRules) {
                [rule processStage:stage];
            }
        }
        for (CJPayPerformanceStage *stage in stageList) {
            for (CJPayPerformanceUploadRule *rule in headToEndRules) {
                [rule processStage:stage];
            }
        }
        [self debug_notifyProcessSucess:stageList rules:headToEndRules];
        [self debug_notifyProcessSucess:stageList rules:endToHeadRules];
        dispatch_async(dispatch_get_main_queue(), ^{
            // 上报规则
            for (CJPayPerformanceUploadRule *rule in endToHeadRules) {
                [rule uploadEvents:^(NSArray<NSDictionary *> * _Nonnull events) {
                    [events enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        [CJTracker event:@"wallet_rd_page_load_time" params:obj];
                    }];
                    CJPayLogInfo(@"CJPayPerformanceTracker: %@", events);
                }];
            }
            // 上报规则
            for (CJPayPerformanceUploadRule *rule in headToEndRules) {
                [rule uploadEvents:^(NSArray<NSDictionary *> * _Nonnull events) {
                    [events enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        [CJTracker event:@"wallet_rd_page_load_time" params:obj];
                    }];
                    CJPayLogInfo(@"CJPayPerformanceTracker: %@", events);
                }];
            }
        });
    });
}

- (void)debug_notifyProcessSucess:(NSArray<CJPayPerformanceStage *> *)stageList rules:(NSArray<CJPayPerformanceUploadRule *> *)rules {
    // 供外面hook测试用
}

@end
