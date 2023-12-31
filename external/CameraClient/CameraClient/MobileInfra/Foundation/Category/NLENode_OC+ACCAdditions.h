//
//  NLENode_OC+ACCAdditions.h
//  CameraClient-Pods-Aweme
//
//  Created by fangxiaomin on 2021/2/9.
//

#import <NLEPlatform/NLENode+iOS.h>

NS_ASSUME_NONNULL_BEGIN

@interface NLENode_OC (ACCAdditions)

- (NSObject *)getValueFromDouyinExtraWithKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
