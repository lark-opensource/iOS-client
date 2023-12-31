//
//  TTVideoInfoModel.m
//  Article
//
//  Created by Dai Dongpeng on 6/2/16.
//
//

#import "TTVideoEngineInfoModel.h"
#import "NSDictionary+TTVideoEngine.h"
#import "NSObject+TTVideoEngine.h"
#import "TTVideoEngineUtilPrivate.h"
#import "NSString+TTVideoEngine.h"
#import "NSArray+TTVideoEngine.h"

#import <TTPlayerSDK/ByteCrypto.h>

NSString *kTTVideoEngineCodecH264    = @"h264";
NSString *kTTVideoEngineCodecByteVC1 = @"bytevc1";
NSString *kTTVideoEngineCodecByteVC2 = @"bytevc2";

id checkNSNull(id obj) {
    return obj == [NSNull null] ? nil : obj;
}

@interface TTVideoEngineURLInfo ()

@property (nonatomic, copy) NSString       *vType_ver2;
@property (nonatomic, copy) NSString       *codecType_ver2;
@property (nonatomic, copy) NSString       *mainURLStr_ver2;
@property (nonatomic, copy) NSString       *backupURL1_ver2;
@property (nonatomic, copy) NSString       *spade_a_ver2;
@property (nonatomic, copy) NSString       *fileHash_ver2;
@property (nonatomic, copy) NSString       *quality_ver2;
@property (nonatomic, copy) NSString       *defination_ver2;
@property (nonatomic, copy) NSString       *mediaType_ver2;
@property (nonatomic, strong) NSNumber     *vHeight_ver2;
@property (nonatomic, strong) NSNumber     *vWidth_ver2;
@property (nonatomic, strong) NSNumber     *size_ver2;
@property (nonatomic, assign) NSInteger     bitrate_ver2;
@property (nonatomic, assign) NSInteger     qualityType;
@property (nonatomic, strong) NSNumber     *preloadSize_ver2;
@property (nonatomic, strong) NSNumber     *preLoadMaxStep_ver2;
@property (nonatomic, strong) NSNumber     *preLoadMinStep_ver2;
@property (nonatomic, strong) NSNumber     *preloadSocketBuffer_ver2;
@property (nonatomic, strong) NSNumber     *preloadInterval_ver2;
@property (nonatomic, strong) NSNumber     *urlExpire;
@property (nonatomic, copy) NSString       *logoType;
@property (nonatomic, assign) NSInteger     apiVer;
@property (nonatomic, strong) NSDictionary *videoResolutionMap;
@property (nonatomic, strong) NSDictionary *audioResolutionMap;
@property (nonatomic, copy) NSString       *checkInfo_ver2;
@end

@implementation TTVideoEngineURLInfo
/// Please use @property.

- (void)setUpResolutionMap:(NSDictionary *)map {
    NSString *mediaType    = _mediaType ? _mediaType : _mediaType_ver2;
    BOOL      isVideoMedia = NO;
    //
    if ([mediaType isEqualToString:@"video"]) {
        if (![map isEqual:TTVideoEngineDefaultAudioResolutionMap()]) {
            _videoResolutionMap = map;
        }
        isVideoMedia = YES;
    } else if ([mediaType isEqualToString:@"audio"]) {
        if (![map isEqual:TTVideoEngineDefaultVideoResolutionMap()]) {
            _audioResolutionMap = map;
        }
        isVideoMedia = NO;
    }
    //
    NSString *typeString = isVideoMedia ? (_defination_ver2 ? _defination_ver2 : _definition)
                                        : (_quality_ver2 ? _quality_ver2 : _audioQuality);
    [self setVideoDefinitionTypeWithNSString:typeString mediaType:mediaType];
}

- (void)_parse:(NSDictionary *)jsonDict mediaType:(NSString *)mediaType key:(NSString *)key {
    if (!jsonDict)
        return;
    BOOL isVideo = ![mediaType isEqualToString:@"audio"];
    //
    if (checkNSNull(jsonDict[@"MainPlayUrl"]) != nil) {
        _apiVer = TTVideoEnginePlayAPIVersion2;
    } else {
        _apiVer = TTVideoEnginePlayAPIVersion1;
    }
    //
    _infoId = checkNSNull(jsonDict[@"info_id"]) ? [jsonDict[@"info_id"] integerValue] : -1;
    if (_apiVer >= TTVideoEnginePlayAPIVersion2) {
        _bitrate_ver2         = [checkNSNull(jsonDict[@"Bitrate"]) integerValue];
        _fileHash_ver2        = checkNSNull(jsonDict[@"FileHash"]);
        _size_ver2            = checkNSNull(jsonDict[@"Size"]);
        _vWidth_ver2          = checkNSNull(jsonDict[@"Width"]);
        _vHeight_ver2         = checkNSNull(jsonDict[@"Height"]);
        _vType_ver2           = checkNSNull(jsonDict[@"Format"]);
        _codecType_ver2       = checkNSNull(jsonDict[@"Codec"]);
        _logoType             = checkNSNull(jsonDict[@"Logo"]);
        _defination_ver2      = checkNSNull(jsonDict[@"Definition"]);
        _quality_ver2         = checkNSNull(jsonDict[@"Quality"]);
        _spade_a_ver2         = checkNSNull(jsonDict[@"PlayAuth"]);
        _urlExpire            = checkNSNull(jsonDict[@"UrlExpire"]);
        _mainURLStr_ver2      = checkNSNull(jsonDict[@"MainPlayUrl"]);
        _backupURL1_ver2      = checkNSNull(jsonDict[@"BackupPlayUrl"]);
        _preloadSize_ver2     = checkNSNull(jsonDict[@"PreloadSize"]);
        _preLoadMaxStep_ver2  = checkNSNull(jsonDict[@"PreloadMaxStep"]);
        _preLoadMinStep_ver2  = checkNSNull(jsonDict[@"PreloadMinStep"]);
        _preloadInterval_ver2 = checkNSNull(jsonDict[@"PreloadInterval"]);
        _mediaType_ver2       = mediaType;
        _mediaType_ver2       = checkNSNull(jsonDict[@"MediaType"]);
        _qualityType          = [checkNSNull(jsonDict[@"QualityType"]) integerValue];
        _bashInitRange        = checkNSNull(jsonDict[@"InitRange"]);
        _bashIndexRange       = checkNSNull(jsonDict[@"IndexRange"]);
        _languageId = checkNSNull(jsonDict[@"LanguageId"]) ? [jsonDict[@"LanguageId"] integerValue] : -1;
        _languageCode = checkNSNull(jsonDict[@"LanguageCode"]);
        _dubVersion = checkNSNull(jsonDict[@"DubVersion"]);
        if (_mediaType_ver2 == nil) {
            _mediaType_ver2 = mediaType;
        } else if ([_mediaType_ver2 isEqualToString:@"video"]) {
            isVideo = true;
        } else if ([_mediaType_ver2 isEqualToString:@"audio"]) {
            isVideo = false;
        }
        _fieldId = checkNSNull(jsonDict[@"FileID"]);

        if (_fieldId != nil && _fileHash_ver2 == nil) {
            _fileHash_ver2 = [@"fileid" stringByAppendingString:_fieldId];
        }

        _p2pVerifyUrl   = checkNSNull(jsonDict[@"P2pVerifyURL"]);
        _checkInfo_ver2 = checkNSNull(jsonDict[@"CheckInfo"]);
        [self setVideoDefinitionTypeWithNSString:isVideo ? _defination_ver2 : _quality_ver2
                                       mediaType:mediaType];

        NSDictionary *fitter_info = checkNSNull(jsonDict[@"fitter_info"]);
        if (fitter_info) {
            _fitterInfo = [[TTVideoEngineMediaFitterInfo alloc] initWithDictionary:fitter_info];
        }

        NSString *packet_offset = checkNSNull(jsonDict[@"pkt_offset"]);
        [self _parsePacketOffset:packet_offset];
    } else {
        _videoModelVersion = [checkNSNull(jsonDict[@"version"]) integerValue];
        if (_videoModelVersion == TTVideoEngineVideoModelVersion3) {
            _mainURLStr = checkNSNull(jsonDict[@"main_url"]);
            _backupURL1 = checkNSNull(jsonDict[@"backup_url"]);
            _urlExpire  = checkNSNull(jsonDict[@"url_expire"]);
            _mediaType  = mediaType;

            NSDictionary *video_meta = [jsonDict ttVideoEngineDictionaryValueForKey:@"video_meta"
                                                                       defaultValue:nil];
            if (video_meta && video_meta.count) {
                _qualityDesc  = checkNSNull(video_meta[@"quality_desc"]);
                _definition   = checkNSNull(video_meta[@"definition"]);
                _audioQuality = checkNSNull(video_meta[@"quality"]);
                _vType        = checkNSNull(video_meta[@"vtype"]);
                _size         = checkNSNull(video_meta[@"size"]);
                _vWidth       = checkNSNull(video_meta[@"vwidth"]);
                _vHeight      = checkNSNull(video_meta[@"vheight"]);
                _codecType    = checkNSNull(video_meta[@"codec_type"]);
                _fieldId      = checkNSNull(video_meta[@"file_id"]);
                _fileHash     = checkNSNull(video_meta[@"file_hash"]);
                if (_fieldId != nil && _fileHash == nil) {
                    _fileHash = [@"fileid" stringByAppendingString:_fieldId];
                }
                _fps     = checkNSNull(video_meta[@"fps"]);
                _bitrate = [video_meta ttVideoEngineIntegerValueForKey:@"bitrate" defaultValue:0];
                _qualityType = [video_meta ttVideoEngineIntegerValueForKey:@"quality_type"
                                                              defaultValue:0];
            }
            NSDictionary *audio_meta = [jsonDict ttVideoEngineDictionaryValueForKey:@"audio_meta"
                                                                       defaultValue:nil];
            if (audio_meta && audio_meta.count) {
                _qualityDesc  = checkNSNull(audio_meta[@"quality_desc"]);
                _definition   = checkNSNull(audio_meta[@"definition"]);
                _audioQuality = checkNSNull(audio_meta[@"quality"]);
                _vType        = checkNSNull(audio_meta[@"atype"]);
                _size         = checkNSNull(audio_meta[@"size"]);
                _codecType    = checkNSNull(audio_meta[@"codec_type"]);
                _fieldId      = checkNSNull(audio_meta[@"file_id"]);
                _fileHash     = checkNSNull(audio_meta[@"file_hash"]);
                if (_fieldId != nil && _fileHash == nil) {
                    _fileHash = [@"fileid" stringByAppendingString:_fieldId];
                }
                _bitrate = [audio_meta ttVideoEngineIntegerValueForKey:@"bitrate" defaultValue:0];
            }
            NSDictionary *encrypt_info =
                [jsonDict ttVideoEngineDictionaryValueForKey:@"encrypt_info" defaultValue:nil];
            if (encrypt_info && encrypt_info.count) {
                _encrypt = [encrypt_info ttVideoEngineBoolValueForKey:@"encrypt" defaultValue:NO];
                _spade_a = checkNSNull(encrypt_info[@"spade_a"]);
                _kid     = checkNSNull(encrypt_info[@"kid"]);
            }
            NSDictionary *p2p_info = checkNSNull(jsonDict[@"p2p_info"]);
            if (p2p_info && p2p_info.count) {
                _p2pVerifyUrl = checkNSNull(p2p_info[@"p2p_verify_url"]);
            }
            NSDictionary *check_info = checkNSNull(jsonDict[@"check_info"]);
            if (check_info && check_info.count) {
                _checkInfo = checkNSNull(check_info[@"check_info"]);
            }
            NSDictionary *barrage_info = checkNSNull(jsonDict[@"barrage_info"]);
            if (barrage_info && barrage_info.count) {
                _barrageMaskOffset = checkNSNull(check_info[@"barrage_mask_offset"]);
            }
            NSDictionary *base_range_info = checkNSNull(jsonDict[@"base_range_info"]);
            if (base_range_info && base_range_info.count) {
                _bashInitRange  = checkNSNull(base_range_info[@"init_range"]);
                _bashIndexRange = checkNSNull(base_range_info[@"index_range"]);
            }

            NSDictionary *fitter_info = checkNSNull(jsonDict[@"fitter_info"]);
            if (fitter_info) {
                _fitterInfo = [[TTVideoEngineMediaFitterInfo alloc] initWithDictionary:fitter_info];
            }

            NSString *packet_offset = checkNSNull(jsonDict[@"pkt_offset"]);
            [self _parsePacketOffset:packet_offset];

        } else {
            _vType        = checkNSNull(jsonDict[@"vtype"]);
            _size         = checkNSNull(jsonDict[@"size"]);
            _vWidth       = checkNSNull(jsonDict[@"vwidth"]);
            _vHeight      = checkNSNull(jsonDict[@"vheight"]);
            _codecType    = checkNSNull(jsonDict[@"codec_type"]);
            _fileHash     = checkNSNull(jsonDict[@"file_hash"]);
            _mediaType    = mediaType;
            _audioQuality = checkNSNull(jsonDict[@"quality"]);
            _qualityDesc  = checkNSNull(jsonDict[@"quality_desc"]);
            _qualityType  = [jsonDict ttVideoEngineIntValueForKey:@"quality_type" defaultValue:0];
            _mainURLStr =
                [TTVideoEngineURLInfo transformedFromBase64:checkNSNull(jsonDict[@"main_url"])
                                                        key:key];
            _backupURL1 =
                [TTVideoEngineURLInfo transformedFromBase64:checkNSNull(jsonDict[@"backup_url_1"])
                                                        key:key];
            _backupURL2 =
                [TTVideoEngineURLInfo transformedFromBase64:checkNSNull(jsonDict[@"backup_url_2"])
                                                        key:key];
            _backupURL3 =
                [TTVideoEngineURLInfo transformedFromBase64:checkNSNull(jsonDict[@"backup_url_3"])
                                                        key:key];
            _barrageMaskUrl  = [TTVideoEngineURLInfo
                transformedFromBase64:checkNSNull(jsonDict[@"barrage_mask_url"])
                                  key:key];
            _aiBarrageUrl    = [TTVideoEngineURLInfo
                                transformedFromBase64:checkNSNull(jsonDict[@"effect_barrage_url"])
                                                  key:key];
            _preloadSize     = checkNSNull(jsonDict[@"preload_size"]);
            _playLoadMaxStep = checkNSNull(jsonDict[@"preload_max_step"]);
            _playLoadMinStep = checkNSNull(jsonDict[@"preload_min_step"]);
            _encrypt         = [jsonDict ttVideoEngineBoolValueForKey:@"encrypt" defaultValue:NO];
            _spade_a         = checkNSNull(jsonDict[@"spade_a"]);
            _urlExpire       = checkNSNull(jsonDict[@"url_expire"]);
            _bitrate         = [jsonDict ttVideoEngineIntegerValueForKey:@"bitrate" defaultValue:0];
            _logoType        = checkNSNull(jsonDict[@"logo_type"]);
            _fieldId         = checkNSNull(jsonDict[@"file_id"]);
            if (_fieldId != nil && _fileHash == nil) {
                _fileHash = [@"fileid" stringByAppendingString:_fieldId];
            }
            _definition = checkNSNull(jsonDict[@"definition"]);
            _p2pVerifyUrl =
                [TTVideoEngineURLInfo transformedFromBase64:checkNSNull(jsonDict[@"p2p_verify_url"])
                                                        key:key];
            _checkInfo      = checkNSNull(jsonDict[@"check_info"]);
            _bashInitRange  = checkNSNull(jsonDict[@"init_range"]);
            _bashIndexRange = checkNSNull(jsonDict[@"index_range"]);
        }
        _languageId = checkNSNull(jsonDict[@"language_id"]) ? [jsonDict[@"language_id"] integerValue] : -1;
        _languageCode = checkNSNull(jsonDict[@"language_code"]);
        _dubVersion = checkNSNull(jsonDict[@"dub_version"]);
        NSDictionary *volume = [jsonDict ttVideoEngineDictionaryValueForKey:@"volume"
                                                               defaultValue:nil];
        if (volume && volume.count) {
            if (checkNSNull(volume[@"loudness"]) != nil || checkNSNull(volume[@"peak"]) != nil) {
                _loudness = [volume ttVideoEngineFloatValueForKey:@"loudness" defalutValue:0];
                _peak     = [volume ttVideoEngineFloatValueForKey:@"peak" defalutValue:0];
            }
        }
        [self setVideoDefinitionTypeWithNSString:isVideo ? _definition : _audioQuality
                                       mediaType:mediaType];
        NSDictionary *fitter_info = checkNSNull(jsonDict[@"fitter_info"]);
        if (fitter_info) {
            _fitterInfo = [[TTVideoEngineMediaFitterInfo alloc] initWithDictionary:fitter_info];
        }

        NSString *packet_offset = checkNSNull(jsonDict[@"pkt_offset"]);
        [self _parsePacketOffset:packet_offset];
    }
}

- (NSDictionary *)getVideoInfo {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"main_url"]         = _mainURLStr;
    dict[@"backup_url_1"]     = _backupURL1;
    dict[@"bitrate"]          = @(_bitrate).stringValue;
    dict[@"init_range"]       = _bashInitRange;
    dict[@"index_range"]      = _bashIndexRange;
    dict[@"check_info"]       = _checkInfo;
    dict[@"kid"]              = _kid;
    return [dict copy];
}

- (void)_initDefaultResolutionMap {
    _videoResolutionMap = TTVideoEngineDefaultVideoResolutionMap();
    _audioResolutionMap = TTVideoEngineDefaultAudioResolutionMap();
}

- (instancetype)init {
    if (self = [super init]) {
        _apiVer = TTVideoEnginePlayAPIVersion1;
        [self _initDefaultResolutionMap];
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)jsonDict
                         mediaType:(NSString *)mediaType
                               key:(NSString *)key {
    if (self = [super init]) {
        if (jsonDict == nil) {
            return nil;
        }
        if (!mediaType || mediaType.length == 0) {
            mediaType = @"video";
        }
        //
        [self _initDefaultResolutionMap];
        //
        [self _parse:jsonDict mediaType:mediaType key:key];
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)jsonDict mediaType:(NSString *)mediaType {
    return [self initWithDictionary:jsonDict mediaType:mediaType key:nil];
}

- (void)setVideoDefinitionTypeWithNSString:(NSString *)typeString mediaType:(NSString *)mediaType {
    if (!mediaType || mediaType.length == 0) {
        mediaType = @"video";
    }
    //
    if ([mediaType isEqualToString:@"video"]) {
        NSNumber *resolutionIndex = [_videoResolutionMap objectForKey:typeString];
        if (resolutionIndex) {
            _videoDefinitionType = (TTVideoEngineResolutionType)(resolutionIndex.integerValue);
        } else {
            _videoDefinitionType = TTVideoEngineResolutionTypeSD;
        }
    } else if ([mediaType isEqualToString:@"audio"]) {
        NSNumber *resolutionIndex = [_audioResolutionMap objectForKey:typeString];
        if (resolutionIndex) {
            _videoDefinitionType = (TTVideoEngineResolutionType)(resolutionIndex.integerValue);
        } else {
            _videoDefinitionType = TTVideoEngineResolutionTypeSD;
        }
    } else { //
        _videoDefinitionType = TTVideoEngineResolutionTypeSD;
    }
    //
    _definitionString = typeString;
}

- (TTVideoEngineResolutionType)getVideoDefinitionType {
    return _videoDefinitionType;
}

+ (NSString *)transformedFromBase64:(NSString *)base64 key:(NSString *)key {
    if (isEmptyStringForVideoPlayer(base64)) {
        return nil;
    }
    if (!TTVideoEngineStringIsBase64Encode(base64)) {
        return base64;
    }
    NSData *encodedData =
        [[NSData alloc] initWithBase64EncodedString:base64
                                            options:NSDataBase64DecodingIgnoreUnknownCharacters];
    if (!encodedData || encodedData.length < 1) {
        return nil;
    }
    if (isEmptyStringForVideoPlayer(key)) {
        return [[NSString alloc] initWithData:encodedData encoding:NSUTF8StringEncoding];
    }
    return [self decode:encodedData withKey:key];
}

+ (NSString *)decode:(NSData *)encodedData withKey:(NSString *)seed {
    NSData *seedData =
        [[NSData alloc] initWithBase64EncodedString:seed
                                            options:NSDataBase64DecodingIgnoreUnknownCharacters];
    uint8_t *keyseed = (uint8_t *)seedData.bytes;
    if (keyseed == NULL) {
        return nil;
    }
    const uint8_t *encoded = encodedData.bytes;
    if (encoded == NULL) {
        return nil;
    }
    size_t   inLen     = encodedData.length;
    size_t   outLen    = TTVideo_getDecryptBufferSize(inLen);
    size_t   originLen = outLen;
    uint8_t *outbuff   = malloc(outLen);
    if (outbuff == NULL) {
        return nil;
    }
    memset(outbuff, 0, outLen);
    int ret = TTVideo_byteCryptoDecrypt(encoded, inLen, outbuff, &originLen, keyseed);
    if (ret) {
        free(outbuff);
        return nil;
    }
    if (outLen > originLen) {
        outbuff[originLen] = 0;
    }
    NSString *outStr = [[NSString alloc] initWithBytes:outbuff
                                                length:originLen
                                              encoding:NSUTF8StringEncoding];
    free(outbuff);
    return outStr;
}

- (NSArray *)allURLForVideoID:(NSString *)videoID transformedURL:(BOOL)transformed {
    return [self _getAllUrls];
}

- (NSArray *)_getAllUrls {
    NSMutableArray *array        = [[NSMutableArray alloc] initWithCapacity:4];
    void (^addBlock)(NSString *) = ^(NSString *urlStr) {
        if (isEmptyStringForVideoPlayer(urlStr)) {
            return;
        }
        [array addObject:urlStr];
    };

    if (_apiVer >= TTVideoEnginePlayAPIVersion2) {
        addBlock(self.mainURLStr_ver2);
        addBlock(self.backupURL1_ver2);
    } else {
        addBlock(self.mainURLStr);
        addBlock(self.backupURL1);
        addBlock(self.backupURL2);
        addBlock(self.backupURL3);
    }

    return [array copy];
}

- (CGFloat)getValueFloat:(NSInteger)key {
    switch (key) {
        case VALUE_VOLUME_LOUDNESS:
            return _loudness;
        case VALUE_VOLUME_PEAK:
            return _peak;
        default:
            return 0.0f;
    }
}

- (NSNumber *)getValueNumber:(NSInteger)key {
    if (_apiVer >= TTVideoEnginePlayAPIVersion2) {
        switch (key) {
            case VALUE_VWIDTH:
                return _vWidth_ver2;
            case VALUE_VHEIGHT:
                return _vHeight_ver2;
            case VALUE_SIZE:
                return _size_ver2;
            case VALUE_PRELOAD_SIZE:
                return _preloadSize_ver2;
            case VALUE_PRELOAD_MIN_STEP:
                return _preLoadMinStep_ver2;
            case VALUE_PRELOAD_MAX_STEP:
                return _preLoadMaxStep_ver2;
            case VALUE_PRELOAD_INTERVAL:
                return _preloadInterval_ver2;
            case VALUE_URL_EXPIRE:
                return _urlExpire;
            default:
                return nil;
        }
    } else {
        switch (key) {
            case VALUE_VWIDTH:
                return _vWidth;
            case VALUE_VHEIGHT:
                return _vHeight;
            case VALUE_SIZE:
                return _size;
            case VALUE_PRELOAD_SIZE:
                return _preloadSize;
            case VALUE_PRELOAD_MIN_STEP:
                return _playLoadMinStep;
            case VALUE_PRELOAD_MAX_STEP:
                return _playLoadMaxStep;
            case VALUE_URL_EXPIRE:
                return _urlExpire;
            default:
                return nil;
        }
    }
}

- (NSString *)getValueStr:(NSInteger)key {
    if (_apiVer >= TTVideoEnginePlayAPIVersion2) {
        switch (key) {
            case VALUE_MAIN_URL:
                return _mainURLStr_ver2;
            case VALUE_FILE_HASH:
                return _fileHash_ver2;
            case VALUE_PLAY_AUTH:
                return _spade_a_ver2;
            case VALUE_FORMAT_TYPE:
                return _vType_ver2;
            case VALUE_CODEC_TYPE:
                return _codecType_ver2;
            case VALUE_DEFINITION:
                return _defination_ver2;
            case VALUE_LOGO_TYPE:
                return _logoType;
            case VALUE_QUALITY:
                return _quality_ver2;
            case VALUE_BACKUP_URL_1:
                return _backupURL1_ver2;
            case VALUE_MEDIA_TYPE:
                return _mediaType_ver2;
            case VALUE_CHECK_INFO:
                return _checkInfo_ver2;
            case VALUE_FILE_ID:
                return _fieldId;
            case VALUE_P2P_VERIFYURL:
                return _p2pVerifyUrl;
            default:
                return nil;
        }
    } else {
        switch (key) {
            case VALUE_MAIN_URL:
                return _mainURLStr;
            case VALUE_BACKUP_URL_1:
                return _backupURL1;
            case VALUE_BACKUP_URL_2:
                return _backupURL2;
            case VALUE_BACKUP_URL_3:
                return _backupURL3;
            case VALUE_FILE_HASH:
                return _fileHash;
            case VALUE_DEFINITION:
                return _definition;
            case VALUE_PLAY_AUTH:
                return _spade_a;
            case VALUE_FORMAT_TYPE:
                return _vType;
            case VALUE_CODEC_TYPE:
                return _codecType;
            case VALUE_QUALITY:
                return _audioQuality;
            case VALUE_MEDIA_TYPE:
                return _mediaType;
            case VALUE_LOGO_TYPE:
                return _logoType;
            case VALUE_CHECK_INFO:
                return _checkInfo;
            case VALUE_VIDEO_QUALITY_DESC:
                return _qualityDesc;
            case VALUE_BARRAGE_MASK_OFFSET:
                return _barrageMaskOffset;
            case VALUE_BARRAGE_MASK_URL:
                return _barrageMaskUrl;
            case VALUE_AI_BARRAGE_URL:
                return _aiBarrageUrl;
            default:
                return nil;
        }
    }
}

- (NSInteger)getValueInt:(NSInteger)key {
    if (_apiVer >= TTVideoEnginePlayAPIVersion2) {
        switch (key) {
            case VALUE_BITRATE:
                return _bitrate_ver2;
            case VALUE_QUALITY_TYPE:
                return _qualityType;
            case VALUE_VIDEO_HEAD_SIZE:
                return (NSInteger)self.fitterInfo.headerSize;
            default:
                return -1;
        }
    } else {
        switch (key) {
            case VALUE_BITRATE:
                return _bitrate;
            case VALUE_QUALITY_TYPE:
                return _qualityType;
            case VALUE_VIDEO_HEAD_SIZE:
                return (NSInteger)self.fitterInfo.headerSize;
            default:
                return -1;
        }
    }
}

- (void)_parsePacketOffset:(NSString *)info {
    if (info == nil || [info length] <= 0) {
        return;
    }

    NSError *err             = nil;
    NSData  *jsonData        = [info dataUsingEncoding:NSUTF8StringEncoding];
    NSArray *packetOffsetArr = [NSJSONSerialization JSONObjectWithData:jsonData
                                                               options:0
                                                                 error:&err];

    if (err != nil || packetOffsetArr == nil || [packetOffsetArr count] <= 0) {
        return;
    }

    _packetOffset = [[NSMutableDictionary alloc] init];

    //"pkt_offset": "[[371,6266385]]" 371(s) 6266385(file_offset)
    for (int i = 0; i < [packetOffsetArr count]; i++) {
        NSArray *packetArray = packetOffsetArr[i];
        if (packetArray && [packetArray count] == 2 &&
            [packetArray[0] isKindOfClass:[NSNumber class]] &&
            [packetArray[1] isKindOfClass:[NSNumber class]]) {
            NSNumber *time      = packetArray[0];
            NSNumber *offset    = packetArray[1];
            _packetOffset[time] = offset;
        }
    }
}

- (BOOL)getValueBool:(NSInteger)key {
    if (_apiVer >= TTVideoEnginePlayAPIVersion2) {

    } else {
        switch (key) {
            case VALUE_ENCRYPT:
                return _encrypt;
            default:
                return NO;
        }
    }
    return NO;
}

- (NSDictionary *)toMediaInfoDict {
    NSMutableDictionary *temDict = [NSMutableDictionary dictionary];
    [temDict setValue:self.fieldId forKey:@"file_id"];
    [temDict setValue:[self getValueStr:VALUE_MEDIA_TYPE] forKey:@"media_type"];
    [temDict setValue:[self getValueNumber:VALUE_SIZE] forKey:@"file_size"];
    [temDict setObject:@([self getValueInt:VALUE_BITRATE]) forKey:@"bitrate"];
    [temDict setValue:[self getValueStr:VALUE_QUALITY] forKey:@"quality"];
    [temDict setValue:[self getValueNumber:VALUE_VWIDTH] forKey:@"width"];
    [temDict setValue:[self getValueNumber:VALUE_VHEIGHT] forKey:@"height"];
    [temDict setValue:[self getValueStr:VALUE_CODEC_TYPE] forKey:@"codec"];
    [temDict setValue:[self _getAllUrls] forKey:@"urls"];
    [temDict setValue:[self getValueStr:VALUE_FILE_HASH] forKey:@"file_hash"];
    [temDict setValue:[self getValueStr:VALUE_DEFINITION] forKey:@"definition"];
    return temDict.copy;
}

- (void)parseMediaDict:(NSDictionary *)info {
    self.setFileId(info[@"file_id"]);
    self.setVType(info[@"media_type"]);
    self.setSize(info[@"file_size"]);
    self.setBitrate([info[@"bitrate"] integerValue]);
    self.setQualityDesc(info[@"quality"]);
    self.setVWidth(info[@"width"]);
    self.setVHeight(info[@"height"]);
    self.setCodecType(info[@"codec"]);
    self.setFileHash(info[@"file_hash"]);
    self.setDefinition(info[@"definition"]);
    NSArray *urls = info[@"urls"];
    self.setMainURLStr([urls ttvideoengine_objectAtIndex:0]);
    self.setBackupURL1([urls ttvideoengine_objectAtIndex:1]);
    self.setBackupURL2([urls ttvideoengine_objectAtIndex:2]);
    self.setBackupURL3([urls ttvideoengine_objectAtIndex:3]);
}

- (NSDictionary *)videoEngineUrlInfoToDict {
    return @{
        @"main_url" : [self getValueStr:VALUE_MAIN_URL] ? :@"",
        @"backup_url_1" : [self getValueStr:VALUE_BACKUP_URL_1] ? :@"",
        @"bitrate" : @([self getValueInt:VALUE_BITRATE]),
        @"vwidth" : [self getValueNumber:VALUE_VWIDTH] ? :@(0),
        @"vheight" : [self getValueNumber:VALUE_VHEIGHT] ? :@(0),
        @"init_range" : self.bashInitRange ? :@"",
        @"index_range" : self.bashIndexRange ? :@"",
        @"check_info" : [self getValueStr:VALUE_CHECK_INFO] ? :@"",
        @"kid" : self.kid ? :@"",
        @"loudness" : @([self getValueFloat:VALUE_VOLUME_LOUDNESS]),
        @"peak" : @([self getValueFloat:VALUE_VOLUME_PEAK]),
        @"info_id" : @(self.infoId)
    };
}

/// MARK:  NSSecureCoding

TTVIDEOENGINE_NSSECURECODING_IMPLEMENTATON

- (NSString *)description {
    return [self ttvideoengine_debugDescription];
}

- (nonnull instancetype _Nonnull (^)(NSNumber *_Nonnull))setVHeight {
    assert(_apiVer == TTVideoEnginePlayAPIVersion1);
    return ^(NSNumber *vHeight) {
        self.vHeight = vHeight;
        return self;
    };
}

- (nonnull instancetype _Nonnull (^)(NSNumber *_Nonnull))setVWidth {
    assert(_apiVer == TTVideoEnginePlayAPIVersion1);
    return ^(NSNumber *vWidth) {
        self.vWidth = vWidth;
        return self;
    };
}

- (nonnull instancetype _Nonnull (^)(NSNumber *_Nonnull))setUrlExpire {
    assert(_apiVer == TTVideoEnginePlayAPIVersion1);
    return ^(NSNumber *urlExpire) {
        self.urlExpire = urlExpire;
        return self;
    };
}

- (nonnull instancetype _Nonnull (^)(NSInteger))setBitrate {
    assert(_apiVer == TTVideoEnginePlayAPIVersion1);
    return ^(NSInteger bitrate) {
        self.bitrate = bitrate;
        return self;
    };
}

- (nonnull instancetype _Nonnull (^)(NSNumber *_Nonnull))setSize {
    assert(_apiVer == TTVideoEnginePlayAPIVersion1);
    return ^(NSNumber *size) {
        self.size = size;
        return self;
    };
}

- (nonnull instancetype _Nonnull (^)(NSString *_Nonnull))setCodecType {
    assert(_apiVer == TTVideoEnginePlayAPIVersion1);
    return ^(NSString *codecType) {
        self.codecType = codecType;
        return self;
    };
}

- (nonnull instancetype _Nonnull (^)(NSString *_Nonnull))setVType {
    assert(_apiVer == TTVideoEnginePlayAPIVersion1);
    return ^(NSString *vType) {
        self.vType = vType;
        return self;
    };
}

- (nonnull instancetype _Nonnull (^)(NSString *_Nonnull))setFileHash {
    assert(_apiVer == TTVideoEnginePlayAPIVersion1);
    return ^(NSString *fileHash) {
        self.fileHash = fileHash;
        return self;
    };
}

- (nonnull instancetype _Nonnull (^)(NSString *_Nonnull))setFileId {
    assert(_apiVer == TTVideoEnginePlayAPIVersion1);
    return ^(NSString *fileId) {
        self.fieldId = fileId;
        return self;
    };
}

- (nonnull instancetype _Nonnull (^)(NSString *_Nonnull))setQualityDesc {
    assert(_apiVer == TTVideoEnginePlayAPIVersion1);
    return ^(NSString *qualityDesc) {
        self.qualityDesc = qualityDesc;
        return self;
    };
}

- (nonnull instancetype _Nonnull (^)(NSString *_Nonnull))setDefinition {
    assert(_apiVer == TTVideoEnginePlayAPIVersion1);
    return ^(NSString *definition) {
        self.definition = definition;
        return self;
    };
}

- (nonnull instancetype _Nonnull (^)(NSString *_Nonnull))setSpade_a {
    assert(_apiVer == TTVideoEnginePlayAPIVersion1);
    return ^(NSString *spade_a) {
        self.spade_a = spade_a;
        return self;
    };
}

- (nonnull instancetype _Nonnull (^)(NSString *_Nonnull))setCheckInfo {
    assert(_apiVer == TTVideoEnginePlayAPIVersion1);
    return ^(NSString *checkInfo) {
        self.checkInfo = checkInfo;
        return self;
    };
}

- (nonnull instancetype _Nonnull (^)(NSString *_Nonnull))setMediaType {
    assert(_apiVer == TTVideoEnginePlayAPIVersion1);
    return ^(NSString *mediaType) {
        self.mediaType = mediaType;
        return self;
    };
}

- (nonnull instancetype _Nonnull (^)(NSString *_Nonnull))setMainURLStr {
    assert(_apiVer == TTVideoEnginePlayAPIVersion1);
    return ^(NSString *URLStr) {
        self.mainURLStr = URLStr;
        return self;
    };
}

- (nonnull instancetype _Nonnull (^)(NSString *_Nonnull))setBackupURL1 {
    assert(_apiVer == TTVideoEnginePlayAPIVersion1);
    return ^(NSString *URLStr) {
        self.backupURL1 = URLStr;
        return self;
    };
}

- (nonnull instancetype _Nonnull (^)(NSString *_Nonnull))setBackupURL2 {
    assert(_apiVer == TTVideoEnginePlayAPIVersion1);
    return ^(NSString *URLStr) {
        self.backupURL2 = URLStr;
        return self;
    };
}

- (nonnull instancetype _Nonnull (^)(NSString *_Nonnull))setBackupURL3 {
    assert(_apiVer == TTVideoEnginePlayAPIVersion1);
    return ^(NSString *URLStr) {
        self.backupURL3 = URLStr;
        return self;
    };
}

@end

/// MARK: - TTVideoEngineURLInfoMap
/// MARK: -
@implementation TTVideoEngineURLInfoMap
/// Please use @property.

- (instancetype)init {
    if (self = [super init]) {
        _videoInfoList = [NSMutableArray array];
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)jsonDict
                         mediaType:(NSString *)mediaType
                               key:(NSString *)key {
    self = [super init];
    if (self) {
        _videoInfoList     = [NSMutableArray array];
        _videoModelVersion = [checkNSNull(jsonDict[@"version"]) integerValue];
        if (_videoModelVersion == TTVideoEngineVideoModelVersion3) {
            NSArray *video_list = checkNSNull(jsonDict[@"video_list"]);
            for (NSDictionary *dict in video_list) {
                NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:0];
                [dictionary setObject:@(TTVideoEngineVideoModelVersion3) forKey:@"version"];
                if (checkNSNull(jsonDict[@"url_expire"]) != nil) {
                    [dictionary setObject:checkNSNull(jsonDict[@"url_expire"])
                                   forKey:@"url_expire"];
                }
                [dictionary addEntriesFromDictionary:dict];
                TTVideoEngineURLInfo *info =
                    [[TTVideoEngineURLInfo alloc] initWithDictionary:dictionary
                                                           mediaType:mediaType
                                                                 key:nil];
                [_videoInfoList addObject:info];
            }
        } else {
            if (checkNSNull(jsonDict[@"video_1"])) {
                _video1 = [[TTVideoEngineURLInfo alloc]
                    initWithDictionary:checkNSNull(jsonDict[@"video_1"])
                             mediaType:mediaType
                                   key:key];
                [_videoInfoList addObject:_video1];
            }
            if (checkNSNull(jsonDict[@"video_2"])) {
                _video2 = [[TTVideoEngineURLInfo alloc]
                    initWithDictionary:checkNSNull(jsonDict[@"video_2"])
                             mediaType:mediaType
                                   key:key];
                [_videoInfoList addObject:_video2];
            }
            if (checkNSNull(jsonDict[@"video_3"])) {
                _video3 = [[TTVideoEngineURLInfo alloc]
                    initWithDictionary:checkNSNull(jsonDict[@"video_3"])
                             mediaType:mediaType
                                   key:key];
                [_videoInfoList addObject:_video3];
            }
            if (checkNSNull(jsonDict[@"video_4"])) {
                _video4 = [[TTVideoEngineURLInfo alloc]
                    initWithDictionary:checkNSNull(jsonDict[@"video_4"])
                             mediaType:mediaType
                                   key:key];
                [_videoInfoList addObject:_video4];
            }
            if (checkNSNull(jsonDict[@"video_5"])) {
                _video5 = [[TTVideoEngineURLInfo alloc]
                    initWithDictionary:checkNSNull(jsonDict[@"video_5"])
                             mediaType:mediaType
                                   key:key];
                [_videoInfoList addObject:_video5];
            }
            if (checkNSNull(jsonDict[@"video_6"])) {
                _video6 = [[TTVideoEngineURLInfo alloc]
                    initWithDictionary:checkNSNull(jsonDict[@"video_6"])
                             mediaType:mediaType
                                   key:key];
                [_videoInfoList addObject:_video6];
            }
            if (checkNSNull(jsonDict[@"video_7"])) {
                _video7 = [[TTVideoEngineURLInfo alloc]
                    initWithDictionary:checkNSNull(jsonDict[@"video_7"])
                             mediaType:mediaType
                                   key:key];
                [_videoInfoList addObject:_video7];
            }
            if (checkNSNull(jsonDict[@"video_8"])) {
                _video8 = [[TTVideoEngineURLInfo alloc]
                    initWithDictionary:checkNSNull(jsonDict[@"video_8"])
                             mediaType:mediaType
                                   key:key];
                [_videoInfoList addObject:_video8];
            }
        }
    }

    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)jsonDict mediaType:(NSString *)mediaType {
    return [self initWithDictionary:jsonDict mediaType:mediaType key:nil];
}

- (void)setUpResolutionMap:(NSDictionary *)map {
    if (!map || map.count == 0) {
        return;
    }
    //
    if (_video1) {
        [_video1 setUpResolutionMap:map];
    }
    if (_video2) {
        [_video2 setUpResolutionMap:map];
    }
    if (_video3) {
        [_video3 setUpResolutionMap:map];
    }
    if (_video4) {
        [_video4 setUpResolutionMap:map];
    }
    if (_video5) {
        [_video5 setUpResolutionMap:map];
    }
    if (_video6) {
        [_video6 setUpResolutionMap:map];
    }
    if (_video7) {
        [_video7 setUpResolutionMap:map];
    }
    if (_video8) {
        [_video8 setUpResolutionMap:map];
    }
}

- (TTVideoEngineURLInfo *)videoForResolutionType:(TTVideoEngineResolutionType)type
                                  otherCondition:(NSDictionary *)searchCondition {
    if (_videoInfoList != nil && [_videoInfoList count] > 0) {
        for (TTVideoEngineURLInfo *info in _videoInfoList) {
            if (searchCondition != nil || searchCondition.count > 0) {
                NSString *value = [searchCondition objectForKey:@(VALUE_VIDEO_QUALITY_DESC)];
                if (value != nil &&
                    [value isEqualToString:[info getValueStr:VALUE_VIDEO_QUALITY_DESC]]) {
                    return info;
                }
            }
            if ([info getVideoDefinitionType] != type) {
                continue;
            }
            if (searchCondition == nil || searchCondition.count == 0) {
                return info;
            }

            BOOL isFound = YES;
            for (NSNumber *key in searchCondition) {
                NSString *value     = [searchCondition objectForKey:key];
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
    }
    return nil;
}

/// MARK:  NSSecureCoding

TTVIDEOENGINE_NSSECURECODING_IMPLEMENTATON

- (NSString *)description {
    return [self ttvideoengine_debugDescription];
}

@end

/// MARK: - TTVideoEngineDynamicVideo
/// MARK: -
@interface TTVideoEngineDynamicVideo ()

@property (nonatomic, assign) BOOL hasVideo;
@end

@implementation TTVideoEngineDynamicVideo

- (instancetype)initWithDictionary:(NSDictionary *)jsonDict key:(NSString *)key {
    self = [super init];
    if (self) {
        _videoModelVersion = [checkNSNull(jsonDict[@"version"]) integerValue];
        if (_videoModelVersion == TTVideoEngineVideoModelVersion3) {
            _mainURL   = checkNSNull(jsonDict[@"main_url"]);
            _backupURL = checkNSNull(jsonDict[@"backup_url"]);
        } else {
            _mainURL =
                [TTVideoEngineURLInfo transformedFromBase64:checkNSNull(jsonDict[@"main_url"])
                                                        key:key];
            _backupURL =
                [TTVideoEngineURLInfo transformedFromBase64:checkNSNull(jsonDict[@"backup_url_1"])
                                                        key:key];
        }
                
        _dynamicType                      = checkNSNull(jsonDict[@"dynamic_type"]);
        NSArray        *dynamicVideoArray = checkNSNull(jsonDict[@"dynamic_video_list"]);
        NSMutableArray *temArray          = [NSMutableArray array];
        NSMutableArray *temAudioArray     = [NSMutableArray array];
        NSMutableArray *temOriAudioArray  = [NSMutableArray array];
        NSInteger infoId                  = 0;
        for (NSDictionary *dict in dynamicVideoArray) {
            NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
            if (_videoModelVersion == TTVideoEngineVideoModelVersion3) {
                [dictionary setValue:@(infoId++) forKey:@"info_id"];
                [dictionary setObject:@(TTVideoEngineVideoModelVersion3) forKey:@"version"];
                if (checkNSNull(jsonDict[@"url_expire"]) != nil) {
                    [dictionary setObject:checkNSNull(jsonDict[@"url_expire"])
                                   forKey:@"url_expire"];
                }
                [dictionary addEntriesFromDictionary:dict];
            } else {
                [dictionary setObject:@(TTVideoEngineVideoModelVersion1) forKey:@"version"];
                [dictionary addEntriesFromDictionary:dict];
            }
            TTVideoEngineURLInfo *info = [[TTVideoEngineURLInfo alloc] initWithDictionary:dictionary
                                                                                mediaType:@"video"
                                                                                      key:key];
            _hasVideo                  = YES;
            [temArray addObject:info];
        }
        _dynamicVideoInfoV3 = temArray.copy;
        
        BOOL needSetDefaultAudio = NO;
        NSArray *dubbedAudioArray = checkNSNull(jsonDict[@"dynamic_dubbed_audios"]);
        for (NSDictionary *dict in dubbedAudioArray) {
            NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
            [dictionary setValue:@(infoId++) forKey:@"info_id"];
            if(_videoModelVersion == TTVideoEngineVideoModelVersion3){
                [dictionary setObject:@(TTVideoEngineVideoModelVersion3) forKey:@"version"];
                if(checkNSNull(jsonDict[@"url_expire"]) != nil){
                    [dictionary setObject:checkNSNull(jsonDict[@"url_expire"]) forKey:@"url_expire"];
                }
                [dictionary addEntriesFromDictionary:dict];
            }else{
                [dictionary setObject:@(TTVideoEngineVideoModelVersion1) forKey:@"version"];
                [dictionary addEntriesFromDictionary:dict];
            }
            TTVideoEngineURLInfo *info = [[TTVideoEngineURLInfo alloc] initWithDictionary:dictionary mediaType:@"audio" key:key];
            
            if (!needSetDefaultAudio)
                needSetDefaultAudio = YES;
            
            [temArray addObject:info];
            [temAudioArray addObject:info];
        }
        _dubbedAudioInfo = temAudioArray.copy;
        
        NSArray *dynamicAudioArray = checkNSNull(jsonDict[@"dynamic_audio_list"]);
        for (NSDictionary *dict in dynamicAudioArray) {
            NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
            [dictionary setValue:@(infoId++) forKey:@"info_id"];
            if (_videoModelVersion == TTVideoEngineVideoModelVersion3) {
                [dictionary setObject:@(TTVideoEngineVideoModelVersion3) forKey:@"version"];
                if (checkNSNull(jsonDict[@"url_expire"]) != nil) {
                    [dictionary setObject:checkNSNull(jsonDict[@"url_expire"])
                                   forKey:@"url_expire"];
                }
                [dictionary addEntriesFromDictionary:dict];
            } else {
                [dictionary setObject:@(TTVideoEngineVideoModelVersion1) forKey:@"version"];
                [dictionary addEntriesFromDictionary:dict];
            }
            TTVideoEngineURLInfo *info = [[TTVideoEngineURLInfo alloc] initWithDictionary:dictionary
                                                                                mediaType:@"audio"
                                                                                      key:key];
            if (needSetDefaultAudio && _defaultAudioInfoId < 0) {
                _defaultAudioInfoId = info.infoId;
                needSetDefaultAudio = NO;
            }
            [temArray addObject:info];
            [temAudioArray addObject:info];
            [temOriAudioArray addObject:info];
        }
        _dynamicAudioInfoV3 = temAudioArray.copy;
        _dynamicVideoInfo   = temArray.copy;
        _originalAudioInfo = temOriAudioArray;
    }

    return self;
}

- (void)setUpResolutionMap:(NSDictionary *)map {
    if (!map || map.count == 0) {
        return;
    }
    //
    if (_dynamicVideoInfo) {
        for (NSInteger i = _dynamicVideoInfo.count - 1; i >= 0; i--) {
            TTVideoEngineURLInfo *obj = [_dynamicVideoInfo objectAtIndex:i];
            [obj setUpResolutionMap:map];
        }
    }
}

- (TTVideoEngineURLInfo *)videoForResolutionType:(TTVideoEngineResolutionType)type
                                       mediaType:(NSString *)mediaType
                                  otherCondition:(NSDictionary *)searchCondition {
    TTVideoEngineLog(@"find videoInfo from dynamic: type = %d, mediaType = %@, other = %@",
                     (int)type,
                     mediaType,
                     searchCondition);
    TTVideoEngineURLInfo *retInfo = nil;
    if (searchCondition && searchCondition.count > 0) {
        BOOL isFound = NO;
        for (TTVideoEngineURLInfo *info in self.dynamicVideoInfo) {
            for (NSNumber *key in searchCondition) {
                NSString *value     = [searchCondition objectForKey:key];
                NSString *infoValue = [info getValueStr:key.integerValue];
                if (value && infoValue && [value isEqualToString:infoValue]) {
                    retInfo = info;
                    isFound = YES;
                    break;
                }
            }
            if (isFound) {
                break;
            }
        }
        if (isFound) {
            return retInfo;
        }
    }

    for (TTVideoEngineURLInfo *info in self.dynamicVideoInfo) {
        if (![[info getValueStr:VALUE_MEDIA_TYPE] isEqualToString:mediaType]) {
            continue;
        }

        if (info.videoDefinitionType != type) {
            continue;
        }

        retInfo = info;
        break;
    }
    return retInfo;
}

- (TTVideoEngineURLInfo *)videoForResolutionType:(TTVideoEngineResolutionType)type {
    return [self videoForResolutionType:type mediaType:@"video" otherCondition:nil];
}

- (NSArray *)allURLForVideoID:(NSString *)videoID transformedURL:(BOOL)transformed {
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:2];

    void (^addBlock)(NSString *) = ^(NSString *urlStr) {
        if (isEmptyStringForVideoPlayer(urlStr)) {
            return;
        }
        [array addObject:urlStr];
    };

    addBlock(self.mainURL);
    addBlock(self.backupURL);

    return [array copy];
}

/// MARK:  NSSecureCoding

TTVIDEOENGINE_NSSECURECODING_IMPLEMENTATON

- (NSString *)description {
    return [self ttvideoengine_debugDescription];
}

//MARK: - TTS
- (NSArray<TTVideoEngineURLInfo *> *)getSupportedTTSAudioInfo {
    return self.dubbedAudioInfo;
}

- (NSArray<TTVideoEngineURLInfo *> *)getOriginalAudioInfo {
    return self.originalAudioInfo;
}

- (NSArray<NSNumber *> *)getSupportedMediaInfoIds:(NSString *)mediaType {
    NSMutableArray *resultArr = [NSMutableArray array];
    if ([mediaType isEqualToString:@"audio"]) {
        for (TTVideoEngineURLInfo *info in self.dynamicAudioInfoV3) {
            [resultArr addObject:@(info.infoId)];
        }
    } else if ([mediaType isEqualToString:@"video"]) {
        for (TTVideoEngineURLInfo *info in self.dynamicVideoInfoV3) {
            [resultArr addObject:@(info.infoId)];
        }
    }
    return resultArr;
}

- (TTVideoEngineURLInfo *)getUrlInfoWithMediaInfoId:(NSInteger)infoId {
    if (infoId < 0 || self.dynamicVideoInfo.count <= 0)
        return nil;
    for (TTVideoEngineURLInfo *info in self.dynamicVideoInfo) {
        if (info.infoId == infoId)
            return info;
    }
    return nil;
}

@end

/// MARK: - TTVideoEngineLiveURLInfo
/// MARK: -
@implementation TTVideoEngineLiveURLInfo
/// Please use @property.

- (instancetype)initWithDictionary:(NSDictionary *)jsonDict {
    self = [super init];
    if (self) {
        _mainPlayURL   = [checkNSNull(jsonDict[@"main_play_url"]) copy];
        _backupPlayURL = [checkNSNull(jsonDict[@"backup_play_url"]) copy];
    }
    return self;
}

/// MARK: NSSecureCoding

TTVIDEOENGINE_NSSECURECODING_IMPLEMENTATON

- (NSString *)description {
    return [self ttvideoengine_debugDescription];
}

@end

/// MARK: - TTVideoEngineLiveVideo
/// MARK: -
@implementation TTVideoEngineLiveVideo
/// Please use @property.

- (instancetype)initWithDictionary:(NSDictionary *)jsonDict {
    self = [super init];
    if (self) {
        _backupStatus = [checkNSNull(jsonDict[@"backup_status"]) integerValue];
        _liveStatus   = [checkNSNull(jsonDict[@"live_status"]) integerValue];
        _status       = [checkNSNull(jsonDict[@"status"]) integerValue];
        _startTime    = [checkNSNull(jsonDict[@"start_time"]) longLongValue];
        _endTime      = [checkNSNull(jsonDict[@"end_time"]) longLongValue];
        _liveURLInfos = [NSMutableArray array];
        if (checkNSNull(jsonDict[@"live_0"])) {
            TTVideoEngineLiveURLInfo *live0 = [[TTVideoEngineLiveURLInfo alloc]
                initWithDictionary:checkNSNull(jsonDict[@"live_0"])];
            [_liveURLInfos addObject:live0];
        }
        if (checkNSNull(jsonDict[@"live_1"])) {
            TTVideoEngineLiveURLInfo *live1 = [[TTVideoEngineLiveURLInfo alloc]
                initWithDictionary:checkNSNull(jsonDict[@"live_1"])];
            [_liveURLInfos addObject:live1];
        }
    }
    return self;
}

- (NSArray *)allURLForVideoID:(NSString *)videoID transformedURL:(BOOL)transformed {
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:2];

    void (^addBlock)(NSString *) = ^(NSString *urlStr) {
        if (isEmptyStringForVideoPlayer(urlStr)) {
            return;
        }
        [array addObject:urlStr];
    };

    TTVideoEngineLiveURLInfo *liveInfo = nil;
    if (self.liveURLInfos.count) {
        liveInfo = self.liveURLInfos[0];
    }
    addBlock(liveInfo.mainPlayURL);
    addBlock(liveInfo.backupPlayURL);

    return [array copy];
}

/// MARK:  NSSecureCoding

TTVIDEOENGINE_NSSECURECODING_IMPLEMENTATON

- (NSString *)description {
    return [self ttvideoengine_debugDescription];
}

@end

/// MARK: - TTVideoEngineAdaptiveInfo
/// MARK: -
@implementation TTVideoEngineAdaptiveInfo

- (instancetype)initWithDictionary:(NSDictionary *)jsonDict {
    self = [super init];
    if (self) {
        _mainPlayURL   = checkNSNull(jsonDict[@"MainPlayUrl"]);
        _backupPlayURL = checkNSNull(jsonDict[@"BackupPlayUrl"]);
        _adaptiveType  = checkNSNull(jsonDict[@"AdaptiveType"]);
    }
    return self;
}

- (NSArray *)allURLForVideoID:(NSString *)videoID transformedURL:(BOOL)transformed {
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:2];

    void (^addBlock)(NSString *) = ^(NSString *urlStr) {
        if (isEmptyStringForVideoPlayer(urlStr)) {
            return;
        }
        [array addObject:urlStr];
    };

    addBlock(self.mainPlayURL);
    addBlock(self.backupPlayURL);

    return [array copy];
}

/// MARK:  NSSecureCoding

TTVIDEOENGINE_NSSECURECODING_IMPLEMENTATON

- (NSString *)description {
    return [self ttvideoengine_debugDescription];
}

@end

/// MARK: - TTVideoEngineSeekTS
/// MARK: -
@interface                              TTVideoEngineSeekTS ()
@property (nonatomic, assign) CGFloat   opening_ver2; //片头，单位: 秒
@property (nonatomic, assign) CGFloat   ending_ver2;  //片尾, 单位: 秒
@property (nonatomic, assign) NSInteger apiVer;
@end
@implementation TTVideoEngineSeekTS

- (instancetype)initWithDictionary:(NSDictionary *)jsonDict {
    self = [super init];
    if (self) {
        if (checkNSNull(jsonDict[@"opening"]) != nil || checkNSNull(jsonDict[@"ending"]) != nil) {
            _apiVer  = TTVideoEnginePlayAPIVersion1;
            _opening = [checkNSNull(jsonDict[@"opening"]) floatValue];
            _ending  = [checkNSNull(jsonDict[@"ending"]) floatValue];
        } else {
            _apiVer       = TTVideoEnginePlayAPIVersion2;
            _opening_ver2 = [checkNSNull(jsonDict[@"Opening"]) floatValue];
            _ending_ver2  = [checkNSNull(jsonDict[@"Ending"]) floatValue];
        }
    }
    return self;
}

- (CGFloat)getValueFloat:(NSInteger)key {
    if (_apiVer >= TTVideoEnginePlayAPIVersion2) {
        switch (key) {
            case VALUE_SEEKTS_OPENING:
                return _opening_ver2;
            case VALUE_SEEKTS_ENDING:
                return _ending_ver2;
            default:
                return -1;
        }
    } else {
        switch (key) {
            case VALUE_SEEKTS_OPENING:
                return _opening;
            case VALUE_SEEKTS_ENDING:
                return _ending;
            default:
                return -1;
        }
    }
}

/// MARK:  NSSecureCoding

TTVIDEOENGINE_NSSECURECODING_IMPLEMENTATON

- (NSString *)description {
    return [self ttvideoengine_debugDescription];
}

@end

/// MARK: - TTVideoEngineMediaFitterInfo
/// MARK: -
@implementation TTVideoEngineMediaFitterInfo

- (instancetype)initWithDictionary:(NSDictionary *)jsonDict {
    self = [super init];
    if (self) {
        NSArray *funcParams = checkNSNull(jsonDict[@"func_params"]);
        if (funcParams && [funcParams isKindOfClass:[NSArray class]] && [funcParams count] > 0) {
            _functionParams = [NSMutableArray arrayWithArray:funcParams];
        }
        _headerSize   = [checkNSNull(jsonDict[@"header_size"]) unsignedIntegerValue];
        _duration     = [checkNSNull(jsonDict[@"duration"]) unsignedIntegerValue];
        _functionType = [checkNSNull(jsonDict[@"func_method"]) unsignedIntegerValue];
    }
    return self;
}

- (NSUInteger)calculateSizeBySecond:(double)second {
    if (!_functionParams || second > _duration || second < 0) {
        return 0;
    }

    if (_functionType == 0) {
        return [self caclulateSizeDefaultFunc:second];
    } else if (_functionType == 1) {
        return [self caclulateSizeFunc2:second];
    }

    return 0;
}

- (NSUInteger)caclulateSizeDefaultFunc:(double)second {

    double fitting_size = 0.0, temp;

    if ([_functionParams count] > 50) {
        // more than 50 just return
        return 0;
    }

    for (int i = 0; i < [_functionParams count]; ++i) {
        temp = 1;
        for (int j = 0; j < ([_functionParams count] - i - 1); ++j) {
            temp *= second;
        }
        temp *= [_functionParams[i] doubleValue];
        fitting_size += temp;
    }

    double result = fitting_size * second * 1024 / 8;

    return (int)result;
}

- (NSUInteger)caclulateSizeFunc2:(double)second {

    if (!_functionParams || [_functionParams count] != 3) {
        return 0;
    }

    double p1 = [_functionParams[0] doubleValue];
    double p0 = [_functionParams[1] doubleValue];
    double n  = [_functionParams[2] doubleValue];

    double bitrate = p1 / pow(second, n) + p0;

    double result_size = (int)(bitrate * second) * 1024 / 8;

    return result_size;
}

/// MARK:  NSSecureCoding

TTVIDEOENGINE_NSSECURECODING_IMPLEMENTATON

- (NSString *)description {
    return [self ttvideoengine_debugDescription];
}

@end

/// MARK: - TTVideoEngineVideoStyle
/// MARK: -
@implementation TTVideoEngineVideoStyle

- (instancetype)initWithDictionary:(NSDictionary *)jsonDict {
    self = [super init];
    if (self) {
        _videoStyle = [checkNSNull(jsonDict[@"vstyle"]) integerValue];
        _dimension = [checkNSNull(jsonDict[@"dimension"]) integerValue];
        _projectionModel = [checkNSNull(jsonDict[@"projection_model"]) integerValue];
        _viewSize = [checkNSNull(jsonDict[@"view_size"]) integerValue];
    }
    return self;
}

/// MARK:  NSSecureCoding

TTVIDEOENGINE_NSSECURECODING_IMPLEMENTATON

- (NSString *)description {
    return [self ttvideoengine_debugDescription];
}

@end

/// MARK: - TTVideoEngineInfoModel
/// MARK: -
static NSInteger const kModelEffectiveDuration = 40 * 60 * 1; // 40 min

@interface TTVideoEngineInfoModel ()

@property (nonatomic, copy) NSString *videoID_ver2;
@property (nonatomic, copy) NSString *mediaType_ver2;
@property (nonatomic, copy) NSString *posterUrl_ver2;

@property (nonatomic, strong) NSMutableArray<TTVideoEngineURLInfo *> *videoInfoList_ver2;

@property (nonatomic, strong) TTVideoEngineLiveVideo *liveVideo_ver2;

@property (nonatomic, strong) NSNumber *videoDuration_ver2;
@property (nonatomic, assign) NSInteger videoStatusCode_ver2;
@property (nonatomic, assign) NSInteger totalCount_ver2;

@property (nonatomic, assign) BOOL      hasByteVC1Codec;
@property (nonatomic, assign) BOOL      hasByteVC2Codec;
@property (nonatomic, assign) BOOL      hasH264Codec;
@property (nonatomic, assign) BOOL      hasVideo;
@property (nonatomic, assign) NSInteger apiVer;

@property (nonatomic, strong) NSMutableArray<NSString *> *codecList;

@property (nonatomic, assign) NSTimeInterval createTimeInterval;
@property (nonatomic, strong) NSArray       *supportedResolutionTypes;
@property (nonatomic, strong) NSDictionary  *resolutionMap;
@property (nonatomic, assign) CGFloat        loudness;
@property (nonatomic, assign) CGFloat        peak;
@property (nonatomic, copy) NSString        *fullscreen_strategy;
@end

@implementation TTVideoEngineInfoModel

- (BOOL)hasExpired {
    NSTimeInterval nowTimeInterval = [[NSDate date] timeIntervalSince1970];
    long long      expire          = _urlExpire.longLongValue;
    if (_videoModelVersion == TTVideoEngineVideoModelVersion3 && expire > 1.0) {
        if (nowTimeInterval > expire) {
            return YES;
        }
        return NO;
    } else if (_createTimeInterval > 1.0) {
        return nowTimeInterval >= (_createTimeInterval + kModelEffectiveDuration);
    }
    return YES;
}

- (instancetype)init {
    if (self = [super init]) {
        _createTimeInterval = [[NSDate date] timeIntervalSince1970];
        _videoURLInfoMap = [[TTVideoEngineURLInfoMap alloc] init];
        _apiVer = TTVideoEnginePlayAPIVersion1;
        _videoModelVersion = TTVideoEngineVideoModelVersion1;
    }
    return self;
}

- (instancetype)initVideoInfoWithPb:(NSData *)data {
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)jsonDict {
    return [self initWithDictionary:jsonDict encrypted:NO];
}

- (instancetype)initWithDictionary:(NSDictionary *)jsonDict encrypted:(BOOL)encrypted {
    self = [super init];
    if (self) {
        _createTimeInterval = [[NSDate date] timeIntervalSince1970];

        if (checkNSNull(jsonDict[@"VideoID"]) != nil) {
            _apiVer = TTVideoEnginePlayAPIVersion2;
        } else {
            _apiVer = TTVideoEnginePlayAPIVersion1;
        }

        if (_apiVer >= TTVideoEnginePlayAPIVersion2) {
            _videoID_ver2         = checkNSNull(jsonDict[@"VideoID"]);
            _videoDuration_ver2   = checkNSNull(jsonDict[@"Duration"]);
            _videoStatusCode_ver2 = [checkNSNull(jsonDict[@"Status"]) integerValue];
            _posterUrl_ver2       = checkNSNull(jsonDict[@"CoverUrl"]);
            _mediaType_ver2       = checkNSNull(jsonDict[@"MediaType"]);
            _totalCount_ver2      = [checkNSNull(jsonDict[@"TotalCount"]) integerValue];
            _enableAdaptive       = [jsonDict ttVideoEngineBoolValueForKey:@"enable_adaptive"
                                                        defaultValue:NO];
            _videoModelVersion    = TTVideoEngineVideoModelVersion2;
            NSDictionary *adaptiveInfoDict = checkNSNull(jsonDict[@"AdaptiveInfo"]);
            if (adaptiveInfoDict && adaptiveInfoDict.count) {
                _adaptiveInfo = [[TTVideoEngineAdaptiveInfo alloc]
                    initWithDictionary:checkNSNull(jsonDict[@"AdaptiveInfo"])];
            }
            NSArray *bigThumbsArray = checkNSNull(jsonDict[@"BigThumbs"]);
            _bigThumbs              = [NSMutableArray array];
            for (NSDictionary *bigThumbDict in bigThumbsArray) {
                TTVideoEngineThumbInfo *thumbInfo =
                    [[TTVideoEngineThumbInfo alloc] initWithDictionary:bigThumbDict];
                [_bigThumbs addObject:thumbInfo];
            }
            NSDictionary *seekTsDict = checkNSNull(jsonDict[@"Seekts"]);
            if (seekTsDict.count) {
                _seekTs = [[TTVideoEngineSeekTS alloc]
                    initWithDictionary:checkNSNull(jsonDict[@"Seekts"])];
            }
            NSArray *videoInfoArray = checkNSNull(jsonDict[@"PlayInfoList"]);
            if (videoInfoArray != nil && [videoInfoArray count] > 0) {
                _videoInfoList_ver2 = [NSMutableArray array];
                for (NSDictionary *dict in videoInfoArray) {
                    TTVideoEngineURLInfo *info =
                        [[TTVideoEngineURLInfo alloc] initWithDictionary:dict
                                                               mediaType:_mediaType_ver2];
                    if (!_hasByteVC1Codec) {
                        if ([[info getValueStr:VALUE_CODEC_TYPE]
                                isEqualToString:kTTVideoEngineCodecByteVC1]) {
                            _hasByteVC1Codec = YES;
                        }
                    }
                    if (!_hasByteVC2Codec) {
                        if ([[info getValueStr:VALUE_CODEC_TYPE]
                                isEqualToString:kTTVideoEngineCodecByteVC2]) {
                            _hasByteVC2Codec = YES;
                        }
                    }
                    if (!_hasH264Codec) {
                        if ([[info getValueStr:VALUE_CODEC_TYPE]
                                isEqualToString:kTTVideoEngineCodecH264]) {
                            _hasH264Codec = YES;
                        }
                    }

                    if ([[info getValueStr:VALUE_MEDIA_TYPE] isEqualToString:@"video"]) {
                        _hasVideo = YES;
                    }
                    [_videoInfoList_ver2 addObject:info];
                }
            }

            NSDictionary *live_video = checkNSNull(jsonDict[@"live_info"]);
            if (live_video) {
                _liveVideo_ver2 = [[TTVideoEngineLiveVideo alloc] initWithDictionary:live_video];
            }
            NSData *tmpData = [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:nil];
            _refString      = [[NSString alloc] initWithData:tmpData encoding:NSUTF8StringEncoding];
        } else {
            _hasEmbeddedSubtitle = [jsonDict ttVideoEngineBoolValueForKey:@"has_embedded_subtitle"
                                                             defaultValue:NO];
            _subtitleInfos       = checkNSNull(jsonDict[@"subtitle_infos"]);
            _videoModelVersion   = [jsonDict ttVideoEngineIntegerValueForKey:@"version"
                                                              defaultValue:1];
            _videoID             = checkNSNull(jsonDict[@"video_id"]);
            if (!_videoID) {
                _videoID = checkNSNull(jsonDict[@"live_id"]);
            }
            _decodingMode  = checkNSNull(jsonDict[@"optimal_decoding_mode"]);
            _userID        = checkNSNull(jsonDict[@"user_id"]);
            _videoDuration = checkNSNull(jsonDict[@"video_duration"]);
            _mediaType = [jsonDict ttVideoEngineStringValueForKey:@"media_type" defaultValue:nil];
            _autoDefinition  = checkNSNull(jsonDict[@"auto_definition"]);
            _videoStatusCode = [jsonDict ttVideoEngineIntegerValueForKey:@"status" defaultValue:0];
            _enableAdaptive  = [jsonDict ttVideoEngineBoolValueForKey:@"enable_adaptive"
                                                        defaultValue:NO];
            NSDictionary *volume = [jsonDict ttVideoEngineDictionaryValueForKey:@"volume"
                                                                   defaultValue:nil];
            if (volume && volume.count) {
                if (checkNSNull(volume[@"loudness"]) != nil ||
                    checkNSNull(volume[@"peak"]) != nil) {
                    _loudness = [checkNSNull(volume[@"loudness"]) floatValue];
                    _peak     = [checkNSNull(volume[@"peak"]) floatValue];
                }
            }
            _pallasVidLabels = checkNSNull(jsonDict[@"pallas_vid_labels"]);
            
            _fullscreen_strategy = checkNSNull(jsonDict[@"full_screen_strategy"]);
            NSDictionary *maskInfoDict = [jsonDict ttVideoEngineDictionaryValueForKey:@"barrage_mask_info"
                                                                       defaultValue:nil];
            if (maskInfoDict && maskInfoDict.count) {
                _maskInfo = [[TTVideoEngineMaskInfo alloc]
                    initWithDictionary:checkNSNull(jsonDict[@"barrage_mask_info"])];
            }
            if (_videoModelVersion == TTVideoEngineVideoModelVersion3) {
                NSDictionary *fallbackApi =
                    [jsonDict ttVideoEngineDictionaryValueForKey:@"fallback_api" defaultValue:nil];
                if (fallbackApi && fallbackApi.count) {
                    _fallbackAPI = checkNSNull(fallbackApi[@"fallback_api"]);
                    _keyseed     = checkNSNull(fallbackApi[@"key_seed"]);
                }
                _urlExpire          = checkNSNull(jsonDict[@"url_expire"]);
                _popularityLevel    = [jsonDict ttVideoEngineIntegerValueForKey:@"popularity_level"
                                                                defaultValue:0];
                _barrageMaskUrl     = checkNSNull(jsonDict[@"barrage_mask_url"]);
                if(_maskInfo){
                    _barrageMaskUrl = _maskInfo.maskUrl;
                }
                _aiBarrageUrl       = checkNSNull(jsonDict[@"effect_barrage_url"]);
                NSArray *video_list = [jsonDict ttVideoEngineArrayValueForKey:@"video_list"
                                                                 defaultValue:nil];
                if (video_list != nil && [video_list count] > 0) {
                    if ([_mediaType isEqualToString:@"video"]) {
                        _hasVideo = YES;
                    }
                    _videoURLInfoMap = [[TTVideoEngineURLInfoMap alloc]
                        initWithDictionary:jsonDict
                                 mediaType:_mediaType
                                       key:encrypted ? _keyseed : nil];
                }

                NSDictionary *dynamic_video =
                    [jsonDict ttVideoEngineDictionaryValueForKey:@"dynamic_video" defaultValue:nil];
                if (dynamic_video && dynamic_video.count) {
                    NSMutableDictionary *dynamic_dict =
                        [NSMutableDictionary dictionaryWithCapacity:0];
                    [dynamic_dict setObject:@(TTVideoEngineVideoModelVersion3) forKey:@"version"];
                    [dynamic_dict addEntriesFromDictionary:dynamic_video];
                    _dynamicVideo = [[TTVideoEngineDynamicVideo alloc]
                        initWithDictionary:dynamic_dict
                                       key:encrypted ? _keyseed : nil];
                }
                if (dynamic_video && dynamic_video.count) {
                    [self getNewModelRefString:jsonDict key:encrypted ? _keyseed : nil];
                }
                
                NSDictionary *video_style_dict = [jsonDict ttVideoEngineDictionaryValueForKey:@"video_style" defaultValue:nil];
                if (video_style_dict && video_style_dict.count) {
                    _videoStyle = [[TTVideoEngineVideoStyle alloc] initWithDictionary:video_style_dict];
                }
            } else {
                if (!_videoModelVersion) {
                    _videoModelVersion = TTVideoEngineVideoModelVersion1;
                }
                _fallbackAPI     = checkNSNull(jsonDict[@"fallback_api"]);
                _keyseed         = checkNSNull(jsonDict[@"key_seed"]); /// before url info parse.
                _validate        = checkNSNull(jsonDict[@"validate"]);
                _popularityLevel = [checkNSNull(jsonDict[@"popularity_level"]) integerValue];
                _barrageMaskUrl  = [TTVideoEngineURLInfo
                    transformedFromBase64:checkNSNull(jsonDict[@"barrage_mask_url"])
                                      key:encrypted ? _keyseed : nil];
                if(_maskInfo){
                    _barrageMaskUrl = [TTVideoEngineURLInfo
                                       transformedFromBase64:_maskInfo.maskUrl
                                                         key:encrypted ? _keyseed : nil];
                }
                NSDictionary *video_list =
                    [jsonDict ttVideoEngineDictionaryValueForKey:@"video_list" defaultValue:nil];
                if (video_list && video_list.count) {
                    if ([_mediaType isEqualToString:@"video"]) {
                        _hasVideo = YES;
                    }
                    _videoURLInfoMap = [[TTVideoEngineURLInfoMap alloc]
                        initWithDictionary:video_list
                                 mediaType:_mediaType
                                       key:encrypted ? _keyseed : nil];
                }
                NSDictionary *dynamic_video =
                    [jsonDict ttVideoEngineDictionaryValueForKey:@"dynamic_video" defaultValue:nil];
                if (dynamic_video && dynamic_video.count) {
                    _dynamicVideo = [[TTVideoEngineDynamicVideo alloc]
                        initWithDictionary:dynamic_video
                                       key:encrypted ? _keyseed : nil];
                }
                NSDictionary *live_video = [jsonDict ttVideoEngineDictionaryValueForKey:@"live_info"
                                                                           defaultValue:nil];
                if (live_video) {
                    _liveVideo = [[TTVideoEngineLiveVideo alloc] initWithDictionary:live_video];
                }
                if (dynamic_video && dynamic_video.count) {
                    [self getRefString:jsonDict key:encrypted ? _keyseed : nil];
                }
            }
            NSDictionary *seekTsDict = [jsonDict ttVideoEngineDictionaryValueForKey:@"seek_ts"
                                                                       defaultValue:nil];
            if (seekTsDict.count) {
                _seekTs = [[TTVideoEngineSeekTS alloc]
                    initWithDictionary:checkNSNull(jsonDict[@"seek_ts"])];
            }
            _enableSSL = [jsonDict ttVideoEngineBoolValueForKey:@"enable_ssl" defaultValue:NO];
            NSArray *bigThumbsArray = checkNSNull(jsonDict[@"big_thumbs"]);
            _bigThumbs              = [NSMutableArray array];
            for (NSDictionary *bigThumbDict in bigThumbsArray) {
                TTVideoEngineThumbInfo *thumbInfo =
                    [[TTVideoEngineThumbInfo alloc] initWithDictionary:bigThumbDict];
                [_bigThumbs addObject:thumbInfo];
            }
        }
        self.memString = [self toMemString];
        [self setUpResolutionMap:TTVideoEngineDefaultVideoResolutionMap()];
    }
    return self;
}

- (NSArray<TTVideoEngineURLInfo *> *)getVideoList {
    if (_apiVer >= TTVideoEnginePlayAPIVersion2) {
        return self.videoInfoList_ver2;
    }
    NSArray<TTVideoEngineURLInfo *> *videoList = nil;
    if (self.videoURLInfoMap && self.videoURLInfoMap.videoInfoList.count > 0) {
        videoList = self.videoURLInfoMap.videoInfoList;
    }
    if (self.dynamicVideo && self.dynamicVideo.dynamicVideoInfo.count > 0) {
        videoList = self.dynamicVideo.dynamicVideoInfo;
    }
    return videoList;
}

- (NSString *)toMemString {
    NSArray<TTVideoEngineURLInfo *> *infolist  = [self getVideoList];
    NSMutableArray<NSDictionary *>  *videoList = [NSMutableArray new];
    NSMutableArray<NSDictionary *>  *audioList = [NSMutableArray new];
    [infolist enumerateObjectsUsingBlock:^(
                  TTVideoEngineURLInfo *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        NSString *mediaType =
            _apiVer >= TTVideoEnginePlayAPIVersion2 ? obj.mediaType_ver2 : obj.mediaType;
        if ([mediaType isEqualToString:@"video"]) {
            if ([obj.vType isEqualToString:@"mp4"] && _enableAdaptive && obj.peak == 0.0f) {
                obj.loudness = _loudness;
                obj.peak = _peak;
            }
            [videoList addObject:[self videoEngineUrlInfoToDict:obj]];
        } else if ([mediaType isEqualToString:@"audio"]) {
            if(obj.peak == 0.0f){
                obj.loudness = _loudness;
                obj.peak = _peak;
            }
            [audioList addObject:[self videoEngineUrlInfoToDict:obj]];
        }
    }];
    NSDictionary *infoDic = @{@"dynamic_video_list" : videoList, @"dynamic_audio_list" : audioList};
    NSError      *error;
    NSData   *jsonData = [NSJSONSerialization dataWithJSONObject:infoDic options:0 error:&error];
    NSString *jsonStr  = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return jsonStr;
}

- (NSDictionary *)videoEngineUrlInfoToDict:(TTVideoEngineURLInfo *)videoEngineUrlInfo {
    NSDictionary *dict = _apiVer >= TTVideoEnginePlayAPIVersion2
                           ? @{
                                 @"main_url" : videoEngineUrlInfo.mainURLStr_ver2 ?: @"",
                                 @"backup_url_1" : videoEngineUrlInfo.backupURL1_ver2 ?: @"",
                                 @"bitrate" : @(videoEngineUrlInfo.bitrate_ver2),
                                 @"vwidth" : videoEngineUrlInfo.vWidth_ver2 ?: @(0),
                                 @"vheight" : videoEngineUrlInfo.vHeight_ver2 ?: @(0),
                                 @"init_range" : videoEngineUrlInfo.bashInitRange ?: @"",
                                 @"index_range" : videoEngineUrlInfo.bashIndexRange ?: @"",
                                 @"check_info" : videoEngineUrlInfo.checkInfo_ver2 ?: @"",
                                 @"kid" : videoEngineUrlInfo.kid ?: @"",
                                 @"loudness" : @(videoEngineUrlInfo.loudness),
                                 @"peak" : @(videoEngineUrlInfo.peak),
                                 @"info_id" : @(videoEngineUrlInfo.infoId)
                             }
                           : @{
                                 @"main_url" : videoEngineUrlInfo.mainURLStr ?: @"",
                                 @"backup_url_1" : videoEngineUrlInfo.backupURL1 ?: @"",
                                 @"bitrate" : @(videoEngineUrlInfo.bitrate),
                                 @"vwidth" : videoEngineUrlInfo.vWidth ?: @(0),
                                 @"vheight" : videoEngineUrlInfo.vHeight ?: @(0),
                                 @"init_range" : videoEngineUrlInfo.bashInitRange ?: @"",
                                 @"index_range" : videoEngineUrlInfo.bashIndexRange ?: @"",
                                 @"check_info" : videoEngineUrlInfo.checkInfo ?: @"",
                                 @"kid" : videoEngineUrlInfo.kid ?: @"",
                                 @"loudness" : @(videoEngineUrlInfo.loudness),
                                 @"peak" : @(videoEngineUrlInfo.peak),
                                 @"info_id" : @(videoEngineUrlInfo.infoId)
                             };
    return dict;
}

- (void)setUpResolutionMap:(NSDictionary *)map {
    if (!map || map.count == 0) {
        return;
    }
    //
    _resolutionMap = map;
    // video-map
    TTVideoEngineURLInfoMap *infoMap = _videoURLInfoMap;
    if (infoMap) {
        [infoMap setUpResolutionMap:map];
    }
    // video-list
    NSArray *videoList_ver2 = _videoInfoList_ver2;
    if (videoList_ver2) {
        for (TTVideoEngineURLInfo *obj in videoList_ver2) {
            [obj setUpResolutionMap:map];
        }
    }
    NSArray *videoList_ver3 = self.videoURLInfoMap.videoInfoList;
    if (videoList_ver3) {
        for (TTVideoEngineURLInfo *obj in videoList_ver3) {
            [obj setUpResolutionMap:map];
        }
    }
    // dynamic-video
    TTVideoEngineDynamicVideo *dynamicVideo = _dynamicVideo;
    if (dynamicVideo) {
        [dynamicVideo setUpResolutionMap:map];
    }
}

- (void)getNewModelRefString:(NSDictionary *)jsonDict key:(NSString *)key {
    NSMutableDictionary *dynamicDict = [NSMutableDictionary dictionary];
    NSMutableDictionary *innerDict   = [NSMutableDictionary dictionary];
    NSMutableArray      *videoArray  = [NSMutableArray array];
    NSMutableArray      *audioArray  = [NSMutableArray array];
    if (_dynamicVideo) {
        for (TTVideoEngineURLInfo *info in _dynamicVideo.dynamicVideoInfoV3) {
            NSDictionary *videoInfoMutable = info.getVideoInfo;
            [videoArray addObject:videoInfoMutable];
        }
        for (TTVideoEngineURLInfo *info in _dynamicVideo.dynamicAudioInfoV3) {
            NSDictionary *audioInfoMutable = info.getVideoInfo;
            [audioArray addObject:audioInfoMutable];
        }
    }
    innerDict[@"dynamic_video_list"] = videoArray;
    innerDict[@"dynamic_audio_list"] = audioArray;
    dynamicDict[@"dynamic_video"]    = innerDict;
    NSData *tmpData = [NSJSONSerialization dataWithJSONObject:dynamicDict options:0 error:nil];
    self.refString  = [[NSString alloc] initWithData:tmpData encoding:NSUTF8StringEncoding];
}

- (void)getRefString:(NSDictionary *)jsonDict key:(NSString *)key {
    _videoModelVersion                 = [checkNSNull(jsonDict[@"version"]) integerValue];
    NSMutableDictionary *dynamicDict   = [NSMutableDictionary dictionaryWithDictionary:jsonDict];
    NSMutableDictionary *innerDict     = [jsonDict[@"dynamic_video"] mutableCopy];
    NSArray             *videoListDict = checkNSNull([innerDict[@"dynamic_video_list"] copy]);
    NSMutableArray      *videoArray    = [NSMutableArray array];
    for (NSDictionary *info in videoListDict) {
        NSMutableDictionary *videoInfoMutable = [info mutableCopy];
        NSString            *video_main_url, *video_backup_url_1;
        if (_videoModelVersion == TTVideoEngineVideoModelVersion3) {
            video_main_url     = checkNSNull(videoInfoMutable[@"main_url"]);
            video_backup_url_1 = checkNSNull(videoInfoMutable[@"backup_url_1"]);
        } else {
            video_main_url     = [TTVideoEngineURLInfo
                transformedFromBase64:checkNSNull(videoInfoMutable[@"main_url"])
                                  key:key];
            video_backup_url_1 = [TTVideoEngineURLInfo
                transformedFromBase64:checkNSNull(videoInfoMutable[@"backup_url_1"])
                                  key:key];
        }
        videoInfoMutable[@"main_url"]     = video_main_url;
        videoInfoMutable[@"backup_url_1"] = video_backup_url_1;
        [videoArray addObject:videoInfoMutable];
    }

    NSArray        *audioListDict = [innerDict[@"dynamic_audio_list"] copy];
    NSMutableArray *audioArray    = [NSMutableArray array];
    for (NSDictionary *info in audioListDict) {
        NSMutableDictionary *audioInfoMutable = [info mutableCopy];
        NSString            *audio_main_url =
            [TTVideoEngineURLInfo transformedFromBase64:checkNSNull(audioInfoMutable[@"main_url"])
                                                    key:key];
        NSString *audio_backup_url_1      = [TTVideoEngineURLInfo
            transformedFromBase64:checkNSNull(audioInfoMutable[@"backup_url_1"])
                              key:key];
        audioInfoMutable[@"main_url"]     = audio_main_url;
        audioInfoMutable[@"backup_url_1"] = audio_backup_url_1;
        [audioArray addObject:audioInfoMutable];
    }
    innerDict[@"dynamic_audio_list"] = audioArray;
    innerDict[@"dynamic_video_list"] = videoArray;
    dynamicDict[@"dynamic_video"]    = innerDict;
    NSData *tmpData = [NSJSONSerialization dataWithJSONObject:dynamicDict options:0 error:nil];
    _refString      = [[NSString alloc] initWithData:tmpData encoding:NSUTF8StringEncoding];
}

- (NSArray *)allURLWithDefinition:(TTVideoEngineResolutionType)type
                   transformedURL:(BOOL)transformed {
    NSArray *urls = nil;
    if (self.apiVer >= TTVideoEnginePlayAPIVersion2) {
        if (self.adaptiveInfo) {
            return [self.adaptiveInfo allURLForVideoID:self.videoID transformedURL:transformed];
        } else {
            TTVideoEngineURLInfo *info = [self videoInfoForType:type];
            if (info) {
                urls = [info allURLForVideoID:self.videoID_ver2 transformedURL:transformed];
            }
        }
    } else {
        if (self.videoURLInfoMap.videoInfoList.count > 0) {
            TTVideoEngineURLInfo *info = [self.videoURLInfoMap videoForResolutionType:type
                                                                       otherCondition:_params];
            if (info) {
                urls = [info allURLForVideoID:self.videoID transformedURL:transformed];
            }
            return urls;
        }
        if (self.dynamicVideo) {
            urls = [self.dynamicVideo allURLForVideoID:self.videoID transformedURL:transformed];
            if (urls == nil || urls.count == 0) {
                TTVideoEngineURLInfo *info = [self.dynamicVideo videoForResolutionType:type];
                if (info) {
                    urls = [info allURLForVideoID:self.videoID transformedURL:transformed];
                }
                return urls;
            }
            return urls;
        }
        if (self.liveVideo) {
            return [self.liveVideo allURLForVideoID:self.videoID transformedURL:transformed];
        }
    }
    return urls;
}

- (NSInteger)videoSizeForType:(TTVideoEngineResolutionType)type {
    TTVideoEngineURLInfo *info = [self videoInfoForType:type];
    return [[info getValueNumber:VALUE_SIZE] integerValue];
}

- (NSString *)definitionStrForType:(TTVideoEngineResolutionType)type {
    __block NSString *resultString = @"";
    [_resolutionMap.copy enumerateKeysAndObjectsUsingBlock:^(
                             NSString *_Nonnull key, NSNumber *_Nonnull obj, BOOL *_Nonnull stop) {
        if (obj.integerValue == type) {
            resultString = key;
            *stop        = YES;
        }
    }];
    return resultString;
}

- (NSInteger)preloadSizeForType:(TTVideoEngineResolutionType)type {
    TTVideoEngineURLInfo *info = [self videoInfoForType:type];
    return [[info getValueNumber:VALUE_PRELOAD_SIZE] integerValue];
}

- (NSInteger)playLoadMaxStepForType:(TTVideoEngineResolutionType)type {
    TTVideoEngineURLInfo *info = [self videoInfoForType:type];
    return [[info getValueNumber:VALUE_PRELOAD_MAX_STEP] integerValue];
}

- (NSInteger)playLoadMinStepForType:(TTVideoEngineResolutionType)type {
    TTVideoEngineURLInfo *info = [self videoInfoForType:type];
    return [[info getValueNumber:VALUE_PRELOAD_MIN_STEP] integerValue];
}

- (TTVideoEngineURLInfo *)videoInfoForType:(TTVideoEngineResolutionType)type {
    NSString *mediaType = @"video";
    BOOL      hasVideo  = [self getValueBool:VALUE_HAS_VIDEO];
    if (!hasVideo) {
        mediaType = @"audio";
    }
    return [self videoInfoForType:type mediaType:mediaType otherCondition:_params];
}

- (TTVideoEngineURLInfo *)videoInfoForType:(TTVideoEngineResolutionType)type
                                 mediaType:(NSString *)mediaType
                            otherCondition:(NSMutableDictionary *)searchCondition {
    if (self.apiVer >= TTVideoEnginePlayAPIVersion2) {
        if (_videoInfoList_ver2 != nil && [_videoInfoList_ver2 count] > 0) {
            for (TTVideoEngineURLInfo *info in _videoInfoList_ver2) {
                if ([info getVideoDefinitionType] != type) {
                    continue;
                }
                if (![[info getValueStr:VALUE_MEDIA_TYPE] isEqualToString:mediaType]) {
                    continue;
                }

                if (searchCondition == nil || searchCondition.count == 0) {
                    return info;
                }

                BOOL isFound = YES;
                for (NSNumber *key in searchCondition) {
                    NSString *value     = [searchCondition objectForKey:key];
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

            return nil; // not found
        }
    } else {
        if (self.videoURLInfoMap.videoInfoList.count > 0) {
            TTVideoEngineURLInfo *info =
                [self.videoURLInfoMap videoForResolutionType:type otherCondition:searchCondition];
            return info;
        }
        if (self.dynamicVideo) {
            TTVideoEngineURLInfo *info = [self.dynamicVideo videoForResolutionType:type
                                                                         mediaType:mediaType
                                                                    otherCondition:searchCondition];
            return info;
        }
        return nil;
    }
    return nil;
}

- (NSArray *)codecTypes {
    if (self.codecList != nil) {
        return self.codecList;
    }
    self.codecList = [[NSMutableArray alloc] init];
    if (self.apiVer >= TTVideoEnginePlayAPIVersion2) {
        if (self.videoInfoList_ver2 != nil && [self.videoInfoList_ver2 count] > 0) {
            NSMutableArray *tmparray = [[NSMutableArray alloc] init];
            for (TTVideoEngineURLInfo *tmpinfo in self.videoInfoList_ver2) {
                [tmparray addObject:[tmpinfo getValueStr:VALUE_CODEC_TYPE]];
            }
            for (NSString *value in tmparray) {
                if (![self.codecList containsObject:value]) {
                    [self.codecList addObject:value];
                }
            }
        } else {
            return nil;
        }
    } else {
        TTVideoEngineURLInfo *info  = self.videoURLInfoMap.video1;
        NSString             *codec = @"";
        if (info) {
            codec = info.codecType;
        } else if (self.dynamicVideo.dynamicVideoInfo.count) {
            info  = [self.dynamicVideo.dynamicVideoInfo objectAtIndex:0];
            codec = info.codecType;
        }
        if (codec.length > 0) {
            [self.codecList addObject:codec];
        }
    }
    return self.codecList;
}

- (NSString *)videoType {
    TTVideoEngineURLInfo *info  = nil;
    NSString             *vtype = @"";
    if (self.apiVer >= TTVideoEnginePlayAPIVersion2) {
        if (self.videoInfoList_ver2 != nil && [self.videoInfoList_ver2 count] > 0) {
            info = [self.videoInfoList_ver2 objectAtIndex:0];
        }
        if (info) {
            vtype = [info getValueStr:VALUE_FORMAT_TYPE];
        }
        if (vtype.length > 0) {
            return vtype;
        }
        return @"mp4";
    } else {
        info = self.videoURLInfoMap.video1;
        if (info) {
            vtype = info.vType;
        } else if (self.dynamicVideo.dynamicVideoInfo.count) {
            info  = [self.dynamicVideo.dynamicVideoInfo objectAtIndex:0];
            vtype = info.vType;
        }
        if (vtype.length > 0) {
            return vtype;
        }
        return @"mp4";
    }
}

- (NSArray<NSString *> *)supportedQualityInfos {
    NSMutableArray *types = [NSMutableArray arrayWithCapacity:5];
    if (self.videoURLInfoMap.videoInfoList.count > 0) {
        for (TTVideoEngineURLInfo *info in _videoURLInfoMap.videoInfoList) {
            NSString *qualityDesc = [info getValueStr:VALUE_VIDEO_QUALITY_DESC];
            if (qualityDesc != nil && ![types containsObject:qualityDesc]) {
                [types addObject:qualityDesc];
            }
        }
    }
    TTVideoEngineDynamicVideo *dynamicVideo = _dynamicVideo;
    if (dynamicVideo) {
        for (TTVideoEngineURLInfo *info in dynamicVideo.dynamicVideoInfo) {
            NSString *qualityDesc = [info getValueStr:VALUE_VIDEO_QUALITY_DESC];
            if (qualityDesc != nil && ![types containsObject:qualityDesc]) {
                [types addObject:qualityDesc];
            }
        }
    }
    return types;
}

- (NSArray<NSNumber *> *)supportedResolutionTypes {
    NSMutableArray *types = [NSMutableArray arrayWithCapacity:3];
    if (self.apiVer >= TTVideoEnginePlayAPIVersion2) {
        NSUInteger allReslutionLen = TTVideoEngineAllResolutions().count + 2;
        NSUInteger resolutionArray[allReslutionLen];
        for (int i = 0; i < allReslutionLen; i++) {
            resolutionArray[i] = 0;
        }
        for (TTVideoEngineURLInfo *info in self.videoInfoList_ver2) {
            resolutionArray[[info getVideoDefinitionType]] = 1;
        }
        for (int i = 0; i < allReslutionLen; i++) {
            if (resolutionArray[i] == 1) {
                [self addIfNeededResolution:i toArray:types];
            }
        }
        return types;
    } else {
        if (self.videoURLInfoMap) {
            if (self.videoURLInfoMap.video1) {
                [self addIfNeededResolution:self.videoURLInfoMap.video1.videoDefinitionType
                                    toArray:types];
            }
            if (self.videoURLInfoMap.video2) {
                [self addIfNeededResolution:self.videoURLInfoMap.video2.videoDefinitionType
                                    toArray:types];
            }
            if (self.videoURLInfoMap.video3) {
                [self addIfNeededResolution:self.videoURLInfoMap.video3.videoDefinitionType
                                    toArray:types];
            }
            if (self.videoURLInfoMap.video4) {
                [self addIfNeededResolution:self.videoURLInfoMap.video4.videoDefinitionType
                                    toArray:types];
            }
            if (self.videoURLInfoMap.video5) {
                [self addIfNeededResolution:self.videoURLInfoMap.video5.videoDefinitionType
                                    toArray:types];
            }
            if (self.videoURLInfoMap.video6) {
                [self addIfNeededResolution:self.videoURLInfoMap.video6.videoDefinitionType
                                    toArray:types];
            }
            if (self.videoURLInfoMap.video7) {
                [self addIfNeededResolution:self.videoURLInfoMap.video7.videoDefinitionType
                                    toArray:types];
            }
            if (self.videoURLInfoMap.video8) {
                [self addIfNeededResolution:self.videoURLInfoMap.video8.videoDefinitionType
                                    toArray:types];
            }
            for (TTVideoEngineURLInfo *info in self.videoURLInfoMap.videoInfoList) {
                [self addIfNeededResolution:info.videoDefinitionType toArray:types];
            }
        }
        TTVideoEngineDynamicVideo *dynamicVideo = self.dynamicVideo;
        if (dynamicVideo) {
            for (TTVideoEngineURLInfo *info in dynamicVideo.dynamicVideoInfo) {
                NSString *mediaType = [info getValueStr:VALUE_MEDIA_TYPE];
                if (dynamicVideo.hasVideo && [mediaType isEqualToString:@"video"]) {
                    [self addIfNeededResolution:info.videoDefinitionType toArray:types];
                } else if (!dynamicVideo.hasVideo && [mediaType isEqualToString:@"audio"]) {
                    [self addIfNeededResolution:info.videoDefinitionType toArray:types];
                }
            }
        }
        return types;
    }
}
- (void)addIfNeededResolution:(TTVideoEngineResolutionType)resolution
                      toArray:(NSMutableArray<NSNumber *> *)array {
    for (NSNumber *number in array) {
        if (number.unsignedIntegerValue == resolution) {
            return;
        }
    }
    [array addObject:@(resolution)];
}

- (TTVideoEngineLiveVideo *)getLiveVideo {
    if (_apiVer >= TTVideoEnginePlayAPIVersion2) {
        return self.liveVideo_ver2;
    } else {
        return self.liveVideo;
    }
}

- (NSNumber *)getValueNumber:(NSInteger)key {
    if (_apiVer >= TTVideoEnginePlayAPIVersion2) {
        switch (key) {
            case VALUE_VIDEO_DURATION:
                return _videoDuration_ver2;
            default:
                return nil;
        }
    } else {
        switch (key) {
            case VALUE_VIDEO_DURATION:
                return _videoDuration;
            default:
                return nil;
        }
    }
}

- (NSString *)getValueStr:(NSInteger)key {
    if (_apiVer >= TTVideoEnginePlayAPIVersion2) {
        switch (key) {
            case VALUE_VIDEO_ID:
                return _videoID_ver2;
            case VALUE_POSTER_URL:
                return _posterUrl_ver2;
            case VALUE_MEDIA_TYPE:
                return _mediaType_ver2;
            case VALUE_DYNAMIC_TYPE:
                if (self.adaptiveInfo) {
                    return self.adaptiveInfo.adaptiveType;
                }
                return nil;
            case VALUE_VIDEO_REF_STRING:
                return _refString;
            default:
                return nil;
        }
    } else {
        switch (key) {
            case VALUE_VIDEO_ID:
                return _videoID;
            case VALUE_USER_ID:
                return _userID;
            case VALUE_MEDIA_TYPE:
                return _mediaType;
            case VALUE_AUTO_DEFINITION:
                return _autoDefinition;
            case VALUE_DYNAMIC_TYPE:
                if (self.dynamicVideo) {
                    return self.dynamicVideo.dynamicType;
                }
                return nil;
            case VALUE_VIDEO_REF_STRING:
                return _refString;
            case VALUE_BARRAGE_MASK_URL:
                return _barrageMaskUrl;
            case VALUE_AI_BARRAGE_URL:
                return _aiBarrageUrl;
            case VALUE_VIDEO_DECODING_MODE:
                return _decodingMode;
            case VALUE_FULLSCREEN_STRATEGY:
                return _fullscreen_strategy;
            case VALUE_MASK_FILE_HASH:
                if (self.maskInfo) {
                    return self.maskInfo.filehash;
                }
                return nil;
            default:
                return nil;
        }
    }
}

- (NSInteger)getValueInt:(NSInteger)key {
    if (_apiVer >= TTVideoEnginePlayAPIVersion2) {
        switch (key) {
            case VALUE_STATUS:
                return _videoStatusCode_ver2;
            case VALUE_TOTAL_COUNT:
                return _totalCount_ver2;
            default:
                return -1;
        }
    } else {
        switch (key) {
            case VALUE_STATUS:
                return _videoStatusCode;
            case VALUE_VIDEO_MODEL_VERSION:
                return _videoModelVersion;
            case VALUE_MASK_HEAD_LEN:
                if (self.maskInfo) {
                    return self.maskInfo.headLen;
                }
                return -1;
            case VALUE_MASK_FILE_SIZE:
                if (self.maskInfo) {
                    return [self.maskInfo getValueInt:key];
                }
                return -1;
            default:
                return -1;
        }
    }
}

- (NSMutableArray<TTVideoEngineURLInfo *> *)getValueArray:(NSInteger)key {
    if (_apiVer >= TTVideoEnginePlayAPIVersion2) {
        switch (key) {
            case VALUE_VIDEO_LIST:
                return _videoInfoList_ver2;
            default:
                return nil;
        }
    } else {
        switch (key) {
            case VALUE_VIDEO_LIST:
                if (self.dynamicVideo) {
                    return self.dynamicVideo.dynamicVideoInfo;
                } else if (self.videoURLInfoMap) {
                    return self.videoURLInfoMap.videoInfoList;
                }
                return nil;
            default:
                return nil;
        }
    }
    return nil;
}

- (BOOL)getValueBool:(NSInteger)key {
    if (_apiVer >= TTVideoEnginePlayAPIVersion2) {
        switch (key) {
            case VALUE_CODEC_HAS_BYTEVC1:
                return _hasByteVC1Codec;
            case VALUE_CODEC_HAS_BYTEVC2:
                return _hasByteVC2Codec;
            case VALUE_CODEC_HAS_H264:
                return _hasH264Codec;
            case VALUE_HAS_VIDEO:
                return _hasVideo;
            default:
                return NO;
        }
    } else {
        switch (key) {
            case VALUE_VIDEO_ENABLE_SSL:
                return _enableSSL;
            case VALUE_HAS_VIDEO:
                if (self.dynamicVideo) {
                    return self.dynamicVideo.hasVideo;
                }
                return _hasVideo;
            default:
                return NO;
        }
    }
}

- (CGFloat)getValueFloat:(NSInteger)key {
    switch (key) {
        case VALUE_VOLUME_LOUDNESS:
            return _loudness;
        case VALUE_VOLUME_PEAK:
            return _peak;
        default:
            return 0.0f;
    }
}

- (TTVideoEngineURLInfo *)videoInfoForType:(TTVideoEngineResolutionType)type
                                 mediaType:(NSString *)mediaType
                                    params:(NSDictionary *)params {
    NSAssert((type != TTVideoEngineResolutionTypeABRAuto), @"Code execution path error");

    if (type == TTVideoEngineResolutionTypeUnknown || type == TTVideoEngineResolutionTypeAuto) {
        type = [self autoResolution];
    }

    TTVideoEngineURLInfo       *info    = nil;
    TTVideoEngineResolutionType temType = type;
    if ((_videoModelVersion == TTVideoEngineVideoModelVersion3) &&
        !s_array_is_empty(sVideoEngineQualityInfos) && !s_dict_is_empty(params)) {
        NSArray  *allQualityInfos   = sVideoEngineQualityInfos;
        NSInteger qualityInfosCount = allQualityInfos.count;
        NSString *value             = [params objectForKey:@(VALUE_VIDEO_QUALITY_DESC)];
        if (value != nil && [sVideoEngineQualityInfos containsObject:value]) {
            NSInteger qualityIndex = [allQualityInfos indexOfObject:value];
            if (qualityIndex >= qualityInfosCount) {
                qualityIndex = qualityInfosCount - 1;
            }
            NSInteger initQualityIndex = qualityIndex;
            info = [self videoInfoForType:temType mediaType:mediaType otherCondition:params];
            while (info == nil) {
                qualityIndex         = (qualityIndex + qualityInfosCount - 1) % qualityInfosCount;
                NSString *temQuality = [sVideoEngineQualityInfos objectAtIndex:qualityIndex];
                NSMutableDictionary *dic1 = [NSMutableDictionary dictionary];
                [dic1 setValue:temQuality forKey:@(VALUE_VIDEO_QUALITY_DESC)];
                info = [self videoInfoForType:temType mediaType:mediaType otherCondition:dic1];
                if (info) {
                    return info;
                }
                if (qualityIndex == initQualityIndex) {
                    break;
                }
            }
            if (info != nil) {
                temType = [info getVideoDefinitionType];
            }
        }
    }

    NSArray  *allResolutions = TTVideoEngineAllResolutions();
    NSInteger count          = allResolutions.count;
    NSInteger index          = [allResolutions indexOfObject:@(temType)];
    if (index >= count) {
        index = count - 1;
    }

    NSInteger initIndex = index;

    info = [self videoInfoForType:temType mediaType:mediaType otherCondition:params];
    while (info == nil) {
        info   = [self videoInfoForType:temType mediaType:mediaType otherCondition:nil];
        params = nil;
        if (info) {
            break;
        }

        index                   = (index + count - 1) % count;
        NSNumber *temResolution = [allResolutions objectAtIndex:index];
        temType                 = temResolution.integerValue;
        if (temType == type) {
            break;
        }

        if (index == initIndex) {
            break;
        }
    }
    type = temType;
    return info;
}

- (TTVideoEngineURLInfo *)videoInfoForType:(TTVideoEngineResolutionType *)type
                                 mediaType:(NSString *)mediaType
                                  autoMode:(BOOL)mode {
    if (type == nil) {
        return nil;
    }
    NSAssert(((*type) != TTVideoEngineResolutionTypeABRAuto), @"Code execution path error");

    if (*type == TTVideoEngineResolutionTypeUnknown || *type == TTVideoEngineResolutionTypeAuto) {
        *type = [self autoResolution];
    }

    if (mode == NO) {
        return [self videoInfoForType:*type mediaType:mediaType otherCondition:_params];
    }
    //
    TTVideoEngineURLInfo       *info    = nil;
    TTVideoEngineResolutionType temType = *type;
    if ((_videoModelVersion == TTVideoEngineVideoModelVersion3) &&
        !s_array_is_empty(sVideoEngineQualityInfos) && !s_dict_is_empty(_params)) {
        NSArray  *allQualityInfos   = sVideoEngineQualityInfos;
        NSInteger qualityInfosCount = allQualityInfos.count;
        NSString *value             = [_params objectForKey:@(VALUE_VIDEO_QUALITY_DESC)];
        if (value != nil && [sVideoEngineQualityInfos containsObject:value]) {
            NSInteger qualityIndex = [allQualityInfos indexOfObject:value];
            if (qualityIndex >= qualityInfosCount) {
                qualityIndex = qualityInfosCount - 1;
            }
            NSInteger initQualityIndex = qualityIndex;
            info = [self videoInfoForType:temType mediaType:mediaType otherCondition:_params];
            while (info == nil) {
                qualityIndex         = (qualityIndex + qualityInfosCount - 1) % qualityInfosCount;
                NSString *temQuality = [sVideoEngineQualityInfos objectAtIndex:qualityIndex];
                NSMutableDictionary *dic1 = [NSMutableDictionary dictionary];
                [dic1 setValue:temQuality forKey:@(VALUE_VIDEO_QUALITY_DESC)];
                info = [self videoInfoForType:temType mediaType:mediaType otherCondition:dic1];
                if (info) {
                    return info;
                }
                if (qualityIndex == initQualityIndex) {
                    break;
                }
            }
            if (info != nil) {
                temType = [info getVideoDefinitionType];
            }
        }
    }

    NSArray  *allResolutions = TTVideoEngineAllResolutions();
    NSInteger count          = allResolutions.count;
    NSInteger index          = [allResolutions indexOfObject:@(temType)];
    if (index >= count) {
        index = count - 1;
    }

    NSInteger initIndex = index;

    info = [self videoInfoForType:temType mediaType:mediaType otherCondition:_params];
    while (info == nil) {
        info    = [self videoInfoForType:temType mediaType:mediaType otherCondition:nil];
        _params = nil;
        if (info) {
            break;
        }

        index                   = (index + count - 1) % count;
        NSNumber *temResolution = [allResolutions objectAtIndex:index];
        temType                 = temResolution.integerValue;
        if (temType == *type) {
            break;
        }

        if (index == initIndex) {
            break;
        }
    }
    *type = temType;
    return info;
}

- (TTVideoEngineURLInfo *)videoInfoForType:(TTVideoEngineResolutionType *)type autoMode:(BOOL)mode {
    NSString *mediaType = [self getValueBool:VALUE_HAS_VIDEO] ? @"video" : @"audio";
    return [self videoInfoForType:type mediaType:mediaType autoMode:mode];
}

- (NSArray<NSString *> *)allUrlsWithResolution:(TTVideoEngineResolutionType *)type
                                      autoMode:(BOOL)model {
    if (type == nil) {
        return nil;
    }
    NSAssert((*type != TTVideoEngineResolutionTypeABRAuto), @"Code execution path error");

    if (*type == TTVideoEngineResolutionTypeUnknown || *type == TTVideoEngineResolutionTypeAuto) {
        *type = [self autoResolution];
    }

    if (model == NO) {
        return [self allURLWithDefinition:*type transformedURL:YES];
    }
    //
    NSArray                    *temArray       = nil;
    TTVideoEngineResolutionType temType        = *type;
    NSArray                    *allResolutions = TTVideoEngineAllResolutions();
    NSInteger                   count          = allResolutions.count;
    NSInteger                   index          = [allResolutions indexOfObject:@(temType)];
    if (index >= count) {
        index = count - 1;
    }

    NSInteger initIndex = index;

    temArray = [self allURLWithDefinition:temType transformedURL:YES];
    while (temArray == nil) {
        _params  = nil;
        temArray = [self allURLWithDefinition:temType transformedURL:YES];
        if (temArray) {
            break;
        }

        index                   = (index + count - 1) % count;
        NSNumber *temResolution = [allResolutions objectAtIndex:index];
        temType                 = temResolution.integerValue;
        if (temType == *type) {
            break;
        }

        if (index == initIndex) {
            break;
        }
    }
    *type = temType;
    return temArray;
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[TTVideoEngineInfoModel class]]) {
        return NO;
    }

    if ([super isEqual:object]) {
        return YES;
    }

    TTVideoEngineInfoModel *other = (TTVideoEngineInfoModel *)object;
    BOOL                    videoId =
        [[self getValueStr:VALUE_VIDEO_ID] isEqualToString:[other getValueStr:VALUE_VIDEO_ID]];
    BOOL codec =
        [self getValueBool:VALUE_CODEC_HAS_BYTEVC1] ==
            [other getValueBool:VALUE_CODEC_HAS_BYTEVC1] &&
        [self getValueBool:VALUE_CODEC_HAS_BYTEVC2] == [other getValueBool:VALUE_CODEC_HAS_BYTEVC2];
    BOOL mediaType = [[self videoType] isEqualToString:[other videoType]];

    return videoId && codec && mediaType;
}

- (NSString *)getSpade_aForType:(TTVideoEngineResolutionType)type {

    NSString *temSpada = nil;

    TTVideoEngineURLInfo *info   = [self videoInfoForType:type];
    BOOL                  isDash = [[info getValueStr:VALUE_FORMAT_TYPE] isEqualToString:@"dash"] ||
                  [[info getValueStr:VALUE_FORMAT_TYPE] isEqualToString:@"mpd"];

    if (isDash) {
        NSArray *allResolutions = TTVideoEngineAllResolutions();
        for (int i = 0; i < allResolutions.count; i++) {
            NSNumber             *resolution = [allResolutions objectAtIndex:i];
            TTVideoEngineURLInfo *temInfo    = [self videoInfoForType:resolution.integerValue];
            NSString             *infoSpada  = [temInfo getValueStr:VALUE_PLAY_AUTH];
            if (infoSpada && ![infoSpada isEqualToString:@""]) {
                temSpada = infoSpada;
                break;
            }
        }
    } else {
        temSpada = [info getValueStr:VALUE_PLAY_AUTH];
    }
    return temSpada;
}

- (TTVideoEngineResolutionType)autoResolution {
    TTVideoEngineResolutionType temType = [[self supportedResolutionTypes] lastObject].integerValue;

    NSString *autoResolution = self.autoDefinition ?: @"";
    NSNumber *resolution     = [self.resolutionMap objectForKey:autoResolution];
    NSArray  *allResolutions = TTVideoEngineAllResolutions();
    if (resolution) {
        if ([allResolutions containsObject:resolution]) {
            temType = resolution.integerValue;
        }
    }
    return temType;
}

- (NSMutableDictionary *)toMediaInfoDict {
    NSString *format   = [self videoType];
    NSString *videoId  = [self getValueStr:VALUE_VIDEO_ID];
    NSInteger duration = [[self getValueNumber:VALUE_VIDEO_DURATION] integerValue];
    NSArray<TTVideoEngineURLInfo *> *infoList = [self getVideoList];
    NSMutableDictionary             *temDict  = [NSMutableDictionary dictionary];
    NSMutableArray                  *temArray = [NSMutableArray array];
    for (TTVideoEngineURLInfo *info in infoList) {
        [temArray addObject:info.toMediaInfoDict];
    }
    //
    if (_maskInfo) {
        [temArray addObject:_maskInfo.toMediaInfoDict];
    }
    
    [temDict setValue:format forKey:@"format"];
    [temDict setValue:videoId forKey:@"vid"];
    [temDict setObject:@(duration) forKey:@"duration"];
    [temDict setObject:temArray forKey:@"infos"];
    return temDict;
}

- (NSString *)toMediaInfoJsonString {
    return [self toMediaInfoDict].ttvideoengine_jsonString;
}

- (void)parseMediaDict:(NSDictionary *)json {
    _apiVer = TTVideoEnginePlayAPIVersion1;
    NSString *format = json[@"format"];
    self.setVideoID(json[@"vid"]);
    self.setVideoDuration(json[@"duration"]);
    NSArray *infos = json[@"infos"];
    for (NSDictionary *info in infos) {
        TTVideoEngineURLInfo *obj = [TTVideoEngineURLInfo new];
        obj.apiVer = TTVideoEnginePlayAPIVersion1;
        [obj parseMediaDict:info];
        obj.setMediaType(format);
        self.addVideoInfo(obj);
    }
}


/// MARK: NSSecureCoding

TTVIDEOENGINE_NSSECURECODING_IMPLEMENTATON

- (NSString *)description {
    return [self ttvideoengine_debugDescription];
}

- (nonnull instancetype _Nonnull (^)(NSString *_Nonnull))setVideoID {
    return ^(NSString *videoID) {
        self.videoID = videoID;
        return self;
    };
}

- (nonnull instancetype _Nonnull (^)(NSNumber *_Nonnull))setVideoDuration {
    return ^(NSNumber *videoDuration) {
        self.videoDuration = videoDuration;
        return self;
    };
}

- (nonnull instancetype _Nonnull (^)(CGFloat))setLoudness {
    return ^(CGFloat loudness) {
        self.loudness = loudness;
        return self;
    };
}

- (nonnull instancetype _Nonnull (^)(CGFloat))setPeak {
    return ^(CGFloat peak) {
        self.peak = peak;
        return self;
    };
}

- (nonnull instancetype _Nonnull (^)(BOOL))setAdaptive {
    return ^(BOOL enableAdaptive) {
        self.enableAdaptive = enableAdaptive;
        return self;
    };
}

- (nonnull instancetype _Nonnull (^)(TTVideoEngineURLInfo *_Nonnull))addVideoInfo {
    return ^(TTVideoEngineURLInfo *videoInfo) {
        [self.videoURLInfoMap.videoInfoList addObject:videoInfo];
        return self;
    };
}

@end
