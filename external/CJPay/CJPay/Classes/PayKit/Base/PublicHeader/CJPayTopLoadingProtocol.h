//
//  CJPayTopLoadingProtocol.h
//  Pods
//
//  Created by 王新华 on 3/4/20.
//

#ifndef CJPayTopLoadingProtocol_h
#define CJPayTopLoadingProtocol_h

@protocol CJPayTopLoadingProtocol <NSObject>

// 展示Loading
- (void)showWindowLoadingWithTitle:(NSString *)title;
// 隐藏loading
- (void)dismissWindowLoading;

@end

#endif /* CJPayTopLoadingProtocol_h */
