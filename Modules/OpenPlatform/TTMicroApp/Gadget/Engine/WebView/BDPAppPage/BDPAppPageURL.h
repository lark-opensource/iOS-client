//
//  BDPAppPageURL.h
//  Timor
//
//  Created by 王浩宇 on 2018/12/29.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDPAppPageURL : NSObject

@property (nonatomic, copy) NSString *path;
@property (nonatomic, copy) NSString *absoluteString;
@property (nonatomic, copy) NSString *queryString;

- (instancetype _Nullable)initWithURLString:(NSString * _Nullable)url;
- (BOOL)isEqualToPage:(BDPAppPageURL * _Nullable)page;

@end

NS_ASSUME_NONNULL_END
