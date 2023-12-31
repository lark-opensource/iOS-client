//
//  AWEKaraokeSelectMusicViewFactory.m
//  AWEStudioService-Pods-Aweme
//
//  Created by bytedance on 2021/8/24.
//

#import "AWEKaraokeSelectMusicViewFactory.h"
#import <CameraClient/ACCMusicModelProtocolD.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIFont+ACCAdditions.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>

static dispatch_once_t _onceToken;
static AWEKaraokeSelectMusicViewFactory *_instance;

@interface AWEKaraokeSelectMusicViewFactory ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, UIImage *> *tagModelToImage;

@end

@implementation AWEKaraokeSelectMusicViewFactory

+ (instancetype)sharedInstance
{
    dispatch_once(&_onceToken, ^{
        if (_instance == nil) {
            _instance = [[AWEKaraokeSelectMusicViewFactory alloc] init];
        }
    });
    return _instance;
}

 + (void)destroySharedInstance
{
    _onceToken = 0;
    _instance = nil;
}

- (nullable UIImage *)tagFromModel:(id<ACCMusicKaraokeTagModelProtocol>)tagModel
{
    if (ACC_isEmptyString(tagModel.text) || ACC_isEmptyString(tagModel.textColor)) {
        return nil;
    }
    NSString *cacheKey = [tagModel.text stringByAppendingString:tagModel.textColor];
    UIImage *image = [self.tagModelToImage acc_objectForKey:cacheKey ofClass:[UIImage class]];
    if (image) {
        return image;
    }
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(26, 14), NO, [UIScreen mainScreen].scale); {
        CGContextRef context = UIGraphicsGetCurrentContext();
        CATextLayer *textLayer = [CATextLayer layer];
        textLayer.frame = CGRectMake(0, 0, 26, 14);
        textLayer.contentsScale = [UIScreen mainScreen].scale;
        textLayer.backgroundColor = ACCColorFromRGBA(255, 255, 255, 0.06).CGColor;
        textLayer.foregroundColor = ACCColorFromHexString(tagModel.textColor).CGColor;
        textLayer.alignmentMode = kCAAlignmentCenter;
        textLayer.wrapped = NO;
        UIFont *font = [UIFont acc_systemFontOfSize:10 weight:ACCFontWeightRegular];
        CGFontRef fontRef = CGFontCreateWithFontName((__bridge CFStringRef)font.fontName);
        textLayer.font = fontRef;
        textLayer.fontSize = font.pointSize;
        CGFontRelease(fontRef);
        textLayer.string = tagModel.text;
        textLayer.cornerRadius = 2.0;
        [textLayer renderInContext:context];
        image = UIGraphicsGetImageFromCurrentImageContext();
    } UIGraphicsEndImageContext();
    self.tagModelToImage[cacheKey] = image;
    return image;
}

@end
