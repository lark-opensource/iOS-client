//
//  HTSBundleLoader+Private.h
//  HTSBootLoader
//
//  Created by Huangwenchen on 2019/11/26.
//  Copyright © 2019 bytedance. All rights reserved.
//

#ifndef HTSBundleLoader_Private_h
#define HTSBundleLoader_Private_h
#import "HTSBundleLoader.h"
FOUNDATION_EXPORT void _HTSBundleLoaderLock(void);
FOUNDATION_EXPORT void _HTSBundleLoaderUnlock(void);

@class HTSBundleLoader;
@protocol HTSBundleLoaderDelegate <NSObject>

- (void)bundleLoader:(HTSBundleLoader *)loader didLoadBundle:(NSString *)name;

- (void)bundleLoader:(HTSBundleLoader *)loader willUnLoadName:(NSString *)name;

@end

@interface HTSBundleLoader()

@property (weak, nonatomic) id<HTSBundleLoaderDelegate> delegate;

@end

#endif /* HTSBundleLoader_Private_h */
