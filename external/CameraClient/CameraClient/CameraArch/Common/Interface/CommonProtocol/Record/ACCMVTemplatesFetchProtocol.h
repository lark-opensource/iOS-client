//
//  ACCMVTemplatesFetchProtocol.h
//  CameraClient
//
//  Created by long.chen on 2020/3/12.
//

#import <Foundation/Foundation.h>

#import <CreativeKit/ACCServiceLocator.h>
#import "ACCMVCategoryModel.h"
#import <CreationKitArch/ACCMVTemplateModelProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCMVTemplatesFetchProtocol <NSObject>

@property (nonatomic, assign, readonly) NSString *classicMvPannel;
@property (nonatomic, assign, readonly) NSUInteger fetchCountPerRequest;

- (void)fetchMVTemplatesCategories:(void(^)(NSError * _Nullable error,
                                            NSArray<ACCMVCategoryModel *> * _Nullable categories))completion;

- (void)refreshMergedMVTemplatesWithCategory:(ACCMVCategoryModel *)category
                                  completion:(void(^)(NSError * _Nullable error,
                                                      NSArray<id<ACCMVTemplateModelProtocol>> * _Nullable templates,
                                                      BOOL hasMore,
                                                      NSNumber *cursor,
                                                      NSNumber *sortedPosition))completion;

- (void)loadmoreMergedMVTemplatesWithCategory:(ACCMVCategoryModel *)category
                                       cursor:(NSNumber *)cursor
                               sortedPosition:(NSNumber *)sortedPosition
                                   completion:(void(^)(NSError * _Nullable error,
                                                       NSArray<id<ACCMVTemplateModelProtocol>> * _Nullable templates,
                                                       BOOL hasMore,
                                                       NSNumber *cursor,
                                                       NSNumber *sortedPosition))completion;

- (void)refreshMergedFavoriteMVTemplatesCompletion:(void(^)(NSError * _Nullable error,
                                                            NSArray<id<ACCMVTemplateModelProtocol>> * _Nullable templates,
                                                            BOOL hasMore,
                                                            NSNumber *cursor,
                                                            NSNumber *sortedPosition))completion;

- (void)loadmoreMergedFavoriteMVTemplatesWithCursor:(NSNumber *)cursor
                                     sortedPosition:(NSNumber *)sortedPosition
                                         completion:(void(^)(NSError * _Nullable error,
                                                             NSArray<id<ACCMVTemplateModelProtocol>> * _Nullable templates,
                                                             BOOL hasMore,
                                                             NSNumber *cursor,
                                                             NSNumber *sortedPosition))completion;

- (void)getClassicalMVFavoriteStateWithTemplateIDs:(NSArray<NSNumber *> *)templateIDs
                                          simplify:(BOOL)simplify
                                        completion:(void(^)(NSDictionary<NSNumber *, id<ACCMVTemplateModelProtocol>> * _Nullable templateModelDict, NSError * _Nullable error))completion;

- (void)favoriteMVTemplateWithID:(NSUInteger)templateID
                    templateType:(ACCMVTemplateType)templateType
                      completion:(void(^)(NSError * _Nullable))completion;

- (void)unFavoriteMVTemplateWithID:(NSUInteger)templateID
                      templateType:(ACCMVTemplateType)templateType
                        completion:(void(^)(NSError * _Nullable))completion;

@end

FOUNDATION_STATIC_INLINE id<ACCMVTemplatesFetchProtocol> ACCMVTemplatesFetch() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCMVTemplatesFetchProtocol)];
}

NS_ASSUME_NONNULL_END
