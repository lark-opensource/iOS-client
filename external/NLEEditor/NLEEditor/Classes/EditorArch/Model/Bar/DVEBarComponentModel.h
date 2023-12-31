//
//   DVEBarComponentModel.h
//   NLEEditor
//
//   Created  by bytedance on 2021/5/27.
//   Copyright © 2021 ByteDance Ltd. All rights reserved.
//
 
#import <Foundation/Foundation.h>
#import "DVEBarComponentProtocol.h"

@interface DVEBarComponentViewModel : NSObject <DVEBarComponentViewModelProtocol>

- (instancetype)initWithImage:(UIImage *)image url:(NSURL *)url title:(NSString *)title;

@end

@interface DVEBarComponentModel : NSObject <DVEBarComponentProtocol>

@end
