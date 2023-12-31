//
//  ACCMVTemplatesDataControllerProtocol.h
//  CameraClient
//
//  Created by long.chen on 2020/3/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ACCMVCategoryModel;
@protocol ACCMVTemplateModelProtocol;

@protocol ACCMVTemplatesDataControllerProtocol <NSObject>

@property (nonatomic, strong) NSMutableArray<id<ACCMVTemplateModelProtocol>> *dataSource;
@property (nonatomic, assign) BOOL hasMore;
@property (nonatomic, strong) NSNumber *cursor;
@property (nonatomic, strong) NSNumber *sortedPosition;

- (void)refreshContentDataWithCompletion:(void (^)(NSError *, NSArray<id<ACCMVTemplateModelProtocol>> *, BOOL))completion;
- (void)loadMoreContentDataWithCompletion:(void (^)(NSError *, NSArray<id<ACCMVTemplateModelProtocol>> *, BOOL))completion;


@optional
@property (nonatomic, strong) ACCMVCategoryModel *categoryModel;

@end

NS_ASSUME_NONNULL_END
