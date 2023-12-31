//
//  ACCDuetLayoutModel.m
//  CameraClient-Pods-Aweme
//
//  Created by 李辉 on 2020/2/15.
//

#import "ACCDuetLayoutModel.h"
#import <CreationKitInfra/ACCLogProtocol.h>
#import <EffectPlatformSDK/IESEffectModel.h>

NSString * const kACCDuetLayoutGuideTagUpDown = @"guide_up_down";
NSString * const kACCDuetLayoutGudieThreeScreen = @"guide_three_screen";
NSString * const kACCDuetGreenScreenIsEverShot = @"kACCDuetGreenScreenIsEverShot";

NSString * const supportDuetLayoutNewUp = @"new_up";
NSString * const supportDuetLayoutNewDown = @"new_down";
NSString * const supportDuetLayoutNewLeft = @"new_left";
NSString * const supportDuetLayoutNewRight = @"new_right";
NSString * const supportDuetLayoutPictureInPicture = @"picture_in_picture";

@implementation ACCDuetLayoutTrackModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"name" : @"name",
             @"switchType" : @"change_direction_mode",
             @"shootAtList" : @"direction_status",
             @"duetLayoutList" : @"safety_status"
             };
}

@end

@implementation ACCDuetLayoutModel

- (instancetype)initWithEffect:(IESEffectModel *)effect
{
    if (self = [super init]) {
        self.effect = effect;
    }
    return self;
}

- (BOOL)enable
{
    return self.effect.downloaded && [[NSFileManager defaultManager] fileExistsAtPath:self.effect.filePath];
}

- (VEComposerInfo *)node
{
    BOOL hasDownloaded = self.effect.downloaded && [[NSFileManager defaultManager] fileExistsAtPath:self.effect.filePath];
    if (!hasDownloaded) {
        return nil;
    }
    VEComposerInfo *node = [VEComposerInfo new];
    for (NSString *tag in self.effect.tags) {
        if (!([tag isEqualToString:kACCDuetLayoutGuideTagUpDown] || [tag isEqualToString:kACCDuetLayoutGudieThreeScreen])) {
            node.tag = tag;
            break;
        }
    }
    node.node = self.effect.filePath;
    return node;
}

- (ACCDuetLayoutSwitchType)switchType
{
    return self.trackModel ? self.trackModel.switchType : ACCDuetLayoutSwitchTypeNone;
}

-(NSString *)duetLayout
{
    NSInteger index = self.toggled ? 1 : 0;
    return  index < self.trackModel.duetLayoutList.count ? [self.trackModel.duetLayoutList objectAtIndex:index] : @"";
}

- (NSInteger)duetLayoutIndexOf:(NSString *)duetLayout
{
    NSInteger index = -1;
    for (NSString *layout in self.trackModel.duetLayoutList) {
        index ++;
        if ([duetLayout isEqualToString:layout]) {
            return index;
        }
    }
    return -1;
}

- (void)setEffect:(IESEffectModel *)effect
{
    _effect = effect;
    if (effect.extra) {
        //https://bytedance.feishu.cn/docs/doccnJD8QQbp6wY39BerpKb0uYf#
        NSData *jsonData = [effect.extra dataUsingEncoding:NSUTF8StringEncoding];
        if (!jsonData) {
             AWELogToolError(AWELogToolTagRecord, @"ACCDuetLayoutModel parse-1 effect: %@, failed!", effect.effectName);
            return;
        }
        NSDictionary *extraDic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
        NSData *actualJsonData = [[extraDic objectForKey:@"duet_layout_mode"] dataUsingEncoding:NSUTF8StringEncoding];
        if (!actualJsonData) {
             AWELogToolError(AWELogToolTagRecord, @"ACCDuetLayoutModel parse-2 effect: name = %@,extra = %@ failed!", effect.effectName, effect.extra);
            return;
        }
        NSDictionary *trackDic = [NSJSONSerialization JSONObjectWithData:actualJsonData options:NSJSONReadingMutableContainers error:nil];
        if (trackDic) {
            self.trackModel = [MTLJSONAdapter modelOfClass:[ACCDuetLayoutTrackModel class] fromJSONDictionary:trackDic error:nil];
        }
    }
}

@end

@implementation ACCDuetLayoutFrameModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        @"type" : @"type",
        @"x1" : @"x1",
        @"y1" : @"y1",
        @"x2" : @"x2",
        @"y2" : @"y2"
    };
}

+ (ACCDuetLayoutFrameModel *)configDuetLayoutFrameModelWithString:(NSString *)layoutFrame {
    NSData *jsonData = [layoutFrame dataUsingEncoding:NSUTF8StringEncoding];
    if (!jsonData) {
         AWELogToolError(AWELogToolTagRecord, @"ACCDuetLayoutFrameModel jsonData failed!");
        return nil;
    }
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
    if (dic) {
        NSError *error;
        ACCDuetLayoutFrameModel *model = [MTLJSONAdapter modelOfClass:[ACCDuetLayoutFrameModel class] fromJSONDictionary:dic error:&error];
        if (error) {
            AWELogToolError(AWELogToolTagRecord, @"ACCDuetLayoutFrameModel convert failed!");
        } else {
            return model;
        }
    }
    return nil;
}

+ (NSArray<NSString *> *)supportDuetLayoutFrameList {
    return @[supportDuetLayoutNewUp, supportDuetLayoutNewDown, supportDuetLayoutNewLeft, supportDuetLayoutNewRight, supportDuetLayoutPictureInPicture];
}

@end
