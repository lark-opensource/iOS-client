//
//  DYOpenUILoadingView.h
//  AWEUIKit
//
//  Created by 熊典 on 2018/7/11.
//

#import <UIKit/UIKit.h>
#import "DYOpenUILoadingViewProtocol.h"

@interface DYOpenUILoadingView : UIView <DYOpenUILoadingViewProtocol>

typedef NS_ENUM(NSInteger, DYOpenUILoadingViewStatus) {
    DYOpenUILoadingViewStatusStop,
    DYOpenUILoadingViewStatusAnimating,
};

@property (nonatomic, assign) CGFloat progress;

- (instancetype)initWithDisableUserInteraction;

@end
