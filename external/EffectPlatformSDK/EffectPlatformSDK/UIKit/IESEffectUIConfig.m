//
//  IESEffectUIConfig.m
//  EffectPlatformSDK
//
//  Created by Kun Wang on 2018/3/6.
//

#import "IESEffectUIConfig.h"

static NSBundle * ies_effect_uikit_shared_bundle(void)
{
    NSBundle *bundle = [NSBundle bundleWithURL:[[NSBundle mainBundle] URLForResource:@"IESStickerUIKit" withExtension:@"bundle"]];
    return bundle;
}

@implementation IESEffectUIConfig
- (instancetype)init
{
    self = [super init];
    if (self) {
        _sectionMinWidth = 56;
        _sectionHeight = 38;
        _contentScrollEnable = YES;
        _showCategory = YES;
        _showClearInCategory = YES;
        _contentHeight = 200;
        _contentInsets = UIEdgeInsetsMake(16, 16, 16, 16);
        _horizonInterval = 16;
        _verticalInterval = 16;
        _numberOfItemPerRow = 5;
        _sectionSeperatorColor = [UIColor colorWithWhite:1 alpha:0.16];
        _sectionSeperatorHeight = 0.5;
        _sectionTextFont = [UIFont boldSystemFontOfSize:16];
        _blurBackground = YES;
        _redDotTagForEffect = @"new";
        _redDotTagForCategory = @"new";
        _backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
        _sectionBackgroundColor = [UIColor clearColor];
        _downloadImage = [UIImage imageNamed:@"iesEffectDownload" inBundle:ies_effect_uikit_shared_bundle() compatibleWithTraitCollection:nil];
        _selectedBorderColor = [UIColor colorWithRed:255.0 / 255.0 green:34.0 / 255.0 blue:0 alpha:1];
        _sectionTitleSelectedColor = [UIColor colorWithRed:255.0 / 255.0 green:34.0 / 255.0 blue:0 alpha:1];
        _sectionTitleUnSelectedColor = [UIColor whiteColor];
        _selectedBorderWidth = 2.0;
        _selectedBorderRadius = 8.0;
        _cleanImage = [UIImage imageNamed:@"iesEffectNoSticker" inBundle:ies_effect_uikit_shared_bundle() compatibleWithTraitCollection:nil];
        _placeHolderImage = [UIImage imageNamed:@"iesEffectLoading" inBundle:ies_effect_uikit_shared_bundle() compatibleWithTraitCollection:nil];
        _categoryCleanImage = [UIImage imageNamed:@"imgNone" inBundle:ies_effect_uikit_shared_bundle() compatibleWithTraitCollection:nil];
    }
    return self;
}

- (BOOL)blurBackground
{
    BOOL iOS9OrLater = [[[UIDevice currentDevice] systemVersion] compare:@"9.0" options:NSNumericSearch] != NSOrderedAscending;
    return _blurBackground && iOS9OrLater;
}

+ (IESEffectUIConfig *)sharedInstance
{
    static IESEffectUIConfig *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[IESEffectUIConfig alloc] init];
    });
    return sharedInstance;
}

@end
