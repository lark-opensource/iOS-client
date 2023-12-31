//
//  LVVEBundleDataSourceHelper.h
//  VideoTemplate
//
//  Created by Lemonior on 2020/4/22.
//

#import <Foundation/Foundation.h>

@class LVVEBundleDataSourceProvider;

@interface LVVEBundleDataSourceHelper : NSObject

@property (nonatomic, strong) LVVEBundleDataSourceProvider *bundleDataSource;

- (instancetype)initWithRootPath:(NSString *)rootPath;
- (NSString *)chromaPathWithBundleDataSource:(LVVEBundleDataSourceProvider *)bundleDataSource
                                 payloadPath:(NSString *)payloadPath;

@end
