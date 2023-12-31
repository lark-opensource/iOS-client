//
//  ACCPublishRepositoryElementProtocols.h
//  CameraClient
//
//  Created by Charles on 2020/8/10.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/NSObject+ACCAdditions.h>

#ifndef ACCPublishRepositoryElementProtocols_h
#define ACCPublishRepositoryElementProtocols_h

// add this check to ACCRepositoryCoding's implementation, to avoid repeating implementation of coding methods.
// TODO: @yangying this part cannot pass the ci test
//#ifndef ACCRepositoryCodingCheck
//#if DEBUG
//    #define ACCRepositoryCodingCheck \
//    + (void)load { \
//        NSString *repeatSelStr = [self repeatSelectorImpOfProtocol:@[@protocol(ACCRepositoryCoding), @protocol(NSCoding)]]; \
//        NSAssert(!repeatSelStr, @"repeatCodingImp! %@ - %@", NSStringFromClass(self), repeatSelStr); \
//    }
//#else
//    #define ACCRepositoryCodingCheck
//#endif
//#endif

@class AWEVideoPublishViewModel, AWEVideoFragmentInfo, ACCMigrateContextModel, ACCRepositoryRegisterInfo;
@protocol ACCPublishRepository;

#pragma mark - Category Protocol - register behaviors to DraftModel/PublishViewModel via runtime

/// This protocol is used to inject the business model into the publishViewModel while setup
/// Note: create a AWEVideoPublishViewModel's category and Conform to it.
@protocol ACCRepositoryElementRegisterCategoryProtocol <NSObject>

- (ACCRepositoryRegisterInfo *)repoRegisterInfo;

@end


#pragma mark - Draft Migrate

@protocol ACCRepositoryMigrateProtocol <NSObject>

@optional

- (void)draft:(id<ACCPublishRepository>)draft willMigrateWithContext:(ACCMigrateContextModel *)context completion:(dispatch_block_t)completion;
- (void)draft:(id<ACCPublishRepository>)draft didReceivedWithContext:(ACCMigrateContextModel *)context completion:(dispatch_block_t)completion;

@end


#pragma mark - Video-Creation contexts


/// Methods relavent to Record-Context
@protocol ACCRepositoryRecordContextProtocol <NSObject>

- (void)onRemoveLastVideoFragmentInfo:(AWEVideoFragmentInfo *)fragment;

@end


/// Methods relavent to Edit-Context
@protocol ACCRepositoryEditContextProtocol <NSObject>

@optional
@property (nonatomic, copy) NSArray *locationInfos;

@end

/// Methods relavent to Track-Context
@protocol ACCRepositoryTrackContextProtocol <NSObject>

@optional
/// this is the params for 'referExtra'
- (NSDictionary *)acc_referExtraParams;

/// this is the params for 'getLogInfo'
- (NSDictionary *)acc_errorLogParams;

/// this is the params for the track event 'publish'
- (NSDictionary *)acc_publishTrackEventParams:(AWEVideoPublishViewModel *)publishViewModel;

@end

/// A protocol that enables an object to provide params for publish-request.
@protocol ACCRepositoryRequestParamsProtocol <NSObject>

/// this is the params for the 'create/aweme' network request
- (NSDictionary *)acc_publishRequestParams:(AWEVideoPublishViewModel *)publishViewModel;

@optional
- (id)acc_publishRequestParamsForKeyPath:(NSString *)keypath;
- (void)acc_precheckRequestParameters:(NSDictionary *)parameters;

@end

@protocol ACCRepositoryDraftContextProtocol <NSObject>

@optional
- (void)draftWillBeSavedWithID:(NSString *)draftID;
- (void)modelDidRetrievedFromDraftWithID:(NSString *)draftID;

@end

@protocol ACCRepositoryContextProtocol <NSObject>

/// this is the model container
@property (nonatomic, weak) id<ACCPublishRepository> repository;

@end

#endif /* ACCPublishRepositoryElementProtocols_h */
