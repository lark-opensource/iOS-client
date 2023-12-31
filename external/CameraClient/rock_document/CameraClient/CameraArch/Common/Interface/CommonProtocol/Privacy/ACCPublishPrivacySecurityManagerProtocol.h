//
//  ACCPublishPrivacySecurityManagerProtocol.h
//  CameraClient-Pods-AwemeCore
//
//  Created by ZhangJunwei on 2021/11/15.
//

#ifndef ACCPublishPrivacySecurityManagerProtocol_h
#define ACCPublishPrivacySecurityManagerProtocol_h

@class AWEVideoPublishViewModel;

@protocol ACCPublishPrivacySecurityManagerProtocol <NSObject>

//校验repoAuthority
- (void)resetAuthorityModelWithPrivacyCheck:(AWEVideoPublishViewModel *)publishViewModel;

//校验repoShare.syncToToutiao字段
- (void)resetSyncModelWithPrivacyCheck:(AWEVideoPublishViewModel *)publishViewModel;

@end

#endif /* ACCPublishPrivacySecurityManagerProtocol_h */
