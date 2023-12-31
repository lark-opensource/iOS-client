//
//  BDPModel+H5Gadget.h
//  EEMicroAppSDK
//
//  Created by tujinqiu on 2019/12/25.
//

#import "BDPModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDPModel (H5Gadget)

@property (nonatomic, strong) NSString *h5WebURL;
@property (nonatomic, assign) long long h5WebVersionCode;
@property (nonatomic, strong) NSString *h5md5;

- (BOOL)isH5NewerThanAppModel:(BDPModel *)model;
/// 判断代码包文件路径是否属于H5小程序
+ (BOOL)isH5FolderName:(NSString *)folderName;

@end

NS_ASSUME_NONNULL_END
