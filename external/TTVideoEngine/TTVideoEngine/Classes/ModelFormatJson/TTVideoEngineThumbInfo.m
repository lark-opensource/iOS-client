//
//  TTVideoEngineThumbInfo.m
//  Pods
//
//  Created by guikunzhi on 2018/5/2.
//

#import "TTVideoEngineThumbInfo.h"
#import "NSObject+TTVideoEngine.h"
#import "TTVideoEngineInfoModel.h"
#import "TTVideoEnginePlayerDefine.h"


extern id checkNSNull(id obj);

@interface TTVideoEngineThumbInfo()
@property (nonatomic, assign) NSInteger imageNum_ver2;
@property (nonatomic, copy) NSString *uri_ver2;
@property (nonatomic, copy) NSString *imageURL_ver2;
@property (nonatomic, assign) NSInteger imageXSize_ver2;
@property (nonatomic, assign) NSInteger imageYSize_ver2;
@property (nonatomic, assign) NSInteger imageXLen_ver2;
@property (nonatomic, assign) NSInteger imageYLen_ver2;
@property (nonatomic, assign) CGFloat duration_ver2;
@property (nonatomic, assign) CGFloat interval_ver2;
@property (nonatomic, copy) NSString *fext_ver2;
@property (nonatomic, assign) NSInteger apiVer;
@end
@implementation TTVideoEngineThumbInfo
/// Please use @property.

- (instancetype)initWithDictionary:(NSDictionary *)jsonDict {
    if (!jsonDict) return nil;
    
    self = [super init];
    if (self) {
        if (checkNSNull(jsonDict[@"img_num"]) != nil) {
            _apiVer = TTVideoEnginePlayAPIVersion1;
        } else {
            _apiVer = TTVideoEnginePlayAPIVersion2;
        }
        
        if (_apiVer == TTVideoEnginePlayAPIVersion1) {
            _imageNum = [checkNSNull(jsonDict[@"img_num"]) integerValue];
            _uri = checkNSNull(jsonDict[@"uri"]);
            _imageURL = checkNSNull(jsonDict[@"img_url"]);
            _imageXSize = [checkNSNull(jsonDict[@"img_x_size"]) integerValue];
            _imageYSize = [checkNSNull(jsonDict[@"img_y_size"]) integerValue];
            _imageXLen = [checkNSNull(jsonDict[@"img_x_len"]) integerValue];
            _imageYLen = [checkNSNull(jsonDict[@"img_y_len"]) integerValue];
            _duration = [checkNSNull(jsonDict[@"duration"]) floatValue];
            _interval = [checkNSNull(jsonDict[@"interval"]) floatValue];
            _fext = checkNSNull(jsonDict[@"fext"]);
            _imageURLs = checkNSNull(jsonDict[@"img_urls"]);
        } else {
            _imageNum_ver2 = [checkNSNull(jsonDict[@"ImgNum"]) integerValue];
            _uri_ver2 = checkNSNull(jsonDict[@"Uri"]);
            _imageURL_ver2 = checkNSNull(jsonDict[@"ImgUrl"]);
            _imageXSize_ver2 = [checkNSNull(jsonDict[@"ImgXSize"]) integerValue];
            _imageYSize_ver2 = [checkNSNull(jsonDict[@"ImgYSize"]) integerValue];
            _imageXLen_ver2 = [checkNSNull(jsonDict[@"ImgXLen"]) integerValue];
            _imageYLen_ver2 = [checkNSNull(jsonDict[@"ImgYLen"]) integerValue];
            _duration_ver2 = [checkNSNull(jsonDict[@"Duration"]) floatValue];
            _interval_ver2 = [checkNSNull(jsonDict[@"Interval"]) floatValue];
            _fext_ver2 = checkNSNull(jsonDict[@"Fext"]);
        }
    }
    return self;
}

- (NSInteger)getValueInt:(NSInteger)key {
    if (_apiVer >= TTVideoEnginePlayAPIVersion2) {
        switch (key) {
            case VALUE_THUMB_IMG_NUM:
                return _imageNum_ver2;
            case VALUE_THUMB_IMG_X_SIZE:
                return _imageXSize_ver2;
            case VALUE_THUMB_IMG_Y_SIZE:
                return _imageYSize_ver2;
            case VALUE_THUMB_IMG_X_LEN:
                return _imageXLen_ver2;
            case VALUE_THUMB_IMG_Y_LEN:
                return _imageYLen_ver2;
            default:
                return -1;
        }
    } else {
        switch (key) {
            case VALUE_THUMB_IMG_NUM:
                return _imageNum;
            case VALUE_THUMB_IMG_X_SIZE:
                return _imageXSize;
            case VALUE_THUMB_IMG_Y_SIZE:
                return _imageYSize;
            case VALUE_THUMB_IMG_X_LEN:
                return _imageXLen;
            case VALUE_THUMB_IMG_Y_LEN:
                return _imageYLen;
            default:
                return -1;
        }
    }
}

- (CGFloat)getValueFloat:(NSInteger)key {
    if (_apiVer >= TTVideoEnginePlayAPIVersion2) {
        switch (key) {
            case VALUE_THUMB_DURATION:
                return _duration_ver2;
            case VALUE_THUMB_INTERVAL:
                return _interval_ver2;
            default:
                return -1;
        }
    } else {
        switch (key) {
            case VALUE_THUMB_DURATION:
                return _duration;
            case VALUE_THUMB_INTERVAL:
                return _interval;
            default:
                return -1;
        }
    }
}

- (NSString *)getValueStr:(NSInteger)key {
    if (_apiVer >= TTVideoEnginePlayAPIVersion2) {
        switch (key) {
            case VALUE_THUMB_URI:
                return _uri_ver2;
            case VALUE_THUMB_IMG_URL:
                return _imageURL_ver2;
            case VALUE_THUMB_FEXT:
                return _fext_ver2;
            default:
                return @"";
        }
    } else {
        switch (key) {
            case VALUE_THUMB_URI:
                return _uri;
            case VALUE_THUMB_IMG_URL:
                return _imageURL;
            case VALUE_THUMB_FEXT:
                return _fext;
            default:
                return @"";
        }
    }
}

- (NSMutableArray<NSString *> *)getValueArray:(NSInteger)key {
    switch(key) {
        case VALUE_THUMB_IMG_URLS:
            return _imageURLs;
        default:
            return nil;
    }
}



///MARK: - NSSecureCoding

TTVIDEOENGINE_NSSECURECODING_IMPLEMENTATON

- (NSString *)description {
    return [self ttvideoengine_debugDescription];
}

@end
