//
//  ACCWeakObjectWrapper.h
//  CameraClient
//
//  Created by Liu Deping on 2020/5/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCWeakObjectWrapper<T> : NSObject

@property (nonatomic, weak) T weakObject;

@end

NS_ASSUME_NONNULL_END
