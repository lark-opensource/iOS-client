//
//  ACCMomentDebugViewController.h
//  Pods
//
//  Created by Pinka on 2020/6/17.
//

#if INHOUSE_TARGET

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^ACCMomentDebugViewControllerPHAssetSelection)(PHAsset *asset);
typedef void(^ACCMomentDebugViewControllerPHAssetCallback)(ACCMomentDebugViewControllerPHAssetSelection selection);

@interface ACCMomentDebugViewController : UIViewController

@property (nonatomic, copy) ACCMomentDebugViewControllerPHAssetCallback imageCallback;

@property (nonatomic, copy) ACCMomentDebugViewControllerPHAssetCallback videoCallback;

@end

NS_ASSUME_NONNULL_END

#endif
