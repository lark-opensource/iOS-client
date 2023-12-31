//
//  NLEEditor_OC+Extension.h
//  CameraClient-Pods-Aweme
//
//  Created by geekxing on 2021/1/19.
//

#import <NLEPlatform/NLEEditor+iOS.h>

NS_ASSUME_NONNULL_BEGIN

@interface NLEEditor_OC (Extension)

- (void)acc_commitAndRender:(nullable void (^)(NSError *_Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
