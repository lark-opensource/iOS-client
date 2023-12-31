//
//  TTVideoEngineStartUpSelector.m
//  TTVideoEngine
//
//  Created by haocheng on 2021/7/14.
//

#import "TTVideoEngineStartUpSelector.h"
#import "TTVideoEngine+Preload.h"
#import "TTVideoEngineUtilPrivate.h"
#import "TTVideoEngineNetworkPredictorAction.h"
#import "TTVideoEngineActionManager.h"
#import "TTVideoEnginePlayBaseSource.h"

NSString *kAudioMediaTypeKey = @"audio";
NSString *kVideoMediaTypeKey = @"video";

@interface _TTVideoEngineStartUpSelector()
@property (nonatomic, strong) id<IVCABRModule> abrModule;
@property (nonatomic, assign) int scene;
@end

@interface _TTVideoEngineSelectorVideoStream : NSObject<IVCABRVideoStream>
@property (nonatomic, assign) int brandWidth;
@property (nonatomic, copy) NSString *codec;
@property (nonatomic, assign) int segmentDuration;
@property (nonatomic, copy) NSString *streamId;
@property (nonatomic, assign) float frameRate;
@property (nonatomic, assign) int height;
@property (nonatomic, assign) int width;
@end
@implementation _TTVideoEngineSelectorVideoStream
- (int)getBandwidth {
    return self.brandWidth;
}
- (nullable NSString *)getCodec {
    return self.codec;
}
- (int)getSegmentDuration {
    return self.segmentDuration;
}
- (nullable NSString *)getStreamId {
    return self.streamId;
}
- (float)getFrameRate {
    return self.frameRate;
}
- (int)getHeight {
    return self.height;
}
- (int)getWidth {
    return self.width;
}
@end

@interface _TTVideoEngineSelectorAudioStream : NSObject<IVCABRAudioStream>
@property (nonatomic, assign) int brandWidth;
@property (nonatomic, copy) NSString *codec;
@property (nonatomic, assign) int segmentDuration;
@property (nonatomic, copy) NSString *streamId;
@property (nonatomic, assign) int sampleRate;
@end
@implementation _TTVideoEngineSelectorAudioStream
- (int)getBandwidth {
    return self.brandWidth;
}
- (nullable NSString *)getCodec {
    return self.codec;
}
- (int)getSegmentDuration {
    return self.segmentDuration;
}
- (nullable NSString *)getStreamId {
    return self.streamId;
}
- (int)getSampleRate {
    return self.sampleRate;
}
@end

@interface _TTVideoEngineSelectorABRDeviceInfo : NSObject <IVCABRDeviceInfo>
@property (nonatomic, assign) int width;
@property (nonatomic, assign) int height;
- (instancetype)initWithWidth:(int)width height:(int)height;
@end

@implementation _TTVideoEngineSelectorABRDeviceInfo
- (instancetype)initWithWidth:(int)width height:(int)height {
    self = [super init];
    if (self) {
        self.width = width;
        self.height = height;
    }
    return self;
}
- (int)getScreenWidth {
    return self.width;
}
- (int)getScreenHeight {
    return self.height;
}
- (int)getScreenFps {
    //todo c: same as android
    return -1;
}
- (int)getHWDecodeMaxLength {
    //todo c: same as android
    return -1;
}
- (int)getHDRInfo {
    //todo c: same as android
    return -1;
}
@end

@interface _TTVideoEngineSelectorParams()

@property (nonatomic, assign) long expectedBitRate;
@property (nonatomic, assign) long defaultWifiBitRate;
@property (nonatomic, assign) long startUpMaxBitrate;
@property (nonatomic, assign) long cellularMaxBitrate;
@property (nonatomic, assign) long downgradeBitrate;
@property (nonatomic, assign) long defaultCellularBitrate;
@property (nonatomic, assign) long startupMinBitrate;

@property (nonatomic, assign) TTVideoEngineResolutionType expectedResolution;
@property (nonatomic, assign) TTVideoEngineResolutionType defaultWifiResolution;
@property (nonatomic, assign) TTVideoEngineResolutionType startUpMaxResolution;
@property (nonatomic, assign) TTVideoEngineResolutionType cellularMaxResolution;
@property (nonatomic, assign) TTVideoEngineResolutionType downgradeResolution;
@property (nonatomic, assign) TTVideoEngineResolutionType defaultCellularResolution;
@property (nonatomic, assign) TTVideoEngineResolutionType startupMinResolution;

@property (nonatomic, copy) NSDictionary *expectedQuality;
@property (nonatomic, copy) NSDictionary *defaultWifiQuality;
@property (nonatomic, copy) NSDictionary *startUpMaxQuality;
@property (nonatomic, copy) NSDictionary *cellularMaxQuality;
@property (nonatomic, copy) NSDictionary *downgradeQuality;
@property (nonatomic, copy) NSDictionary *defaultCellularQuality;
@property (nonatomic, copy) NSDictionary *startUpMinQuality;

@property (nonatomic, assign) int screenWidth;
@property (nonatomic, assign) int screenHeight;
@property (nonatomic, assign) int displayWidth;
@property (nonatomic, assign) int displayHeight;
@property (nonatomic, assign) int useCacheMode;
@property (nonatomic, assign) int expectedFitScreenMode;
@property (nonatomic, assign) int startupModel;
@property (nonatomic, assign) float brandWidthFactor;

@property (nonatomic, assign) BOOL useCustomParams;
@property (nonatomic, assign) double firstParam;
@property (nonatomic, assign) double secondParam;
@property (nonatomic, assign) double thirdParam;
@property (nonatomic, assign) double fourthParam;

@property (nonatomic, nullable, copy) NSString *pallasVidLabels;

@end

@implementation _TTVideoEngineSelectorParams

- (instancetype)initWithParams:(TTVideoEngineAutoResolutionParams *)params {
    self = [super init];
    if (self) {
        self.expectedResolution = params.expectedResolution;
        self.defaultWifiResolution = params.defaultWifiResolution;
        self.startUpMaxResolution = params.startUpMaxResolution;
        self.cellularMaxResolution = params.cellularMaxResolution;
        self.downgradeResolution = params.downgradeResolution;
        self.defaultCellularResolution = params.defaultCellularResolution;
        self.startupMinResolution = params.startupMinResolution;
        
        self.startupModel = (int)params.startupModel;
        
        self.brandWidthFactor = params.brandwidthFactor;
        
        self.useCustomParams = params.useCustomStartupParams;
        self.firstParam = params.firstStartupParam;
        self.secondParam = params.secondStartupParam;
        self.thirdParam = params.thirdStartupParam;
        self.fourthParam = params.fourthStartupParam;

        self.expectedQuality = params.expectedQuality;
        self.defaultWifiQuality = params.defaultWifiQuality;
        self.startUpMaxQuality = params.startUpMaxQuality;
        self.cellularMaxQuality = params.cellularMaxQuality;
        self.downgradeQuality = params.downgradeQuality;
        self.defaultCellularQuality = params.defaultCellularQuality;
        self.startUpMinQuality = params.startupMinQuality;

        self.screenWidth = (int)([UIScreen mainScreen].bounds.size.width * [UIScreen mainScreen].scale);
        self.screenHeight = (int)([UIScreen mainScreen].bounds.size.height * [UIScreen mainScreen].scale);
        self.displayWidth = params.displayWidth;
        self.displayHeight = params.displayHeight;
        
        self.useCacheMode = (int)params.useCacheMode;
        self.expectedFitScreenMode = (int)params.fitScreenMode;
        
        self.expectedBitRate = -1;
        self.defaultWifiBitRate = -1;
        self.startUpMaxBitrate = -1;
        self.cellularMaxBitrate = -1;
        self.downgradeBitrate = -1;
        self.defaultCellularBitrate = -1;
        self.startupMinBitrate = -1;
    }
    return self;
}

- (void)configBitrateWithPlaySource:(id<TTVideoEnginePlaySource>)playSource {
    if (!playSource)
        return;
    
    if ((NSInteger)self.expectedResolution >= 0) {
        TTVideoEngineURLInfo *info = [playSource urlInfoForResolution:self.expectedResolution mediaType:kVideoMediaTypeKey params:self.expectedQuality];
        if (info) {
            self.expectedBitRate = [info getValueInt:VALUE_BITRATE];
        }
    }
    
    if ((NSInteger)self.defaultWifiResolution >= 0) {
        TTVideoEngineURLInfo *info = [playSource urlInfoForResolution:self.defaultWifiResolution mediaType:kVideoMediaTypeKey params:self.defaultWifiQuality];
        if (info) {
            self.defaultWifiBitRate = [info getValueInt:VALUE_BITRATE];
        }
    }
    
    if ((NSInteger)self.startUpMaxResolution >= 0) {
        TTVideoEngineURLInfo *info = [playSource urlInfoForResolution:self.startUpMaxResolution mediaType:kVideoMediaTypeKey params:self.startUpMaxQuality];
        if (info) {
            self.startUpMaxBitrate = [info getValueInt:VALUE_BITRATE];
        }
    }
    
    if ((NSInteger)self.cellularMaxResolution >= 0) {
        TTVideoEngineURLInfo *info = [playSource urlInfoForResolution:self.cellularMaxResolution mediaType:kVideoMediaTypeKey params:self.cellularMaxQuality];
        if (info) {
            self.cellularMaxBitrate = [info getValueInt:VALUE_BITRATE];
        }
    }
    
    if ((NSInteger)self.downgradeResolution >= 0) {
        TTVideoEngineURLInfo *info = [playSource urlInfoForResolution:self.downgradeResolution mediaType:kVideoMediaTypeKey params:self.downgradeQuality];
        if (info) {
            self.downgradeBitrate = [info getValueInt:VALUE_BITRATE];
        }
    }
    
    if ((NSInteger)self.defaultCellularResolution >= 0) {
        TTVideoEngineURLInfo *info = [playSource urlInfoForResolution:self.defaultCellularResolution mediaType:kVideoMediaTypeKey params:self.defaultCellularQuality];
        if (info) {
            self.defaultCellularBitrate = [info getValueInt:VALUE_BITRATE];
        }
    }
    
    if ((NSInteger)self.startupMinResolution >= 0) {
        TTVideoEngineURLInfo *info = [playSource urlInfoForResolution:self.startupMinResolution mediaType:kVideoMediaTypeKey params:self.startUpMinQuality];
        if (info) {
            self.startupMinBitrate = [info getValueInt:VALUE_BITRATE];
        }
    }
}

- (void)configBitrateWithInfoModel:(TTVideoEngineInfoModel *)infoModel {
    if (!infoModel)
        return;
    
    if ((NSInteger)self.expectedResolution >= 0) {
        TTVideoEngineURLInfo *info = [infoModel videoInfoForType:self.expectedResolution mediaType:kVideoMediaTypeKey params:self.expectedQuality];
        if (info) {
            self.expectedBitRate = [info getValueInt:VALUE_BITRATE];
        }
    }
    
    if ((NSInteger)self.defaultWifiResolution >= 0) {
        TTVideoEngineURLInfo *info = [infoModel videoInfoForType:self.defaultWifiResolution mediaType:kVideoMediaTypeKey params:self.defaultWifiQuality];
        if (info) {
            self.defaultWifiBitRate = [info getValueInt:VALUE_BITRATE];
        }
    }
    
    if ((NSInteger)self.startUpMaxResolution >= 0) {
        TTVideoEngineURLInfo *info = [infoModel videoInfoForType:self.startUpMaxResolution mediaType:kVideoMediaTypeKey params:self.startUpMaxQuality];
        if (info) {
            self.startUpMaxBitrate = [info getValueInt:VALUE_BITRATE];
        }
    }
    
    if ((NSInteger)self.cellularMaxResolution >= 0) {
        TTVideoEngineURLInfo *info = [infoModel videoInfoForType:self.cellularMaxResolution mediaType:kVideoMediaTypeKey params:self.cellularMaxQuality];
        if (info) {
            self.cellularMaxBitrate = [info getValueInt:VALUE_BITRATE];
        }
    }
    
    if ((NSInteger)self.downgradeResolution >= 0) {
        TTVideoEngineURLInfo *info = [infoModel videoInfoForType:self.downgradeResolution mediaType:kVideoMediaTypeKey params:self.downgradeQuality];
        if (info) {
            self.downgradeBitrate = [info getValueInt:VALUE_BITRATE];
        }
    }
    
    if ((NSInteger)self.defaultCellularResolution >= 0) {
        TTVideoEngineURLInfo *info = [infoModel videoInfoForType:self.defaultCellularResolution mediaType:kVideoMediaTypeKey params:self.defaultCellularQuality];
        if (info) {
            self.defaultCellularBitrate = [info getValueInt:VALUE_BITRATE];
        }
    }
    
    if ((NSInteger)self.startupMinResolution >= 0) {
        TTVideoEngineURLInfo *info = [infoModel videoInfoForType:self.startupMinResolution mediaType:kVideoMediaTypeKey params:self.startUpMinQuality];
        if (info) {
            self.startupMinBitrate = [info getValueInt:VALUE_BITRATE];
        }
    }
}

- (void)configPallasVidLabelsWithPlaySource:(id<TTVideoEnginePlaySource>)playSource {
    if(!playSource) {
        return;
    }
    
    TTVideoEngineInfoModel *infoModel = NULL;
    if ([playSource isKindOfClass:[TTVideoEnginePlayBaseSource class]]) {
        TTVideoEnginePlayBaseSource *pbs = (TTVideoEnginePlayBaseSource *)playSource;
        infoModel = pbs.fetchData;
    }
    
    [self configPallasVidLabelsWithInfoModel:infoModel];
}

- (void)configPallasVidLabelsWithInfoModel:(TTVideoEngineInfoModel *)infoModel {
    if(!infoModel) {
        return;
    }
    
    self.pallasVidLabels = infoModel.pallasVidLabels;
}

@end

@implementation _TTVideoEngineStartUpSelector

- (instancetype)initWithScene:(TTVideoEngineSelectorScene)scene PredictType:(ABRPredictAlgoType)PredictAlgo {
    self = [super init];
    if (self) {
        self.scene = scene;
        Class abrCls = NSClassFromString(@"DefaultVCABRModule");
        if (abrCls == nil) {
            return nil;
        }
        SEL initSelector = @selector(initWithAlgoType:);
        if (initSelector == nil) {
            return nil;
        }
        NSMethodSignature *signature = [abrCls instanceMethodSignatureForSelector:initSelector];
        if (signature == nil) {
            return nil;
        }
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        self.abrModule = [abrCls alloc];
        if (!self.abrModule) {
            return nil;
        }
        
        invocation.target = self.abrModule;
        invocation.selector = initSelector;
        [invocation setArgument:&PredictAlgo atIndex:2];
        [invocation invoke];
        [invocation getReturnValue:&_abrModule];
    }
    return self;
}

- (TTVideoEngineURLInfo *_Nullable)selectWithPlaySource:(NSArray<TTVideoEngineURLInfo *>*)urlInfo
                                                 params:(_TTVideoEngineSelectorParams *)params
                                           onceAlgoType:(ABROnceAlgoType)onceAlgoType
                                        isAddBufferInfo:(BOOL)isAddBufferInfo {
    if (!urlInfo || !params || !self.abrModule)
        return nil;
    
    [self.abrModule setStringValue:gABRPreloadJsonParams forKey:ABRKeyIsPreloadJsonParams];
    [self.abrModule setStringValue:gABRStartupJsonParams forKey:ABRKeyIsStartupJsonParams];
    [self.abrModule setStringValue:gABRFlowJsonParams forKey:ABRKeyIsFlowJsonParams];
    
    [self.abrModule setIntValue:self.scene forKey:ABRKeyIsSelectScene];
    //params info:
    [self.abrModule setLongValue:params.expectedBitRate forKey:ABRKeyIsUserExpectedBitrate];
    [self.abrModule setLongValue:params.defaultWifiBitRate forKey:ABRKeyIsDefaultWifiBitrate];
    [self.abrModule setLongValue:params.startUpMaxBitrate forKey:ABRKeyIsStartupMaxBitrate];
    [self.abrModule setLongValue:params.cellularMaxBitrate forKey:ABRKeyIs4GMaxBitrate];
    [self.abrModule setLongValue:params.downgradeBitrate forKey:ABRKeyIsDowngradeBitrate];
    [self.abrModule setLongValue:params.defaultCellularBitrate forKey:ABRKeyIsDefault4GBitrate];
    [self.abrModule setLongValue:params.startupMinBitrate forKey:ABRKeyIsStartupMinBitrate];
    [self.abrModule setIntValue:params.useCacheMode forKey:ABRKeyIsStartupUseCache];
    [self.abrModule setIntValue:params.expectedFitScreenMode forKey:ABRKeyIsExpectedFitScreen];
    
    _TTVideoEngineSelectorABRDeviceInfo *deviceInfo = [[_TTVideoEngineSelectorABRDeviceInfo alloc] initWithWidth:params.screenWidth height:params.screenHeight];
    [self.abrModule setDeviceInfo:deviceInfo];
    [self.abrModule setIntValue:params.displayWidth forKey:ABRKeyIsPlayerDisplayWidth];
    [self.abrModule setIntValue:params.displayHeight forKey:ABRKeyIsPlayerDisplayHeight];
    [self.abrModule setIntValue:params.startupModel forKey:ABRKeyIsStartupModel];
    [self.abrModule setStringValue:params.pallasVidLabels forKey:ABRKeyIsPallasVidLabels];
        
    TTVideoEngineLog(@"auto res: scene %d, expectedBitRate: %ld, defaultWifiBitRate: %ld, startUpMaxBitrate: %ld, cellularMaxBitrate: %ld, downgradeBitrate: %ld, defaultCellularBitrate: %ld, startupMinBitrate: %ld, cache mode: %d, expectedFitScreen: %d, isAddBufferInfo: %@, startupModel: %d, pallasVidLabels: %@",
                     self.scene,
                     params.expectedBitRate,
                     params.defaultWifiBitRate,
                     params.startUpMaxBitrate,
                     params.cellularMaxBitrate,
                     params.downgradeBitrate,
                     params.defaultCellularBitrate,
                     params.startupMinBitrate,
                     params.useCacheMode,
                     params.expectedFitScreenMode,
                     isAddBufferInfo ? @"YES" : @"NO",
                     params.startupModel,
                     params.pallasVidLabels)
    
    [self.abrModule setFloatValue:params.brandWidthFactor forKey:ABRKeyIsStartupBandwidthParameter];
    TTVideoEngineLog(@"auto res: startup brandwidth params: %f", params.brandWidthFactor)
    
    if (params.useCustomParams) {
        [self.abrModule setDoubleValue:params.firstParam forKey:ABRKeyIsStartupModelFirstParam];
        [self.abrModule setDoubleValue:params.secondParam forKey:ABRKeyIsStartupModelSecondParam];
        [self.abrModule setDoubleValue:params.thirdParam forKey:ABRKeyIsStartupModelThirdParam];
        [self.abrModule setDoubleValue:params.fourthParam forKey:ABRKeyIsStartupModelFourthParam];
        TTVideoEngineLog(@"auto res: set start up params: first: %f, second: %f, third: %f, fourth: %f",
                         params.firstParam, params.secondParam, params.thirdParam, params.fourthParam)
    }
    TTVideoEngineLog(@"auto res: use custom startup params: %d", params.useCustomParams)
    
    //video model info:
    NSMutableArray<id<IVCABRAudioStream>> *audioInfoList = [NSMutableArray array];
    NSMutableArray<id<IVCABRVideoStream>> *videoInfoList = [NSMutableArray array];
    NSArray<TTVideoEngineURLInfo *> *infoList = urlInfo;
    for (TTVideoEngineURLInfo *info in infoList) {
        if ([[info getValueStr:VALUE_MEDIA_TYPE] isEqualToString:kAudioMediaTypeKey]) {
            NSString *fileHash = [info getValueStr:VALUE_FILE_HASH];
            NSInteger bitrate = [info getValueInt:VALUE_BITRATE];
            
            _TTVideoEngineSelectorAudioStream *audioStream = [[_TTVideoEngineSelectorAudioStream alloc] init];
            audioStream.streamId = fileHash;
            audioStream.brandWidth = (int)bitrate;
            audioStream.codec = [info getValueStr:VALUE_CODEC_TYPE];
            //todo c: segment duration
            audioStream.segmentDuration = 5000;
            //todo c: sample rate
            audioStream.sampleRate = -1;
            [audioInfoList addObject:audioStream];
            
            TTVideoEngineLog(@"auto res: add audio info, file hash: %@, brand width: %d, codec: %@, segment duration: %d, sample rate: %d",
                             audioStream.streamId,
                             audioStream.brandWidth,
                             audioStream.codec,
                             audioStream.segmentDuration,
                             audioStream.sampleRate)
            
            if (isAddBufferInfo) {
                int64_t cacheSize = [TTVideoEngine ls_getCacheSizeByKey:fileHash];
                NSInteger headSize = [info getValueInt:VALUE_VIDEO_HEAD_SIZE];
                [self.abrModule addBufferInfo:ABRStreamTypeAudio
                                    streamKey:fileHash
                                      bitrate:bitrate
                                    availSize:cacheSize
                                     headSize:headSize];
                TTVideoEngineLog(@"auto res: add buffer info, cache size: %lld, header size: %ld", cacheSize, headSize)
            }
            
        }
        else if ([[info getValueStr:VALUE_MEDIA_TYPE] isEqualToString:kVideoMediaTypeKey]) {
            NSString *fileHash = [info getValueStr:VALUE_FILE_HASH];
            NSInteger bitrate = [info getValueInt:VALUE_BITRATE];
            
            _TTVideoEngineSelectorVideoStream *videoStream = [[_TTVideoEngineSelectorVideoStream alloc] init];
            videoStream.brandWidth = (int)bitrate;
            videoStream.codec = [info getValueStr:VALUE_CODEC_TYPE];
            //todo c: segment duration
            videoStream.segmentDuration = 5000;
            videoStream.streamId = fileHash;
            //todo c: frame rate
            videoStream.frameRate = -1;
            videoStream.height = [[info getValueNumber:VALUE_VHEIGHT] intValue];
            videoStream.width = [[info getValueNumber:VALUE_VWIDTH] intValue];
            [videoInfoList addObject:videoStream];
            
            TTVideoEngineLog(@"auto res: add video info, file hash: %@, brand width: %d, codec: %@, segment duration: %d, frame rate: %f, height: %d, width: %d",
                             videoStream.streamId,
                             videoStream.brandWidth,
                             videoStream.codec,
                             videoStream.segmentDuration,
                             videoStream.frameRate,
                             videoStream.height,
                             videoStream.width)
            
            if (isAddBufferInfo) {
                int64_t cacheSize = [TTVideoEngine ls_getCacheSizeByKey:fileHash];
                NSInteger headSize = [info getValueInt:VALUE_VIDEO_HEAD_SIZE];
                
                [self.abrModule addBufferInfo:ABRStreamTypeVideo
                                    streamKey:fileHash
                                      bitrate:bitrate
                                    availSize:cacheSize
                                     headSize:headSize];
                TTVideoEngineLog(@"auto res: add buffer info, cache size: %lld, header size: %ld", cacheSize, headSize)
            }
            
        }
    }
    [self.abrModule setMediaInfo:videoInfoList withAudio:audioInfoList];
    
    //network info:
    Class predictAction = [[TTVideoEngineActionManager shareInstance] actionClassWithProtocal:@protocol(TTVideoEngineNetworkPredictorAction)];
    if (!predictAction) {
        TTVideoEngineLog(@"auto res: empty network speed predictor action")
    } else {
        //config parameters:
        if ([predictAction respondsToSelector:@selector(getPredictSpeed)]) {
            float predictSpeed = (float)[predictAction getPredictSpeed];
            [self.abrModule setFloatValue:predictSpeed forKey:ABRKeyIsNetworkSpeed];
            TTVideoEngineLog(@"auto res: start up predictSpeed: %f", predictSpeed)
        }
        if ([predictAction respondsToSelector:@selector(getDownLoadSpeed)]) {
            float downloadSpeed = (float)[predictAction getDownLoadSpeed];
            [self.abrModule setFloatValue:downloadSpeed forKey:ABRKeyIsDownloadSpeed];
            TTVideoEngineLog(@"auto res: start up downloadSpeed: %f", downloadSpeed)
        }
        if ([predictAction respondsToSelector:@selector(getAverageDownLoadSpeed)]) {
            float avgDownloadSpeed = 0.0;
            if (self.scene == ABRSelectSceneStartUp && params.useCacheMode == ABRStrictUseCache) {
                // only startup average speed trigger update
                avgDownloadSpeed = (float)[predictAction getAverageDownLoadSpeedFromSpeedAlgo:ABRStreamTypeVideo speedType:NetworkPredictAverageEMADownloadSpeed trigger:true];
            } else {
                avgDownloadSpeed = (float)[predictAction getAverageDownLoadSpeedFromSpeedAlgo:ABRStreamTypeVideo speedType:NetworkPredictAverageEMADownloadSpeed trigger:false];
            }
            [self.abrModule setFloatValue:avgDownloadSpeed forKey:ABRKeyIsAverageNetworkSpeed];
            [self.abrModule setFloatValue:avgDownloadSpeed forKey:ABRKeyIsAverageStartupEndNetworkSpeed];
            TTVideoEngineLog(@"auto res: start up avgDownloadSpeed: %f", avgDownloadSpeed)
        }
        if ([predictAction respondsToSelector:@selector(getSpeedConfidence)]) {
            float networkSpeedConfidence = (float)[predictAction getSpeedConfidence];
            [self.abrModule setFloatValue:networkSpeedConfidence forKey:ABRKeyIsNetworkSpeedConfidence];
            TTVideoEngineLog(@"auto res: start up networkSpeedConfidence: %f", networkSpeedConfidence)
        }
    }
    
    int networkState = (int)[_TTVideoEngineStartUpSelector
                                convertToABRNetworkState:[[TTVideoEngineNetWorkReachability shareInstance]
                                                          currentReachabilityStatus]];
    TTVideoEngineLog(@"auto res: network state %d", networkState)
    [self.abrModule setIntValue:networkState forKey:ABRKeyIsNetworkState];
    
    int64_t videoBitrate = 0;
    VCABRResult *result = [self.abrModule onceSelect:onceAlgoType scene:self.scene];
    for (int i = 0; i < [result getSize]; i++) {
        VCABRResultElement *ele = [result elementAtIndex:i];
        if (ele.mediaType == VCABRResultElementMediaTypeVideo) {
            videoBitrate = ele.bitrate;
            break;
        }
    }
    TTVideoEngineLog(@"auto res: selected video bitrate: %lld", videoBitrate)
    
    TTVideoEngineURLInfo *selectedInfo = nil;
    if (videoBitrate > 0) {
        int diff = -1L;
        for (TTVideoEngineURLInfo *info in infoList) {
            if (!info || [[info getValueStr:VALUE_MEDIA_TYPE] isEqualToString:kAudioMediaTypeKey]
                || ![info getValueStr:VALUE_DEFINITION].length)
                continue;
            if (diff < 0 || abs((int)([info getValueInt:VALUE_BITRATE] - videoBitrate)) < diff) {
                diff = abs((int)([info getValueInt:VALUE_BITRATE] - videoBitrate));
                selectedInfo = info;
                TTVideoEngineLog(@"auto res: changed selected info bitrate: %ld", [info getValueInt:VALUE_BITRATE])
            }
        }
    }
    
    return selectedInfo;
}

+ (ABRNetworkState)convertToABRNetworkState:(TTVideoEngineNetWorkStatus)state {
    switch (state) {
        case TTVideoEngineNetWorkStatusWWAN:
            return ABRNetworkState4G;
            
        case TTVideoEngineNetWorkStatusWiFi:
            return ABRNetworkStateWifi;
            
        default:
            return ABRNetworkStateUnknow;;
    }
}


@end
