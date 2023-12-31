//
//  ACCBarItemCustomView.h
//  CameraClient-Pods-Aweme
//
//  Created by Liu Deping on 2020/4/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCBarItemCustomView <NSObject>

@property (nonatomic, assign) BOOL needShow;
@property (nonatomic, copy) NSString *imageName;
@property (nonatomic, copy) NSString *selectedImageName;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) CGFloat alpha;

@property (nonatomic, weak) UIButton *barItemButton;
@property (nonatomic, strong) void (^itemViewDidClicked)(__kindof UIButton *sender);

@end

NS_ASSUME_NONNULL_END
