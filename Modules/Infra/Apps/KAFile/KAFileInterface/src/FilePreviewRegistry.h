//
//  FilePreviewRegistry.h
//  KAFileInterface
//
//  Created by Supeng on 2021/12/2.
//

#import <Foundation/Foundation.h>
@import UIKit;


@protocol FilePreviewer <NSObject>

@required

/// 是否可以预览 fileName 文件
/// @param fileName 文件名字，包括后缀 e.g. 123.test
-(bool)canPreviewFileName: (nonnull NSString*) fileName;
/// 预览filePath路径下的文件
/// @param filePath 相对于沙盒根目录的文件路径，包含文件名字
-(nullable UIViewController*)previewFilePath: (nonnull NSString*)filePath;
@end
