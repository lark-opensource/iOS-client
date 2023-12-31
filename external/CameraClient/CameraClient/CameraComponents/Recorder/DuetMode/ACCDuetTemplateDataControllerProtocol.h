//
//  ACCDuetTemplateDataControllerProtocol.h
//  CameraClient
//
//  Created by bytedance on 2021/10/20.
//
#import <CreationKitArch/ACCAwemeModelProtocol.h>
#import <CameraClient/ACCAwemeModelProtocolD.h>
#import <Foundation/Foundation.h>

#ifndef ACCDuetTemplateDataControllerProtocol_h
#define ACCDuetTemplateDataControllerProtocol_h

typedef NS_ENUM(NSInteger, ACCDuetSingSceneType) {
    AWEDuetSingSceneTypeSingTab = 1, //
    AWEDuetSingSceneTypeDuetTabOriginal = 2, //
    AWEDuetSingSceneTypeDuetTabDuet = 3,
};
typedef NS_ENUM(NSUInteger, ACCAweFeedColumnType) {
    ACCAweFeedColumnTypeOne = 0,
    ACCAweFeedColumnTypeTwo = 1,
    ACCAweFeedColumnTypeThree = 2,
    ACCAweFeedColumnTypeFour = 3
};
typedef void(^ACCAweListDataBlock)(NSArray *list, NSError *error);

@protocol ACCDuetTemplateDataControllerProtocol <NSObject>

@property (nonatomic, strong, nonnull) NSMutableArray<id<ACCAwemeModelProtocolD>> *dataSource;
@property (nonatomic, strong, nonnull) NSMutableArray *filteredDataSource;
@property (nonatomic, assign) ACCDuetSingSceneType scene;
@property (nonatomic, assign) BOOL loadmoreHasMore;
@property (nonatomic, strong, nonnull) NSNumber *cursor;
@property (nonatomic, assign) BOOL isRequestOnAir;
- (void)refreshContentDataWithCompletion:(void (^)(NSError *_Nonnull, NSArray<id<ACCAwemeModelProtocolD>> *_Nonnull, BOOL))completion;
- (void)loadMoreContentDataWithCompletion:(void (^)(NSError *_Nonnull, NSArray<id<ACCAwemeModelProtocolD>> *_Nonnull, BOOL))completion;
- (void)initFetchWithCompletion:(ACCAweListDataBlock)completion;
- (void)refreshWithCompletion:(ACCAweListDataBlock)completion;
- (void)loadMoreWithCompletion:(ACCAweListDataBlock)completion;

@end
#endif /* ACCDuetTemplateDataControllerProtocol_h */
