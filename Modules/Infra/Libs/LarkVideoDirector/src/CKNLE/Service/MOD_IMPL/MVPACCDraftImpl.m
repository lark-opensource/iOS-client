//
//  MVPACCDraftImpl.m
//  MVP
//
//  Created by liyingpeng on 2020/12/30.
//

#import "MVPACCDraftImpl.h"
#import <AWEBaseLib/AWEMacros.h>
#import <CreativeKit/ACCMacros.h>

@implementation MVPACCDraftImpl

- (void)clearAllDraft {
    
}

- (void)clearAllEditBackUps {
    
}

- (void)deleteDraftWithID:(nonnull NSString *)draftID {
    
}

- (NSInteger)draftCount {
    return 1;
}

- (nonnull NSString *)draftIDKey {
    return @"";
}

- (BOOL)hasDraft {
    return NO;
}

- (BOOL)hasPublishBackUp {
    return NO;
}

- (void)markAllPublishBackupAsDraft {
    
}

- (nonnull NSArray<id<ACCDraftModelProtocol,ACCPublishRepository>> *)retrieveDrafts {
    return @[];
}

- (nonnull NSArray<id<ACCDraftModelProtocol,ACCPublishRepository>> *)retrieveEditBackUps {
    return @[];
}

- (void)retrieveNewestDraftCoverWithCompletion:(nonnull void (^)(UIImage * _Nonnull, NSError * _Nonnull))completion {
    ACCBLOCK_INVOKE(completion, nil, nil);
}

- (nonnull id<ACCDraftModelProtocol,ACCPublishRepository>)retrieveWithDraftId:(nonnull NSString *)draftId {
    return nil;
}

- (void)saveDraftWithPublishViewModel:(nonnull AWEVideoPublishViewModel *)model video:(nonnull HTSVideoData *)video backup:(BOOL)backup completion:(void (^ _Nullable)(BOOL, NSError * _Nonnull))completion {
    ACCBLOCK_INVOKE(completion, YES, nil);
}

- (void)saveDraftWithPublishViewModel:(nonnull AWEVideoPublishViewModel *)model video:(nonnull HTSVideoData *)video backup:(BOOL)backup presaveHandler:(nonnull void (^)(id<ACCDraftModelProtocol> _Nonnull))presaveHandler completion:(void (^ _Nullable)(BOOL, NSError * _Nonnull))completion {
    ACCBLOCK_INVOKE(completion, YES, nil);
}

- (void)saveInfoStickerPath:(nonnull NSString *)filePath draftID:(nonnull NSString *)draftID completion:(nonnull void (^)(NSError * _Nonnull, NSString * _Nonnull))completion {
    ACCBLOCK_INVOKE(completion, nil, filePath);
}

- (void)setCacheDirPathWithID:(nonnull NSString *)draftID {
    
}

@end
