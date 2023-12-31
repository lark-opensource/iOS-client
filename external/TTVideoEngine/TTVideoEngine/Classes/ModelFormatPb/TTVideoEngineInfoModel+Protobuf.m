//
//  TTVideoInfoModel.m
//  Article
//
//  Created by Dai Dongpeng on 6/2/16.
//
//

#import "TTVideoEngineInfoModel+Protobuf.h"
#import "NSDictionary+TTVideoEngine.h"
#import "NSObject+TTVideoEngine.h"
#import "TTVideoEngineUtilPrivate.h"
#import "TTVideoEngineModelPb.pbobjc.h"
#import "TTVideoEnginePlayerDefine.h"


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

static id checkNSNull(id obj) {
    return obj == [NSNull null] ? nil : obj;
}

@interface TTVideoEngineURLInfo()

@property (nonatomic, copy) NSString  *vType_ver2;
@property (nonatomic, copy) NSString *codecType_ver2;
@property (nonatomic, copy) NSString *mainURLStr_ver2;
@property (nonatomic, copy) NSString  *backupURL1_ver2;
@property (nonatomic, copy) NSString *spade_a_ver2;
@property (nonatomic, copy) NSString *fileHash_ver2;
@property (nonatomic, copy) NSString *quality_ver2;
@property (nonatomic, copy) NSString *defination_ver2;
@property (nonatomic, copy) NSString *mediaType_ver2;
@property (nonatomic, strong) NSNumber  *vHeight_ver2;
@property (nonatomic, strong) NSNumber  *vWidth_ver2;
@property (nonatomic, strong) NSNumber  *size_ver2;
@property (nonatomic, assign) NSInteger bitrate_ver2;
@property (nonatomic, strong) NSNumber  *preloadSize_ver2;
@property (nonatomic, strong) NSNumber  *preLoadMaxStep_ver2;
@property (nonatomic, strong) NSNumber  *preLoadMinStep_ver2;
@property (nonatomic, strong) NSNumber  *preloadSocketBuffer_ver2;
@property (nonatomic, strong) NSNumber  *preloadInterval_ver2;
@property (nonatomic, strong) NSNumber  *urlExpire;
@property (nonatomic, copy) NSString *logoType;
@property (nonatomic, assign) NSInteger apiVer;
@property (nonatomic, strong) NSDictionary *videoResolutionMap;
@property (nonatomic, strong) NSDictionary *audioResolutionMap;
@property (nonatomic, copy) NSString *checkInfo_ver2;


@end

@implementation TTVideoEngineURLInfo (Protobuf)
/// Please use @property.

- (instancetype)initVideoInfoWithPb:(TTVideoEnginePbVideo* )video {
    self = [super init];
    if (self) {
         [self _initDefaultResolutionMap];
        self.mainURLStr = video.mainURL;
        self.backupURL1 = video.backupURL;
        TTVideoEnginePbVideoMeta *videoMeta = video.videoMeta;
        self.definition = videoMeta.definition;
        self.audioQuality = videoMeta.quality;
        self.qualityDesc = videoMeta.qualityDesc;
        self.vType = videoMeta.vtype;
        self.vWidth = [NSNumber numberWithLongLong:videoMeta.vwidth];
        self.vHeight = [NSNumber numberWithLongLong:videoMeta.vheight];
        self.bitrate = videoMeta.bitrate;
        self.codecType = videoMeta.codecType;
        self.size = [NSNumber numberWithLongLong:videoMeta.size];
        self.fieldId = videoMeta.fileId;
        self.fileHash = [@"fileid" stringByAppendingString: self.fieldId];
        self.fps = [NSNumber numberWithLongLong:videoMeta.fps];
        self.encrypt = video.encryptInfo.encrypt;
        self.kid = video.encryptInfo.kid;
        self.spade_a = video.encryptInfo.spadeA;
        self.p2pVerifyUrl = video.p2PInfo.p2PVerifyURL;
        self.checkInfo = video.checkInfo.checkInfo;
        self.barrageMaskOffset = video.barrageInfo.barrageMaskOffset;
        self.bashIndexRange = video.baseRangeInfo.indexRange;
        self.bashInitRange = video.baseRangeInfo.initRange;
        self.mediaType = @"video";
    }
    return self;
}

- (instancetype)initAudioInfoWithPb:(TTVideoEnginePbAudio* )audio {
    self = [super init];
    if (self) {
         [self _initDefaultResolutionMap];
        self.mainURLStr = audio.mainURL;
        self.backupURL1 = audio.backupURL;
        TTVideoEnginePbAudioMeta *audioMeta = audio.audioMeta;
        self.definition = audioMeta.definition;
        self.audioQuality = audioMeta.quality;
        self.qualityDesc = audioMeta.qualityDesc;
        self.vType = audioMeta.atype;
        self.bitrate = audioMeta.bitrate;
        self.codecType = audioMeta.codecType;
        self.size = [NSNumber numberWithLongLong:audioMeta.size];
        self.fieldId = audioMeta.fileId;
        self.fileHash = [@"fileid" stringByAppendingString: self.fieldId];
        self.encrypt = audio.encryptInfo.encrypt;
        self.kid = audio.encryptInfo.kid;
        self.spade_a = audio.encryptInfo.spadeA;
        self.p2pVerifyUrl = audio.p2PInfo.p2PVerifyURL;
        self.checkInfo = audio.checkInfo.checkInfo;
        self.bashIndexRange = audio.baseRangeInfo.indexRange;
        self.bashInitRange = audio.baseRangeInfo.initRange;
        self.mediaType =@"audio";
    }
    return self;
}

- (NSDictionary *)getVideoInfo {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"main_url"] = self.mainURLStr;
    dict[@"backup_url_1"] = self.backupURL1;
    dict[@"bitrate"] = @(self.bitrate).stringValue;
    dict[@"vwidth"] = self.vWidth;
    dict[@"vheight"] = self.vHeight;
    dict[@"init_range"] = self.bashInitRange;
    dict[@"index_range"] = self.bashIndexRange;
    dict[@"check_info"] = self.checkInfo;
    dict[@"kid"] = self.kid;
    return [dict copy];
}


- (void)_initDefaultResolutionMap {
    self.videoResolutionMap = TTVideoEngineDefaultVideoResolutionMap();
    self.audioResolutionMap = TTVideoEngineDefaultAudioResolutionMap();
}

- (NSNumber *)getValueNumber:(NSInteger)key {
    if (self.apiVer >= TTVideoEnginePlayAPIVersion2) {
        switch(key) {
            case VALUE_VWIDTH:
                return self.vWidth_ver2;
            case VALUE_VHEIGHT:
                return self.vHeight_ver2;
            case VALUE_SIZE:
                return self.size_ver2;
            case VALUE_PRELOAD_SIZE:
                return self.preloadSize_ver2;
            case VALUE_PRELOAD_MIN_STEP:
                return self.preLoadMinStep_ver2;
            case VALUE_PRELOAD_MAX_STEP:
                return self.preLoadMaxStep_ver2;
            case VALUE_PRELOAD_INTERVAL:
                return self.preloadInterval_ver2;
            case VALUE_URL_EXPIRE:
                return self.urlExpire;
            default:
                return nil;
        }
    } else {
        switch (key) {
            case VALUE_VWIDTH:
                return self.vWidth;
            case VALUE_VHEIGHT:
                return self.vHeight;
            case VALUE_SIZE:
                return self.size;
            case VALUE_PRELOAD_SIZE:
                return self.preloadSize;
            case VALUE_PRELOAD_MIN_STEP:
                return self.playLoadMinStep;
            case VALUE_PRELOAD_MAX_STEP:
                return self.playLoadMaxStep;
            case VALUE_URL_EXPIRE:
                return self.urlExpire;
            default:
                return nil;
        }
    }
    
}

- (NSString *)getValueStr:(NSInteger)key {
    if (self.apiVer >= TTVideoEnginePlayAPIVersion2) {
        switch(key) {
            case VALUE_MAIN_URL:
                return self.mainURLStr_ver2;
            case VALUE_FILE_HASH:
                return self.fileHash_ver2;
            case VALUE_PLAY_AUTH:
                return self.spade_a_ver2;
            case VALUE_FORMAT_TYPE:
                return self.vType_ver2;
            case VALUE_CODEC_TYPE:
                return self.codecType_ver2;
            case VALUE_DEFINITION:
                return self.defination_ver2;
            case VALUE_LOGO_TYPE:
                return self.logoType;
            case VALUE_QUALITY:
                return self.quality_ver2;
            case VALUE_BACKUP_URL_1:
                return self.backupURL1_ver2;
            case VALUE_MEDIA_TYPE:
                return self.mediaType_ver2;
            case VALUE_CHECK_INFO:
                return self.checkInfo_ver2;
            default:
                return nil;
        }
    } else {
        switch(key) {
            case VALUE_MAIN_URL:
                return self.mainURLStr;
            case VALUE_BACKUP_URL_1:
                return self.backupURL1;
            case VALUE_BACKUP_URL_2:
                return self.backupURL2;
            case VALUE_BACKUP_URL_3:
                return self.backupURL3;
            case VALUE_FILE_HASH:
                return self.fileHash;
            case VALUE_DEFINITION:
                return self.definition;
            case VALUE_PLAY_AUTH:
                return self.spade_a;
            case VALUE_FORMAT_TYPE:
                return self.vType;
            case VALUE_CODEC_TYPE:
                return self.codecType;
            case VALUE_QUALITY:
                return self.audioQuality;
            case VALUE_MEDIA_TYPE:
                return self.mediaType;
            case VALUE_LOGO_TYPE:
                return self.logoType;
            case VALUE_CHECK_INFO:
                return self.checkInfo;
            case VALUE_VIDEO_QUALITY_DESC:
                return self.qualityDesc;
            case VALUE_BARRAGE_MASK_OFFSET:
                return self.barrageMaskOffset;
            default:
                return nil;
        }
    }
}

- (NSInteger)getValueInt:(NSInteger)key {
    if (self.apiVer >= TTVideoEnginePlayAPIVersion2) {
        switch(key) {
            case VALUE_BITRATE:
                return self.bitrate_ver2;
            default:
                return -1;
        }
    } else {
        switch(key) {
            case VALUE_BITRATE:
                return self.bitrate;
            default:
                return -1;
        }
    }
}

- (BOOL)getValueBool:(NSInteger)key {
    if (self.apiVer >= TTVideoEnginePlayAPIVersion2) {
        
    } else {
        switch(key) {
            case VALUE_ENCRYPT:
                return self.encrypt;
            default:
                return NO;
        }
    }
    return NO;
}

@end

/// MARK: - TTVideoEngineURLInfoMap
/// MARK: -
@implementation TTVideoEngineURLInfoMap (Protobuf)
/// Please use @property.
- (instancetype)initVideoListWithPb:(NSMutableArray<TTVideoEnginePbVideo*> *)video_list {
    self = [super init];
    if (self) {
        self.videoInfoList = [NSMutableArray array];
        for (TTVideoEnginePbVideo *video in video_list) {
            TTVideoEngineURLInfo *videoInfo = [[TTVideoEngineURLInfo alloc] initVideoInfoWithPb:video];
            [self.videoInfoList addObject:videoInfo];
        }
    }
    return self;
}

@end

/// MARK: - TTVideoEngineDynamicVideo
/// MARK: -
@interface TTVideoEngineDynamicVideo()
@property (nonatomic, assign) BOOL hasVideo;
@end

@implementation TTVideoEngineDynamicVideo (Protobuf)

- (instancetype)initDynamicVideoWithPb:(TTVideoEnginePbDynamicVideo*)dynamicVideo {
    self = [super init];
    if (self) {
        self.dynamicType = dynamicVideo.dynamicType;
        self.mainURL = dynamicVideo.mainURL;
        self.backupURL = dynamicVideo.backupURL;
        NSMutableArray *temArray = [NSMutableArray array];
        NSMutableArray *temAudioArray = [NSMutableArray array];
        if(dynamicVideo.dynamicVideoListArray_Count > 0){
            NSMutableArray<TTVideoEnginePbVideo*> *dynamicVideoArray = dynamicVideo.dynamicVideoListArray;
            for (TTVideoEnginePbVideo *video in dynamicVideoArray) {
                TTVideoEngineURLInfo *info = [[TTVideoEngineURLInfo alloc] initVideoInfoWithPb:video];
                self.hasVideo = YES;
                [temArray addObject:info];
            }
        }
        if(dynamicVideo.dynamicAudioListArray_Count){
            NSMutableArray<TTVideoEnginePbAudio*> *dynamicAudioArray = dynamicVideo.dynamicAudioListArray;
            for (TTVideoEnginePbAudio *audio in dynamicAudioArray) {
                TTVideoEngineURLInfo *info = [[TTVideoEngineURLInfo alloc] initAudioInfoWithPb:audio];
                [temArray addObject:info];
                [temAudioArray addObject:info];
            }
        }
        self.dynamicVideoInfo = temArray.copy;
        self.dynamicAudioInfoV3 = temAudioArray.copy;

    }
    return self;
}


- (TTVideoEngineURLInfo *)videoForResolutionType:(TTVideoEngineResolutionType)type mediaType:(NSString *)mediaType otherCondition:(NSDictionary *)searchCondition{
    for (TTVideoEngineURLInfo *info in self.dynamicVideoInfo) {
        if (searchCondition != nil || searchCondition.count > 0) {
            NSString *value = [searchCondition objectForKey:@(VALUE_VIDEO_QUALITY_DESC)];
            if(value != nil && [value isEqualToString:[info getValueStr:VALUE_VIDEO_QUALITY_DESC]]){
                return info;
            }
        }
        if (info.videoDefinitionType != type) {
            continue;
        }
        if(![[info getValueStr:VALUE_MEDIA_TYPE] isEqualToString:mediaType]){
            continue;
        }
        
        if (searchCondition == nil || searchCondition.count == 0) {
            return info;
        }
        BOOL isFound = YES;
        for (NSNumber *key in searchCondition) {
            NSString *value = [searchCondition objectForKey:key];
            NSString *infoValue = [info getValueStr:key.integerValue];
            if (![infoValue isEqualToString:value]) {
                isFound = NO;
                break;
            }
        }
        if (isFound) {
            return info;
        }
    }
    return nil;
}

@end

/// MARK: - TTVideoEngineSeekTS
/// MARK: -
@interface TTVideoEngineSeekTS()
@property (nonatomic, assign) CGFloat opening_ver2; //片头，单位: 秒
@property (nonatomic, assign) CGFloat ending_ver2; //片尾, 单位: 秒
@property (nonatomic, assign) NSInteger apiVer;
@end
@implementation TTVideoEngineSeekTS (Protobuf)

- (instancetype)initSeekOffSetWithPb:(TTVideoEnginePbSeekOffSet *)seekOffSet {
    self = [super init];
    if (self) {
        self.opening = seekOffSet.opening;
        self.ending = seekOffSet.ending;
    }
    return self;
}

- (CGFloat)getValueFloat:(NSInteger)key {
    if (self.apiVer >= TTVideoEnginePlayAPIVersion2) {
        switch (key) {
            case VALUE_SEEKTS_OPENING:
                return self.opening_ver2;
            case VALUE_SEEKTS_ENDING:
                return self.ending_ver2;
            default:
                return -1;
        }
    } else {
        switch (key) {
            case VALUE_SEEKTS_OPENING:
                return self.opening;
            case VALUE_SEEKTS_ENDING:
                return self.ending;
            default:
                return -1;
        }
    }
}


@end


/// MARK: - TTVideoEngineInfoModel
/// MARK: -
static NSInteger const kModelEffectiveDuration = 40 * 60 * 1;//40 min
@interface TTVideoEngineInfoModel()
@property (nonatomic, copy) NSString *videoID_ver2;
@property (nonatomic, copy) NSString *mediaType_ver2;
@property (nonatomic, copy) NSString *posterUrl_ver2;

@property (nonatomic, strong) NSMutableArray<TTVideoEngineURLInfo *> *videoInfoList_ver2;
@property (nonatomic, strong) TTVideoEngineLiveVideo *liveVideo_ver2;
@property (nonatomic, strong) NSNumber  *videoDuration_ver2;
@property (nonatomic, assign) NSInteger videoStatusCode_ver2;
@property (nonatomic, assign) NSInteger totalCount_ver2;

@property (nonatomic, assign) BOOL hasH265Codec;
@property (nonatomic, assign) BOOL hasH264Codec;
@property (nonatomic, assign) BOOL hasVideo;
@property (nonatomic, assign) NSInteger apiVer;
@property (nonatomic, strong) NSMutableArray<NSString *> *codecList;
@property (nonatomic, assign) NSTimeInterval createTimeInterval;
@property (nonatomic, strong) NSArray *supportedResolutionTypes;
@property (nonatomic, strong) NSDictionary *resolutionMap;

@end

@implementation TTVideoEngineInfoModel (Protobuf)


- (instancetype)initVideoInfoWithPb:(NSData * )data {
    self = [super init];
    if (self) {
        NSError *error = nil;
        TTVideoEnginePbVideoInfo *videoInfo = [TTVideoEnginePbVideoInfo parseFromData:data error:&error];
        if (!error) {
            self.createTimeInterval = [[NSDate date] timeIntervalSince1970];
            self.videoStatusCode = videoInfo.status;
            self.videoModelVersion = TTVideoEngineVideoModelVersion4;
            self.videoID = videoInfo.videoId;
            self.mediaType = videoInfo.mediaType;
            self.enableSSL = videoInfo.enableSsl;
            self.videoDuration = [NSNumber numberWithDouble:videoInfo.videoDuration];
            self.urlExpire = [NSNumber numberWithDouble:videoInfo.URLExpire];
            self.barrageMaskUrl = videoInfo.barrageMaskURL;
             if (videoInfo.bigThumbsArray_Count > 0) {
                NSMutableArray<TTVideoEnginePbBigThumb*> *bigThumbsArray = videoInfo.bigThumbsArray;
                self.bigThumbs = [NSMutableArray array];
                for (TTVideoEnginePbBigThumb *bigThumb in bigThumbsArray) {
                    TTVideoEngineThumbInfo *thumbInfo = [[TTVideoEngineThumbInfo alloc] initWithDictionaryPb:bigThumb];
                    [self.bigThumbs addObject:thumbInfo];
                }
             }
            self.fallbackAPI = videoInfo.fallbackApi.fallbackApi;
            self.keyseed = videoInfo.fallbackApi.keySeed;
            self.seekTs = [[TTVideoEngineSeekTS alloc] initSeekOffSetWithPb:videoInfo.seekTs];
            //TTVideoEngineDNSInfo *dnsInfo = videoInfo.dnsInfo;
            if (videoInfo.videoListArray_Count > 0) {
                NSMutableArray<TTVideoEnginePbVideo*> *video_list = videoInfo.videoListArray;
                self.videoURLInfoMap = [[TTVideoEngineURLInfoMap alloc] initVideoListWithPb:video_list];
            }
            if (videoInfo.dynamicVideo) {
                self.dynamicVideo = [[TTVideoEngineDynamicVideo alloc] initDynamicVideoWithPb:videoInfo.dynamicVideo];
                [self getRefStringWithPb:videoInfo.dynamicVideo];
            }
            self.memString = [self toMemString];
            [self setUpResolutionMap:TTVideoEngineDefaultVideoResolutionMap()];
        }
    }
    return self;
}

- (void)getRefStringWithPb:(TTVideoEnginePbDynamicVideo *)dynamicVideo {
    NSMutableDictionary *dynamicDict = [NSMutableDictionary dictionary];
    NSMutableDictionary *innerDict = [NSMutableDictionary dictionary];
    NSArray *videoListDict = dynamicVideo.dynamicVideoListArray;
    NSMutableArray *videoArray = [NSMutableArray array];
    NSMutableArray *audioArray = [NSMutableArray array];
    if(dynamicVideo.dynamicVideoListArray_Count > 0){
        for (TTVideoEnginePbVideo *video in videoListDict) {
            TTVideoEngineURLInfo *info = [[TTVideoEngineURLInfo alloc] initVideoInfoWithPb:video];
            NSDictionary *videoInfoMutable = info.getVideoInfo;
            [videoArray addObject:videoInfoMutable];
        }
    }
    if(dynamicVideo.dynamicAudioListArray_Count > 0){
        for (TTVideoEnginePbAudio *audio in dynamicVideo.dynamicAudioListArray) {
            TTVideoEngineURLInfo *info = [[TTVideoEngineURLInfo alloc] initAudioInfoWithPb:audio];
            NSDictionary *audioInfoMutable = info.getVideoInfo;
            [audioArray addObject:audioInfoMutable];
        }
    }
    innerDict[@"dynamic_audio_list"] = audioArray;
    innerDict[@"dynamic_video_list"] = videoArray;
    dynamicDict[@"dynamic_video"] =innerDict;
    NSData *tmpData = [NSJSONSerialization dataWithJSONObject:innerDict options:0 error:nil];
    self.refString = [[NSString alloc] initWithData:tmpData encoding:NSUTF8StringEncoding];
}
@end

#pragma clang diagnostic pop


