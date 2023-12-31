//
//  EMAAppAboutUpdateHandler.h
//  EEMicroAppSDK
//
//  Created by tujinqiu on 2020/2/5.
//

#import <Foundation/Foundation.h>
#import <OPFoundation/BDPUniqueID.h>

typedef NS_ENUM(NSUInteger, EMAAppAboutUpdateStatus) {
    EMAAppAboutUpdateStatusNone = 0,
    EMAAppAboutUpdateStatusFetchingMeta,
    EMAAppAboutUpdateStatusMetaFailed,
    EMAAppAboutUpdateStatusNewestVersion,
    EMAAppAboutUpdateStatusDownloading,
    EMAAppAboutUpdateStatusDownloadSuccess,
    EMAAppAboutUpdateStatusDownloadFailed,
};

typedef void (^EMAAppAboutUpdateCallback)(EMAAppAboutUpdateStatus status, NSString *latestVersion);

@interface EMAAppAboutUpdateHandler : NSObject

- (instancetype)initWithUniqueID:(BDPUniqueID *)uniqueID;

@property (nonatomic, strong) BDPUniqueID *uniqueID;
@property (nonatomic, copy) NSString *latestVersion;
@property (nonatomic, assign) EMAAppAboutUpdateStatus status;
@property (nonatomic, copy) EMAAppAboutUpdateCallback statusChangedCallback;

- (void)fetchMetaAndDownload;
- (void)download;

@end

