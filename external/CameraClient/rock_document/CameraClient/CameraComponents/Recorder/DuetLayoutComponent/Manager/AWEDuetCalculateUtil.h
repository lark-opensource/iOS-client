//
//  AWEDuetCalculateUtil.h
//  Pods
//
//  Created by 郝一鹏 on 2019/4/15.
//

#import <Foundation/Foundation.h>
#import "ACCEditVideoData.h"

NS_ASSUME_NONNULL_BEGIN

@interface AWEDuetCalculateUtil : NSObject

+ (nullable NSArray *)duetBoundsInfoArrayForPublishModelVideo:(ACCEditVideoData *)video;

@end

NS_ASSUME_NONNULL_END
