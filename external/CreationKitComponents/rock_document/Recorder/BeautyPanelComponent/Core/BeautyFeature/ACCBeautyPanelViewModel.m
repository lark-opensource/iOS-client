//
//  ACCBeautyPanelViewModel.m
//  CameraClient
//
//  Created by chengfei xiao on 2020/1/17.
//

#import "ACCBeautyPanelViewModel.h"
#import <CreativeKit/ACCMacros.h>

@interface ACCBeautyPanelViewModel ()

@property (nonatomic,   copy, readwrite) NSArray<AWEComposerBeautyEffectCategoryWrapper *> *filteredCategories;
@property (nonatomic, strong, readwrite) AWEComposerBeautyEffectCategoryWrapper *currentCategory;
@property (nonatomic,   copy, readwrite) NSString *businessName;

@end


@implementation ACCBeautyPanelViewModel

- (void)dealloc
{
    ACCLog(@"%@ dealloc",NSStringFromSelector(_cmd));
}

- (instancetype)initWithBusinessName:(NSString *)businessName
{
    self = [super init];
    if (self) {
        _businessName = businessName;
    }
    return self;
}

@end
