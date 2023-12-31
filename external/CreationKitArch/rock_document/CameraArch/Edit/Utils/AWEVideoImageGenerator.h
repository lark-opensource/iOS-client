//
//  AWEVideoImageGenerator.h
//  Aweme
//
//  Created by Liu Bing on 4/10/17.
//  Copyright © 2017 Bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^AWEVideoImageGeneratorOneByOneImageBlock)(UIImage *image, NSInteger index);

extern NSString * const AWEVideoImageGeneratorTimeKey;
extern NSString * const AWEVideoImageGeneratorImageKey;

@protocol ACCEditServiceProtocol;

@interface AWEVideoImageGenerator : NSObject

- (void)cancel;

- (void)requestImages:(NSUInteger)count
               effect:(BOOL)withEffect
                index:(NSUInteger)index
                 step:(CGFloat)step
                 size:(CGSize)size
                array:(NSMutableArray *)previewImageDictArray
          editService:(__weak id<ACCEditServiceProtocol>)editService
   oneByOneImageBlock:(AWEVideoImageGeneratorOneByOneImageBlock)oneByOneImageBlock
           completion:(void (^)(void))completion;

/**
 @param count how many images to request
 @param withEffect whether to have effects
 @param index set to 0
 @param startTime the point in time to start pumping from
 @param step step size
 @param size What size image you want to get
 @param previewImageDictArray Pass in a dictionary user to get the generated image (@"atTime":@(atTime),@"image":image)
 @param player Pass in an HTSPlyaer
 @param complete Draw finish callback
 */
- (void)requestImages:(NSUInteger)count
               effect:(BOOL)withEffect
                index:(NSUInteger)index
            startTime:(NSTimeInterval)startTime
                 step:(CGFloat)step
                 size:(CGSize)size
                array:(NSMutableArray *)previewImageDictArray
          editService:(__weak id<ACCEditServiceProtocol>)editService
   oneByOneImageBlock:(AWEVideoImageGeneratorOneByOneImageBlock)oneByOneImageBlock
           completion:(void (^)(void))completion;

@end
