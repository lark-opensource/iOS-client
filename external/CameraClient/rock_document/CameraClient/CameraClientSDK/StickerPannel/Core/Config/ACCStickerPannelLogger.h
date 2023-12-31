//
//  ACCStickerPannelLogger.h
//  Pods
//
//  Created by liyingpeng on 2020/8/4.
//

#ifndef ACCStickerPannelLogger_h
#define ACCStickerPannelLogger_h

NS_ASSUME_NONNULL_BEGIN

@class AWESingleStickerDownloadInfo;

@protocol ACCStickerPannelLogger <NSObject>

// common

- (void)logSlidingDidSelectIndex:(NSInteger)index title:(nullable NSString *)title;

- (void)logStickerPannelDidSelectSticker:(NSString *)stickerIdentifier index:(NSInteger)index tab:(NSString *)tabName categoryName:(NSString *)categoryName extra:(nullable NSDictionary *)extra;

- (void)logStickerWillDisplay:(NSString *)stickerIdentifier categoryId:(NSString *)categoryId categoryName:(NSString *)categoryName;

- (void)logBottomBarDidSelectCategory:(NSString *)categoryName pannelTab:(NSString *)tabName;

// sticker download

- (void)logStickerDownloadFinished:(AWESingleStickerDownloadInfo *)downloadInfo;

// sticker pannel update

- (void)logPannelUpdateFailed:(NSString *)pannelName
               updateDuration:(CFAbsoluteTime)duration;

- (void)logPannelUpdateFinished:(NSString *)pannelName
                     needUpdate:(BOOL)needUpdate
                 updateDuration:(CFAbsoluteTime)duration
                        success:(BOOL)success
                          error:(nullable NSError *)error;

@end

NS_ASSUME_NONNULL_END


#endif /* ACCStickerPannelLogger_h */
