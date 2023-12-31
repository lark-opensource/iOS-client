//
//  ACCClassicalMVTemplatesDataController.m
//  CameraClient
//
//  Created by long.chen on 2020/3/6.
//

#import "ACCClassicalMVTemplatesDataController.h"
#import <CreativeKit/ACCMacros.h>
#import "ACCConfigKeyDefines.h"
#import <CreativeKit/ACCMonitorProtocol.h>
#import "AWEMVTemplateModel.h"
#import "ACCMVTemplatesFetchProtocol.h"
#import <CreationKitArch/ACCModelFactoryServiceProtocol.h>

@interface ACCClassicalMVTemplatesDataController ()

@property (nonatomic, assign) BOOL isRefreshing;

@end

@implementation ACCClassicalMVTemplatesDataController

@synthesize dataSource = _dataSource;
@synthesize hasMore = _hasMore;
@synthesize cursor = _cursor;
@synthesize sortedPosition = _sortedPosition;

- (instancetype)init
{
    if (self = [super init]) {
        _dataSource = @[].mutableCopy;
        _hasMore = NO;
    }
    return self;
}

- (void)setSameMVTemplate:(id<ACCMVTemplateModelProtocol>)sameMVTemplate
{
    _sameMVTemplate = sameMVTemplate;
    if (sameMVTemplate.effectModel) {
        [self.dataSource addObject:sameMVTemplate];
        self.hasMore = YES;
    }
}

- (void)refreshContentDataWithCompletion:(void (^)(NSError *, NSArray<id<ACCMVTemplateModelProtocol>> *, BOOL hasMore))completion
{
    [self loadMoreContentDataWithCompletion:completion];
}

- (void)loadMoreContentDataWithCompletion:(void (^)(NSError *, NSArray<id<ACCMVTemplateModelProtocol>> *, BOOL))completion
{
    if (self.isRefreshing) {
        return;
    }
    self.isRefreshing = YES;
    
    @weakify(self);
    [EffectPlatform checkEffectUpdateWithPanel:[ACCMVTemplatesFetch() classicMvPannel]
                          effectTestStatusType:ACCConfigInt(kConfigInt_effect_test_status_code)
                                    completion:^(BOOL needUpdate) {
        @strongify(self);
        IESEffectPlatformResponseModel *cachedResponse = [EffectPlatform cachedEffectsOfPanel:[ACCMVTemplatesFetch() classicMvPannel]];
        if (!needUpdate && cachedResponse.effects.count > 0) {
            [ACCMonitor() trackService:@"mv_template_old_list_error_state"
                                     status:0
                                      extra:@{}];
            [self fetchUsageCountAndCollectState:cachedResponse.effects urlPrefix:cachedResponse.urlPrefix completion:completion];
        } else {
            @weakify(self);
            [EffectPlatform downloadEffectListWithPanel:[ACCMVTemplatesFetch() classicMvPannel]
                                   effectTestStatusType:ACCConfigInt(kConfigInt_effect_test_status_code)
                                             completion:^(NSError * _Nullable error, IESEffectPlatformResponseModel * _Nullable response) {
                @strongify(self);
                if (!error && response.effects.count > 0) {
                    [ACCMonitor() trackService:@"mv_template_old_list_error_state"
                                             status:0
                                              extra:@{}];
                    [self fetchUsageCountAndCollectState:response.effects urlPrefix:response.urlPrefix completion:completion];
                } else {
                    self.isRefreshing = NO;
                    [self.dataSource removeAllObjects];
                    ACCBLOCK_INVOKE(completion, error, nil, self.hasMore);
                    [ACCMonitor() trackService:@"mv_template_old_list_error_state"
                                             status:1
                                              extra:@{}];
                }
            }];
        }
    }];
    
}

- (NSMutableArray<id<ACCMVTemplateModelProtocol>> *)dataSource
{
    if (!_dataSource) {
        _dataSource = [NSMutableArray array];
    }
    return _dataSource;
}

- (void)fetchUsageCountAndCollectState:(NSArray<IESEffectModel *> *)effects urlPrefix:(NSArray<NSString *> *)urlPrefix completion:(void (^)(NSError *, NSArray<id<ACCMVTemplateModelProtocol>> *, BOOL hasMore))completion
{
    NSMutableArray<NSNumber *> *templateIDs = [[NSMutableArray alloc] initWithCapacity:effects.count];
    NSMutableArray<id<ACCMVTemplateModelProtocol>> *templateList = [[NSMutableArray alloc] initWithCapacity:effects.count];
    
    if (self.sameMVTemplate) {
        [templateList addObject:self.sameMVTemplate];
        [templateIDs addObject:@(self.sameMVTemplate.templateID)];
    }
    
    [effects enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        id<ACCMVTemplateModelProtocol> template = [IESAutoInline(ACCBaseServiceProvider(), ACCModelFactoryServiceProtocol) createMVTemplateWithEffectModel:obj urlPrefix:urlPrefix];
        if (template) {
            if (!self.sameMVTemplate || template.templateID != self.sameMVTemplate.templateID) {
                [templateList addObject:template];
                [templateIDs addObject:@(template.templateID)];
            }
        }
    }];
    
    NSUInteger lengthPerRange = 20;
    NSMutableDictionary<NSNumber *, id<ACCMVTemplateModelProtocol> > *allTemplateModelDict = [NSMutableDictionary dictionary];
    dispatch_group_t group = dispatch_group_create();
    for (NSUInteger index = 0; index < (templateIDs.count / lengthPerRange + (templateIDs.count % lengthPerRange > 0 ? 1 : 0)); index ++) {
        NSUInteger start = index * lengthPerRange;
        NSUInteger length = lengthPerRange;
        if (start + length > templateIDs.count) {
            length = templateIDs.count - start;
        }
        NSRange range = NSMakeRange(start, length);
        
        dispatch_group_enter(group);
        [ACCMVTemplatesFetch() getClassicalMVFavoriteStateWithTemplateIDs:[templateIDs subarrayWithRange:range] simplify:YES completion:^(NSDictionary<NSNumber *,id<ACCMVTemplateModelProtocol> > * _Nullable templateModelDict, NSError * _Nullable error) {
            if (templateModelDict) {
                [allTemplateModelDict addEntriesFromDictionary:templateModelDict];
            }
            dispatch_group_leave(group);
        }];
    }
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        NSMutableArray *finalEffects = [NSMutableArray array];
        [templateList enumerateObjectsUsingBlock:^(id<ACCMVTemplateModelProtocol> obj, NSUInteger idx, BOOL * _Nonnull stop) {
            id<ACCMVTemplateModelProtocol> stateModel = [allTemplateModelDict objectForKey:@(obj.templateID)];
            if (stateModel) {
                obj.usageAmount = stateModel.usageAmount;
                obj.isCollected = stateModel.isCollected;
            }
            if (obj.effectModel) {
                [finalEffects addObject:obj.effectModel];
            }
        }];
        self.isRefreshing = NO;
        [[AWEMVTemplateModel sharedManager] updateTemplateModels:finalEffects];
        [self.dataSource removeAllObjects];
        [self.dataSource addObjectsFromArray:templateList];
        ACCBLOCK_INVOKE(completion, nil, templateList, self.hasMore);
    });
}



@end
