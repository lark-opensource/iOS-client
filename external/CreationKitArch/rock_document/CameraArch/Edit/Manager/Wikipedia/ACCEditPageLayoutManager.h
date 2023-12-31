//
//  ACCEditPageLayoutManager.h
//  CameraClient
//
//  Created by resober on 2020/3/2.
//

#import <UIKit/UIKit.h>
#import "ACCEditPageStrokeConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCEditPageLayoutManager : NSLayoutManager

@property (nonatomic, strong, nullable) ACCEditPageStrokeConfig *strokeConfig;

@end

NS_ASSUME_NONNULL_END
