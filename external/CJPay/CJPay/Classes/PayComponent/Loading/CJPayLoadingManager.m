//
//  CJPayLoadingManager.m
//  Pods
//
//  Created by 易培淮 on 2021/8/10.
//


#import "CJPayLoadingManager.h"
#import "CJPayBrandPromoteABTestManager.h"
#import "CJPaySettingsManager.h"
#import "CJPayUIMacro.h"
#import "CJPayHalfPageBaseViewController.h"
#import <UIKit/UIKit.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import "CJPayDouyinStyleLoadingView.h"
#import "CJPayTimerManager.h"

@implementation CJPayLoadingStyleInfo

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"loadingStyle": @"loading_style",
        @"showPayResult": @"show_pay_result",
        @"preShowInfo": @"trade_confirm_pre_show_info",
        @"bindCardConfirmPreShowInfo": @"bind_card_confirm_pre_show_info",
        @"bindCardCompleteShowInfo": @"bind_card_complete_show_info",
        @"bindCardConfirmPayingShowInfo": @"bind_card_confirm_paying_show_info",
        @"payingShowInfo": @"trade_confirm_paying_show_info",
        @"nopwdCombinePreShowInfo": @"nopwd_combine_pre_show_info",
        @"nopwdCombinePayingShowInfo": @"nopwd_combine_paying_show_info",
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

@implementation CJPayLoadingShowInfo

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"text": @"text",
        @"minTime": @"min_time"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

@interface CJPayLoadingManager()

@property (nonatomic, copy) NSDictionary *loadingTypeMap;
@property (nonatomic, strong) NSMutableDictionary *loadingItemMap;
@property (nonatomic, strong) NSMutableDictionary *loadingCountMap;
@property (nonatomic, strong) NSMutableDictionary *loadingTitleMap;

@end

@implementation CJPayLoadingManager

+ (instancetype)defaultService {
    static CJPayLoadingManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[CJPayLoadingManager alloc] init];
    });
    return manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self p_init];
    }
    return self;
}

- (void)stopLoading {
    [self stopLoading:CJPayLoadingTypeTopLoading isForce:NO];
    [self stopLoading:CJPayLoadingTypeHalfLoading isForce:NO];
    [self stopLoading:CJPayLoadingTypeSuperPayLoading isForce:NO];
    [self stopLoading:CJPayLoadingTypeDouyinOpenDeskLoading isForce:NO];
    [self stopLoading:CJPayLoadingTypeDouyinStyleLoading isForce:NO];
    [self stopLoading:CJPayLoadingTypeDouyinStyleBindCardLoading isForce:NO];
    [self stopLoading:CJPayLoadingTypeDouyinStyleHalfLoading isForce:NO];
    [self stopLoading:CJPayLoadingTypeDouyinFailLoading isForce:NO];
}

- (void)stopLoading:(CJPayLoadingType)type {
    [self stopLoading:type isForce:NO];
}

- (void)stopLoadingWithState:(CJPayLoadingQueryState)state {
    if (!self.isDouyinStyleLoading) {
        [self stopLoading];
        return;
    }
    CJPayLoadingType type = [UIViewController isTopVcBelongHalfVc] ? CJPayLoadingTypeDouyinStyleHalfLoading : CJPayLoadingTypeDouyinStyleLoading;
    NSArray<id<CJPayAdvanceLoadingProtocol>> *itemArray = [self p_getLoadingItemForStop:type];
    if(!Check_ValidArray(itemArray)) {
        return;
    }
    
    [itemArray enumerateObjectsUsingBlock:^(id<CJPayAdvanceLoadingProtocol>  _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
        [self p_removeLoadingTitle:[[item class] loadingType]];
        if ([item respondsToSelector:@selector(stopLoadingWithState:)]) {
            [item stopLoadingWithState:state];
        }
    }];
}

- (void)stopLoading:(CJPayLoadingType)type isForce:(BOOL)isForce {
    NSArray<id<CJPayAdvanceLoadingProtocol>> *itemArray = [self p_getLoadingItemForStop:type  isForce:isForce];
    if(!Check_ValidArray(itemArray)) {
        return;
    }
    [itemArray enumerateObjectsUsingBlock:^(id<CJPayAdvanceLoadingProtocol>  _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
        [self p_removeLoadingTitle:[[item class] loadingType]];
        if ([item respondsToSelector:@selector(stopLoading)]) {
            [item stopLoading];
        }
    }];
}

- (void)startLoading:(CJPayLoadingType)type {
    id<CJPayAdvanceLoadingProtocol> item = [self p_getLoadingItemForStart:type];
    if (!item) {
        return;
    }
    NSString *title = [self p_getLoadingTitle:type];
    if (Check_ValidString(title)) {
        CJPayLogAssert([item respondsToSelector:@selector(startLoadingWithTitle:)], @"item未实现startLoadingWithTitle:");
        if ([item respondsToSelector:@selector(startLoadingWithTitle:)]) {
            [item startLoadingWithTitle:title];
        }
    } else {
        CJPayLogAssert([item respondsToSelector:@selector(startLoading)], @"item未实现startLoading");
        if ([item respondsToSelector:@selector(startLoading)]) {
            [item startLoading];
        }
    }
}

- (void)startLoading:(CJPayLoadingType)type title:(NSString *)title {
    id<CJPayAdvanceLoadingProtocol> item = [self p_getLoadingItemForStart:type];
    if (!item) {
        return;
    }
    [self p_setLoadingTitleWithType:type title:title];
    CJPayLogAssert([item respondsToSelector:@selector(startLoadingWithTitle:)], @"item未实现startLoadingWithTitle:");
    if ([item respondsToSelector:@selector(startLoadingWithTitle:)]) {
        [item startLoadingWithTitle:title];
    }
}

- (void)startLoading:(CJPayLoadingType)type title:(NSString *)title logo:(NSString *)url {
    id<CJPayAdvanceLoadingProtocol> item = [self p_getLoadingItemForStart:type];
    if (!item) {
        return;
    }
    
    [self p_setLoadingTitleWithType:type title:title];
    CJPayLogAssert([item respondsToSelector:@selector(startLoadingWithTitle:logo:)], @"item未实现startLoadingWithTitle:logo:");
    if ([item respondsToSelector:@selector(startLoadingWithTitle:logo:)]) {
        [item startLoadingWithTitle:title logo:url];
    }
    
}

- (void)startLoading:(CJPayLoadingType)type vc:(UIViewController *)vc {
    id<CJPayAdvanceLoadingProtocol> item = [self p_getLoadingItemForStart:type];
    if (!item) {
        return;
    }
    CJPayLogAssert([item respondsToSelector:@selector(startLoadingWithVc:)], @"item未实现startLoadingWithVc:");
    if ([item respondsToSelector:@selector(startLoadingWithVc:)]) {
        [item startLoadingWithVc:vc];
    }
}

- (void)startLoading:(CJPayLoadingType)type vc:(UIViewController *)vc title:(NSString *)title {
    id<CJPayAdvanceLoadingProtocol> item = [self p_getLoadingItemForStart:type];
    if (!item) {
        return;
    }
    [self p_setLoadingTitleWithType:type title:title];
    CJPayLogAssert([item respondsToSelector:@selector(startLoadingWithVc:title:)], @"item未实现startLoadingWithVc:title:");
    if ([item respondsToSelector:@selector(startLoadingWithVc:title:)]) {
        [item startLoadingWithVc:vc title:title];
    }
}

- (void)startLoading:(CJPayLoadingType)type url:(NSString *)url view:(UIView *)view {
    CJPayLoadingType realType = type;
    if (type == CJPayLoadingTypeDouyinLoading
        && ![self p_isSpecialLoadingForUrl:url]) {
        realType = CJPayLoadingTypeTopLoading;
    }
    id<CJPayAdvanceLoadingProtocol> item = [self p_getLoadingItemForStart:realType];
    if (!item) {
        return;
    }
    CJPayLogAssert([item respondsToSelector:@selector(startLoadingOnView:)], @"item未实现startLoadingOnView:");
    if ([item respondsToSelector:@selector(startLoadingOnView:)]) {
        [item startLoadingOnView:view];
    }
}

- (void)startLoading:(CJPayLoadingType)type withView:(UIView *)view {
    id<CJPayAdvanceLoadingProtocol> item = [self p_getLoadingItemForStart:type];
    if (!item) {
        return;
    }
    CJPayLogAssert([item respondsToSelector:@selector(startLoadingWithView:)], @"item未实现startLoadingWithView:");
    if ([item respondsToSelector:@selector(startLoadingWithView:)]) {
        [item startLoadingWithView:view];
    }
}

- (void)startLoading:(CJPayLoadingType)type isNeedValidateTimer:(BOOL)isNeedValidateTimer {
    if (!isNeedValidateTimer) {
        [self startLoading:type];
    }
    
    id<CJPayAdvanceLoadingProtocol> item = [self p_getLoadingItemForStart:type];
    if (!item) {
        return;
    }
    CJPayLogAssert([item respondsToSelector:@selector(startLoadingWithValidateTimer:)], @"item未实现startLoadingWithView:");
    if ([item respondsToSelector:@selector(startLoadingWithValidateTimer:)]) {
        [item startLoadingWithValidateTimer:isNeedValidateTimer];
    }
}

- (BOOL)isLoading {
    return [self.loadingCountMap btd_intValueForKey:@(CJPayLoadingTypeTopLoading)] ||
        [self.loadingCountMap btd_intValueForKey:@(CJPayLoadingTypeDouyinLoading)] ||
        [self.loadingCountMap btd_intValueForKey:@(CJPayLoadingTypeSuperPayLoading)] ||
        [self.loadingCountMap btd_intValueForKey:@(CJPayLoadingTypeHalfLoading)] ||
        [self.loadingCountMap btd_intValueForKey:@(CJPayLoadingTypeDouyinHalfLoading)] ||
        [self.loadingCountMap btd_intValueForKey:@(CJPayLoadingTypeDouyinOpenDeskLoading)] ||
        [self.loadingCountMap btd_intValueForKey:@(CJPayLoadingTypeDouyinStyleLoading)] ||
        [self.loadingCountMap btd_intValueForKey:@(CJPayLoadingTypeDouyinStyleBindCardLoading)] ||
        [self.loadingCountMap btd_intValueForKey:@(CJPayLoadingTypeDouyinStyleHalfLoading)];
}

#pragma mark - Private Method
- (void)p_init {
    _loadingTypeMap =  @{
        @(CJPayLoadingTypeTopLoading) : @"CJPayTopLoadingItem",
        @(CJPayLoadingTypeDouyinLoading) : @"CJPayDouyinLoadingItem",
        @(CJPayLoadingTypeDouyinFailLoading) : @"CJPayDouyinFailLoadingItem",
        @(CJPayLoadingTypeSuperPayLoading) : @"CJPaySuperPayLoadingItem",
        @(CJPayLoadingTypeHalfLoading) : @"CJPayHalfLoadingItem",
        @(CJPayLoadingTypeDouyinHalfLoading) : @"CJPayDouyinHalfLoadingItem",
        @(CJPayLoadingTypeDouyinOpenDeskLoading) : @"CJPayDouyinOpenDeskLoadingItem",
        @(CJPayLoadingTypeDouyinStyleLoading) : @"CJPayDouyinStyleLoadingItem",
        @(CJPayLoadingTypeDouyinStyleBindCardLoading) : @"CJPayDouyinStyleBindCardLoadingItem",
        @(CJPayLoadingTypeDouyinStyleHalfLoading) : @"CJPayDouyinStyleHalfLoadingItem",
    };
}

- (id<CJPayAdvanceLoadingProtocol>)p_createLoadingItem:(CJPayLoadingType)type {
    Class loadingTypeClass = NSClassFromString((NSString *)(self.loadingTypeMap[@(type)]));
    id<CJPayAdvanceLoadingProtocol> item = [loadingTypeClass new];
    CJPayLogAssert(item,@"Loading对象创建失败");
    item.delegate = self;
    if (item) {
        [self.loadingItemMap addEntriesFromDictionary:@{
            @(type):item
        }];
    }
    return item;
}

- (NSString *)p_getLoadingTitle:(CJPayLoadingType)type {
    NSString *loadingTitle = @"";
    if(self.loadingTitleMap.count > 0) {
        loadingTitle = [self.loadingTitleMap btd_stringValueForKey:@(type)];
    }
    return loadingTitle;
}

- (void)p_setLoadingTitleWithType:(CJPayLoadingType)type title:(NSString *)title {
    if(self.loadingTitleMap.count > 0) {
        self.loadingTitleMap[@(type)] = title;
    }
}

- (void)p_removeLoadingTitle:(CJPayLoadingType)type {
    if(self.loadingTitleMap.count > 0) {
        self.loadingTitleMap[@(type)] = @"";
    }
}

- (id<CJPayAdvanceLoadingProtocol>)p_getLoadingItemForStart:(CJPayLoadingType)type {
    CJPayLoadingType realType = [self p_isABTestHit:type];
    realType = [self p_isNeedConvertToTopLoading:realType];
    id<CJPayAdvanceLoadingProtocol> item = nil;
    if(self.loadingItemMap.count > 0) {
        item = self.loadingItemMap[@(realType)];
    }
    if(!item) {
        item = [self p_createLoadingItem:realType];
    }
    if (![self p_allowStartLoading:realType]) {
        return nil;
    }
    self.currentLoadingItem = item;
    return item;
}

- (BOOL)p_allowStartLoading:(CJPayLoadingType)type {
    if (self.loadingCountMap.count >0) {
        int count = [self.loadingCountMap btd_intValueForKey:@(type)];
        int another_count; //指抖音与非抖音loading相互对标的数量
        switch (type) {
            case CJPayLoadingTypeTopLoading:
                another_count = [self.loadingCountMap btd_intValueForKey:@(CJPayLoadingTypeDouyinLoading)];
                return (another_count == 0) && (count == 0);
            case CJPayLoadingTypeDouyinLoading:
            case CJPayLoadingTypeDouyinStyleLoading:
            case CJPayLoadingTypeDouyinStyleBindCardLoading:
            case CJPayLoadingTypeDouyinFailLoading:
                another_count = [self.loadingCountMap btd_intValueForKey:@(CJPayLoadingTypeTopLoading)];
                if (another_count == 0 && count >0) {
                    self.loadingCountMap[@(type)] = @(count - 1);   //同类型loading覆盖
                }
                return (another_count == 0);
            case CJPayLoadingTypeHalfLoading:
                another_count = [self.loadingCountMap btd_intValueForKey:@(CJPayLoadingTypeDouyinHalfLoading)];
                return (another_count == 0) && (count == 0);
            case CJPayLoadingTypeDouyinHalfLoading:
            case CJPayLoadingTypeDouyinStyleHalfLoading:
                another_count = [self.loadingCountMap btd_intValueForKey:@(CJPayLoadingTypeHalfLoading)];
                return (another_count == 0) && (count == 0);
            case CJPayLoadingTypeSuperPayLoading:
                if (count > 0) {
                    self.loadingCountMap[@(type)] = @(count - 1);
                }
                return YES;
            case CJPayLoadingTypeDouyinOpenDeskLoading:
                if (count > 0) {
                    self.loadingCountMap[@(type)] = @(count - 1);
                }
                return YES;
            default:
                return NO;
        }
    } else {
        return YES;
    }
}

- (BOOL)p_isSpecialLoadingForUrl:(NSString *)url {
    CJPayBrandPromoteModel *model = [CJPaySettingsManager shared].currentSettings.abSettingsModel.brandPromoteModel;
    if (model && model.showNewLoading &&
        Check_ValidArray(model.douyinLoadingUrlList) &&
        [model.douyinLoadingUrlList btd_contains:^BOOL(NSString * _Nonnull obj) {
            return [obj isEqualToString:url];
        }]) {
        return YES;
    }
    return NO;
}

- (NSArray<id<CJPayAdvanceLoadingProtocol>> *)p_getLoadingItemForStop:(CJPayLoadingType)type
                                            isForce:(BOOL)isForce {
    if(self.loadingItemMap.count < 1) {
        return nil;
    }
    NSArray<id<CJPayAdvanceLoadingProtocol>> * itemArray = [self p_getLoadingItemForStop:type];
    if (!Check_ValidArray(itemArray)) {
        return nil;
    }
    if (isForce) {
        return itemArray;
    }
    return [self p_allowStopLoading:itemArray];
}

-(NSArray<id<CJPayAdvanceLoadingProtocol>>*)p_getLoadingItemForStop:(CJPayLoadingType)type {
    NSMutableArray *resultArray = [NSMutableArray new];
    switch (type) {
        case CJPayLoadingTypeTopLoading:
        case CJPayLoadingTypeDouyinLoading:
            if (self.loadingItemMap[@(CJPayLoadingTypeTopLoading)]) {
                [resultArray btd_addObject:self.loadingItemMap[@(CJPayLoadingTypeTopLoading)]];
            }
            if (self.loadingItemMap[@(CJPayLoadingTypeDouyinLoading)]) {
                [resultArray btd_addObject:self.loadingItemMap[@(CJPayLoadingTypeDouyinLoading)]];
            }
            break;
        case CJPayLoadingTypeHalfLoading:
        case CJPayLoadingTypeDouyinHalfLoading:
            if (self.loadingItemMap[@(CJPayLoadingTypeHalfLoading)]) {
                [resultArray btd_addObject:self.loadingItemMap[@(CJPayLoadingTypeHalfLoading)]];
            }
            if (self.loadingItemMap[@(CJPayLoadingTypeDouyinHalfLoading)]) {
                [resultArray btd_addObject:self.loadingItemMap[@(CJPayLoadingTypeDouyinHalfLoading)]];
            }
            break;
        case CJPayLoadingTypeSuperPayLoading:
            [resultArray btd_addObject:self.loadingItemMap[@(CJPayLoadingTypeSuperPayLoading)]];
            break;
        case CJPayLoadingTypeDouyinOpenDeskLoading:
            [resultArray btd_addObject:self.loadingItemMap[@(CJPayLoadingTypeDouyinOpenDeskLoading)]];
            break;
        case CJPayLoadingTypeDouyinStyleLoading:
            [resultArray btd_addObject:self.loadingItemMap[@(CJPayLoadingTypeDouyinStyleLoading)]];
            break;
        case CJPayLoadingTypeDouyinStyleBindCardLoading:
            [resultArray btd_addObject:self.loadingItemMap[@(CJPayLoadingTypeDouyinStyleBindCardLoading)]];
            break;
        case CJPayLoadingTypeDouyinStyleHalfLoading:
            [resultArray btd_addObject:self.loadingItemMap[@(CJPayLoadingTypeDouyinStyleHalfLoading)]];
            break;
        case CJPayLoadingTypeDouyinFailLoading:
            [resultArray btd_addObject:self.loadingItemMap[@(CJPayLoadingTypeDouyinFailLoading)]];
            break;
        default:
            return nil;
    }
    return [resultArray copy];
}

- (NSArray<id<CJPayAdvanceLoadingProtocol>> *)p_allowStopLoading:(NSArray<id<CJPayAdvanceLoadingProtocol>>*)itemArray {
    if(!Check_ValidArray(itemArray)) {
        return nil;
    }
    NSMutableArray *resultArray = [NSMutableArray new];
    [itemArray enumerateObjectsUsingBlock:^(id<CJPayAdvanceLoadingProtocol>  _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!item){
            return;
        }
        int count = [self.loadingCountMap btd_intValueForKey:@([[item class] loadingType])];
        if (count == 1) {
            [resultArray addObject:item];
            return;
        } else if (count > 1){
            self.loadingCountMap[@([[item class] loadingType])] = @(count - 1); //loading count大于1时，不关闭loading，只对引用计数减1
            return;
        } else {
            return;
        }
    }];
    return [resultArray copy];
}

- (CJPayLoadingType)p_isABTestHit:(CJPayLoadingType)type {
    switch (type) {
        case CJPayLoadingTypeDouyinLoading:
            return [[CJPayBrandPromoteABTestManager shared] isHitTest] ? type :CJPayLoadingTypeTopLoading;
        case CJPayLoadingTypeDouyinHalfLoading:
            return [[CJPayBrandPromoteABTestManager shared] isHitTest] ? type
                :CJPayLoadingTypeHalfLoading;
        default:
            return type;
    }
}

- (CJPayLoadingType)p_isNeedConvertToTopLoading:(CJPayLoadingType)type {
    switch (type) {
        case CJPayLoadingTypeHalfLoading:
        case CJPayLoadingTypeDouyinHalfLoading:
            if (![UIViewController isTopVcBelongHalfVc]) {  //topVC不是半屏VC，则半屏loading变为全屏loading
                return CJPayLoadingTypeTopLoading;
            } else {
                return type;
            }
        case CJPayLoadingTypeDouyinStyleLoading:
        case CJPayLoadingTypeDouyinStyleBindCardLoading:
            if (!self.isDouyinStyleLoading) {
                return CJPayLoadingTypeDouyinLoading;
            } else {
                return type;
            }
        case CJPayLoadingTypeDouyinStyleHalfLoading:
            if (!self.isDouyinStyleLoading) {
                return [self p_isNeedConvertToTopLoading:CJPayLoadingTypeDouyinHalfLoading];
            } else {
                return type;
            }
        default:
            return type;
    }
}

#pragma mark - Getter
- (NSMutableDictionary *)loadingItemMap {
    if(!_loadingItemMap) {
        _loadingItemMap = [NSMutableDictionary new];
    }
    return _loadingItemMap;
}

- (NSMutableDictionary *)loadingCountMap {
    if(!_loadingCountMap) {
        _loadingCountMap = [NSMutableDictionary new];
    }
    return _loadingCountMap;
}

- (NSMutableDictionary *)loadingTitleMap {
    if(!_loadingTitleMap) {
        _loadingTitleMap = [NSMutableDictionary new];
    }
    return _loadingTitleMap;
}

- (CJPayTimerManager *)preShowTimerManger {
    if (!_preShowTimerManger) {
        _preShowTimerManger = [CJPayTimerManager new];
    }
    return _preShowTimerManger;
}

- (CJPayTimerManager *)payingShowTimerManger {
    if (!_payingShowTimerManger) {
        _payingShowTimerManger = [CJPayTimerManager new];
    }
    return _payingShowTimerManger;
}

- (void)setLoadingStyleInfo:(CJPayLoadingStyleInfo *)loadingStyleInfo {
    _loadingStyleInfo = loadingStyleInfo;
    _isLoadingTitleDowngrade = NO;
    [CJPayDouyinStyleLoadingView sharedView].loadingStyleInfo = loadingStyleInfo;
    
    NSString *loadingStyle = loadingStyleInfo.loadingStyle;
    if (!Check_ValidString(loadingStyle) || [loadingStyle isEqualToString:@"crude"]) {
        self.isDouyinStyleLoading = NO;
        return;
    }
    
    self.isDouyinStyleLoading = YES;
    if ([loadingStyleInfo.showPayResult isEqualToString:@"1"]) {
        loadingStyleInfo.isNeedShowPayResult = YES;
    }
}

- (void)setBindCardLoadingStyleInfo:(CJPayLoadingStyleInfo *)bindCardLoadingStyleInfo {
    if (!bindCardLoadingStyleInfo) {
        return;
    }
    _bindCardLoadingStyleInfo = bindCardLoadingStyleInfo;
    _isLoadingTitleDowngrade = NO;
    [CJPayDouyinStyleLoadingView sharedView].loadingStyleInfo = bindCardLoadingStyleInfo;
}

- (UIView *)getCurrentHalfLoadingView {
    if (!self.currentLoadingItem) {
        return nil;
    }
    id<CJPayAdvanceLoadingProtocol> loadingItem = self.currentLoadingItem;
    UIView *currentLoadingView;
    if ([loadingItem respondsToSelector:@selector(getLoadingView)]) {
        currentLoadingView = [loadingItem getLoadingView];
    }
    return currentLoadingView;
}

#pragma mark - CJPayLoadingManagerProtocol

- (void)resetLoadingCount:(CJPayLoadingType)type {
    self.loadingCountMap[@(type)] = @(0);
}

- (void)addLoadingCount:(CJPayLoadingType)type {
    int count = [self.loadingCountMap btd_intValueForKey:@(type)] ?: 0;
    self.loadingCountMap[@(type)] = @(count +1);
}

@end

