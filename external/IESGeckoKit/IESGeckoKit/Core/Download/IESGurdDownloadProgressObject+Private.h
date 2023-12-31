//
//  IESGurdDownloadProgressObject+Private.h
//  Pods
//
//  Created by bytedance on 2021/11/4.
//

#ifndef IESGurdDownloadProgressObject_Private_h
#define IESGurdDownloadProgressObject_Private_h

#import "IESGurdDownloadProgressObject.h"

@interface IESGurdDownloadProgressObject ()

@property (nonatomic, strong) NSProgress *progress;

@property (nonatomic, strong) NSMutableArray *progressBlocks;

+ (instancetype)object;

- (void)addProgressBlock:(void (^)(NSProgress *progress))progressBlock;

@end

#endif /* IESGurdDownloadProgressObject_Private_h */
