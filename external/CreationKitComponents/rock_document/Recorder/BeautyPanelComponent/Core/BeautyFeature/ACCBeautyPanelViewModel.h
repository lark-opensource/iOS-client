//
//  ACCBeautyPanelViewModel.h
//  CameraClient
//
//  Created by chengfei xiao on 2020/1/17.
//

#import <Foundation/Foundation.h>
#import <CreationKitBeauty/AWEComposerBeautyEffectCategoryWrapper.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCBeautyPanelViewModel : NSObject

@property (nonatomic,   copy, readonly) NSString *businessName;

- (instancetype)initWithBusinessName:(NSString *)businessName;

@end

NS_ASSUME_NONNULL_END
