//
//  ImageDataCommand.m
//  LynxExample
//
//  Created by chenweiwei.luna on 2020/11/8.
//  Copyright © 2020 Lynx. All rights reserved.
//

#import "ImageDataCommand.h"

@interface ImageDataCommand ()

@property(nonatomic, assign) CGPoint origin;

@property(nonatomic, assign) CGSize size;

@property (nonatomic, copy) UIImage *image;

@end

@implementation ImageDataCommand

#pragma mark - override
- (NSString *)typeStr
{
    return @"id";
}

- (void)configWithData:(NSDictionary *)data context:(LolaDrawContext *)context
{
    [self parseRect:data];

    NSArray *bitmap =  [data objectForKey:@"id"];
    int imageWidth = self.size.width;
    int imageHeight = self.size.height;

    size_t bufferSize = imageWidth *imageHeight *4;
    
    UInt8* rgba = (UInt8*)malloc(bufferSize);
    for(int i=0; i < bufferSize; ++i) {
        rgba[i] = [(NSNumber *)bitmap[i] unsignedCharValue];
    }
    
    CGBitmapInfo info = kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault;

    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, rgba, bufferSize, NULL);
    size_t bitsOnePixel = 32;
    size_t bitsOneComponent = 8;
    size_t bytesOneRow = 4* imageWidth;
    
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    if(colorSpaceRef == NULL) {
        free(rgba);
        CGDataProviderRelease(dataProvider);
        return;
    }

    CGImageRef imageRef = CGImageCreate(imageWidth,
                                        imageHeight,
                                        bitsOneComponent,
                                        bitsOnePixel,
                                        bytesOneRow,
                                        colorSpaceRef,
                                        info,
                                        dataProvider,   // data provider
                                        NULL,       // decode
                                        YES,            // should interpolate
                                        kCGRenderingIntentDefault);
    
    self.image = [UIImage imageWithCGImage:imageRef];

    free(rgba);
    CGDataProviderRelease(dataProvider);
    CGColorSpaceRelease(colorSpaceRef);
    CGImageRelease(imageRef);
}

- (void)parsePoint:(NSDictionary *)data
{
    NSInteger x = [[data objectForKey:@"x"] floatValue];
    NSInteger  y =  [[data objectForKey:@"y"] floatValue];
    self.origin = CGPointMake(x, y);
}


- (void)parseRect:(NSDictionary *)data
{
    [self parsePoint:data];
    NSInteger  width =  [[data objectForKey:@"w"] floatValue];
    NSInteger height =[[data objectForKey:@"h"] floatValue];
    
    self.size = CGSizeMake(width, height);
}

- (void)draw:(LolaDrawContext *)drawContext context:(CGContextRef)context
{
    CGRect rect = {self.origin, self.size};
        
    CGContextDrawImage(context, rect, self.image.CGImage);
}

- (void)recycle {
}

@end
