//
//  ACCRecordTextModeColorManager.h
//  CameraClient-Pods-Aweme
//
//  Created by Yangguocheng on 2020/9/20.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCTextModeColorModel : NSObject

@property (nonatomic, copy, readonly) NSArray *bgColors;
@property (nonatomic, strong, readonly) UIColor *fontColor;
@property (nonatomic, copy, readonly) NSString *colorsString;

@end

@interface ACCRecordTextModeColorManager : NSObject

@property (nonatomic, strong, readonly) ACCTextModeColorModel *currentModel;
@property (nonatomic, strong, readonly) NSArray<ACCTextModeColorModel *> *storyColors;

- (void)loadCache;

- (void)switchToNext;

@end

NS_ASSUME_NONNULL_END
