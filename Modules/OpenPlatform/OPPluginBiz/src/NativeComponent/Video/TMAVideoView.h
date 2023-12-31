//
//  TMAVIdeoView.h
//  OPPluginBiz
//
//  Created by muhuai on 2017/12/10.
//  Copyright © 2017年 muhuai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TTMicroApp/BDPAppPage.h>
#import <OPFoundation/BDPMediaPluginDelegate.h>

@interface TMAVideoView : UIView <BDPVideoViewDelegate>

@property (nonatomic, copy) NSString *componentID;
@property (nonatomic, strong, readonly) BDPVideoViewModel *model;
@property (nonatomic, weak) id<BDPVideoPlayerControlProtocol> delegate;

@end
