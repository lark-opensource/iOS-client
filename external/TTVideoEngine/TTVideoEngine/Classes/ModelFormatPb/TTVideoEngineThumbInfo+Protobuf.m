//
//  TTVideoEngineThumbInfo.m
//  Pods
//
//  Created by guikunzhi on 2018/5/2.
//

#import "TTVideoEngineThumbInfo+Protobuf.h"
#import "NSObject+TTVideoEngine.h"
#import "TTVideoEnginePlayerDefine.h"
#import "TTVideoEngineModel.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

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
@implementation TTVideoEngineThumbInfo (Protobuf)
/// Please use @property.

- (instancetype)initWithDictionaryPb:(TTVideoEnginePbBigThumb *)bigThumb {
    self = [super init];
    if (self) {
        self.imageNum = bigThumb.imgNum;
        self.uri = bigThumb.imgUri;
        self.imageURL = bigThumb.imgURL;
        self.imageXSize = bigThumb.imgXSize;
        self.imageYSize = bigThumb.imgYSize;
        self.imageXLen = bigThumb.imgXLen;
        self.imageYLen = bigThumb.imgYLen;
        self.duration = bigThumb.duration;
        self.interval = bigThumb.interval;
        self.fext = bigThumb.fext;
    }
    return self;
}

- (NSInteger)getValueInt:(NSInteger)key {
    if (self.apiVer >= TTVideoEnginePlayAPIVersion2) {
        switch (key) {
            case VALUE_THUMB_IMG_NUM:
                return self.imageNum_ver2;
            case VALUE_THUMB_IMG_X_SIZE:
                return self.imageXSize_ver2;
            case VALUE_THUMB_IMG_Y_SIZE:
                return self.imageYSize_ver2;
            case VALUE_THUMB_IMG_X_LEN:
                return self.imageXLen_ver2;
            case VALUE_THUMB_IMG_Y_LEN:
                return self.imageYLen_ver2;
            default:
                return -1;
        }
    } else {
        switch (key) {
            case VALUE_THUMB_IMG_NUM:
                return self.imageNum;
            case VALUE_THUMB_IMG_X_SIZE:
                return self.imageXSize;
            case VALUE_THUMB_IMG_Y_SIZE:
                return self.imageYSize;
            case VALUE_THUMB_IMG_X_LEN:
                return self.imageXLen;
            case VALUE_THUMB_IMG_Y_LEN:
                return self.imageYLen;
            default:
                return -1;
        }
    }
}

- (CGFloat)getValueFloat:(NSInteger)key {
    if (self.apiVer >= TTVideoEnginePlayAPIVersion2) {
        switch (key) {
            case VALUE_THUMB_DURATION:
                return self.duration_ver2;
            case VALUE_THUMB_INTERVAL:
                return self.interval_ver2;
            default:
                return -1;
        }
    } else {
        switch (key) {
            case VALUE_THUMB_DURATION:
                return self.duration;
            case VALUE_THUMB_INTERVAL:
                return self.interval;
            default:
                return -1;
        }
    }
}

- (NSString *)getValueStr:(NSInteger)key {
    if (self.apiVer >= TTVideoEnginePlayAPIVersion2) {
        switch (key) {
            case VALUE_THUMB_URI:
                return self.uri_ver2;
            case VALUE_THUMB_IMG_URL:
                return self.imageURL_ver2;
            case VALUE_THUMB_FEXT:
                return self.fext_ver2;
            default:
                return @"";
        }
    } else {
        switch (key) {
            case VALUE_THUMB_URI:
                return self.uri;
            case VALUE_THUMB_IMG_URL:
                return self.imageURL;
            case VALUE_THUMB_FEXT:
                return self.fext;
            default:
                return @"";
        }
    }
}

@end

#pragma clang diagnostic pop

