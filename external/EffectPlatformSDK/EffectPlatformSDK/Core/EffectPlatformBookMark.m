//
//  EffectPlatformBookMark.m
//  EffectPlatformSDK
//
//  Created by Kun Wang on 2018/3/26.
//

#import "EffectPlatformBookMark.h"
#import "IESEffectDefines.h"
#import "EffectPlatform.h"

@interface EffectPlatformBookMark()
@property (nonatomic, strong) NSMutableDictionary *bookmarkDic;
@end

@implementation EffectPlatformBookMark
+ (EffectPlatformBookMark *)sharedInstance;
{
    static EffectPlatformBookMark *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[EffectPlatformBookMark alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self _loadBookMark];
    }
    return self;
}

- (void)_loadBookMark
{
    NSDictionary *loaded = [NSDictionary dictionaryWithContentsOfFile:IESEffectBookMarkPath()];
    _bookmarkDic = loaded ? [loaded mutableCopy] : [NSMutableDictionary dictionary];
}

- (void)_save
{
    NSDictionary *data = [_bookmarkDic copy];
    [data writeToFile:IESEffectBookMarkPath() atomically:YES];
}

+ (void)markReadForPanelName:(NSString *)panelName
                   timeStamp:(NSString *)timeStamp
{
    NSString *lastTimeStamp = [self sharedInstance].bookmarkDic[[NSString stringWithFormat:@"panel-%@", panelName]];
    if (lastTimeStamp && [lastTimeStamp isEqualToString:timeStamp]) {
        return;
    }
    [self sharedInstance].bookmarkDic[[NSString stringWithFormat:@"panel-%@", panelName]] = timeStamp;
    [[self sharedInstance] _save];
}

+ (void)markReadForPanel:(IESPlatformPanelModel *)panel
{
    NSString *lastTimeStamp = [self sharedInstance].bookmarkDic[[NSString stringWithFormat:@"panel-%@", panel.text]];
    if (lastTimeStamp && [lastTimeStamp isEqualToString:panel.tagsUpdatedTimeStamp]) {
        return;
    }
    [self sharedInstance].bookmarkDic[[NSString stringWithFormat:@"panel-%@", panel.text]] = panel.tagsUpdatedTimeStamp;
    [[self sharedInstance] _save];
}

+ (void)markReadForEffect:(IESEffectModel *)effect
{
    if (effect.tagsUpdatedTimeStamp && effect.tagsUpdatedTimeStamp.length > 0 && effect.tags.count > 0) {
        NSString *lastTimeStamp = [self sharedInstance].bookmarkDic[[NSString stringWithFormat:@"effect-%@", effect.effectIdentifier]];
        if (lastTimeStamp && [lastTimeStamp isEqualToString:effect.tagsUpdatedTimeStamp]) {
            return;
        }
        [self sharedInstance].bookmarkDic[[NSString stringWithFormat:@"effect-%@", effect.effectIdentifier]] = effect.tagsUpdatedTimeStamp;
        [[self sharedInstance] _save];
    }
}

+ (void)markReadForCategory:(IESCategoryModel *)category
{
    if (category.tagsUpdatedTimeStamp &&
        category.tagsUpdatedTimeStamp.length > 0 &&
        category.tags.count > 0) {
        NSString *lastTimeStamp = [self sharedInstance].bookmarkDic[[NSString stringWithFormat:@"category-%@", category.categoryIdentifier]];
        if (lastTimeStamp && [lastTimeStamp isEqualToString:category.tagsUpdatedTimeStamp]) {
            return;
        }
        [self sharedInstance].bookmarkDic[[NSString stringWithFormat:@"category-%@", category.categoryIdentifier]] = category.tagsUpdatedTimeStamp;
        [[self sharedInstance] _save];
    }
}

+ (BOOL)isReadForPanelName:(NSString *)panelName
                 timeStamp:(NSString *)timeStamp
{
    NSString *savedTimeStamp = [self sharedInstance].bookmarkDic[[NSString stringWithFormat:@"panel-%@", panelName]];
    if (!savedTimeStamp) {
        return NO;
    }
    return [timeStamp isEqualToString:savedTimeStamp];
}

+ (BOOL)isReadForPanel:(IESPlatformPanelModel *)panel
{
    NSString *savedTimeStamp = [self sharedInstance].bookmarkDic[[NSString stringWithFormat:@"panel-%@", panel.text]];
    if (!savedTimeStamp) {
        return NO;
    }
    return [panel.tagsUpdatedTimeStamp isEqualToString:savedTimeStamp];
}

+ (BOOL)isReadForEffect:(IESEffectModel *)effect
{
    NSString *savedTimeStamp = [self sharedInstance].bookmarkDic[[NSString stringWithFormat:@"effect-%@", effect.effectIdentifier]];
    if (!savedTimeStamp) {
        return NO;
    }
    return [effect.tagsUpdatedTimeStamp isEqualToString:savedTimeStamp];
}

+ (BOOL)isReadForCategory:(IESCategoryModel *)category
{
    NSString *savedTimeStamp = [self sharedInstance].bookmarkDic[[NSString stringWithFormat:@"category-%@", category.categoryIdentifier]];
    if (!savedTimeStamp) {
        return NO;
    }
    return [category.tagsUpdatedTimeStamp isEqualToString:savedTimeStamp];
}



@end
