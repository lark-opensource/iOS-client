//
//  BDXLynxAudioUI.h
//  BDXElement-Pods-Aweme
//
//  Created by DylanYang on 2020/9/25.
//

#import <Lynx/LynxUI.h>
#import "BDXAudioView.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXLynxAudioUI : LynxUI<BDXAudioView *>
@property (nonatomic, assign) BOOL autoPlay;
@end

NS_ASSUME_NONNULL_END
