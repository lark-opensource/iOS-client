//
//  TTAdSplashDownloader.h
//  Article
//
//  Created by Zhang Leonardo on 12-11-19.
//
//

#import <Foundation/Foundation.h>

@class TTAdSplashModel;
@interface TTAdSplashDownloader : NSObject

- (void)fetchADResourceWithModels:(NSArray *)models;

@end

