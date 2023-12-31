/**
 * @file UIImage+BTDAdditions
 * @author David<gaotianpo@songshulin.net>
 *
 * @brief UIImage's category
 * 
 * @details UIImage's category
 * 
 */

#import "UIImage+BTDAdditions.h"
#import "BTDMacros.h"
#import <QuartzCore/QuartzCore.h>
#import <Accelerate/Accelerate.h>

//Return the aspect ratio of the size.
static CGFloat aspectRatioForSize(CGSize size)
{
    if (size.height == 0) {
        return 0.f;
    }
    return size.width / size.height;
}

static CGFloat radiansToDegrees(CGFloat radians)
{
    return radians * 180/M_PI;
};

static CGFloat degreesToRadians(CGFloat degrees)
{
    return degrees * M_PI / 180;
};

@implementation UIImage (BTDAdditions)

+ (UIImage *)btd_centerStrechedResourceImage:(UIImage *)image
{
    return [image stretchableImageWithLeftCapWidth:image.size.width/2 topCapHeight:image.size.height/2];
}

- (UIImage *)btd_imageScaleAspectToMaxSize:(CGFloat)newSize
{
    CGFloat ratio;
    if (self.size.width > self.size.height) {
        ratio = newSize / self.size.width;
    } 
    else {
        ratio = newSize / self.size.height;
    }
    
    CGRect rect = CGRectMake(0.0, 0.0, ratio * self.size.width, ratio * self.size.height);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.0);
    [self drawInRect:rect];
    UIImage * scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}

- (UIImage *)btd_imageCroppingFromRect:(CGRect)rect
{
    return [UIImage btd_cutImage:self withRect:rect];
}

- (UIImage*)btd_transformWidth:(CGFloat)width height:(CGFloat)height rotate:(BOOL)rotate {
    CGFloat destW = width;
    CGFloat destH = height;
    CGFloat sourceW = width;
    CGFloat sourceH = height;
    if (rotate) {
        if (self.imageOrientation == UIImageOrientationRight
            || self.imageOrientation == UIImageOrientationLeft) {
            sourceW = height;
            sourceH = width;
        }
    }
    
    CGImageRef imageRef = self.CGImage;
    int bytesPerRow = destW * (CGImageGetBitsPerPixel(imageRef) >> 3);
    CGContextRef bitmap = CGBitmapContextCreate(NULL, destW, destH,
                                                CGImageGetBitsPerComponent(imageRef), bytesPerRow, CGImageGetColorSpace(imageRef),
                                                CGImageGetBitmapInfo(imageRef));
    
    if (rotate) {
        if (self.imageOrientation == UIImageOrientationDown) {
            CGContextTranslateCTM(bitmap, sourceW, sourceH);
            CGContextRotateCTM(bitmap, 180 * (M_PI/180));
            
        } else if (self.imageOrientation == UIImageOrientationLeft) {
            CGContextTranslateCTM(bitmap, sourceH, 0);
            CGContextRotateCTM(bitmap, 90 * (M_PI/180));
            
        } else if (self.imageOrientation == UIImageOrientationRight) {
            CGContextTranslateCTM(bitmap, 0, sourceW);
            CGContextRotateCTM(bitmap, -90 * (M_PI/180));
        }
    }
    
    CGContextDrawImage(bitmap, CGRectMake(0,0,sourceW,sourceH), imageRef);
    
    CGImageRef ref = CGBitmapContextCreateImage(bitmap);
    UIImage* result = [UIImage imageWithCGImage:ref];
    CGContextRelease(bitmap);
    CGImageRelease(ref);
    
    return result;
}


- (CGRect)btd_convertRect:(CGRect)rect withContentMode:(UIViewContentMode)contentMode {
    if (self.size.width != rect.size.width || self.size.height != rect.size.height) {
        if (contentMode == UIViewContentModeLeft) {
            return CGRectMake(rect.origin.x,
                              rect.origin.y + floor(rect.size.height/2 - self.size.height/2),
                              self.size.width, self.size.height);
            
        } else if (contentMode == UIViewContentModeRight) {
            return CGRectMake(rect.origin.x + (rect.size.width - self.size.width),
                              rect.origin.y + floor(rect.size.height/2 - self.size.height/2),
                              self.size.width, self.size.height);
            
        } else if (contentMode == UIViewContentModeTop) {
            return CGRectMake(rect.origin.x + floor(rect.size.width/2 - self.size.width/2),
                              rect.origin.y,
                              self.size.width, self.size.height);
            
        } else if (contentMode == UIViewContentModeBottom) {
            return CGRectMake(rect.origin.x + floor(rect.size.width/2 - self.size.width/2),
                              rect.origin.y + floor(rect.size.height - self.size.height),
                              self.size.width, self.size.height);
            
        } else if (contentMode == UIViewContentModeCenter) {
            return CGRectMake(rect.origin.x + floor(rect.size.width/2 - self.size.width/2),
                              rect.origin.y + floor(rect.size.height/2 - self.size.height/2),
                              self.size.width, self.size.height);
            
        } else if (contentMode == UIViewContentModeBottomLeft) {
            return CGRectMake(rect.origin.x,
                              rect.origin.y + floor(rect.size.height - self.size.height),
                              self.size.width, self.size.height);
            
        } else if (contentMode == UIViewContentModeBottomRight) {
            return CGRectMake(rect.origin.x + (rect.size.width - self.size.width),
                              rect.origin.y + (rect.size.height - self.size.height),
                              self.size.width, self.size.height);
            
        } else if (contentMode == UIViewContentModeTopLeft) {
            return CGRectMake(rect.origin.x,
                              rect.origin.y,
                              
                              self.size.width, self.size.height);
            
        } else if (contentMode == UIViewContentModeTopRight) {
            return CGRectMake(rect.origin.x + (rect.size.width - self.size.width),
                              rect.origin.y,
                              self.size.width, self.size.height);
            
        } else if (contentMode == UIViewContentModeScaleAspectFill) {
            CGSize imageSize = self.size;
            if (imageSize.height < imageSize.width) {
                imageSize.width = floor((imageSize.width/imageSize.height) * rect.size.height);
                imageSize.height = rect.size.height;
                
            } else {
                imageSize.height = floor((imageSize.height/imageSize.width) * rect.size.width);
                imageSize.width = rect.size.width;
            }
            return CGRectMake(rect.origin.x + floor(rect.size.width/2 - imageSize.width/2),
                              rect.origin.y + floor(rect.size.height/2 - imageSize.height/2),
                              imageSize.width, imageSize.height);
            
        } else if (contentMode == UIViewContentModeScaleAspectFit) {
            CGSize imageSize = self.size;
            if (imageSize.height < imageSize.width) {
                imageSize.height = floor((imageSize.height/imageSize.width) * rect.size.width);
                imageSize.width = rect.size.width;
                
            } else {
                imageSize.width = floor((imageSize.width/imageSize.height) * rect.size.height);
                imageSize.height = rect.size.height;
            }
            return CGRectMake(rect.origin.x + floor(rect.size.width/2 - imageSize.width/2),
                              rect.origin.y + floor(rect.size.height/2 - imageSize.height/2),
                              imageSize.width, imageSize.height);
        }
    }
    return rect;
}


- (void)btd_drawInRect:(CGRect)rect contentMode:(UIViewContentMode)contentMode {
    BOOL clip = NO;
    CGRect originalRect = rect;
    if (self.size.width != rect.size.width || self.size.height != rect.size.height) {
        clip = contentMode != UIViewContentModeScaleAspectFill
        && contentMode != UIViewContentModeScaleAspectFit;
        rect = [self btd_convertRect:rect withContentMode:contentMode];
    }
    

    if (clip) {
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSaveGState(context);
        CGContextAddRect(context, originalRect);
        CGContextClip(context);
        [self drawInRect:rect];
         CGContextRestoreGState(context);
    }else{
         [self drawInRect:rect];
    }    
}

- (void)btd_addRoundedRectToPath:(CGContextRef)context rect:(CGRect)rect radius:(float)radius {
    CGContextBeginPath(context);
    CGContextSaveGState(context);
    
    if (radius == 0) {
        CGContextTranslateCTM(context, CGRectGetMinX(rect), CGRectGetMinY(rect));
        CGContextAddRect(context, rect);
        
    } else {
        CGContextTranslateCTM(context, CGRectGetMinX(rect), CGRectGetMinY(rect));
        CGContextScaleCTM(context, radius, radius);
        float fw = CGRectGetWidth(rect) / radius;
        float fh = CGRectGetHeight(rect) / radius;
        
        CGContextMoveToPoint(context, fw, fh/2);
        CGContextAddArcToPoint(context, fw, fh, fw/2, fh, 1);
        CGContextAddArcToPoint(context, 0, fh, 0, fh/2, 1);
        CGContextAddArcToPoint(context, 0, 0, fw/2, 0, 1);
        CGContextAddArcToPoint(context, fw, 0, fw, fh/2, 1);
    }
    
    CGContextClosePath(context);
    CGContextRestoreGState(context);
}

- (void)btd_drawInRect:(CGRect)rect radius:(CGFloat)radius {
    [self btd_drawInRect:rect radius:radius contentMode:UIViewContentModeScaleToFill];
}

- (void)btd_drawInRect:(CGRect)rect radius:(CGFloat)radius contentMode:(UIViewContentMode)contentMode {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    if (radius) {
        [self btd_addRoundedRectToPath:context rect:rect radius:radius];
        CGContextClip(context);
    }
    
    [self btd_drawInRect:rect contentMode:contentMode];
    
    CGContextRestoreGState(context);
}
- (UIImage *)btd_imageWithRadius:(CGFloat)radius
{
    CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);
    return  [self btd_imageCroppingFromRect: rect radius:radius];
}

- (UIImage *)btd_imageCroppingFromRect:(CGRect)rect radius:(CGFloat)radius
{
    UIImage *drawImage = [self btd_imageCroppingFromRect:rect];
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, self.scale);
    [drawImage btd_drawInRect:(CGRect){.size=rect.size} radius:radius];
    UIImage * scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}

- (UIImage *)btd_imageCroppingWithSize:(CGSize)size scale:(CGFloat)scale radius:(CGFloat)radius
{
    UIGraphicsBeginImageContextWithOptions(size, NO, scale);
    [self btd_drawInRect:(CGRect){.size=size} radius:radius];
    UIImage * scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}

- (NSData*)btd_imageDataWithMaxSize:(CGSize)maxSize maxDataSize:(float)dataSize
{
    UIImage *currentImage = nil;
    if (maxSize.height >= self.size.height && maxSize.width >= self.size.width) {
        currentImage = self;
    } else {
        if (!maxSize.width || !maxSize.height || !self.size.height || !self.size.width)
            return nil;
        CGFloat imageRatio = self.size.width / self.size.height;
        CGFloat containerRatio = maxSize.width / maxSize.height;
        CGFloat targetWidth;
        CGFloat targetHeight;
        if (imageRatio > containerRatio) {
            targetWidth = maxSize.width;
            targetHeight = targetWidth / imageRatio;
        } else {
            targetHeight = maxSize.height;
            targetWidth = targetHeight * imageRatio;
        }
        CGSize targetSize = CGSizeMake(targetWidth, targetHeight);
        UIGraphicsBeginImageContextWithOptions(targetSize, NO, self.scale);
        [self drawInRect:CGRectMake(0, 0, targetSize.width, targetSize.height)];
        currentImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    float compression = 1.f;
    NSData *currentData = UIImageJPEGRepresentation(currentImage, compression);
    float sizeInKB = currentData.length / 1024;
    
    BTDLog(@"original image size:%@, file size:%fkb", NSStringFromCGSize(self.size), sizeInKB);
    
    if(sizeInKB <= dataSize)
    {
        return currentData;
    }
    
    int end = 9, middle;
    int len = 10, half;
    while (len > 0)
    {
        @autoreleasepool {
            half = len >> 1;
            middle = end - half;
            currentData = UIImageJPEGRepresentation(currentImage, (float)middle / 10.f);
            sizeInKB = currentData.length / 1024;
            if (sizeInKB > dataSize) {
                end = middle - 1;
                len = len - half - 1;
            } else {
                len = half;
            }
        }
    }
    
    compression = MAX(end, 0) / 10.f;
    currentData = UIImageJPEGRepresentation(currentImage, compression);
    return  currentData;
}

+ (UIImage *)btd_imageWithColor:(UIColor *)color {
    return [self btd_imageWithColor:color size:CGSizeMake(1, 1)];
}

+ (UIImage*)btd_imageWithColor:(UIColor *)color size:(CGSize)size
{
    CGRect rect = CGRectMake(0.0f, 0.0f, size.width, size.height);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)btd_ImageWithTintColor:(UIColor *)tintColor
{
    UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0f);
    [tintColor setFill];
    CGRect bounds = CGRectMake(0, 0, self.size.width, self.size.height);
    UIRectFill(bounds);
    [self drawInRect:bounds blendMode:kCGBlendModeDestinationIn alpha:1.0f];
    UIImage *tintedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return tintedImage;
}

- (UIImage *)btd_blurredImageWithRadius:(CGFloat)radius iterations:(NSUInteger)iterations tintColor:(UIColor *)tintColor
{
    //image must be nonzero size
    if (floorf(self.size.width) * floorf(self.size.height) <= 0.0f) return self;
    
    //boxsize must be an odd integer
    uint32_t boxSize = (uint32_t)(radius * self.scale);
    if (boxSize % 2 == 0) boxSize ++;
    
    //create image buffers
    CGImageRef imageRef = self.CGImage;
    vImage_Buffer buffer1, buffer2;
    buffer1.width = buffer2.width = CGImageGetWidth(imageRef);
    buffer1.height = buffer2.height = CGImageGetHeight(imageRef);
    buffer1.rowBytes = buffer2.rowBytes = CGImageGetBytesPerRow(imageRef);
    size_t bytes = buffer1.rowBytes * buffer1.height;
    buffer1.data = malloc(bytes);
    buffer2.data = malloc(bytes);
    
    //create temp buffer
    void *tempBuffer = malloc((size_t)vImageBoxConvolve_ARGB8888(&buffer1, &buffer2, NULL, 0, 0, boxSize, boxSize,
                                                                 NULL, kvImageEdgeExtend + kvImageGetTempBufferSize));
    
    //copy image data
    CFDataRef dataSource = CGDataProviderCopyData(CGImageGetDataProvider(imageRef));
    memcpy(buffer1.data, CFDataGetBytePtr(dataSource), bytes);
    CFRelease(dataSource);
    
    for (NSUInteger i = 0; i < iterations; i++)
    {
        //perform blur
        vImageBoxConvolve_ARGB8888(&buffer1, &buffer2, tempBuffer, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);
        
        //swap buffers
        void *temp = buffer1.data;
        buffer1.data = buffer2.data;
        buffer2.data = temp;
    }
    
    //free buffers
    free(buffer2.data);
    free(tempBuffer);
    
    //create image context from buffer
    CGContextRef ctx = CGBitmapContextCreate(buffer1.data, buffer1.width, buffer1.height,
                                             8, buffer1.rowBytes, CGImageGetColorSpace(imageRef),
                                             CGImageGetBitmapInfo(imageRef));
    
    //apply tint
    if (tintColor && CGColorGetAlpha(tintColor.CGColor) > 0.0f)
    {
        CGContextSetFillColorWithColor(ctx, [tintColor colorWithAlphaComponent:0.25].CGColor);
        CGContextSetBlendMode(ctx, kCGBlendModePlusLighter);
        CGContextFillRect(ctx, CGRectMake(0, 0, buffer1.width, buffer1.height));
    }
    
    //create image from context
    imageRef = CGBitmapContextCreateImage(ctx);
    UIImage *image = [UIImage imageWithCGImage:imageRef scale:self.scale orientation:self.imageOrientation];
    CGImageRelease(imageRef);
    CGContextRelease(ctx);
    free(buffer1.data);
    return image;
}

- (UIImage *)btd_blurredImageWithRadius:(CGFloat)radius
{
    CGImageRef imageRef = self.CGImage;
    CGFloat imageScale = self.scale;
    UIImageOrientation imageOrientation = self.imageOrientation;
    
    // Image must be nonzero size
    if (CGImageGetWidth(imageRef) * CGImageGetHeight(imageRef) == 0) {
        return self;
    }
    
    //convert to ARGB if it isn't
    if (CGImageGetBitsPerPixel(imageRef) != 32 ||
        CGImageGetBitsPerComponent(imageRef) != 8 ||
        !((CGImageGetBitmapInfo(imageRef) & kCGBitmapAlphaInfoMask))) {
        UIGraphicsBeginImageContextWithOptions(self.size, NO, self.scale);
        [self drawAtPoint:CGPointZero];
        imageRef = UIGraphicsGetImageFromCurrentImageContext().CGImage;
        UIGraphicsEndImageContext();
    }
    
    vImage_Buffer buffer1, buffer2;
    buffer1.width = buffer2.width = CGImageGetWidth(imageRef);
    buffer1.height = buffer2.height = CGImageGetHeight(imageRef);
    buffer1.rowBytes = buffer2.rowBytes = CGImageGetBytesPerRow(imageRef);
    size_t bytes = buffer1.rowBytes * buffer1.height;
    buffer1.data = malloc(bytes);
    buffer2.data = malloc(bytes);
    
    // A description of how to compute the box kernel width from the Gaussian
    // radius (aka standard deviation) appears in the SVG spec:
    // http://www.w3.org/TR/SVG/filters.html#feGaussianBlurElement
    uint32_t boxSize = floor((radius * imageScale * 3 * sqrt(2 * M_PI) / 4 + 0.5) / 2);
    boxSize |= 1; // Ensure boxSize is odd
    
    //create temp buffer
    void *tempBuffer = malloc((size_t)vImageBoxConvolve_ARGB8888(&buffer1, &buffer2, NULL, 0, 0, boxSize, boxSize,
                                                                 NULL, kvImageEdgeExtend + kvImageGetTempBufferSize));
    
    //copy image data
    CFDataRef dataSource = CGDataProviderCopyData(CGImageGetDataProvider(imageRef));
    memcpy(buffer1.data, CFDataGetBytePtr(dataSource), bytes);
    CFRelease(dataSource);
    
    //perform blur
    vImageBoxConvolve_ARGB8888(&buffer1, &buffer2, tempBuffer, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);
    vImageBoxConvolve_ARGB8888(&buffer2, &buffer1, tempBuffer, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);
    vImageBoxConvolve_ARGB8888(&buffer1, &buffer2, tempBuffer, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);
    
    //free buffers
    free(buffer2.data);
    free(tempBuffer);
    
    //create image context from buffer
    CGContextRef ctx = CGBitmapContextCreate(buffer1.data, buffer1.width, buffer1.height,
                                             8, buffer1.rowBytes, CGImageGetColorSpace(imageRef),
                                             CGImageGetBitmapInfo(imageRef));
    
    //create image from context
    imageRef = CGBitmapContextCreateImage(ctx);
    UIImage *outputImage = [UIImage imageWithCGImage:imageRef scale:imageScale orientation:imageOrientation];
    CGImageRelease(imageRef);
    CGContextRelease(ctx);
    free(buffer1.data);
    return outputImage;
}

- (UIImage *)btd_brighterImage:(CGFloat)lightenValue
{
    UIImage *brighterImage;
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *inputImage = [CIImage imageWithCGImage:self.CGImage];
    
    CIFilter *lighten = [CIFilter filterWithName:@"CIColorControls"];
    [lighten setValue:inputImage forKey:kCIInputImageKey];
    [lighten setValue:@(lightenValue) forKey:@"inputBrightness"];
    
    CIImage *result = [lighten valueForKey:kCIOutputImageKey];
    CGImageRef cgImage = [context createCGImage:result fromRect:[inputImage extent]];
    brighterImage = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    
    return brighterImage;
}

- (UIImage *)btd_darkenImage:(CGFloat)darkenValue
{
    UIGraphicsBeginImageContextWithOptions(self.size, NO, [UIScreen mainScreen].scale);
    [self drawInRect:CGRectMake(0, 0, self.size.width, self.size.height)
           blendMode:kCGBlendModeDarken
               alpha:darkenValue];
    UIImage *darkenImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return darkenImage;
}

+ (UIImage *)btd_imageWithUIColor:(UIColor *)color
{
    CGRect rect=CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return theImage;
}

#pragma mark -
+ (UIImage *)btd_imageWithSize:(CGSize)size
               backgroundColor:(UIColor *)backgroundColor {
    return [UIImage btd_imageWithSize:size
                         cornerRadius:0
                          borderWidth:0
                          borderColor:nil
                      backgroundColor:backgroundColor];
}

+ (UIImage *)btd_imageWithSize:(CGSize)size
                  cornerRadius:(CGFloat)cornerRadius
               backgroundColor:(UIColor *)backgroundColor {
    return [UIImage btd_imageWithSize:size
                         cornerRadius:cornerRadius
                          borderWidth:0
                          borderColor:nil
                      backgroundColor:backgroundColor];
}

+ (UIImage *)btd_imageWithSize:(CGSize)size
                   borderWidth:(CGFloat)borderWidth
                   borderColor:(UIColor *)borderColor
               backgroundColor:(UIColor *)backgroundColor {
    return [UIImage btd_imageWithSize:size
                         cornerRadius:0
                          borderWidth:borderWidth
                          borderColor:borderColor
                      backgroundColor:backgroundColor];
}

+ (UIImage *)btd_imageWithSize:(CGSize)size
                  cornerRadius:(CGFloat)cornerRadius
                   borderWidth:(CGFloat)borderWidth
                   borderColor:(UIColor *)borderColor
               backgroundColor:(UIColor *)backgroundColor {
    return [UIImage btd_imageWithSize:size
                         cornerRadius:cornerRadius
                          borderWidth:borderWidth
                          borderColor:borderColor
                     backgroundColors:@[backgroundColor?:[UIColor whiteColor]]];
}

+ (UIImage *)btd_imageWithSize:(CGSize)size
                  cornerRadius:(CGFloat)cornerRadius
                   borderWidth:(CGFloat)borderWidth
                   borderColor:(UIColor *)borderColor
              backgroundColors:(NSArray *)backgroundColors {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    
    // border
    if ((borderWidth > 0.0f) && borderColor && [borderColor isKindOfClass:[UIColor class]]) {
        CGRect borderRect = CGRectMake(0, 0, size.width, size.height);
        UIBezierPath * borderBezierPath = [UIBezierPath bezierPathWithRoundedRect:borderRect
                                                                     cornerRadius:cornerRadius];
        [borderColor setFill];
        [borderBezierPath fill];
    }
    
    // background
    if (backgroundColors && backgroundColors.count>0) {
        // background bezier path
        CGFloat doubleBorderWidth = borderWidth * 2;
        CGRect backgroundRect = CGRectMake(borderWidth,
                                           borderWidth,
                                           size.width - doubleBorderWidth,
                                           size.height - doubleBorderWidth);
        UIBezierPath * backgroundBezierPath = [UIBezierPath bezierPathWithRoundedRect:backgroundRect
                                                                         cornerRadius:cornerRadius];
        
        if (backgroundColors.count==1) {
            // pure color
            UIColor * backgroundColor = [backgroundColors firstObject];
            [backgroundColor setFill];
            [backgroundBezierPath fill];
        }
        else {
            // gradient color
            [backgroundBezierPath addClip];
            
            UIColor * myStartColor = [backgroundColors firstObject];
            UIColor * myEndColor = [backgroundColors lastObject];
            
            CGGradientRef myGradient;
            CGColorSpaceRef myColorspace;
            size_t num_locations = 2;
            CGFloat locations[2] = { 0.0, 1.0 };
            
            const CGFloat * startColorComponents = CGColorGetComponents(myStartColor.CGColor);
            size_t num_s = CGColorGetNumberOfComponents(myStartColor.CGColor);
            CGFloat s_red = startColorComponents[0];
            CGFloat s_green = num_s==2?s_red:startColorComponents[1];
            CGFloat s_blue = num_s==2?s_red:startColorComponents[2];
            CGFloat s_alpha = num_s==2?startColorComponents[1]:startColorComponents[3];
            
            const CGFloat * endColorComponents = CGColorGetComponents(myEndColor.CGColor);
            size_t num_e = CGColorGetNumberOfComponents(myEndColor.CGColor);
            CGFloat e_red = endColorComponents[0];
            CGFloat e_green = num_e==2?e_red:endColorComponents[1];
            CGFloat e_blue = num_e==2?e_red:endColorComponents[2];
            CGFloat e_alpha = num_e==2?endColorComponents[1]:endColorComponents[3];
            
            CGFloat components[8] = {
                s_red, s_green, s_blue, s_alpha,  // Start color
                e_red, e_green, e_blue, e_alpha // End color
            };
            
            myColorspace = CGColorSpaceCreateDeviceRGB();
            myGradient = CGGradientCreateWithColorComponents (myColorspace,
                                                              components,
                                                              locations,
                                                              num_locations);
            
            CGContextRef myContext = UIGraphicsGetCurrentContext();
            CGPoint myStartPoint, myEndPoint;
            myStartPoint.x = 0.0;
            myStartPoint.y = 0.0;
            myEndPoint.x = size.width;
            myEndPoint.y = size.height;
            CGContextDrawLinearGradient (myContext, myGradient, myStartPoint, myEndPoint, 0);
            CFRelease(myColorspace);
            CFRelease(myGradient);
        }
    }
    
    UIImage * result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return result;
}

+ (UIImage *)btd_cutImage:(UIImage *)img withRect:(CGRect)rect
{
    // 如果输入的坐标为(0.0)，且和原图本身大小一样，没必要创建新图直接返回
    CGRect sourceRect = CGRectMake(0, 0, img.size.width*img.scale, img.size.height*img.scale);
    CGRect targetRect = CGRectMake(rect.origin.x*img.scale, rect.origin.y*img.scale, rect.size.width*img.scale, rect.size.height*img.scale);
    if (CGRectEqualToRect(sourceRect, targetRect)) {
        return img;
    }
    
    CGImageRef sourceImageRef = [img CGImage];
    
    CGImageRef newImagRef = CGImageCreateWithImageInRect(sourceImageRef, targetRect);
    if (newImagRef == NULL) {
        return img;
    }
    UIImage * newImage = [UIImage imageWithCGImage:newImagRef scale:img.scale orientation:img.imageOrientation];
    CGImageRelease(newImagRef);
    return newImage;
}

+ (UIImage *)btd_cutImage:(UIImage *)img withCutWidth:(CGFloat)sideWidth withSideHeight:(CGFloat)sideHeight cutPosition:(BTDImageUtilCutType)cutType
{
    CGFloat borderSizeW = sideWidth;
    CGFloat borderSizeH = sideHeight;
    CGFloat imageWidth = img.size.width;
    CGFloat imageHeight = img.size.height;
    
    if ((borderSizeW == imageWidth && borderSizeH == imageHeight) || cutType == BTDImageUtilCutTypeNone) {
        return img;
    }
    
    UIImage * fixImageData;
    
    if (img && cutType != BTDImageUtilCutTypeNone) {
        
        CGRect imgRect = CGRectZero;
        
        if ((borderSizeW / borderSizeH) < (imageWidth / imageHeight)) {
            // ___________
            //|   |////|  |
            //------------
            imgRect = CGRectMake((imageWidth - (borderSizeW * imageHeight / borderSizeH)) / 2, 0, (borderSizeW * imageHeight / borderSizeH), imageHeight);
        }
        else if((borderSizeW / borderSizeH) >= (imageWidth / imageHeight) && cutType == BTDImageUtilCutTypeTop){
            //the image w/h is less than border w/h like the
            //   -- --
            //   |////|
            //   __ __
            //    | |
            //    | |
            //    --   cow!!! don`t delete this annotation
            CGFloat clipH = imageWidth * borderSizeH / borderSizeW;
            //                    CGFloat clipY = (imageHeight - clipH) / 2;
            imgRect = CGRectMake(0, 0, imageWidth, clipH);
        }
        else {
            //the image w/h is less than border w/h like the
            //    --
            //    | |
            //   -- --
            //   |////|
            //   __ __
            //    | |
            //    --   cow!!! don`t delete this annotation
            CGFloat clipH = imageWidth * borderSizeH / borderSizeW;
            CGFloat clipY = (imageHeight - clipH) / 2;
            
            imgRect = CGRectMake(0, clipY, imageWidth, clipH);
        }
        
        fixImageData = [self btd_cutImage:img withRect:imgRect];
    }
    else {
        fixImageData = img;
    }
    
    UIImage * fImageData = nil;
    
    if (fixImageData.imageOrientation != UIImageOrientationUp) {
        fImageData = [UIImage imageWithCGImage:fixImageData.CGImage scale:1.f orientation:UIImageOrientationUp];
    }
    else {
        fImageData = fixImageData;
    }
    return fImageData;
}

+ (UIImage *)btd_fixImgOrientation:(UIImage *)aImage
{
    
    // No-op if the orientation is already correct
    if (aImage.imageOrientation == UIImageOrientationUp)
        return aImage;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, aImage.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, aImage.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, aImage.size.width, aImage.size.height,
                                             CGImageGetBitsPerComponent(aImage.CGImage), 0,
                                             CGImageGetColorSpace(aImage.CGImage),
                                             CGImageGetBitmapInfo(aImage.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (aImage.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.height,aImage.size.width), aImage.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.width,aImage.size.height), aImage.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

+ (UIImage *)btd_compressImage:(UIImage *)sourceImage withTargetSize:(CGSize)targetSize
{
    UIImage * targetImage = nil;
    // If the length and width of the picture are not integers, there will be a problem of leaving a white border in the generated picture. Round it down here.
    CGSize roundedTargetSize = CGSizeMake((NSInteger)targetSize.width, (NSInteger)targetSize.height);
    UIGraphicsBeginImageContext(roundedTargetSize);
    [sourceImage drawInRect:CGRectMake(0, 0, roundedTargetSize.width, roundedTargetSize.height)];
    
    targetImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return targetImage;
}

+ (UIImage *)btd_tryCompressImage:(UIImage *)sourceImage ifImageSizeLargeTargetSize:(CGSize)targetSize
{
    if (sourceImage == nil || targetSize.height == 0 || targetSize.width == 0) {
        return sourceImage;
    }
    if (sourceImage.size.width < targetSize.width && sourceImage.size.height < targetSize.height) {
        return sourceImage;
    }
    
    if (aspectRatioForSize(sourceImage.size) == aspectRatioForSize(targetSize)) {
        return  [self btd_compressImage:sourceImage withTargetSize:targetSize];
    }
    else if (aspectRatioForSize(sourceImage.size) > aspectRatioForSize(targetSize) && sourceImage.size.width > 0) {
        CGSize size = CGSizeZero;
        size.width = targetSize.width;
        size.height = (size.width * sourceImage.size.height) / sourceImage.size.width;
        return [self btd_compressImage:sourceImage withTargetSize:size];
    }
    else if (aspectRatioForSize(sourceImage.size) < aspectRatioForSize(targetSize) && sourceImage.size.height > 0) {
        CGSize size = CGSizeZero;
        size.height = targetSize.height;
        size.width = (sourceImage.size.width * size.height ) / sourceImage.size.height;
        return [self btd_compressImage:sourceImage withTargetSize:size];
    }
    return sourceImage;
}

+ (UIImage *)btd_imageRotatedByRadians:(CGFloat)radians originImg:(UIImage *)originImg
{
    return [self btd_imageRotatedByRadians:radians originImg:originImg opaque:NO];
}

+ (UIImage *)btd_imageRotatedByDegrees:(CGFloat)degrees originImg:(UIImage *)originImg
{
    return [self btd_imageRotatedByDegrees:degrees originImg:originImg opaque:NO];
}

+ (UIImage *)btd_imageRotatedByRadians:(CGFloat)radians originImg:(UIImage *)originImg opaque:(BOOL)opaque
{
    return [self btd_imageRotatedByDegrees:radiansToDegrees(radians) originImg:originImg opaque:opaque];
}

+ (UIImage *)btd_imageRotatedByDegrees:(CGFloat)degrees originImg:(UIImage *)originImg opaque:(BOOL)opaque
{
    // calculate the size of the rotated view's containing box for our drawing space
    UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0,0,originImg.size.width, originImg.size.height)];
    CGAffineTransform t = CGAffineTransformMakeRotation(degreesToRadians(degrees));
    rotatedViewBox.transform = t;
    CGSize rotatedSize = rotatedViewBox.frame.size;
    
    // Create the bitmap context
    UIGraphicsBeginImageContextWithOptions(rotatedSize, opaque, originImg.scale);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();
    
    // Move the origin to the middle of the image so we will rotate and scale around the center.
    CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);
    
    //   // Rotate the image context
    CGContextRotateCTM(bitmap, degreesToRadians(degrees));
    
    // Now, draw the rotated/scaled image into the context
    CGContextScaleCTM(bitmap, 1.0, -1.0);
    CGContextDrawImage(bitmap, CGRectMake(-originImg.size.width / 2, -originImg.size.height / 2, originImg.size.width, originImg.size.height), [originImg CGImage]);
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
    
}

+ (void)btd_image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    void(^block)(NSError *) = (__bridge_transfer id)contextInfo;
    if (block) {
        block(error);
    }
}

@end

void BTDImageWriteToSavedPhotosAlbum(UIImage *image, void(^completionBlock)(NSError *)) {
    void *blockAsContext = (__bridge_retained void *)[completionBlock copy];
    UIImageWriteToSavedPhotosAlbum(image, UIImage.class, @selector(btd_image:didFinishSavingWithError:contextInfo:), blockAsContext);
}

