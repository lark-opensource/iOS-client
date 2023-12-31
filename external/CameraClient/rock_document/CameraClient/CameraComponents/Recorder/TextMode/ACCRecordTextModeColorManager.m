//
//  ACCRecordTextModeColorManager.m
//  CameraClient-Pods-Aweme
//
//  Created by Yangguocheng on 2020/9/20.
//

#import "ACCRecordTextModeColorManager.h"
#import <CreationKitArch/AWEStoryTextImageModel.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCCacheProtocol.h>

@interface ACCTextModeColorModel()

@property (nonatomic, copy) NSArray *bgColors;
@property (nonatomic, strong) UIColor *fontColor;
@property (nonatomic, copy) NSString *colorsString;

@end

@implementation ACCTextModeColorModel

@end

@interface ACCRecordTextModeColorManager()

@property (nonatomic, strong) NSArray <ACCTextModeColorModel *> *colors;
@property (nonatomic, assign) NSInteger selectIndex;

@end

@implementation ACCRecordTextModeColorManager

static NSString *const kRecorderTextModeColorIndexKey = @"kRecorderTextModeColorIndexKey";

- (void)loadCache
{
    NSInteger index = [ACCCache() integerForKey:kRecorderTextModeColorIndexKey];
    if (index >= 0 && index < self.colors.count) {
        self.selectIndex = index;
    }
}

- (void)switchToNext
{
    if (self.colors.count == 0) {
        return;
    }
    self.selectIndex = (self.selectIndex + 1) % self.colors.count;
}

- (void)setSelectIndex:(NSInteger)selectIndex
{
    _selectIndex = selectIndex;
    [ACCCache() setInteger:_selectIndex forKey:kRecorderTextModeColorIndexKey];
}

- (NSArray *)bgColors
{
    return @[
             @[[AWEStoryColor colorWithHexString:@"0x00ECBC"],
               [AWEStoryColor colorWithHexString:@"0x007ADF"]],
             @[[AWEStoryColor colorWithHexString:@"0xFFB1A3"],
               [AWEStoryColor colorWithHexString:@"0xFF265B"]],
             @[[AWEStoryColor colorWithHexString:@"0x20D5EC"],
               [AWEStoryColor colorWithHexString:@"0xA561FE"],
               [AWEStoryColor colorWithHexString:@"0xFE2C55"]],
             @[[AWEStoryColor colorWithHexString:@"0xF8DB52"],
               [AWEStoryColor colorWithHexString:@"0xFF5B5D"]],
             @[[AWEStoryColor colorWithHexString:@"0x067984"],
               [AWEStoryColor colorWithHexString:@"0x10093D"]],
             @[[AWEStoryColor colorWithHexString:@"0xE4EFE9"],
               [AWEStoryColor colorWithHexString:@"0x93A5CF"]],
             @[[AWEStoryColor colorWithHexString:@"0x434343"],
               [AWEStoryColor colorWithHexString:@"0x000000"]],
             ];
}

- (NSArray *)fontColors
{
    return @[
             (id)ACCUIColorFromRGBA(0xFFFFFF, 0.75),
             (id)ACCUIColorFromRGBA(0xFFFFFF, 0.75),
             (id)ACCUIColorFromRGBA(0xFFFFFF, 0.75),
             (id)ACCUIColorFromRGBA(0xFFFFFF, 0.75),
             (id)ACCUIColorFromRGBA(0xFFFFFF, 0.75),
             (id)ACCUIColorFromRGBA(0x000000, 0.34),
             (id)ACCUIColorFromRGBA(0xFFFFFF, 0.75),
             ];
}

#pragma mark - getter

- (ACCTextModeColorModel *)currentModel
{
    if (self.selectIndex > self.colors.count || self.selectIndex < 0) {
        self.selectIndex = 0;
    }
    return [self.colors objectAtIndex:self.selectIndex];
}

- (NSArray<ACCTextModeColorModel *> *)colors
{
    if (!_colors) {
        NSMutableArray *colors = [NSMutableArray array];
        for (int i = 0; i < [self bgColors].count; i++) {
            ACCTextModeColorModel *model = [[ACCTextModeColorModel alloc] init];
            NSMutableArray *colorArray = [NSMutableArray array];
            NSMutableArray *colorStringArray = [NSMutableArray array];
            for (AWEStoryColor *item in [[self bgColors] objectAtIndex:i]) {
                [colorArray addObject:(id)item.color.CGColor];
                [colorStringArray addObject:item.colorString];
            }
            model.bgColors = [colorArray copy];
            model.colorsString = [colorStringArray componentsJoinedByString:@","];
            model.fontColor = [[self fontColors] objectAtIndex:i];
            [colors addObject:model];
        }
        _colors = [colors copy];
    }
    return _colors;
}

@end
