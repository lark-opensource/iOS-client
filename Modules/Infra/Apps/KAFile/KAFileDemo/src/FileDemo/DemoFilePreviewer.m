//
//  DemoFilePreviewer.m
//  KAFileDemo
//
//  Created by Supeng on 2021/12/2.
//

#import "DemoFilePreviewer.h"
#import "PreviewViewController.h"
@import UIKit;

@implementation DemoFilePreviewer


-(BOOL)canPreviewFileName: (NSString *)fileName {
    return [[[fileName pathExtension] lowercaseString] isEqualToString:@"test"];
}

-(UIViewController*)previewFilePath:(NSString *)filePath {
    return [[PreviewViewController alloc] initWithFilePath: filePath];
}

@end
