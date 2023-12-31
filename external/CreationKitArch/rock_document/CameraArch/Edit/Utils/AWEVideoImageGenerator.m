//
//  AWEVideoImageGenerator.m
//  Aweme
//
//  Created by Liu Bing on 4/10/17.
//  Copyright © 2017 Bytedance. All rights reserved.
//

#import "AWEVideoImageGenerator.h"
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import <CreativeKit/ACCMacros.h>

NSString * const AWEVideoImageGeneratorTimeKey = @"atTime";
NSString * const AWEVideoImageGeneratorImageKey = @"image";

@interface AWEVideoImageGenerator ()

@property (nonatomic, assign) NSInteger taskIdentifier;

@end

@implementation AWEVideoImageGenerator

- (void)cancel
{
    acc_dispatch_main_async_safe(^{
        [self p_invalidateCurrentTask];
    });
}

- (void)requestImages:(NSUInteger)count
               effect:(BOOL)withEffect
                index:(NSUInteger)index
            startTime:(NSTimeInterval)startTime
                 step:(CGFloat)step
                 size:(CGSize)size
                array:(NSMutableArray *)previewImageDictArray
          editService:(__weak id<ACCEditServiceProtocol>)editService
   oneByOneImageBlock:(AWEVideoImageGeneratorOneByOneImageBlock)oneByOneImageBlock
           completion:(void (^)(void))completion
{
    acc_dispatch_main_async_safe(^{
        [self p_invalidateCurrentTask];
        [self p_requestImages:count
                       effect:withEffect
                        index:index
                    startTime:startTime
                         step:step
                         size:size
                        array:previewImageDictArray
                  editService:editService
               taskIdentifier:self.taskIdentifier
           oneByOneImageBlock:oneByOneImageBlock
                   completion:completion];
    });
}

- (void)requestImages:(NSUInteger)count
               effect:(BOOL)withEffect
                index:(NSUInteger)index
                 step:(CGFloat)step
                 size:(CGSize)size
                array:(NSMutableArray *)previewImageDictArray
          editService:(__weak id<ACCEditServiceProtocol>)editService
   oneByOneImageBlock:(AWEVideoImageGeneratorOneByOneImageBlock)oneByOneImageBlock
           completion:(void (^)(void))completion
{
    acc_dispatch_main_async_safe(^{
        [self p_invalidateCurrentTask];
        [self p_requestImages:count
                       effect:withEffect
                        index:index
                    startTime:0.0
                         step:step
                         size:size
                        array:previewImageDictArray
                  editService:editService
               taskIdentifier:self.taskIdentifier
           oneByOneImageBlock:oneByOneImageBlock
                   completion:completion];
    });
}

- (void)p_invalidateCurrentTask
{
    ++self.taskIdentifier;
}

- (void)p_requestImages:(NSUInteger)count
                 effect:(BOOL)withEffect
                  index:(NSUInteger)index
              startTime:(NSTimeInterval)startTime
                   step:(CGFloat)step
                   size:(CGSize)size
                  array:(NSMutableArray *)previewImageDictArray
            editService:(__weak id<ACCEditServiceProtocol>)editService
         taskIdentifier:(NSInteger)taskIdentifier
     oneByOneImageBlock:(AWEVideoImageGeneratorOneByOneImageBlock)oneByOneImageBlock
             completion:(void (^)(void))completion
{
    if (!editService || taskIdentifier != self.taskIdentifier) {
        return;
    }

    if (index > count) {
        return;
    }

    if (index == count) {
        ACCBLOCK_INVOKE(completion);
        return;
    }

    @weakify(self);
    void (^next)(UIImage *_Nullable image, NSTimeInterval atTime) = ^(UIImage * _Nonnull image, NSTimeInterval atTime) {
//        acc_dispatch_main_async_safe(^{
            @strongify(self);
            if (!self || taskIdentifier != self.taskIdentifier) {
                return;
            }

        if (image && (image.size.width <= 0 || image.size.height <= 0)) {
            // do not deliver invalid UIImage
            image = nil;
        }
            if (image) {
                NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
                [dictionary setObject:@(atTime) forKey:AWEVideoImageGeneratorTimeKey];
                [dictionary setObject:image forKey:AWEVideoImageGeneratorImageKey];
                [previewImageDictArray addObject:dictionary];
            }

            ACCBLOCK_INVOKE(oneByOneImageBlock, image, index);

            [self p_requestImages:count
                           effect:withEffect
                            index:index + 1
                        startTime:startTime
                             step:step
                             size:size
                            array:previewImageDictArray
                      editService:editService
                    taskIdentifier:taskIdentifier
               oneByOneImageBlock:oneByOneImageBlock
                       completion:completion];
//        });
    };

    if (withEffect) {
        [editService.captureFrame getProcessedPreviewImageAtTime:startTime + (index * step) preferredSize:size compeletion:next];
    } else {
        [editService.captureFrame getSourcePreviewImageAtTime:startTime + (index * step) preferredSize:size compeletion:next];
    }
}

@end
