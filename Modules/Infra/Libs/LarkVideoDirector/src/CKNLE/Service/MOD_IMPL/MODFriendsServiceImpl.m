//
//  MODFriendsServiceImpl.m
//  CameraClient
//
//  Created by haoyipeng on 2021/11/2.
//  Copyright © 2021 chengfei xiao. All rights reserved.
//

#import "MODFriendsServiceImpl.h"

@implementation MODFriendsServiceImpl

- (nonnull ACCStickerShowcaseEntranceView *)createStickerShowcaseEntranceView {
    return nil;
}

- (CGFloat)enterQuickRecordInFamiliarDateDiff {
    return 0;
}

- (BOOL)isStickerShowcaseEntranceEnabled {
    return NO;
}

- (BOOL)isTextStickerShortcutEnabled {
    return NO;
}

- (NSInteger)minimumDayIntervalToAddAnimatedDateStickerAutomatically {
    return 999999;
}

- (void)recordPreviousEnterFrom:(nonnull NSString *)enterFrom {
    
}

- (BOOL)shouldSelectMusicAutomaticallyForSinglePhoto {
    return NO;
}

- (BOOL)shouldSelectMusicAutomaticallyForTextMode {
    return NO;
}

- (BOOL)shouldShowCloseButtonOnMusicButton {
    return NO;
}

- (BOOL)shouldUseMVMusicForSinglePhoto {
    return NO;
}

- (ACCSinglePhotoOptimizationABTesting)singlePhotoOptimizationABTesting {
    ACCSinglePhotoOptimizationABTesting ab = { 0 };
    return ab;
}

- (void)refreshPublishExclusionListWithAwemeID:(NSString * _Nullable)awemeID isDigest:(BOOL)isDigest completion:(nonnull ACCFriendExclusionListBlock)completion {
    
}

- (nonnull Class<ACCPrivacyPermissionDecouplingManagerProtocol>)AWEPrivacyPermissionDecouplingManagerClass {
    return nil;
}


- (nonnull id<ACCPublishPrivacySecurityManagerProtocol>)publishPrivacySecurityManager {
    return nil;
}

@end
