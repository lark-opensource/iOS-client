//
//  ACCTextStickerRecommendDataHelper.h
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2021/8/1.
//

#import <Foundation/Foundation.h>
#import <CameraClientModel/ACCTextRecommendModel.h>

NS_ASSUME_NONNULL_BEGIN

@class AWEVideoPublishViewModel;

@interface ACCTextStickerRecommendDataHelper : NSObject

+ (void)requestBasicRecommend:(AWEVideoPublishViewModel *)publishModel completion:(nullable void(^)(NSArray<ACCTextStickerRecommendItem *> *, NSError *))completion;

+ (void)requestRecommend:(NSString *)keyword publishModel:(AWEVideoPublishViewModel *)publishModel completion:(nullable void(^)(NSArray<ACCTextStickerRecommendItem *> *, NSError *))completion;

+ (void)requestLibList:(AWEVideoPublishViewModel *)publishModel completion:(nullable void(^)(NSArray<ACCTextStickerLibItem *> *, NSError *))completion;

+ (BOOL)enableRecommend;
+ (AWEModernTextRecommendMode)textBarRecommendMode;

@end

NS_ASSUME_NONNULL_END
