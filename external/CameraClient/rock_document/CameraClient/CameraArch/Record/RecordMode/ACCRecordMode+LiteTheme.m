//
//  ACCRecordMode+LiteTheme.m
//  CameraClient-Pods-AwemeLiteCore
//
//  Created by Fengfanhua.byte on 2021/10/14.
//

#import "ACCRecordMode+LiteTheme.h"
#import <objc/runtime.h>

@implementation ACCRecordMode (LiteTheme)

- (BOOL (^)(void))additionIsVideoBlock
{
    return objc_getAssociatedObject(self, @selector(additionIsVideoBlock));
}

- (void)setAdditionIsVideoBlock:(BOOL (^)(void))additionIsVideoBlock
{
    objc_setAssociatedObject(self, @selector(additionIsVideoBlock), additionIsVideoBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (BOOL)isStoryStyleMode
{
    return self.modeId == ACCRecordModeStory || self.modeId == ACCRecordModeTheme;
}

- (BOOL)isAdditionVideo
{
    return (self.additionIsVideoBlock ? self.additionIsVideoBlock() : YES);
}

@end
