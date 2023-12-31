//
//  ACCRecognitionWrapper.m
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/6/16.
//

#import "ACCRecognitionScannerWrapper.h"
#import <SmartScan/SSTypeConverter.h>
#import <SmartScan/SSSmartScanner.h>
#import <DavinciResource/DAVNetworkCreator.h>
#import <CreationKitRTProtocol/ACCCameraService.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIImage+ACC.h>
#import <CreationKitInfra/ACCDeviceInfo.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreationKitArch/ACCModuleConfigProtocol.h>
#include <EffectSDK_iOS/bef_effect_api.h>
#import <CreationKitInfra/ACCConfigManager.h>
#import <CameraClient/ACCIronManServiceProtocol.h>
#import <ByteDanceKit/UIApplication+BTDAdditions.h>
#import <CameraClient/ACCBlockSequencer.h>
#import "ACCRecognitionService.h"
#import <CameraClient/ACCRecognitionTrackModel.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitInfra/ACCLogHelper.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import <ReactiveObjC/RACSignal+Operations.h>
#import <ReactiveObjC/NSObject+RACPropertySubscribing.h>
#import <ReactiveObjC/NSObject+RACDeallocating.h>
#import <SmartScan/NSString+SSURLUtil.h>
#import <CameraClient/ACCRecognitionEnumerate.h>
#import <TTNetworkManager/TTNetworkManager.h>

@interface ACCRecognitionScannerParamInner : NSObject
@property (nonatomic,   copy) ACCRecognitionScanBlock recognizeCompletion;
@property (nonatomic,   copy) NSString *modes;
@end
@implementation ACCRecognitionScannerParamInner
@end

#define RUN_BLOCK(block, ...)   (void)(block ? block(__VA_ARGS__): (void)0)

@interface ACCRecognitionScannerWrapper()<SSImageBufferProducerDelegate>
@property (nonatomic, assign) NSInteger autoScanExeId;
@property (nonatomic, assign) NSInteger recommendScanExeId;
@property (nonatomic, strong) SSSmartScanner *scanner;
@property (nonatomic, strong) ACCRecognitionScannerParamInner *innerParam;
@property (nonatomic, strong) ACCBlockSequencer *recommendSeq;
@property (nonatomic, strong) ACCBlockSequencer *autoScanSeq;
@property (nonatomic, strong) NSString *effectParams;
@property (nonatomic, strong) SSSmartScanConfig *config;

@end

@implementation ACCRecognitionScannerWrapper

- (instancetype)init{
    if (self = [super init]){
        [self setup];
    }
    return self;
}

- (void)setup
{
    self.autoScanExeId = -1;
    self.recommendScanExeId = -1;

    SSSmartScanConfig *config = [[SSSmartScanConfig alloc] init];
    config.netType = SSNetType_TTNet;
    config.appID = [ACCDeviceInfo acc_appID];
    auto effectConfig = IESAutoInline(ACCBaseServiceProvider(), ACCModuleConfigProtocol);

    config.accessKey = effectConfig.effectPlatformAccessKey; // @"142710f02c3a11e8b42429f14557854a"; //在特效后台申请应用的accessKey，必需
    config.channel = @"online"; //channel 只有test，local_test为测试平台，“online“是线上平台。必需

    char version[10] = {0};
#if !TARGET_IPHONE_SIMULATOR
    bef_effect_get_sdk_version(version,sizeof(version));
#endif
    NSString *effectSDKVersion = [[NSString alloc] initWithUTF8String:version];

    config.effectSdkVersion = effectSDKVersion; //对应effectSDK版本，a.b.c三位，用于过滤低版本不支持的特效，必需

    config.appVersion = [UIApplication btd_versionName]; //对应自己的app版本，用于过滤低版本不支持的特效，必需
    id<ACCIronManServiceProtocol> ironman = IESAutoInline(ACCBaseServiceProvider(), ACCIronManServiceProtocol);
    config.deviceType = [ironman getDeviceName]; //设备型号，用于过滤该机型不支持的特效，一般传入Build.MODEL，必需
    config.deviceId = [ACCTracker() deviceID]; //@"1355015227456167";  //设备id，传递"0"即可，必需

    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) firstObject];
    NSString *cacheDir = [documentPath stringByAppendingPathComponent:@"com.bytedance.ies/smartscan_cache"];
    if(![[NSFileManager defaultManager] fileExistsAtPath:cacheDir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:cacheDir
                                         withIntermediateDirectories:YES
                                                          attributes:nil
                                                               error:nil];
    }
    config.modelCacheDir = cacheDir;
    config.platform = @"ios";

    config.modelApiHost = effectConfig.effectRequestDomainString;
    [config setImageBufferProducer:self];
    self.config = config;

    self.scanner = [[SSSmartScanner alloc] initWithConfig:config];
}

- (void)setRecognitionService:(id<ACCRecognitionService>)recognitionService
{
    _recognitionService = recognitionService;

    @weakify(self)
    [[RACObserve(recognitionService, recognitionMessage) takeUntil:self.rac_willDeallocSignal] subscribeNext:^(IESMMEffectMessage *  _Nullable x) {
        @strongify(self)
        if (x.msgId == ACCRecognitionMsgRecognizedSpecies &&
            x.arg1 == ACCRecognitionMsgTypeReceiveRequestParameters){
            self.effectParams = x.arg3;
        }
    }];
}

- (BOOL)startAutoScanWithFliter:(ACCRecognitionAutoScanFilterBlock)filter completion:(ACCRecognitionAutoScanBlock)completion
{
    if (self.autoScanSeq || self.autoScanExeId >= 0){
        RECOG_LOG(@"autoscan running")
        return NO;
    }
    if (!completion){
        RECOG_LOG(@"completion is nil")
        return NO;
    }

    __block auto comp = completion;
    self.autoScanSeq = [[[ACCBlockSequencer sequencerWithBlock:^(id res, ACCSeqNextBlock next) {
        /// prefetch models
        RECOG_LOG(@"prefetch model")
        [self.scanner prefetchModels:SSAlgorithmType_Recognition completion:^(BOOL success) {
            next(success? @YES : [NSError errorWithDomain:@"SmartScanError" code:500 userInfo:@{@"message":@"prefetch models failed"}]);
        }];
    }] then:^(id res, ACCSeqNextBlock next) {
        
        RECOG_LOG(@"try autoscan")
        /// auto scan
        SSScanParams *params = [[SSScanParams alloc] init];
        params.scanInterval = 1000;
        params.algType = SSAlgorithmType_Recognition;
        self.autoScanExeId = [self.scanner startAutoScan:params onResult:^(long execID, NSError *error, SSScanResult *result) {
            if (error){
                next(error);
            }else if (filter && filter(result) && comp){
                comp(result, nil);
                comp = nil;
                next(nil);
            }
            self.autoScanSeq = nil;
        }];
    }] error:^(NSError *error){
        completion(nil, error);
        self.autoScanSeq = nil;
    }];
    [self.autoScanSeq run];

    return YES;
}

- (void)stopAutoScan
{
    RECOG_LOG(@"stop autoscan")
    [self.scanner stopAutoScan:self.autoScanExeId];
    self.autoScanExeId = -1;
//    self.autoCompletion = nil;
}

- (void)obtainImageBuffer:(nonnull id<SSImageBufferCallBackDelegate>)callback {

    RECOG_LOG(@"obtain image")
    
    if (self.autoScanExeId == -1 && self.recommendSeq == nil) {
        return;
    }

    

    auto begin = CACurrentMediaTime()*1000;
    [self.cameraService.recorder captureSourcePhotoAsImageByUser:NO completionHandler:^(UIImage * _Nullable image, NSError * _Nullable error) {
        auto t1 = CACurrentMediaTime()*1000 - begin;

        image = [image downsampleToSize:CGSizeMake(360, 640) interpolationQuality:kCGInterpolationMedium];
        auto t2 = CACurrentMediaTime()*1000 - begin;

        long long size = 0;
        unsigned char *picPtr = rgbaImageBufferOfImage(image, &size);
        if (size == 0){
            [callback onImageBufferObtainComplete:NULL];
            /// 线上监控显示，即使size为0，也有几个占位的字节
            free(picPtr);
            return;
        }
        SSImageBuffer *buffer = [SSImageBuffer new];
        buffer.width = image.size.width;
        buffer.height = image.size.height;
        buffer.data = picPtr;
        buffer.length = size;
        RECOG_LOG(@"return image size:%@", @(size));
        auto t3 = CACurrentMediaTime()*1000 - begin;

        [callback onImageBufferObtainComplete:buffer];
        auto t4 = CACurrentMediaTime()*1000 - begin;

        [ACCTracker() trackEvent:@"smart_scan_capture_duration"
                          params:@{@"t1":@(t1),
                                   @"t2":@(t2),
                                   @"t3":@(t3),
                                   @"t4":@(t4),
         } needStagingFlag:NO];

    } afterProcess:NO];

}


#define CHECK_RES(cls) \
if (![res isKindOfClass:[cls class]]){ \
next([NSError errorWithDomain:@"SmartScanError" code:500 userInfo:@{@"message":@"wrong data:" @ #cls}]); \
    return; \
}

/// clearity -> object -> recommend
- (void)scanForRecognizeWithMode:(NSString *)mode completion:(ACCRecognitionScanBlock)completion
{
    if (self.recommendSeq){
        completion(nil, [NSError errorWithDomain:@"SmartScanError" code:408 userInfo:@{@"message":@"smart scan is busy, try again later"}]);
        return;
    }

    /// clear previous effect params
    self.effectParams = nil;

    self.recommendSeq = [[[[[[[ACCBlockSequencer sequencerWithBlock:^(id res, ACCSeqNextBlock next) {
        /// step 0.1: fetch effect params
        auto msg = [IESMMEffectMessage messageWithType:(IESMMEffectMsg)ACCRecognitionMsgRecognizedSpecies];
        msg.arg1 = ACCRecognitionMsgTypeSendRequestForParameters;
        [self.cameraService.message sendMessageToEffect:msg];

        next(nil); /// run next step immediately
    }] then:^(id res, ACCSeqNextBlock next) {
        RECOG_LOG(@"prefetch models")
        /// step 0.2: prefetch models
        [self.scanner prefetchModels:SSAlgorithmType_Recognition|SSAlgorithmType_Grading completion:^(BOOL success) {
            next(success? @YES: [NSError errorWithDomain:@"SmartScanError" code:500 userInfo:@{@"msg":@"prefetch models failed"}]);
        }];

    }] then:^(id res, ACCSeqNextBlock next) {

        RECOG_LOG(@"clear image")
        /// step 1: recognize clear image
        SSClearImageRecParams *params = [SSClearImageRecParams new];
        params.idealThreshold = [self.recognitionService thresholdFor:ACCRecognitionThreasholdClarityIeal];
        params.failureThreshold = [self.recognitionService thresholdFor:ACCRecognitionThreasholdClarityFail];
        params.maxLoopTimes = 5;

        [self.scanner clearImageRecognize:params completion:^(NSError *error, SSImageGradingResult *result) {
            next(result? result: error);
        }];

    }] then:^(SSImageGradingResult * res, ACCSeqNextBlock next) {
        CHECK_RES(SSImageGradingResult)

        RECOG_LOG(@"object recognize")
        /// step 2: object recognize
        SSObjectRecParams *params = [SSObjectRecParams new];
        params.imageBuffer = res.imageBuffer;
        [self.scanner objectRecognize:params completion:^(NSError *error, SSImageRecognitionResult *result) {
            next(result? result: error);
        }];

    }] then:^(SSImageRecognitionResult * res, ACCSeqNextBlock next) {
        CHECK_RES(SSImageRecognitionResult)
        RECOG_LOG(@"recommend")
        /// step 3: server side recommend
        SSRecommendParams *params = [[SSRecommendParams alloc] init];
        [params setJpegDataByImageBuffer:res.imageBuffer];
        params.requestType = SSNetRequestType_Post; /// POST
        NSMutableDictionary *md = [@{
            @"detect_modes": mode,
            @"reality_id": self.recognitionService.trackModel.realityId ?:@"",
            @"conf": self.effectParams ?: @""
        } mutableCopy];
        auto block = [TTNetworkManager.shareInstance commonParamsblock];

        NSDictionary *commonParams = block? block() : nil;
        /// format to NSString
        [commonParams enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            [md setValue:[NSString stringWithFormat:@"%@", obj] forKey:key];
        }];

        params.queryParams = md.copy;
        params.headers = @{
            @"Content-Type":@"application/octet-stream",
        };

        params.url = @"https://aweme.snssdk.com/media/api/scan/aweme/shoot/detect/";
        [self.scanner scanForRecommend:params completionBlock:^(NSError *error, SSRecommendResult *result) {
            next(result ? result : error);
        }];

    }] completion:^(id res) {

        completion(res, nil);

        self.recommendSeq = nil;
    }] error:^(NSError *error) {
        completion(nil, error);
        self.recommendSeq = nil;
    }];

    [self.recommendSeq run];
}

- (void)cancelRecognizeScanning
{
    RECOG_LOG(@"cancel recognize scanning")
    [self.recommendSeq stop];
    self.recommendSeq = nil;
}

#pragma mark - Util
unsigned char * rgbaImageBufferOfImage(UIImage *image, long long *size) {

    // First get the image into your data buffer
    CGImageRef imageRef = [image CGImage];
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    *size = height * width * 4;
    unsigned char *rawData = (unsigned char*) calloc(height * width * 4, sizeof(unsigned char));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                    bitsPerComponent, bytesPerRow, colorSpace,
                    kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    return rawData;
}

@end

