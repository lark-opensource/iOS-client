//
//  TTDownloadTrackModel.h
//  TTNetworkDownloader
//
//  Created by Nami on 2020/3/4.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>
#import "TTDownloadMetaData.h"

NS_ASSUME_NONNULL_BEGIN

@interface TTDownloadTrackModel : JSONModel


@property (atomic, copy) NSString *downloadId;


@property (atomic, copy) NSString *fileStorageDir;

/**
 * md5
 */
@property (atomic, copy) NSString<Optional> *md5Value;

@property (atomic, assign) NSTimeInterval md5Time;


@property (atomic, copy) NSString<Optional> *url;

@property (atomic, copy, nullable) NSString<Optional> *secondUrl;

@property (atomic, copy, nullable) NSString<Optional> *name;

@property (atomic, assign) NSTimeInterval downloadTime;

@property (atomic, assign) int64_t totalBytes;

@property (atomic, assign) int64_t curBytes;

@property (atomic, assign) NSInteger sliceCount;

@property (atomic, assign) NSInteger urlRetryCount;

@property (atomic, assign) NSInteger curUrlRetryTime;

@property (atomic, assign) NSTimeInterval urlRetryInterval;

@property (atomic, assign) NSTimeInterval gclTime;

@property (atomic, assign) NSInteger retryCount;

@property (atomic, assign) NSInteger curRetryTime;

@property (atomic, assign) NSTimeInterval sliceMergeTime;

@property (atomic, assign) NSInteger restoreCount;

@property (atomic, assign) NSInteger curRestoreTime;

@property (atomic, assign) NSTimeInterval retryInterval;

@property (atomic, assign) NSTimeInterval retryIntervalIncrement;

@property (atomic, assign) BOOL httpsDegradeEnable;

@property (atomic, assign) BOOL hasHttpsDegrade;

@property (atomic, assign) int64_t throttleNetSpeed;

@property (atomic, assign) NSInteger failStatus;

@property (atomic, copy, nullable) NSString<Optional> *failMsg;

@property (atomic, assign) BOOL isWifiOnly;

@property (atomic, assign) BOOL isBgDownloadEnable;

@property (atomic, assign) BOOL isBackgroundDownloadFinish;

@property (atomic, assign) NSTimeInterval bgDownloadTime;

@property (atomic, assign) int64_t curBgDownloadBytes;


@property (atomic, assign) float_t downloadSpeed;

@property (atomic, assign) TrackStatus trackStatus;

@property (atomic, copy, nullable) NSDictionary<Optional> *extraParams;

#pragma mark

- (void)setDownloadStartTime;

- (NSTimeInterval)addDownloadTimeWithReSet;

- (NSTimeInterval)addDownloadTime;

- (void)setBgDownloadStartTime;

- (NSTimeInterval)addBgDownloadTimeWithReSet;

#pragma mark

- (void)addCurRetryTime:(NSInteger)num;
- (void)addCurUrlRetryTime:(NSInteger)num;
- (void)addCurRestoreTime:(NSInteger)num;
- (void)addBgDownloadBytes:(int64_t)num;

- (void)recordFgDownloadBytes;

- (void)calBgDownloadBytes;

+ (NSString *)generateDownloadIdWithUrl:(NSString *)url fileName:(NSString *)fileName;

@end

NS_ASSUME_NONNULL_END
