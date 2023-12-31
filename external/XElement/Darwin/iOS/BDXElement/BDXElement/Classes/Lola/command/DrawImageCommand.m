//
//  DrawImage
//  LynxExample
//
//  Created by chenweiwei.luna on 2020/11/4.
//  Copyright © 2020 Lynx. All rights reserved.
//

#import "DrawImageCommand.h"
#import "objc/runtime.h"
/*
"cm" -> Common
"s" -> Simple
"co" -> Complex
 */

/*
 * x y w h
 *sx = getFloat(params, "sx")
 *sy = getFloat(params, "sy")
 *sWidth = getFloat(params, "sw")
 *sHeight = getFloat(params, "sh")
 *
 */

@interface DrawImageCommand ()

@property(nonatomic, assign) CGPoint origin;

@property(nonatomic, assign) CGSize size;

@property(nonatomic, assign) CGRect cropRect;

@property (nonatomic, copy) NSString *subType;

@property (nonatomic, copy) NSString *imageURL;

@property (nonatomic, copy) UIImage *image;

@end

@implementation DrawImageCommand

#pragma mark - override
- (NSString *)typeStr
{
    return @"im";
}

- (void)configWithData:(NSDictionary *)data context:(LolaDrawContext *)context
{
    NSString *subType = [data objectForKey:@"st"];
    self.subType = subType;
    
    NSString *url = data[@"im"];
    if (url.length <= 0) {
        return;
    }
    
    self.imageURL = url;
    
    NSURL *URL = [NSURL URLWithString:self.imageURL];
    
    
    __weak typeof(self) wself = self;
    __weak typeof(context) wcontext = context;
    [context loadImageWithURL:URL size:self.size contextInfo:nil completion:^(UIImage * _Nullable image, NSError * _Nullable error, NSURL * _Nullable imageURL) {
        __strong typeof(self) sself = wself;
        sself.image = image;
        [wcontext invidate];
    }];
    
    if ([self.subType isEqualToString:@"s"]) {
        [self parsePoint:data];
    } else if ([self.subType isEqualToString:@"cm"]) {
        [self parseRect:data];
    } else if ([self.subType isEqualToString:@"co"]) {
        [self parseComplete:data];
    }
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

- (void)parseComplete:(NSDictionary *)data
{
    [self parseRect:data];
        
    NSInteger sx = [[data objectForKey:@"sx"] floatValue];
    NSInteger sy =  [[data objectForKey:@"sy"] floatValue];
    NSInteger sWidth =  [[data objectForKey:@"sw"] floatValue];
    NSInteger sHeight =[[data objectForKey:@"sh"] floatValue];
    
    self.cropRect = CGRectMake(sx, sy, sWidth, sHeight);
}

- (void)draw:(LolaDrawContext *)drawContext context:(CGContextRef)context
{
    //subType :
    if ([self.subType isEqualToString:@"s"]) {
        [self.image drawAtPoint:self.origin];
    } else if ([self.subType isEqualToString:@"cm"]) {
        CGRect rect = {self.origin, self.size};
        [self.image drawInRect:rect];
    } else if ([self.subType isEqualToString:@"co"]) {
        
        CGRect rect = {self.origin, self.size};

        CGImageRef subImageRef = CGImageCreateWithImageInRect(self.image.CGImage, self.cropRect);
        CGContextDrawImage(context, rect, subImageRef);
    }
}

- (void)recycle {
    
    _origin = CGPointZero;
    _size = CGSizeZero;
    _cropRect = CGRectZero;
    _subType = nil;
    _imageURL = nil;
    _image = nil;
}

@end
