//
//  CJPayCaptureFeatureCollector.m
//  CJPaySandBox
//
//  Created by wangxinhua on 2023/5/22.
//

#import "CJPayCaptureFeatureCollector.h"
#import "CJPayFeatureCollectorManager.h"
#import "CJPaySafeFeatures.h"
#import "CJPaySDKMacro.h"

NSString *const kFeatureName = @"Capture";
@interface CJPayCaptureFeatureCollector()

@property (nonatomic, assign) BOOL isAllowRunning;
@property (nonatomic, strong) CJPayIntentionFeature *lastestFeature;

@end

@implementation CJPayCaptureFeatureCollector

@synthesize recordManager;

- (instancetype)init {
    self = [super init];
    // 截屏监听
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_screenShotDetected) name:UIApplicationUserDidTakeScreenshotNotification object:nil];
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


/// 发生了截屏行为
- (void)p_screenShotDetected {
    
    CJPayIntentionFeature *feature = [CJPayIntentionFeature new];
    feature.name = kFeatureName;
    feature.timeStamp = [[NSDate new] timeIntervalSince1970];
    feature.needPersistence = YES;
    // 缺失上下文的情况没必要存储
    if ([self.recordManager respondsToSelector:@selector(getContext)]) {
        CJPayFeatureCollectContext *context = [self.recordManager getContext];
        feature.page = context.page;
        if (!Check_ValidString(context.page)) {
            return;
        }
    } else {
        return;
    }
    // 需要落到缓存
    if ([self.recordManager respondsToSelector:@selector(recordFeature:)]) {
        [self.recordManager recordFeature:feature];
    }
    // 记录最近一次截屏行为
    self.lastestFeature = feature;
}

- (void)beginCollect {
    // 非敏感行为，所以在初始化配置
}

- (void)endCollect {
    // 非敏感行为，所以在初始化配置
}

- (NSDictionary *)buildIntentionParams {
    NSMutableDictionary *mutableDictionary = [NSMutableDictionary new];
    if (!self.lastestFeature) {
        self.lastestFeature = [self.recordManager allFeaturesFor:kFeatureName conditionBlock:^BOOL(CJPayBaseSafeFeature * _Nonnull obj) {
            return YES;
        }].lastObject;
    }
    if (self.lastestFeature) {
        static NSDateFormatter *dateFormatter;
        if (!dateFormatter) {
            dateFormatter = [[NSDateFormatter alloc] init];
            dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        }
        NSString *timeStr = [dateFormatter stringFromDate:[[NSDate alloc] initWithTimeIntervalSince1970:self.lastestFeature.timeStamp]];
        [mutableDictionary cj_setObject:@{
            @"screenshot_page": CJString(self.lastestFeature.page),
//            @"screenshot_timestamp": @(self.lastestFeature.timeStamp),
            @"screenshot_time": CJString(timeStr),
        } forKey:@"latest_screenshot_message"]; //最近一次截屏发生的页面
    }
    
    NSTimeInterval lastest24 = [[NSDate new] timeIntervalSince1970] - 24 * 3600;
    NSArray *features = [self.recordManager allFeaturesFor:kFeatureName conditionBlock:^BOOL(CJPayBaseSafeFeature * _Nonnull obj) {
        if ([obj isKindOfClass:CJPayIntentionFeature.class]) {
            CJPayIntentionFeature *fea = (CJPayIntentionFeature *)obj;
            return fea.timeStamp > lastest24;
        }
        return NO;
    }];
    [mutableDictionary cj_setObject:@([features count]) forKey:@"screenshot_count_24h"]; // 最近24小时的截屏次数
    return [mutableDictionary copy];
}

- (NSDictionary *)buildDeviceParams {
    return @{};
}

@end
