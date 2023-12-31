//
//  ACCClassicalMVTemplatesDataController.h
//  CameraClient
//
//  Created by long.chen on 2020/3/6.
//

#import <UIKit/UIKit.h>
#import "ACCMVTemplatesDataControllerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCClassicalMVTemplatesDataController : NSObject <ACCMVTemplatesDataControllerProtocol>

@property (nonatomic, strong) id<ACCMVTemplateModelProtocol> sameMVTemplate;

@end

NS_ASSUME_NONNULL_END
