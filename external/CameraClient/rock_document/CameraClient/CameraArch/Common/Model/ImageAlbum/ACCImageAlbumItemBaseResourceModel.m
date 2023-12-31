//
//  ACCImageAlbumItemBaseResourceModel.m
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2021/1/4.
//

#import "ACCImageAlbumItemBaseResourceModel.h"
#import <CreationKitArch/AWEDraftUtils.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/ACCLogHelper.h>

NSArray *ACCImageAlbumDeepCopyObjectArray(NSArray <NSObject<NSCopying> *> *targetArray)
{
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:targetArray.count];
    [[targetArray copy] enumerateObjectsUsingBlock:^(NSObject<NSCopying> *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [ret addObject:[obj copy]];
    }];
    return [ret copy];
}

NSDictionary *ACCImageAlbumDeepCopyObjectDictionary(NSDictionary <id, NSObject<NSCopying> *> *targetDictionary)
{
    NSMutableDictionary *ret = [NSMutableDictionary dictionaryWithCapacity:targetDictionary.count];
    [[targetDictionary copy] enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, NSObject<NSCopying> *_Nonnull obj, BOOL * _Nonnull stop) {
        ret[key] = [obj copy];
    }];
    return [ret copy];
}

@implementation ACCImageAlbumItemBaseItemModel

- (instancetype)initWithTaskId:(NSString *)taskId
{
    if (self = [super init]) {
        _taskId = [taskId copy];
    }
    return self;
}
// @override
- (void)updateRecoveredEffectIfNeedWithIdentifier:(NSString *)effectIdentifier filePath:(NSString *)filePath
{
    
}

- (id)copyWithZone:(NSZone *)zone
{
    id copy =  [super copyWithZone:zone];
    [copy deepCopyValuesIfNeedFromTarget:self];
    return copy;
}

// @override
- (void)deepCopyValuesIfNeedFromTarget:(id)target
{
    
}

- (void)amazingMigrateResourceToNewDraftWithTaskId:(NSString *)taskId
{
    _taskId = [taskId copy];
}

@end


@interface ACCImageAlbumItemBaseResourceModel ()

@property (nonatomic, copy, readonly) NSString *filePath;

@end

@implementation ACCImageAlbumItemBaseResourceModel

- (NSString *)p_getProcessedFilePath
{
    return _filePath;
}

- (void)p_setProcessedFilePath:(NSString *)filePath
{
    _filePath = [filePath copy];
}

+ (NSString *)draftFolderPathWithTaskId:(NSString *)taskId
{
    return [AWEDraftUtils generateDraftFolderFromTaskId:taskId];
}

+ (NSString *)documentPath
{
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
}

- (void)setAbsoluteFilePath:(NSString *)filePath
{
    NSAssert(NO, @"sub class should override");
}

- (NSString *)getAbsoluteFilePath
{
    NSAssert(NO, @"sub class should override");
    return @"";
}

#pragma mark - private

@end


@implementation ACCImageAlbumItemDraftResourceRestorableModel


- (void)setAbsoluteFilePath:(NSString *)filePath
{
    NSString *draftPath = [ACCImageAlbumItemBaseResourceModel draftFolderPathWithTaskId:self.taskId];
    NSString *processedFilePath = [filePath stringByReplacingOccurrencesOfString:draftPath withString:@""];
    [self p_setProcessedFilePath:processedFilePath];
}

- (NSString *)getAbsoluteFilePath
{
    NSString *processedFilePath = [self p_getProcessedFilePath];
    if (ACC_isEmptyString(processedFilePath)) {
        return @"";
    }
    NSString *draftPath = [ACCImageAlbumItemBaseResourceModel draftFolderPathWithTaskId:self.taskId];
    return [draftPath stringByAppendingPathComponent:processedFilePath];
}

- (void)amazingMigrateResourceToNewDraftWithTaskId:(NSString *)taskId
{
    // old file path 需要在reload taskid之前获取
    NSString *oldFilePath = [self getAbsoluteFilePath];
    [super amazingMigrateResourceToNewDraftWithTaskId:taskId];
    if (ACC_isEmptyString(oldFilePath) || ![[NSFileManager defaultManager] fileExistsAtPath:oldFilePath]) {
        return;
    }
    [AWEDraftUtils generateDraftFolderFromTaskId:self.taskId];
    NSString *newFilePath = [self getAbsoluteFilePath];
    NSError *error = nil;
    // 遵循草稿只加不删的原则，copy 而非 move
    BOOL copyItemSucceed = [[NSFileManager defaultManager] copyItemAtPath:oldFilePath toPath:newFilePath error:&error];
    if (error || !copyItemSucceed) {
        AWELogToolError(AWELogToolTagEdit, @"ImageAlbumItem:migrate resource faild, error:%@, taskId:%@,  oldFilePath%@, newFilePath:%@", error, taskId, oldFilePath, newFilePath);
    }
}

@end


@implementation ACCImageAlbumItemVEResourceRestorableModel

- (void)setAbsoluteFilePath:(NSString *)filePath
{
    NSString *documentPath = [ACCImageAlbumItemBaseResourceModel documentPath];
    NSString *processedFilePath = [filePath stringByReplacingOccurrencesOfString:documentPath withString:@""];
    [self p_setProcessedFilePath:processedFilePath];
}

- (NSString *)getAbsoluteFilePath
{
    NSString *processedFilePath = [self p_getProcessedFilePath];
    if (ACC_isEmptyString(processedFilePath)) {
        return @"";
    }
    NSString *documentPath = [ACCImageAlbumItemBaseResourceModel documentPath];
    return [documentPath stringByAppendingPathComponent:processedFilePath];
}

- (void)updateRecoveredEffectIfNeedWithIdentifier:(NSString *)effectIdentifier filePath:(NSString *)filePath
{
    if ([effectIdentifier isEqualToString:self.effectIdentifier]) {
        [self setAbsoluteFilePath:filePath];
    }
}


@end
