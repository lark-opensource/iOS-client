//
//  BDPMapViewModel.m
//  OPPluginBiz
//
//  Created by 武嘉晟 on 2019/12/20.
//

#import <UIKit/UIKit.h>
#import "BDPMapViewModel.h"
#import "BDPMapStyleModel.h"

@interface BDPMapViewModel ()
@property (nonatomic, copy, nullable) NSDictionary *sourceParams; // 解析前参数
@end

@implementation BDPMapViewModel

- (instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError **)err;
{
    self = [super initWithDictionary:dict error:err];
    if (self) {
        _sourceParams = dict;
    }
    return self;
}

- (CGRect)frame {
    return CGRectMake(self.style.left, self.style.top, self.style.width, self.style.height);
}

- (BOOL)isEmptyParam:(NSString *)paramKey {
    return self.sourceParams[paramKey] == nil;
}
@end
