//
//  ACCTextInputServiceProtocol.h
//  CameraClient
//
//  Created by HuangHongsen on 2020/8/3.
//

#ifndef ACCTextInputServiceProtocol_h
#define ACCTextInputServiceProtocol_h

#import <CreationKitArch/ACCUserModelProtocol.h>
#import <CreationKitArch/ACCChallengeModelProtocol.h>

typedef void (^ACCTextInputSearchUserCompletion)(NSArray<id<ACCUserModelProtocol>> *, NSString *);
@class AWEVideoPublishViewModel;

@protocol ACCTextInputUserServiceProtocol;

@protocol ACCTextInputServiceProtocol <NSObject>

- (void)configWithPublishViewModel:(AWEVideoPublishViewModel *)publishViewModel;

- (void)fetchHashtagsWithKeyword:(NSString *)keyword completion:(void (^)(NSArray<id<ACCChallengeModelProtocol>> *, NSError *))completion;

- (NSArray<NSString *> *)savedPrivateHashtags;
- (NSArray<NSString *> *)savedHashtags;

#pragma mark - InputTextCutManager
- (void)commitTracker:(NSString *)text;

- (void)beginEditing:(NSString *)text enterFrom:(NSString *)from;

- (void)textDidChange:(NSString *)text;

// User cannot use singleton, otherwise there will be strings between data, so the caller will create a new one and hold it
- (id<ACCTextInputUserServiceProtocol>)creatUserServiceInstance;

@end

@protocol ACCTextInputUserServiceProtocol <NSObject>

@property (nonatomic, copy) ACCTextInputSearchUserCompletion searchUserCompletion;

- (void)fetchUsersWithCompletion:(void (^)(NSError *))completion;

- (void)searchUsersWithKeyword:(NSString *)keyword;

- (void)loadMoreUser;

- (BOOL)hasMoreUsers;

@end

#endif /* ACCTextInputServiceProtocol_h */
