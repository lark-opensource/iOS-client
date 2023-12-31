//
//  IESLiveResouceBundle+Image.h
//  Pods
//
//  Created by Zeus on 2016/12/21.
//
//

#import "IESLiveResouceBundle.h"

@interface IESLiveResouceBundle (Image)

- (UIImage * (^)(NSString *key))image;

@end
