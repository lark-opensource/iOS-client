//
//  AWEAlbumFaceCache.h
//  AWEStudio
//
//  Created by liubing on 2018/5/25.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AWEAlbumImageModel.h"


/**
 This class will be clear, the methods of cleaning cache are retained only.
 */
@interface AWEAlbumFaceCache : NSObject

+ (void)removeAllDetectResults;

@end
