//
//  TTDownloadEventModel.m
//  TTNetworkDownloader
//
//  Created by Nami on 2020/3/4.
//

#import "TTDownloadTrackModel.h"
#import "TTDownloadLog.h"
#import <libkern/OSAtomic.h>
#import <CommonCrypto/CommonCrypto.h>
#import <TTNetworkManager/TTNetworkManager.h>

NS_ASSUME_NONNULL_BEGIN

#if __LP64__ || NS_BUILD_32_LIKE_64
#define AtomicAdd(__theAmount, __theValue) OSAtomicAdd64(__theAmount, __theValue)
#else
#define AtomicAdd(__theAmount, __theValue) OSAtomicAdd32(__theAmount, __theValue)
#endif

@interface TTDownloadTrackModel ()

@property (atomic, assign) NSTimeInterval curStartTime;

@property (atomic, assign) int64_t curFgDownloadBytes;

@property (atomic, assign) NSTimeInterval curBgStartTime;

@end

@implementation TTDownloadTrackModel

- (void)dealloc {
    DLLOGD(@"dlLog:dealloc:file=%s ,function=%s", __FILE__, __FUNCTION__);
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _curStartTime = -1;
        _curFgDownloadBytes = 0;
        _curBgStartTime = -1;
        _downloadSpeed = 0;
        _trackStatus = TRACK_NONE;
    }
    return self;
}

- (id)copyWithZone:(NSZone *_Nullable)zone {
    TTDownloadTrackModel *model = [[TTDownloadTrackModel alloc] init];

    model.downloadId = self.downloadId;
    model.fileStorageDir = self.fileStorageDir;

    model.md5Value = self.md5Value;
    model.md5Time = self.md5Time;

    model.url = self.url;
    model.secondUrl = self.secondUrl;
    model.name = self.name;
    model.downloadTime = self.downloadTime;
    model.totalBytes = self.totalBytes;
    model.curBytes = self.curBytes;
    model.sliceCount = self.sliceCount;

    model.urlRetryCount = self.urlRetryCount;
    model.curUrlRetryTime = self.curUrlRetryTime;
    model.urlRetryInterval = self.urlRetryInterval;
    model.gclTime = self.gclTime;

    model.retryCount = self.retryCount;
    model.curRetryTime = self.curRetryTime;
    model.sliceMergeTime = self.sliceMergeTime;

    model.restoreCount = self.restoreCount;
    model.curRestoreTime = self.curRestoreTime;
    model.retryInterval = self.retryInterval;
    model.retryIntervalIncrement = self.retryIntervalIncrement;
    model.httpsDegradeEnable = self.httpsDegradeEnable;
    model.hasHttpsDegrade = self.hasHttpsDegrade;
    model.throttleNetSpeed = self.throttleNetSpeed;
    model.failStatus = self.failStatus;
    model.failMsg = self.failMsg;
    model.isWifiOnly = self.isWifiOnly;

    model.isBgDownloadEnable = self.isBgDownloadEnable;
    model.isBackgroundDownloadFinish = self.isBackgroundDownloadFinish;
    model.bgDownloadTime = self.bgDownloadTime;
    model.curBgDownloadBytes = self.curBgDownloadBytes;

    model.downloadSpeed = self.downloadSpeed;

    model.trackStatus = self.trackStatus;
    model.extraParams = self.extraParams;

    return model;
}

#pragma mark

- (void)setDownloadStartTime {
    self.curStartTime = CFAbsoluteTimeGetCurrent();
}

- (NSTimeInterval)addDownloadTimeWithReSet {
    if (self.curStartTime == -1) {
        return 0;
    }

    NSTimeInterval curEndTime = CFAbsoluteTimeGetCurrent();
    NSTimeInterval duration = ceil((curEndTime - self.curStartTime) * 1000);
    self.downloadTime += duration;
    self.curStartTime = -1;
    return duration;
}

- (NSTimeInterval)addDownloadTime {
    if (self.curStartTime == -1) {
        return 0;
    }

    NSTimeInterval curEndTime = CFAbsoluteTimeGetCurrent();
    NSTimeInterval duration = ceil((curEndTime - self.curStartTime) * 1000);
    self.downloadTime += duration;
    self.curStartTime = curEndTime;
    return duration;
}

- (void)setBgDownloadStartTime {
    self.curBgStartTime = CFAbsoluteTimeGetCurrent();
}

- (NSTimeInterval)addBgDownloadTimeWithReSet {
    if (self.curBgStartTime == -1) {
        return 0;
    }

    NSTimeInterval curEndTime = CFAbsoluteTimeGetCurrent();
    NSTimeInterval duration = ceil((curEndTime - self.curBgStartTime) * 1000);
    self.bgDownloadTime += duration;
    self.curBgStartTime = -1;
    return duration;
}

- (void)addCurRestoreTime:(NSInteger)num {
    AtomicAdd(num, &_curRestoreTime);
}

- (void)addCurRetryTime:(NSInteger)num {
    AtomicAdd(num, &_curRetryTime);
}

- (void)addCurUrlRetryTime:(NSInteger)num {
    AtomicAdd(num, &_curUrlRetryTime);
}

- (void)addBgDownloadBytes:(int64_t)num {
    OSAtomicAdd64(num, &_curBgDownloadBytes);
}

- (void)recordFgDownloadBytes {
    if (self.curBytes > self.curBgDownloadBytes) {
        self.curFgDownloadBytes = self.curBytes - self.curBgDownloadBytes;
    }
}

- (void)calBgDownloadBytes {
    if (self.curFgDownloadBytes > 0 && self.curFgDownloadBytes <= self.curBytes) {
        self.curBgDownloadBytes = self.curBytes - self.curFgDownloadBytes;
    }
}

+ (NSString *)generateDownloadIdWithUrl:(NSString *)url fileName:(NSString *)fileName {
    NSString *string = [NSString stringWithFormat:@"%@ %@", url, fileName];
    const char *data = [string UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];

    CC_MD5(data, (CC_LONG)strlen(data), result);
    NSMutableString *mString = [NSMutableString string];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [mString appendFormat:@"%02x",result[i]];
    }

    return mString;
}

#pragma mark - JSON

+ (JSONKeyMapper *)keyMapper {
    return [JSONKeyMapper mapperForSnakeCase];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end
NS_ASSUME_NONNULL_END
