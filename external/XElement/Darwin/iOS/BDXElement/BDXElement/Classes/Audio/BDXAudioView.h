//
//  BDXAudioView.h
//  BDXElement-Pods-Aweme
//
//  Created by DylanYang on 2020/9/25.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class BDXAudioView;

@protocol BDXAudioViewLifeCycleDelegate<NSObject>
-(void)audioViewWillAppear:(BDXAudioView *)view;
-(void)audioViewDidDisappear:(BDXAudioView *)view;
@end

@interface BDXAudioView : UIView
@property(nonatomic, weak) id<BDXAudioViewLifeCycleDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
