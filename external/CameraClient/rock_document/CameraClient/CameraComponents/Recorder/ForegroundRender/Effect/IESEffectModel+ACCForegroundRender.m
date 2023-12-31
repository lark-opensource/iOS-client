//
//  IESEffectModel+ACCForegroundRender.m
//  CameraClient-Pods-Aweme
//
//  Created by Howie He on 2020/9/6.
//

#import "IESEffectModel+ACCForegroundRender.h"
#import <CreationKitInfra/NSString+ACCAdditions.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import "ACCConfigKeyDefines.h"

@interface ACCForegroundRenderParams ()

@property (nonatomic, strong) IESEffectModel *model;
@property (nonatomic, strong) NSDictionary *sdkExtra;
@property (nonatomic, assign) BOOL enable1080p;

@end

@implementation ACCForegroundRenderParams

- (instancetype)initWithModel:(IESEffectModel *)model
{
    if (self = [super init]) {
        _model = model;
        NSDictionary *extra = [model.sdkExtra acc_jsonValueDecoded];
        if ([extra isKindOfClass:[NSDictionary class]]) {
            _sdkExtra = extra;
        }
        _enable1080p = ACCConfigBool(kConfigBool_enable_1080p_capture_preview);
    }
    return self;
}

- (BOOL)hasForeground
{
    return self.foregroundRenderResourcePath != nil;
}

- (NSString *)foregroundRenderResourcePath
{
    NSString *path = [self.sdkExtra acc_stringValueForKey:@"befViewResRoot"];
    if (!ACC_isEmptyString(path)) {
        return [self.model.filePath stringByAppendingPathComponent:path];
    }
    return nil;
}

- (CGSize)foregroundRenderSize
{
    NSDictionary *sizeDict = [self.sdkExtra acc_dictionaryValueForKey:@"befViewRenderSize"];
    if (sizeDict.count == 0) {
        if (self.enable1080p) {
            return CGSizeMake(1080, 1920);
        } else {
            return CGSizeMake(720, 1280);
        }
    }
    
    return CGSizeMake([sizeDict acc_floatValueForKey:@"w" defaultValue:720], [sizeDict acc_floatValueForKey:@"h" defaultValue:1280]);
}

- (NSInteger)foregroundRenderFPS
{
    return [self.sdkExtra acc_integerValueForKey:@"befViewRenderFPS" defaultValue:30];
}

- (NSValue *)foregroundRenderViewFrame
{
    NSDictionary *frameDict = [self.sdkExtra acc_dictionaryValueForKey:@"befViewFrame"];
    if (frameDict.count == 0) {
        return nil;
    }
    
    return [NSValue valueWithCGRect:CGRectMake([frameDict acc_floatValueForKey:@"x"],
                      [frameDict acc_floatValueForKey:@"y"],
                      [frameDict acc_floatValueForKey:@"w"],
                      [frameDict acc_floatValueForKey:@"h"])];
}

- (NSInteger)foregroundRenderFitMode
{
    return [self.sdkExtra acc_integerValueForKey:@"befViewFitMode" defaultValue:1];
}

@end

@implementation IESEffectModel (ACCForegroundRender)

- (ACCForegroundRenderParams *)acc_foregroundRenderParams
{
    return [[ACCForegroundRenderParams alloc] initWithModel:self];
}

@end
