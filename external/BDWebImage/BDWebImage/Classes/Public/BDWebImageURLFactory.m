//
//  BDWebImageURLFactory.m
//  BDWebImage
//
//  Created by 陈奕 on 2020/12/25.
//

#import "BDWebImageURLFactory.h"

@implementation BDWebImageURLFactory

- (BDImageRequestOptions)setupRequestOptions:(BDImageRequestOptions)options URL:(NSURL *)url
{
    return options;
}

- (BDWebImageRequestConfig *)setupRequestConfig:(BDWebImageRequestConfig *)config URL:(NSURL *)url
{
    return config;
}

- (BDWebImageRequestBlocks *)setupRequestBlocks:(BDWebImageRequestBlocks *)blocks URL:(NSURL *)url
{
    return blocks;
}

@end
