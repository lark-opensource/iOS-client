//
//  BDUGShareFileManager.h
//  BDUGShare_Example
//
//  Created by 杨阳 on 2019/7/4.
//  Copyright © 2019 xunianqiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BDUGFileDownloader.h"

@interface BDUGShareFileManager : NSObject

+ (void)getFileFromURLStrings:(NSArray <NSString *> *)URLStrings
                     fileName:(NSString *)fileName
             downloadProgress:(BDUGFileDownloaderProgress)downloadProgress
                   completion:(BDUGFileDownloaderCompletion)completion;

@end
