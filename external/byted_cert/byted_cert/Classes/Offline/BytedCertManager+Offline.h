//
//  BytedCertManager+Offline.h
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/8/23.
//

#import "BytedCertManager.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BytedCertMotionType) {
    BytedCertMotionTypenWink = 0, //眨眼
    BytedCertMotionTypeOpenMouth, //张嘴
    BytedCertMotionTypeNod,       //点头
    BytedCertMotionTypeShake      //摇头
};


@interface BytedCertOfflineDetectPatameter : BytedCertParameter

@property (nonatomic, strong, nonnull) NSData *imageCompare;
@property (nonatomic, copy, nullable) NSArray<NSNumber *> *motions;

@end


@interface BytedCertManager (Offline)

+ (void)beginOfflineFaceVerificationWithParameter:(BytedCertOfflineDetectPatameter *)parameter completion:(void (^)(NSError *_Nullable error, NSDictionary *_Nullable result))completion;

@end

NS_ASSUME_NONNULL_END
