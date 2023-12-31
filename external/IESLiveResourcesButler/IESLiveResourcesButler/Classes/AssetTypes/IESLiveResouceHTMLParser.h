//
//  IESLiveResouceHTMLParser.h
//  Pods
//
//  Created by Zeus on 2016/12/27.
//
//

#import <Foundation/Foundation.h>

@interface IESLiveResouceHTMLParser : NSObject

+ (instancetype)sharedInstance;

- (NSAttributedString *)parseHTMLWithString:(NSString *)string error:(NSError **)error;
//- (NSAttributedString *)parseHTMLWithData:(NSData *)data error:(NSError **)error;
//- (NSAttributedString *)parseHTMLWithContentsOfURL:(NSURL *)url error:(NSError **)error;

@end
