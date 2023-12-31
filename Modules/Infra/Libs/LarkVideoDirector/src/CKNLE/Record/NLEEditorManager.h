//
//  NLEEditorManager.h
//  LarkVideoDirector
//
//  Created by 李晨 on 2022/2/15.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "MVPBaseServiceContainer.h"
@class NLEInterface_OC;

NS_ASSUME_NONNULL_BEGIN

@interface NLEEditorManager : NSObject

+(UIViewController *)createDVEViewControllerWithAssets:(NSArray<AVAsset *> *)assets from:(UIViewController *)controller;

+(void)sendVideo:(MVPBaseServiceContainer *)container  sender:(UIControl *)sender;

@end

NS_ASSUME_NONNULL_END
