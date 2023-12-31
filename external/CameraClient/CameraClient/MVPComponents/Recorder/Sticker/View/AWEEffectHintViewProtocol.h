//
//  AWEEffectHintViewProtocol.h
//  AWEStudio
//
//  Created by yuanchang on 2020/6/30.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AWEEffectHintViewProtocol <NSObject>

- (void)showWithImageUrlList:(NSArray<NSString *> *)urlList;

@end

NS_ASSUME_NONNULL_END
