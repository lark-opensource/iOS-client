//
//  ADFeelGoodOpenModel+Private.m
//  ADFeelGood
//
//  Created by cuikeyi on 2021/1/11.
//

#import "ADFeelGoodOpenModel+Private.h"
#import <objc/runtime.h>
#import "ADFeelGoodInfo+Private.h"

@implementation ADFeelGoodOpenModel (Private)
@dynamic infoModel;

- (void)setInfoModel:(ADFeelGoodInfo *)infoModel
{
    objc_setAssociatedObject(self, @selector(infoModel), infoModel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (ADFeelGoodInfo *)infoModel
{
    return objc_getAssociatedObject(self, _cmd);
}

@end
