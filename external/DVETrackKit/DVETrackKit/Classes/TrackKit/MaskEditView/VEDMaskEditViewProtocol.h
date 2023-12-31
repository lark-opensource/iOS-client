//
//  VEDMaskEditViewProtocol.h
//  NLEEditor
//
//  Created by bytedance on 2021/4/11.
//

#import <Foundation/Foundation.h>
#import "VEDMaskEditView.h"

NS_ASSUME_NONNULL_BEGIN

@class VEDMaskEditView;
@protocol VEDMaskEditViewProtocol <NSObject>

- (CGPoint)fixBorderPanMoveInMaskEditView:(VEDMaskEditView *)maskDrawView toPoint:(CGPoint)point;

- (void)didBeganMaskDrawEditInMaskEditView:(VEDMaskEditView *) maskDrawView;

- (void)didMaskDrawEditingInMaskEditView:(VEDMaskEditView *) maskDrawView;

- (void)didEndedMaskDrawEditInMaskEditView:(VEDMaskEditView *) maskDrawView;


- (void)maskDrawViewWillBeginRotateWithMaskEditView:(VEDMaskEditView *) maskDrawView;

- (void)maskDrawViewDidChangeRotateWithMaskEditView:(VEDMaskEditView *) maskDrawView;

- (void)maskDrawViewDidEndRotateWithMaskEditView:(VEDMaskEditView *) maskDrawView;


@end

NS_ASSUME_NONNULL_END
