//
//  LVVideoCropInfo.h
//  LVTemplate
//
//  Created by zenglifeng on 2019/8/23.
//

#import <Foundation/Foundation.h>
#import "LVMediaDraft.h"

NS_ASSUME_NONNULL_BEGIN

@interface LVVideoCropInfo (Interface)

@property (nonatomic, assign) CGPoint upperLeftPoint;

@property (nonatomic, assign) CGPoint upperRightPoint;

@property (nonatomic, assign) CGPoint lowerLeftPoint;

@property (nonatomic, assign) CGPoint lowerRightPoint;

+ (instancetype)defaultCrop;

@end

NS_ASSUME_NONNULL_END
