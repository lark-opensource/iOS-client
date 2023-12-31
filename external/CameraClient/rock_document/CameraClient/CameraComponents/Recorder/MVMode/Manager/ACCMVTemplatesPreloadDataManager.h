//
//  ACCMVTemplatesPreloadDataManager.h
//  CameraClient
//
//  Created by long.chen on 2020/3/13.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

@class ACCMVCategoryModel;
@protocol ACCMVTemplateModelProtocol;

@interface ACCMVTemplatesPreloadDataManager : NSObject

@property (nonatomic, copy) NSArray<ACCMVCategoryModel *> *mvTemplatesCategories;
@property (nonatomic, copy) NSArray<id<ACCMVTemplateModelProtocol>> *firstPageHotMVTemplates;
@property (nonatomic, assign) BOOL hasMore;
@property (nonatomic, strong) NSNumber *cursor;
@property (nonatomic, strong) NSNumber *sortedPosition;

@property (nonatomic, copy) NSDictionary *trackInfo;

+ (instancetype)sharedInstance;

- (void)preloadMVTemplatesCategoriesAndHotMVTemplatesWithCompletion:(void (^)(BOOL success, ACCMVCategoryModel * _Nullable landingCategory))completion;

@end

NS_ASSUME_NONNULL_END
