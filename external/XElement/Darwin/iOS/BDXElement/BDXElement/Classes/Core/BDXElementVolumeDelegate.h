//
//  BDXElementVolumeDelegate.h
//  BDXElement
//
//  Created by Jiayi Xiao on 2020/7/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BDXElementVolumeDelegate <NSObject>

- (void)volumeDidChange:(CGFloat)volume;

@end

NS_ASSUME_NONNULL_END
