//
//  ACCEditActivityDataHelperProtocol.h
//  Aweme
//
//  Created by 卜旭阳 on 2021/11/2.
//

#import "ACCEditVideoData.h"

@class AWEVideoPublishViewModel, ACCEditMVModel;

extern NSString *const ACCNewYearWishModuleLokiKey;

@protocol ACCNewYearWishDataHelperProtocol <NSObject>

+ (NSString *)fetchVideoFileInFolder:(nullable NSString *)folderPath;
+ (NSString *)fetchImageFileInFolder:(nullable NSString *)folderPath;

+ (ACCEditMVModel *)generateWishMVDataWithResource:(nullable NSString *)resourcePath
                                         repository:(nullable AWEVideoPublishViewModel *)repository
                                          videoData:(nullable ACCEditVideoData *)videoData
                                            isImage:(BOOL)isImage
                                         completion:(nullable void(^)(BOOL, NSError *, ACCEditVideoData *))completion;
@end
