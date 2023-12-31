//
//  ACCMiddlemanProxy.h
//  CameraClient-Pods-Aweme
//
//  Created by qiuhang on 2020/8/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCMiddlemanProxy : NSProxy

@property (nonatomic, weak) id originalDelegate;
@property (nonatomic, weak) id middlemanDelegate;

@end

NS_ASSUME_NONNULL_END
