//
//  BDImageRequestKey.m
//  BDWebImage
//
//  Created by 陈奕 on 2020/5/22.
//

#import "BDImageRequestKey.h"
#import "BDWebImageManager.h"

@interface BDImageRequestKey ()

@property (nonatomic, copy)NSString *targetkey;

@end

@implementation BDImageRequestKey

- (instancetype)initWithURL:(NSString *)url
{
    self = [super init];
    if (self) {
        [self commonInitWithURL:url
                 downsampleSize:CGSizeZero
                       cropRect:CGRectZero
                  transfromName:nil
                      smartCrop:NO];
    }
    return self;
}

- (instancetype)initWithURL:(NSString *)url
             downsampleSize:(CGSize)downsampleSize
                   cropRect:(CGRect)cropRect
              transfromName:(NSString *)transfromName
                  smartCrop:(BOOL)smartCrop
{
    self = [super init];
    if (self) {
        [self commonInitWithURL:url downsampleSize:downsampleSize cropRect:cropRect transfromName:transfromName smartCrop:smartCrop];
        self.builded = YES;
    }
    return self;
}

- (void)commonInitWithURL:(NSString *)url
           downsampleSize:(CGSize)downsampleSize
                 cropRect:(CGRect)cropRect
            transfromName:(NSString *)transfromName
                smartCrop:(BOOL)smartCrop
{
    self.sourceKey = url ?: @"";
    self.sourceThumbKey = url ? [url stringByAppendingString:@"_thumb"] : @"";
    self.targetkey = url ?: @"";
    self.downsampleSize = downsampleSize;
    self.cropRect = cropRect;
    self.transfromName = transfromName ?: @"";
    self.smartCrop = smartCrop;
}

- (BOOL)containsUrl:(NSString *)url
{
    if (![url isKindOfClass:[NSString class]] || !url.length) {
        return NO;
    }
    NSString *requestKey = [[BDWebImageManager sharedManager] requestKeyWithURL:[NSURL URLWithString:url]];
    return [_sourceKey isEqualToString:url] || [_sourceKey isEqualToString:requestKey];
}

- (NSString *)extendKeyWithType:(NSString *)type value:(NSString *)value
{
    return [_targetkey stringByAppendingFormat:@"~%@:%@", type, value];
}

#pragma mark setter && init key String

- (void)setBuilded:(BOOL)builded
{
    if (builded) {
        NSString *targetkey = @"";
        if (_sourceKey.length > 0) {
            targetkey = [_sourceKey mutableCopy];
            if (_transfromName.length > 0) {
                targetkey = [targetkey stringByAppendingFormat:@"_transfrom:%@", _transfromName];
            }
            if (!CGRectEqualToRect(CGRectZero, _cropRect)) {
                targetkey = [targetkey stringByAppendingFormat:@"_crop:%@", NSStringFromCGRect(_cropRect)];
            } else if (_smartCrop) {
                targetkey = [targetkey stringByAppendingString:@"_smartCrop"];
            } else if (!CGSizeEqualToSize(CGSizeZero, _downsampleSize)) {
                targetkey = [targetkey stringByAppendingFormat:@"_downsample:%ldx%ld", (NSInteger)(_downsampleSize.width), (NSInteger)(_downsampleSize.height)];
            }
        }
        _targetkey = targetkey;
        _sourceThumbKey = [_sourceKey stringByAppendingString:@"_thumb"];
    }
    _builded = builded;
}

- (void)setDownsampleSize:(CGSize)downsampleSize
{
    _downsampleSize = CGSizeMake(downsampleSize.width * UIScreen.mainScreen.scale, downsampleSize.height * UIScreen.mainScreen.scale);
}

#pragma mark Equal

- (BOOL)isEqual:(id)other
{
    if (other == self) {
        return YES;
    } else {
        if ([other isKindOfClass:[BDImageRequestKey class]]) {
            BDImageRequestKey *otherKey = (BDImageRequestKey *)other;
            return [self.targetkey isEqualToString:otherKey.targetkey];
        }
        return NO;
    }
}

- (NSUInteger)hash
{
    return [self.targetkey hash];
}

- (id)copyWithZone:(NSZone *)zone
{
    BDImageRequestKey *key = [[self class] allocWithZone:zone];
    key.sourceKey = self.sourceKey;
    key.sourceThumbKey = self.sourceThumbKey;
    key.targetkey = self.targetkey;
    key.transfromName = self.transfromName;
    key.cropRect = self.cropRect;
    key.smartCrop = self.smartCrop;
    key.downsampleSize = CGSizeMake(self.downsampleSize.width / UIScreen.mainScreen.scale, self.downsampleSize.height / UIScreen.mainScreen.scale);
    key.builded = self.builded;
    return key;
}

@end
