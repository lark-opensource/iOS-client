#import "Svg.h"

#import <nanosvg/nanosvg.h>

#define UIColorRGBA(rgba) ([[UIColor alloc] initWithRed:((rgba & 0xff) / 255.0f) green:(((rgba >> 8) & 0xff) / 255.0f) blue:(((rgba >> 16) & 0xff) / 255.0f) alpha:(((rgba >> 24) & 0xff) / 255.0f)])

static void nsvg__xformIdentity(float* t)
{
    t[0] = 1.0f; t[1] = 0.0f;
    t[2] = 0.0f; t[3] = 1.0f;
    t[4] = 0.0f; t[5] = 0.0f;
}

static void nsvg__xformInverse(float* inv, float* t) {
    double invdet, det = (double)t[0] * t[3] - (double)t[2] * t[1];
    if (det > -1e-6 && det < 1e-6) {
        nsvg__xformIdentity(t);
        return;
    }
    invdet = 1.0 / det;
    inv[0] = (float)(t[3] * invdet);
    inv[2] = (float)(-t[2] * invdet);
    inv[4] = (float)(((double)t[2] * t[5] - (double)t[3] * t[4]) * invdet);
    inv[1] = (float)(-t[1] * invdet);
    inv[3] = (float)(t[0] * invdet);
    inv[5] = (float)(((double)t[1] * t[4] - (double)t[0] * t[5]) * invdet);
}

static void nsvg__xformPoint(float* dx, float* dy, float x, float y, float* t) {
    *dx = x*t[0] + y*t[2] + t[4];
    *dy = x*t[1] + y*t[3] + t[5];
}

static void nsvg__xformVec(float* dx, float* dy, float x, float y, float* t)
{
    *dx = x*t[0] + y*t[2];
    *dy = x*t[1] + y*t[3];
}

static bool enable_console_log = false;

void svg_set_enable_console_log(bool enable) {
    enable_console_log = enable;
}

static CGSize aspectFillSize(CGSize size, CGSize bounds, TTSvgContentMode model) {
    if (model == TTSvgContentModelScaleToAspectFit) {
        CGFloat scale = MIN(bounds.width / MAX(1.0, size.width), bounds.height / MAX(1.0, size.height));
        return CGSizeMake(floor(size.width * scale), floor(size.height * scale));
    }
    if (model == TTSvgContentModelScaleToAspectFill) {
        CGFloat scale = MAX(bounds.width / MAX(1.0, size.width), bounds.height / MAX(1.0, size.height));
        return CGSizeMake(floor(size.width * scale), floor(size.height * scale));
    }
    if (model == TTSvgContentModelScaleToFill) {
        return bounds;
    }
    return size;
}

@interface TTSvgXMLParsingDelegate : NSObject <NSXMLParserDelegate> {
    NSString *_elementName;
    NSString *_styleString;
}

@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *, NSString *> *styles;

@end

@implementation TTSvgXMLParsingDelegate

- (instancetype)init {
    self = [super init];
    if (self != nil) {
        _styles = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary<NSString *,NSString *> *)attributeDict {
    _elementName = elementName;
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    if ([_elementName isEqualToString:@"style"]) {
        int classNameStartIndex = -1;
        int classContentsStartIndex = -1;
        
        NSString *className = nil;
        
        NSCharacterSet *alphanumeric = [NSCharacterSet alphanumericCharacterSet];
        
        for (int i = 0; i < _styleString.length; i++) {
            unichar c = [_styleString characterAtIndex:i];
            if (classNameStartIndex != -1) {
                if (![alphanumeric characterIsMember:c]) {
                    className = [_styleString substringWithRange:NSMakeRange(classNameStartIndex, i - classNameStartIndex)];
                    classNameStartIndex = -1;
                }
            } else if (classContentsStartIndex != -1) {
                if (c == '}') {
                    NSString *classContents = [_styleString substringWithRange:NSMakeRange(classContentsStartIndex, i - classContentsStartIndex)];
                    if (className != nil && classContents != nil) {
                        _styles[className] = classContents;
                        className = nil;
                    }
                    classContentsStartIndex = -1;
                }
            }
            
            if (classNameStartIndex == -1 && classContentsStartIndex == -1) {
                if (c == '.') {
                    classNameStartIndex = i + 1;
                } else if (c == '{') {
                    classContentsStartIndex = i + 1;
                }
            }
        }
    }
    _elementName = nil;
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if ([_elementName isEqualToString:@"style"]) {
        if (_styleString == nil) {
            _styleString = string;
        } else {
            _styleString = [_styleString stringByAppendingString:string];
        }
    }
}

@end

static CGPathRef setContextClip(CGContextRef context, NSVGclipPath *clipPath, NSVGclip clip);

static UIImage * _Nullable imageFromXhref(NSString *href)
{
    NSData *imageData;
    if ([href hasPrefix:@"http:"] || [href hasPrefix:@"https:"]) {
        // TODO: support http
        return nil;
    } else if ([href hasPrefix:@"data:"]) {
        href = [href stringByReplacingOccurrencesOfString:@"\\s+"
                                               withString:@""
                                                  options:NSRegularExpressionSearch
                                                    range:NSMakeRange(0, href.length)];
        imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:href]];
    }
    UIImage *image = [[UIImage alloc] initWithData:imageData];
    
    return image;
}

static CGPatternRef setContextPattern(CGContextRef context, NSVGpattern *pattern, CGAffineTransform transform, SvgImageCallback imageCb);

UIImage * _Nullable TTDrawSvgImage(NSData * _Nonnull data, CGSize size, SvgImageCallback imageCb) {
    TTDrawSvgOptions options = {.imageCb = imageCb};
    return TTDrawSvgImageWithOptions(data, size, &options);
}

static TTDrawSvgOptions defaultSvgOptions;

static void DrawGradientFill(CGContextRef context, NSVGshape *ishape, BOOL fill) {
    CGContextSaveGState(context);
    
    switch (ishape->fillRule) {
        case NSVG_FILLRULE_EVENODD:
            CGContextEOClip(context);
            break;
        default:
            CGContextClip(context);
            break;
    }
    
    NSVGgradient* gradient = fill ? ishape->fill.gradient : ishape->stroke.gradient;
    BOOL linear = fill ? ishape->fill.type == NSVG_PAINT_LINEAR_GRADIENT : ishape->stroke.type == NSVG_PAINT_LINEAR_GRADIENT;
    
    CGFloat colors[(gradient->nstops) * 4];
    CGFloat offsets[(gradient->nstops)];
    
    // TODO(huzhanbo): support spreadMethod
    for (int idx=0; idx < gradient->nstops; idx++ ) {
        colors[idx * 4] = ((gradient->stops[idx].color & 0x000000FF)) / 255.0 ;
        colors[idx * 4 + 1] = ((gradient->stops[idx].color & 0x0000FF00) >> 8) / 255.0;
        colors[idx * 4 + 2] = ((gradient->stops[idx].color & 0x00FF0000) >> 16) / 255.0;
        colors[idx * 4 + 3] = ((gradient->stops[idx].color ) >> 24) / 255.0;
        offsets[idx] = gradient->stops[idx].offset;
//        NSLog(@"%f %f %f %f", colors[idx * 4], colors[idx * 4 + 1], colors[idx * 4 + 2], colors[idx * 4 + 3]);
    }
    
    CGColorSpaceRef baseSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradientRef = CGGradientCreateWithColorComponents(baseSpace, colors, offsets, gradient->nstops);
    
    if (linear) {
        float xformOrig[6];
        float x1, y1, x2, y2;
        nsvg__xformInverse(xformOrig, gradient->xform);
        nsvg__xformPoint(&x1, &y1, 0, 0, xformOrig);
        nsvg__xformPoint(&x2, &y2, 0, 1, xformOrig);
        
        CGPoint startPoint = CGPointMake(x1, y1);
        CGPoint endPoint = CGPointMake(x2, y2);
        
        CGContextDrawLinearGradient(context, gradientRef, startPoint, endPoint, kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
    } else {
        float xformOrig[6];
        float cx, cy, r1, r2, fx, fy;
        nsvg__xformInverse(xformOrig, gradient->xform);
        nsvg__xformPoint(&cx, &cy, 0, 0, xformOrig);
        nsvg__xformPoint(&r1, &r2, 0, 1, xformOrig);
        CGPoint center = CGPointMake(cx, cy);
        nsvg__xformVec(&fx, &fy, gradient->fx, gradient->fy, xformOrig);
        CGPoint fcenter = CGPointMake(cx + fx, cy + fy);
        CGContextDrawRadialGradient(context, gradientRef, fcenter, 0, center, r2 - cy, kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
    }
    
    CGColorSpaceRelease(baseSpace);
    CGGradientRelease(gradientRef);
    
    CGContextRestoreGState(context);
}

UIImage * _Nullable TTDrawSvgImageWithOptions(NSData * _Nonnull data, CGSize size, TTDrawSvgOptions *options)
{
    NSDate *startTime;
    if (enable_console_log) {
        startTime = [NSDate date];
    }
    
    if (options == NULL) {
        options = &defaultSvgOptions;
    }
    
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
    if (parser == nil) {
        return nil;
    }
    TTSvgXMLParsingDelegate *delegate = [[TTSvgXMLParsingDelegate alloc] init];
    parser.delegate = delegate;
    [parser parse];
    
    NSMutableString *dataString = [[NSMutableString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (dataString == nil) {
        return nil;
    }
    
    for (NSString *styleName in delegate.styles) {
        NSString *styleValue = delegate.styles[styleName];
        [dataString replaceOccurrencesOfString:[NSString stringWithFormat:@"class=\"%@\"", styleName] withString:[NSString stringWithFormat:@"style=\"%@\"", styleValue] options:0 range:NSMakeRange(0, dataString.length)];
    }
    
    char *cString = (char *)dataString.UTF8String;
    
    NSVGimage *image = nsvgParse(cString, "px", 96);
    if (image == nil || image->width < 1.0f || image->height < 1.0f) {
        nsvgDelete(image);
        return nil;
    }
    
    CGSize svgSize = CGSizeMake(image->width, image->height);
    // stroke width 大于1时，可能会有部分线超出区域，因此要扩大一下画布
    float border = 0;
    NSVGshape *firstShape = image->shapes;
    if (firstShape && firstShape->strokeWidth > 0) {
        border = firstShape->strokeWidth;
        svgSize.width += border;
        svgSize.height += border;
    }
    
    if (CGSizeEqualToSize(size, CGSizeZero)) {
        size = svgSize;
    }

    double deltaTime;
    if (enable_console_log) {
        deltaTime = -1.0f * [startTime timeIntervalSinceNow];
        printf("parseTime = %f\n", deltaTime);
        startTime = [NSDate date];
    }
    
    UIGraphicsBeginImageContextWithOptions(size, false, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGSize drawingSize = aspectFillSize(svgSize, size, options->contentMode);
    
    CGFloat scaleX = drawingSize.width / MAX(1.0, svgSize.width);
    CGFloat scaleY = drawingSize.height / MAX(1.0, svgSize.height);
    CGFloat lineScale = MAX(scaleX, scaleY);
    CGContextScaleCTM(context, scaleX, scaleY);
    if (lineScale * border > 1) {
        // coregraphic的起点，不受线段居中影响，需要偏移
        CGContextTranslateCTM(context, (size.width - drawingSize.width) / 2.0 / scaleX + border / 2,
                                       (size.height - drawingSize.height) / 2.0 / scaleY + border / 2);
    } else {
        CGContextTranslateCTM(context, (size.width - drawingSize.width) / 2.0 / scaleX,
                                       (size.height - drawingSize.height) / 2.0 / scaleY);
    }
    for (NSVGshape *ishape = image->shapes; ishape != NULL; ishape = ishape->next) {
        if (!(ishape->flags & NSVG_FLAGS_VISIBLE)) {
            continue;
        }
        
        CGPathRef clipPath = 0;
        CGPatternRef pattern = 0;
        if (ishape->clip.count != 0) {
            clipPath = setContextClip(context, image->clipPaths, ishape->clip);
        }
        if (ishape->image_href) {
            NSString *href = [NSString stringWithUTF8String:ishape->image_href];
            CGRect rect = CGRectMake(ishape->bounds[0], ishape->bounds[1], ishape->bounds[2], ishape->bounds[3]);
            UIImage *image = imageFromXhref(href);
            if (!image) {
                if (options->imageCb) {
                    image = options->imageCb(href);
                }
            }
            if (image) {
                // see https://stackoverflow.com/questions/506622/cgcontextdrawimage-draws-image-upside-down-when-passed-uiimage-cgimage/511199#511199
                CGContextTranslateCTM(context, 0, rect.size.height);
                CGContextScaleCTM(context, 1.0, -1.0);
                
                CGContextDrawImage(context, rect, image.CGImage);
                
                CGContextScaleCTM(context, 1.0, -1.0);
                CGContextTranslateCTM(context, 0, rect.size.height);
            }
        }
        UIColor *color = options->color;
        if (ishape->fill.type != NSVG_PAINT_NONE) {
            if (ishape->fill.type == NSVG_PAINT_COLOR) {
                CGContextSetFillColorWithColor(context, color ? [color colorWithAlphaComponent:CGColorGetAlpha(UIColorRGBA(ishape->fill.color).CGColor) * CGColorGetAlpha(color.CGColor)].CGColor : UIColorRGBA(ishape->fill.color).CGColor);
            } else if (ishape->fill.type == NSVG_PAINT_PATTERN) {
                CGAffineTransform transform = CGAffineTransformMakeScale(scaleX, scaleY);
                pattern = setContextPattern(context, ishape->fill.pattern, transform, options->imageCb);
                CGColorSpaceRef patternSpace = CGColorSpaceCreatePattern(NULL);
                CGContextSetFillColorSpace(context, patternSpace);
                CGColorSpaceRelease(patternSpace);
                
                CGFloat alpha = 1.0;
                CGContextSetFillPattern(context, pattern, &alpha);
            }

            bool isFirst = true;
            bool hasStartPoint = false;
            CGPoint startPoint;
            for (NSVGpath *spath = ishape->paths; spath != NULL; spath = spath->next) {
                if (isFirst) {
                    CGContextBeginPath(context);
                    isFirst = false;
                    hasStartPoint = true;
                    startPoint.x = spath->pts[0];
                    startPoint.y = spath->pts[1];
                }
                CGContextMoveToPoint(context, spath->pts[0], spath->pts[1]);
                for (int i = 0; i < spath->npts - 1; i += 3) {
                    float *p = &spath->pts[i * 2];
                    CGContextAddCurveToPoint(context, p[2], p[3], p[4], p[5], p[6], p[7]);
                }
                
                if (spath->closed) {
                    if (hasStartPoint) {
                        hasStartPoint = false;
                        CGContextAddLineToPoint(context, startPoint.x, startPoint.y);
                    }
                }
            }
            
            if (ishape->fill.type == NSVG_PAINT_LINEAR_GRADIENT || ishape->fill.type == NSVG_PAINT_RADIAL_GRADIENT) {
                DrawGradientFill(context, ishape, YES);
            } else {
                switch (ishape->fillRule) {
                    case NSVG_FILLRULE_EVENODD:
                        CGContextEOFillPath(context);
                        break;
                    default:
                        CGContextFillPath(context);
                        break;
                }
            }
            
            if (pattern) {
                CGContextRestoreGState(context);
                CGPatternRelease(pattern);
                pattern = 0;
            }
        }
        
        if (ishape->stroke.type != NSVG_PAINT_NONE) {
            if (ishape->stroke.type == NSVG_PAINT_COLOR) {
                CGContextSetStrokeColorWithColor(context, color ? [color colorWithAlphaComponent:CGColorGetAlpha(UIColorRGBA(ishape->stroke.color).CGColor) * CGColorGetAlpha(color.CGColor)].CGColor : UIColorRGBA(ishape->stroke.color).CGColor);
            } else if (ishape->fill.type == NSVG_PAINT_PATTERN) {
                CGAffineTransform transform = CGAffineTransformMakeScale(scaleX, scaleY);
                pattern = setContextPattern(context, ishape->fill.pattern, transform, options->imageCb);
                CGFloat alpha = 1.0;
                CGContextSetStrokePattern(context, pattern, &alpha);
            }
            
            CGContextSetMiterLimit(context, ishape->miterLimit);
            if (ishape->nonScalingStroke) {
                if (ishape->strokeWidth < 1.0) {
                    CGContextSetLineWidth(context, 1 / lineScale);
                } else {
                    CGContextSetLineWidth(context, ishape->strokeWidth / lineScale);
                }
            } else {
                // 缩放后，为了保证线条能显示，小于1的情况给它增大到1
                if (ishape->strokeWidth * lineScale < 1.0) {
                    CGContextSetLineWidth(context, 1.0 / lineScale);
                } else {
                    CGContextSetLineWidth(context, ishape->strokeWidth);
                }
            }
            switch (ishape->strokeLineCap) {
                case NSVG_CAP_BUTT:
                    CGContextSetLineCap(context, kCGLineCapButt);
                    break;
                case NSVG_CAP_ROUND:
                    CGContextSetLineCap(context, kCGLineCapRound);
                    break;
                case NSVG_CAP_SQUARE:
                    CGContextSetLineCap(context, kCGLineCapSquare);
                    break;
                default:
                    break;
            }
            switch (ishape->strokeLineJoin) {
                case NSVG_JOIN_BEVEL:
                    CGContextSetLineJoin(context, kCGLineJoinBevel);
                    break;
                case NSVG_JOIN_MITER:
                    CGContextSetLineJoin(context, kCGLineJoinMiter);
                    break;
                case NSVG_JOIN_ROUND:
                    CGContextSetLineJoin(context, kCGLineJoinRound);
                    break;
                default:
                    break;
            }
            if (ishape->strokeDashCount) {
                CGFloat CGStrokeDashArray[ishape->strokeDashCount];
                for (int j = 0; j < ishape->strokeDashCount; ++j) {
                    CGStrokeDashArray[j] = ishape->strokeDashArray[j];
                }
                CGContextSetLineDash(context, ishape->strokeDashOffset, CGStrokeDashArray, ishape->strokeDashCount);
            }
            
            for (NSVGpath *spath = ishape->paths; spath != NULL; spath = spath->next) {
                CGContextBeginPath(context);
                CGContextMoveToPoint(context, spath->pts[0], spath->pts[1]);
                for (int i = 0; i < spath->npts - 1; i += 3) {
                    float *p = &spath->pts[i * 2];
                    CGContextAddCurveToPoint(context, p[2], p[3], p[4], p[5], p[6], p[7]);
                }
                
                if (spath->closed) {
                    CGContextClosePath(context);
                }
                if (ishape->stroke.type == NSVG_PAINT_LINEAR_GRADIENT || ishape->stroke.type == NSVG_PAINT_RADIAL_GRADIENT) {
                    CGContextReplacePathWithStrokedPath(context);
                    DrawGradientFill(context, ishape, NO);
                } else {
                    CGContextStrokePath(context);
                }
            }
            
            if (pattern) {
                CGContextRestoreGState(context);
                CGPatternRelease(pattern);
                pattern = 0;
            }
        }
        
        if (clipPath) {
            CGContextRestoreGState(context);
            CGPathRelease(clipPath);
            clipPath = 0;
        }
    }
    
    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    if (enable_console_log) {
        deltaTime = -1.0f * [startTime timeIntervalSinceNow];
        printf("drawingTime %fx%f = %f\n", size.width, size.height, deltaTime);
    }
    
    nsvgDelete(image);
    
    return resultImage;
}


static CGPathRef setContextClip(CGContextRef context, NSVGclipPath *clipPath, NSVGclip clip)
{
    CGContextSaveGState(context);
    for (int i = 0; i < clip.count; i++) {
        while (clipPath && clipPath->index != *(clip.index+i)) {
            clipPath = clipPath->next;
        }
        if (clipPath) {
            for (NSVGshape *shape = clipPath->shapes; shape != NULL; shape = shape->next) {
                for (NSVGpath *path = shape->paths; path != NULL; path = path->next) {
                    CGContextBeginPath(context);
                    CGContextMoveToPoint(context, path->pts[0], path->pts[1]);
                    for (int i = 0; i < path->npts - 1; i += 3) {
                        float *p = &path->pts[i * 2];
                        CGContextAddCurveToPoint(context, p[2], p[3], p[4], p[5], p[6], p[7]);
                    }
                    
                    if (path->closed) {
                        CGContextClosePath(context);
                    }
                }
            }
        }
    }
    CGPathRef path = CGContextCopyPath(context);
    CGContextAddPath(context, path);
    CGContextClip(context);
    return path;
}

typedef struct PatternFuncInfo {
    NSVGpattern *pattern;
    CFTypeRef imageCbRef;
} PatternFuncInfo;

static void PatternFunction(void* info, CGContextRef context)
{
    PatternFuncInfo *pinfo = (PatternFuncInfo *)info;
    
    SvgImageCallback imageCb = ((__bridge SvgImageCallback)pinfo->imageCbRef);
    NSVGpattern *pattern = pinfo->pattern;

    for (NSVGshape *shape = pattern->shapes; shape != NULL; shape = shape->next) {
        if (!(shape->flags & NSVG_FLAGS_VISIBLE)) {
            continue;
        }
        if (shape->image_href) {
            NSString *href = [NSString stringWithUTF8String:shape->image_href];
            CGRect rect = CGRectMake(shape->bounds[0], shape->bounds[1], shape->bounds[2], shape->bounds[3]);
            UIImage *image = imageFromXhref(href);
            if (!image) {
                if (imageCb) {
                    image = imageCb(href);
                }
            }
            if (image) {
                // see https://stackoverflow.com/questions/506622/cgcontextdrawimage-draws-image-upside-down-when-passed-uiimage-cgimage/511199#511199
                CGContextTranslateCTM(context, 0, rect.size.height);
                CGContextScaleCTM(context, 1.0, -1.0);
                
                CGContextDrawImage(context, rect, image.CGImage);
                
                CGContextScaleCTM(context, 1.0, -1.0);
                CGContextTranslateCTM(context, 0, rect.size.height);
            }
        }
        // TODO: shapes
    }
}

static void PatternReleaseFunction(void *info)
{
    PatternFuncInfo *pinfo = (PatternFuncInfo *)info;
    CFBridgingRelease(pinfo->imageCbRef);
    free(info);
}

static CGPatternRef setContextPattern(CGContextRef context, NSVGpattern *pattern, CGAffineTransform transform, SvgImageCallback imageCb)
{
    const CGPatternCallbacks callbacks = { 0, &PatternFunction, &PatternReleaseFunction };
    
    PatternFuncInfo *info = malloc(sizeof(PatternFuncInfo));
    info->pattern = pattern;
    info->imageCbRef = CFBridgingRetain(imageCb);
    
    
    CGRect bounds = {pattern->bounds[0], pattern->bounds[1], pattern->bounds[2], pattern->bounds[3]};
    
    CGPatternRef cgPattern = CGPatternCreate(info,
                                             bounds,
                                             transform,
                                             bounds.size.width,
                                             bounds.size.height,
                                             kCGPatternTilingConstantSpacing,
                                             true,
                                             &callbacks);
    
    CGContextSaveGState(context);
    
    return cgPattern;
}


