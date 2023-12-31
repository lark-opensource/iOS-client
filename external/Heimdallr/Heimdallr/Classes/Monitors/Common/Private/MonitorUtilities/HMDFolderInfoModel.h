//
//  HMDFolderInfoModel.h
//  Heimdallr
//
//  Created by zhangxiao on 2020/12/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HMDFolderInfoModel : NSObject

@property (nonatomic, copy) NSString *path;
@property (nonatomic, copy) NSString *reportType;
@property (nonatomic, assign) BOOL isUserCustomPath;
@property (nonatomic, assign) BOOL isFolder;
@property (nonatomic, assign) NSUInteger size;
@property (nonatomic, assign) BOOL includeFolder;
@property (nonatomic, assign) NSUInteger level;
@property (nonatomic, strong) NSMutableDictionary<NSString *, HMDFolderInfoModel *> *childs;

- (instancetype)initWithPath:(NSString *)path;

@end


@interface HMDFolderSearchDepthInfo : NSObject

@property (nonatomic, copy) NSString *path;
@property (nonatomic, strong) NSNumber *searchDepth;
@property (nonatomic, strong) NSMutableDictionary *subFolders;

@end

NS_ASSUME_NONNULL_END
