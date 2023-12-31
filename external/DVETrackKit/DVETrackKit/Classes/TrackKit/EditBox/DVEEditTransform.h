//
//  DVEEditTransform.h
//  TTVideoEditorDemo
//
//  created by bytedance on 2020/12/9.
//  Copyright © 2020 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DVEEditTransform : NSObject

@property (nonatomic) CGFloat scale;
@property (nonatomic) CGFloat rotation;
@property (nonatomic) CGPoint translation;

- (CGAffineTransform)convertCGAffineTransform;

@end

NS_ASSUME_NONNULL_END
