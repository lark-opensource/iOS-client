//
//  IESFalconStatRecorder.m
//  Pods
//
//  Created by 陈煜钏 on 2019/10/8.
//

#import "IESFalconStatRecorder.h"

#import <sys/utsname.h>
#import <sys/sysctl.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <BDWebKit/BDWebKitVersion.h>
#import "IESFalconInfo.h"
#import "IESFalconCustomInterceptor.h"
#import <BDTrackerProtocol/BDTrackerProtocol.h>

static dispatch_queue_t IESFalconRecordStatQueue (void);

static NSString *IESFalconCurrentConnectionString (void);

static NSString * const kIESFalconStatURLPath = @"/gecko/server/falcon/stats";

@interface IESFalconStatRecorder ()

@property (nonatomic, strong) NSMutableArray *statArray;

@end

@implementation IESFalconStatRecorder

+ (IESFalconStatRecorder *)sharedInstance
{
    static IESFalconStatRecorder *recorder = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        recorder = [[self alloc] init];
        [recorder setup];
    });
    return recorder;
}

#pragma mark - Public

+ (void)recordFalconStat:(NSDictionary *)statDictionary
{
    if (![statDictionary isKindOfClass:[NSDictionary class]]) {
        return;
    }
    NSMutableDictionary *stat = [NSMutableDictionary dictionaryWithDictionary:statDictionary];
    stat[@"ac"] = IESFalconCurrentConnectionString();
    
    dispatch_async(IESFalconRecordStatQueue(), ^{
        __block BOOL sendStat = NO;
        IESFalconStatRecorder *recorder = [self sharedInstance];
        @synchronized (recorder) {
            [recorder.statArray addObject:[stat copy]];
            sendStat = (recorder.statArray.count >= 20);
        }
        if (sendStat) {
            [recorder _sendFalconStatIfNeeded];
        }
    });
}

#pragma mark - Private

- (void)setup
{
    NSTimer *timer = [NSTimer timerWithTimeInterval:60
                                             target:self
                                           selector:@selector(_sendFalconStatIfNeeded)
                                           userInfo:nil
                                            repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
}

- (void)_sendFalconStatIfNeeded
{
    if (!IESFalconInfo.deviceId) {
        return;
    }
    __block NSArray *statArray = nil;
    @synchronized (self) {
        if (self.statArray.count > 0) {
            statArray = [self.statArray copy];
            [self.statArray removeAllObjects];
        }
    }
    if (!statArray) {
        return;
    }
    [self _sendFalconStat:statArray];
}

- (void)_sendFalconStat:(NSArray *)statArray
{
    [statArray enumerateObjectsUsingBlock:^(NSDictionary *stat, NSUInteger idx, BOOL * _Nonnull stop) {
        NSMutableDictionary *params = [NSMutableDictionary new];
        params[@"params_for_special"] = @"gecko";
        [params addEntriesFromDictionary:[self falconCommonParams]];
        [params addEntriesFromDictionary:stat];
        [BDTrackerProtocol eventV3:@"geckosdk_falcon" params:params];
    }];
    
    [self _sendFalconStatWithArray:statArray remainTimes:3];
}

- (void)_sendFalconStatWithArray:(NSArray *)statArray remainTimes:(NSInteger)remainTimes
{
    if (statArray.count == 0) {
        return;
    }
    if (remainTimes == 0) {
        @synchronized (self) {
            [self.statArray addObjectsFromArray:statArray];
        }
        return;
    }
    NSDictionary *params = @{ @"common" : [self falconCommonParams],
                              @"offline" : statArray };
    [self _sendFalconStatWithParams:params completion:^(BOOL succeed) {
        if (!succeed) {
            [self _sendFalconStatWithArray:statArray remainTimes:remainTimes - 1];
        }
    }];
}

- (void)_sendFalconStatWithParams:(NSDictionary *)params completion:(void (^)(BOOL succeed))completion
{
    NSString *URLString = [NSString stringWithFormat:@"%@%@", IESFalconInfo.platformDomain, kIESFalconStatURLPath];
    NSURL *URL = [NSURL URLWithString:URLString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:params options:0 error:NULL];

    
    // 下掉向/gecko/server/falcon/stats的上报,之后需要加alog
    return;
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        BOOL succeed = NO;
        if ([data isKindOfClass:[NSData class]]) {
            NSDictionary *response = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
            if ([response isKindOfClass:[NSDictionary class]]) {
                NSNumber *status = response[@"status"];
                if ([status isKindOfClass:[NSNumber class]]) {
                    succeed = (status.integerValue == 0);
                }
            }
        }
        !completion ? : completion(succeed);
    }] resume];
}

- (NSDictionary *)falconCommonParams
{
    static NSMutableDictionary *params = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        params = [NSMutableDictionary dictionary];
        
        size_t size;
        sysctlbyname("hw.machine", NULL, &size, NULL, 0);
        char *machine = malloc(size);
        sysctlbyname("hw.machine", machine, &size, NULL, 0);
        NSString * machineModel = [NSString stringWithUTF8String:machine];
        free(machine);
        params[@"device_model"] = machineModel ? : @"unknown";
        
        params[@"os"] = @(1);
        params[@"app_version"] = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ? : @"unknown";
        params[@"sdk_version"] = BDWebKitVersion ? : @"unknown";
    });
    
    __block NSDictionary *result = nil;
    @synchronized (params) {
        NSString *localeIdentifier = [[NSLocale currentLocale] objectForKey:NSLocaleIdentifier];
        params[@"region"] = [localeIdentifier componentsSeparatedByString:@"_"].lastObject ? : @"unknown";
        params[@"device_id"] = IESFalconInfo.deviceId;
        
        result = [params copy];
    }
    return result ? : @{};
}

#pragma mark - Getter

- (NSMutableArray *)statArray
{
    if (!_statArray) {
        _statArray = [NSMutableArray array];
    }
    return _statArray;
}

@end

dispatch_queue_t IESFalconRecordStatQueue (void) {
    static dispatch_queue_t queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_DEFAULT, 0);
        queue = dispatch_queue_create("com.IESFalcon.RecordStatQueue", attr);
    });
    return queue;
}

NSString *IESFalconCurrentConnectionString (void) {
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(NULL, "8.8.8.8");
    SCNetworkReachabilityFlags flags;
    BOOL success = SCNetworkReachabilityGetFlags(reachability, &flags);
    CFRelease(reachability);
    if (!success) {
        return @"unknown";
    }
    BOOL isReachable = ((flags & kSCNetworkReachabilityFlagsReachable) != 0);
    BOOL needsConnection = ((flags & kSCNetworkReachabilityFlagsConnectionRequired) != 0);
    BOOL isNetworkReachable = (isReachable && !needsConnection);
    
    if (!isNetworkReachable) {
        return @"unknown";
    }
    if ((flags & kSCNetworkReachabilityFlagsIsWWAN) != 0) {
        return @"WWAN";
    }
    return @"WiFi";
}
