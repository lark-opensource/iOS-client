//
//  BDPWebPImageFrame.m
//  Timor
//
//  Created by 王浩宇 on 2019/1/24.
//

#import "BDPWebPImageFrame.h"

@implementation BDPWebPImageFrame

+ (instancetype)frameWithImage:(UIImage *)image duration:(NSTimeInterval)duration
{
    BDPWebPImageFrame *frame = [[BDPWebPImageFrame alloc] init];
    frame.image = image;
    frame.duration = duration;
    return frame;
}

@end
