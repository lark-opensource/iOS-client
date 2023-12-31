//
//  BDWebImageURLFilter.m
//  BDWebImage
//
//  Created by 刘诗彬 on 2017/11/28.
//

#import "BDWebImageURLFilter.h"

@implementation BDWebImageURLFilter

- (NSString *)identifierWithURL:(NSURL *)url
{
    return url.absoluteString;
}

@end
