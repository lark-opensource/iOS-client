//
//  ACCMeasureComponent.m
//  Pods
//
//  Created by 郝一鹏 on 2019/8/11.
//

#import "ACCMeasureComponent.h"
// sinkage
#import "ACCMeasureOnceItem.h"
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CreativeKit/ACCComponentManager.h>
#import <CreativeKit/ACCMacros.h>

@interface ACCMeasureComponent ()

@property (nonatomic, readonly) NSString *prefixString;
@property (nonatomic, strong) NSDictionary<NSNumber *, ACCMeasureOnceItem *> *vcLifeCycleStageToItemMap;
@property (nonatomic, strong) NSMutableDictionary *customReportData;

@property (nonatomic, strong) ACCMeasureOnceItem *viewControllerInitItem;

// viewDidLoad
@property (nonatomic, strong) ACCMeasureOnceItem *viewDidLoadStartItem;
@property (nonatomic, strong) ACCMeasureOnceItem *viewDidLoadEndItem;

// viewWillAppear
@property (nonatomic, strong) ACCMeasureOnceItem *viewWillAppearItem;
// viewDidAppear
@property (nonatomic, strong) ACCMeasureOnceItem *viewDidAppearItem;

@property (nonatomic, assign) BOOL didReportViewControllerLifeCycleData;

@property (nonatomic, copy) NSString *customPrefixString;
@property (nonatomic, copy) NSDictionary *extraData;

@end

@implementation ACCMeasureComponent

#pragma mark - life cycle

- (instancetype)initWithContext:(id<IESServiceProvider>)context
{
    self = [super initWithContext:context];
    if (self) {
        _viewControllerInitItem = [[ACCMeasureOnceItem alloc] initWithName:@"vcInit"];
        _viewDidLoadStartItem = [[ACCMeasureOnceItem alloc] initWithName:@"viewDidLoadStart"];
        _viewDidLoadEndItem = [[ACCMeasureOnceItem alloc] initWithName:@"viewDidLoadEnd"];
        _viewWillAppearItem = [[ACCMeasureOnceItem alloc] initWithName:@"viewWillAppear"];
        _viewDidAppearItem = [[ACCMeasureOnceItem alloc] initWithName:@"viewDidAppear"];
        _customReportData = [@{} mutableCopy];
        _viewControllerInitItem.timestamp = [self p_currentTimeInterval];
    }
    return self;
}

- (void)componentDidMount
{
    self.viewDidLoadStartItem.timestamp = [self p_currentTimeInterval];
    @weakify(self);
    [self.controller.componentManager registerMountCompletion:^{
        @strongify(self);
        self.viewDidLoadEndItem.timestamp = [self p_currentTimeInterval];
    }];
}

- (void)componentWillAppear
{
    self.viewWillAppearItem.timestamp = [self p_currentTimeInterval];
}

- (void)componentDidAppear
{
    self.viewDidAppearItem.timestamp = [self p_currentTimeInterval];
    [self postViewControllerLifeCycleData];
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

#pragma mark -

- (void)recordTimeIntervalWithSuffixName:(NSString *)suffixName
                            timeInterval:(NSTimeInterval)timeInterval
                  relateToLifeCycleStage:(ACCVCLifeCycleStage)stage
{
    ACCMeasureOnceItem *measureTtem = self.vcLifeCycleStageToItemMap[@(stage)];
    if (!measureTtem) {
        return;
    }
    NSString *stageString = measureTtem.name;
    NSTimeInterval stageTimeStamp = self.vcLifeCycleStageToItemMap[@(stage)].timestamp;
    NSString *reportName = [self getReportKeyForBeginString:suffixName endString:stageString];
    NSTimeInterval reportTimeInterval = stageTimeStamp - timeInterval;
    self.customReportData[reportName] = @(reportTimeInterval);
}

#pragma mark - report

- (void)postViewControllerLifeCycleData
{
    if (self.didReportViewControllerLifeCycleData) {
        return;
    }
    NSMutableDictionary *viewControllerReportData = [[self getViewControllerLifeCycleData] mutableCopy];
    [viewControllerReportData addEntriesFromDictionary:self.customReportData];
    [viewControllerReportData addEntriesFromDictionary:self.extraData];
    self.customReportData = [@{} mutableCopy];
    NSString *formatString = @"%@_life_cycle_measure_service";
    NSString *prefixString = [self defaultPrefixString];
    NSString *viewControllerReportServiceName = [NSString stringWithFormat:formatString, prefixString];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [ACCMonitor() trackService:[viewControllerReportServiceName copy]
                         status:0
                          extra:viewControllerReportData];
    });
    self.didReportViewControllerLifeCycleData = YES;
}

- (NSDictionary *)getViewControllerLifeCycleData
{
    NSMutableDictionary *viewControllerLifeCycleReportData = [@{} mutableCopy];
    
    [self setLifeCycleDataForDictionary:viewControllerLifeCycleReportData
                       beginMeasureItem:self.viewControllerInitItem
                         endMeasureItem:self.viewDidLoadStartItem];
    
    [self setLifeCycleDataForDictionary:viewControllerLifeCycleReportData
                       beginMeasureItem:self.viewDidLoadStartItem
                         endMeasureItem:self.viewDidLoadEndItem];
    
    [self setLifeCycleDataForDictionary:viewControllerLifeCycleReportData
                       beginMeasureItem:self.viewDidLoadEndItem
                         endMeasureItem:self.viewWillAppearItem];
    
    [self setLifeCycleDataForDictionary:viewControllerLifeCycleReportData
                       beginMeasureItem:self.viewWillAppearItem
                         endMeasureItem:self.viewDidAppearItem];
    
    return viewControllerLifeCycleReportData;
}

- (void)setLifeCycleDataForDictionary:(NSMutableDictionary *)dictionary
                     beginMeasureItem:(ACCMeasureOnceItem *)beginMeasureItem
                       endMeasureItem:(ACCMeasureOnceItem *)endMeasureItem
{
    NSString *key = [self getReportKeyForBeginMeasureItem:beginMeasureItem
                                           endMeasureItem:endMeasureItem];
    
    NSTimeInterval timeInterval = [self getTimeIntervalForBeginMeasureItem:beginMeasureItem
                                                            endMeasureItem:endMeasureItem];
    
    NSString *value = [NSString stringWithFormat:@"%f ms", timeInterval * 1000];
    dictionary[key] = value;
}

- (void)setLifeCycleDataForDictionary:(NSMutableDictionary *)dictionary
                           suffixName:(NSString *)suffixName
                    beginTimeInterval:(NSTimeInterval)beginTimeInterval
                      endTimeInterval:(NSTimeInterval)endTimeInterval
{
    
}

- (NSString *)getReportKeyForBeginMeasureItem:(ACCMeasureOnceItem *)beginMeasureItem
                               endMeasureItem:(ACCMeasureOnceItem *)endMeasureItem
{
    NSString *prefix = self.prefixString;
    NSString *reportKey = [self getReportKeyForBeginString:beginMeasureItem.name
                                                 endString:endMeasureItem.name];
    return [NSString stringWithFormat:@"%@_%@", prefix, reportKey];
}

- (NSString *)getReportKeyForBeginString:(NSString *)beginString
                               endString:(NSString *)endString
{
    return [NSString stringWithFormat:@"%@_to_%@", beginString, endString];
}

- (NSTimeInterval)getTimeIntervalForBeginMeasureItem:(ACCMeasureOnceItem *)beginMeasureItem
                                      endMeasureItem:(ACCMeasureOnceItem *)endMeasureItem
{
    return endMeasureItem.timestamp - beginMeasureItem.timestamp;
}

- (NSDictionary *)vcLifeCycleStageToItemMap
{
    if (!_vcLifeCycleStageToItemMap) {
        _vcLifeCycleStageToItemMap = @{
                                       @(ACCVCLifeCycleStageInit) : self.viewControllerInitItem,
                                       @(ACCVCLifeCycleStageViewDidLoadStart) : self.viewDidLoadStartItem,
                                       @(ACCVCLifeCycleStageViewDidLoadEnd) : self.viewDidLoadEndItem,
                                       @(ACCVCLifeCycleStageViewWillAppear) : self.viewWillAppearItem,
                                       @(ACCVCLifeCycleStageViewDidAppear) : self.viewDidAppearItem,
                                       };
    }
    return _vcLifeCycleStageToItemMap;
}

- (NSTimeInterval)p_currentTimeInterval
{
    return [[NSDate date] timeIntervalSince1970];
}

- (NSString *)prefixString
{
    return self.customPrefixString ?: [self defaultPrefixString];
}

- (NSString *)defaultPrefixString
{
    return NSStringFromClass(self.controller.root.class);
}


@end
