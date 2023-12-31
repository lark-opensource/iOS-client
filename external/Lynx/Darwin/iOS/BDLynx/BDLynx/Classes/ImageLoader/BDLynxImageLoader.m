//
//  BDLynxImageLoader.m
//  BDLynx
//
//  Created by annidy on 2020/3/29.
//

#import "BDLynxImageLoader.h"
#import <BDWebImage/BDImage.h>
#import <BDWebImage/BDWebImageManager.h>
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnullability-completeness"
#import <BDWebImage/UIImage+BDWebImage.h>
#pragma clang diagnostic pop
#import "BDLyxnChannelConfig.h"

@interface BDLynxImageLoader ()
@property NSString *cardID;
@property BDLynxBundle *bundle;
@property NSArray *extURLPrefix;
@property NSURL *extDirRoot;
@end
@implementation BDLynxImageLoader

- (instancetype)initWithBundle:(BDLynxBundle *)bundle cardID:(NSString *)cardID {
  BDLynxTemplateConfig *config = [bundle lynxCardDataWithCardID:cardID];
  return [self initWithTemplateConfig:config];
}

- (instancetype)initWithTemplateConfig:(BDLynxTemplateConfig *)config {
  self = [super init];
  if (self) {
    if (config.hasExtResource && config.extURLPrefix.count > 0) {
      _extURLPrefix = config.extURLPrefix;
      _extDirRoot = [[config.rootDirURL URLByDeletingLastPathComponent]
          URLByAppendingPathComponent:[config.groupID stringByAppendingString:@"_resource"]
                          isDirectory:YES];
    }
  }
  return self;
}

- (BOOL)canRequestURL:(NSURL *)url {
  if ([[url absoluteString] hasPrefix:@"http://"] || [[url absoluteString] hasPrefix:@"https://"] ||
      [[url absoluteString] hasPrefix:@"data:"]) {
    return YES;
  }
  return NO;
}

- (void)requestImage:(NSURL *)url
                size:(CGSize)targetSize
            complete:(void (^)(UIImage *, NSError *))complete {
  for (NSString *prefix in self.extURLPrefix) {
    if ([[url absoluteString] hasPrefix:prefix]) {
      NSString *fileName = [[url absoluteString] substringFromIndex:prefix.length];
      if ([fileName hasPrefix:@"/"]) {
        fileName = [fileName substringFromIndex:1];
      }
      NSRange queryIndex = [fileName rangeOfString:@"?"];
      if (queryIndex.location != NSNotFound) {
        fileName = [fileName substringToIndex:queryIndex.location];
      }

      NSURLComponents *components = [[NSURLComponents alloc] initWithString:url.absoluteString];
      for (NSURLQueryItem *item in components.queryItems) {
        //// gecko_format
        NSString *str = @"Z2Vja29fZm9ybWF0";
        NSString *format = [[NSString alloc] initWithData:[[NSData alloc] initWithBase64EncodedString:str options:0] encoding:NSUTF8StringEncoding];
        if ([item.name isEqual: format]) {
          fileName =
              [[fileName stringByDeletingPathExtension] stringByAppendingPathExtension:item.value];
          break;
        }
      }

      NSURL *fileURL = [_extDirRoot URLByAppendingPathComponent:fileName isDirectory:NO];
      NSString *filePath = [fileURL path];
      BDImage *image = [BDImage imageWithContentsOfFile:filePath];
      if (image) {
        if (image.isAnimateImage) {
          UIImage *mabeAnimationImage = [UIImage bd_imageWithGifData:image.animatedImageData];
          if (complete) {
            complete(mabeAnimationImage, nil);
          }
          return;
        }
        if (complete) {
          complete(image, nil);
        }
        return;
      }
    }
  }

  [[BDWebImageManager sharedManager]
      requestImage:url
           options:BDImageRequestDefaultPriority
          complete:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error,
                     BDWebImageResultFrom from) {
            BDImage *bdIamge = (BDImage *)image;
            if (bdIamge.isAnimateImage) {
              UIImage *mabeAnimationImage = [UIImage bd_imageWithGifData:bdIamge.animatedImageData];
              if (complete) {
                complete(mabeAnimationImage, error);
              }
              return;
            }
            if (complete) {
              complete(image, error);
            }
          }];
}

@end
