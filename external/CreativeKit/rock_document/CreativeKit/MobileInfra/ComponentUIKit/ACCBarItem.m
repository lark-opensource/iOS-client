//
//  ACCBarItem.m
//  CameraClient
//
//  Created by Liu Deping on 2020/3/16.
//

#import "ACCBarItem.h"

@implementation ACCBarItemResourceConfig

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.location = ACCBarItemResourceLocationRight; // defalt right location
    }
    return self;
}

@end

@implementation ACCBarItem

- (instancetype)initWithConfig:(ACCBarItemResourceConfig *)config
{
    if (self = [super init]) {
        _title = config.title;
        _imageName = config.imageName;
        _itemId = config.itemId;
        _location = config.location;
        _selectedImageName = config.selectedImageName;
    }
    return self;
}

- (instancetype)initWithImageName:(NSString *)imageName itemId:(void *)itemId
{
    if (self = [super init]) {
        _imageName = imageName;
        _itemId = itemId;
    }
    return self;
}

- (instancetype)initWithCustomView:(UIView<ACCBarItemCustomView> *)customView itemId:(void *)itemId
{
    if (self = [super init]) {
        _customView = customView;
        _itemId = itemId;
    }
    return self;
}

- (instancetype)initWithImageName:(NSString *)imageName title:(NSString *)title itemId:(void *)itemId
{
    if (self = [super init]) {
        _imageName = imageName;
        _title = title;
        _itemId = itemId;
    }
    return self;
}

- (void)addTarget:(id)target action:(SEL)action
{
    [self.customView.barItemButton addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
}

- (void)setImageName:(NSString *)imageName
{
    _imageName = imageName;
    if (self.customView) {
        self.customView.imageName = imageName;
    }
}

- (void)setSelectedImageName:(NSString *)selectedImageName
{
    _selectedImageName = selectedImageName;
    if (self.customView) {
        self.customView.selectedImageName = selectedImageName;
    }
}

- (void)setTitle:(NSString *)title
{
    _title = title;
    if (self.customView) {
        self.customView.title = title;
    }
}

@end
