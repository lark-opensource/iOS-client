//
//  ACCCutSameProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/3/17.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/ACCMVTemplateModelProtocol.h>
#import "ACCAlbumInputData.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^ACCCutSameDismissBlock)(void);

@protocol ACCCutSameProtocol <NSObject>

- (nonnull UIViewController *)cutSameViewControllerWithTemplateModel:(id<ACCMVTemplateModelProtocol> _Nullable)templateModel
                                                           inputData:(ACCAlbumInputData * _Nullable)inputData
                                                             dismiss:(ACCCutSameDismissBlock _Nullable)dismissBlock;


@end

NS_ASSUME_NONNULL_END
