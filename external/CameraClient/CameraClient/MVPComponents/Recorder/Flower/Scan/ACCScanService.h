//
//  ACCScanService.h
//  Indexer
//
//  Created by xiafeiyu on 11/3/21.
//

#import <Foundation/Foundation.h>

@protocol ACCCameraService;
@protocol ACCRecordPropService;

typedef NS_ENUM(NSUInteger, ACCScanMode) {
    ACCScanModeNone,
    ACCScanModeScan, // 扫一扫模式
    ACCScanModeQRCode, // 二维码模式
};

FOUNDATION_EXPORT NSErrorDomain const kACCScanErrorDomain;
FOUNDATION_EXPORT NSInteger const kACCScanBachPropIDNotExist;
FOUNDATION_EXPORT NSInteger const kACCScanFetchBachPropFailed;
FOUNDATION_EXPORT NSInteger const kACCScanDownloadBachResourceFailed;

FOUNDATION_EXPORT NSInteger const kACCBachPropScanMessageID;
FOUNDATION_EXPORT NSInteger const kACCBachPropScanSuccess;

@protocol ACCScanService;

@protocol ACCScanServiceSubscriber

@optional

- (void)scanService:(id<ACCScanService>)scanService didSwitchModeFrom:(ACCScanMode)oldMode to:(ACCScanMode)mode;

@end

typedef void(^ACCBachScanResultBlock)(NSString * _Nullable, NSError * _Nullable);

@protocol ACCScanService <NSObject>

/**
 * @discussion 方法内部会初始化一个 VEImageDetector 并长期持有（减少反复 alloc + init 的开销），但 VEImageDetector 很耗内存，所以用完了记得调用 releaseImageDetector 释放内存。
 * @return 扫描文本结果。如果缺少有效二维码，返回 nil。
 */
- (nullable NSString *)scanByImageDetector:(nullable UIImage *)image;
- (void)releaseImageDetector;

- (void)prefetchBachPropResource;
- (void)scanByBachProp:(ACCBachScanResultBlock)completion;
- (void)cancelBachPropScan;
@property (nonatomic, assign, readonly) BOOL bachPropScanIsRunning;


/**
 * 以下方法用于 ScanComponent 和 其他 Component/Plugin 通信。
 */

@property (nonatomic, weak, nullable) id<ACCCameraService> cameraService;
@property (nonatomic, weak, nullable) id<ACCRecordPropService> propService;
@property (nonatomic, copy, nullable) NSString *scanReferString;

- (void)addSubscriber:(nonnull id<ACCScanServiceSubscriber>)subscriber;
- (void)removeSubscriber:(nonnull id<ACCScanServiceSubscriber>)subscriber;

@property (nonatomic, assign, readonly) ACCScanMode currentMode;
- (void)switchScanComponentToMode:(ACCScanMode)mode;

@end
