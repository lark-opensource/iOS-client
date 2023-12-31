//
//  BDNativeWebContainerObject.h
//  ByteWebView
//
//  Created by liuyunxuan on 2019/6/12.
//

#import <Foundation/Foundation.h>
#import "BDNativeWebContainerView.h"

@class BDNativeWebBaseComponent;

@interface BDNativeWebContainerObject : NSObject

@property(nonatomic, weak) UIScrollView *scrollView;
@property(nonatomic, strong) BDNativeWebContainerView *containerView;
@property(nonatomic, weak) UIView *nativeView;
@property(nonatomic, strong) BDNativeWebBaseComponent *component;

- (void)enableObserverFrameChanged;

- (NSMutableDictionary *)checkNativeInfo;
@end
