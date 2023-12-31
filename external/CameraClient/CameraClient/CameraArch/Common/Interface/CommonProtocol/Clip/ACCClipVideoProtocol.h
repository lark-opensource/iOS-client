//
//  ACCClipVideoProtocol.h
//  CameraClient
//
//  Created by wishes on 2019/11/19.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "HTSVideoSpeedControl.h"
#import <CreationKitArch/ACCMusicModelProtocol.h>
#import "ACCEditVideoData.h"

NS_ASSUME_NONNULL_BEGIN

@class AWEAssetModel;
@class IESMMVideoDataClipRange;
@class AWEVideoPublishViewModel;

@protocol ACCClipVideoProtocol <NSObject>

- (nonnull UIViewController*)clipViewController:(NSArray<AWEAssetModel *> *)toClipSourceAssets
                                maxClipDuration:(CGFloat)maxClipDuration
                           clipedResultSavePath:(NSString*)savePath
                                allowFastImport:(BOOL)allowFastImport
                              allowSpeedControl:(BOOL)allowSpeedControl
                                      inputData:(NSDictionary*)inputData
                                     completion:(void(^)(ACCEditVideoData *videoData, id<ACCMusicModelProtocol> music, UIImage *coverImage))completion;

@end


NS_ASSUME_NONNULL_END
