//
//  DVEGlobalServiceContainer.h
//  NLEEditor
//
//  Created by bytedance on 2021/9/9.
//

#import <Foundation/Foundation.h>
#import <DVEFoundationKit/DVEFoundationInject.h>

NS_ASSUME_NONNULL_BEGIN

@interface DVEGlobalServiceContainer : DVEDIContainer

+ (instancetype)sharedContainer;

@end

NS_ASSUME_NONNULL_END
