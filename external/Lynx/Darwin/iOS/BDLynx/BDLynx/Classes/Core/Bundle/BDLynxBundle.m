//
//  BDLynxBundle.m
//  BDLynx
//
//  Created by bill on 2020/2/4.
//

#import "BDLynxBundle.h"
#import <CoreText/CoreText.h>
#import "BDLUtils.h"
#import "BDLyxnChannelConfig.h"

@interface BDLynxBundle ()

@property(nonatomic, strong) NSURL *singleFilePath;

@property(nonatomic, strong) NSURL *rootDirURL;

@property(nonatomic, strong) BDLyxnChannelConfig *channelConfig;

@end

@implementation BDLynxBundle

/** config格式
{
    "version": "75501",
    "android":{
        "card_list":[
            {
                "card_id": "124",
                "card_template_path": "hot_board/hot_board.js",
                "card_version": "756",
                "desc": "xxx",
                "ext": {
                    "blist": [],
                    "wlist": [],
                    ......
                }
            },
            {
                "card_id": "456",
                "card_template_path":"header_news/header_news.js",
                "card_version": "777",
                "desc": "xxx",
                "ext": {
                    "blist": [],
                    "wlist": [],
                    ......
                },
                "desc":"落地页站点",
                "fetch_res":true
                ,"res_http_prefix":["]}
            }，
            ......
        ]
    },
    "ios":{
        "card_list":{
            // 同android
        }
    }
}
*/

- (instancetype)initWithRootDir:(NSURL *)rootDirURL groupID:(NSString *)groupID {
  if (!(rootDirURL != nil && [rootDirURL isFileURL])) {
    BDLERROR(@"Invalid root path");
    return nil;
  }

  if (!groupID) {
    BDLERROR(@"Invalid GroupID");
    return nil;
  }

  NSURL *infoFileURL = [rootDirURL URLByAppendingPathComponent:@"config.json"];
  if (![[NSFileManager defaultManager] fileExistsAtPath:infoFileURL.path]) {
    BDLERROR(@"not found config file");
    return nil;
  }

  NSData *data = [NSData dataWithContentsOfURL:infoFileURL];
  NSAssert(data != nil, @"invalid file data");

  NSError *error;
  NSDictionary *infoDict;
  if (data != nil) {
    infoDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (![infoDict isKindOfClass:[NSDictionary class]]) {
      BDLERROR(@"Invalid config file");
      return nil;
    }
  }

  if (self = [super init]) {
    _rootDirURL = rootDirURL;
    _channelConfig = [[BDLyxnChannelConfig alloc] initWithDictionary:infoDict
                                                             groupID:groupID
                                                             rootDir:rootDirURL];
    _groupID = groupID;
    _version = _channelConfig.version;
  }
  return self;
}

- (instancetype)initWithSingleBundleFileURL:(NSURL *)fileURL groupID:(NSString *)groupID {
  if (!(fileURL != nil && [fileURL isFileURL])) {
    NSAssert(NO, @"invalid file url");
    return nil;
  }

  if (self = [super init]) {
    _groupID = groupID;

    if ([[NSFileManager defaultManager] fileExistsAtPath:fileURL.path]) {
      _singleFilePath = fileURL;
      _isSingleFile = YES;
    }
  }

  return self;
}

- (instancetype)initWithBundlePath:(NSString *)path
                             group:(NSString *)groupID
                             error:(NSString **)reason {
  NSString *infoFile = [path stringByAppendingPathComponent:@"config.json"];
  if (![[NSFileManager defaultManager] fileExistsAtPath:infoFile]) {
    if (*reason) {
      *reason = @"缺少config文件";
    }
    return nil;
  }

  NSData *data = [NSData dataWithContentsOfFile:infoFile];
  NSAssert(data != nil, @"invalid file data");

  NSError *error;
  NSDictionary *infoDict;
  if (data != nil) {
    infoDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (![infoDict isKindOfClass:[NSDictionary class]]) {
      if (*reason) {
        *reason = @"无效config文件";
      }
      return nil;
    }
  }

  if (self = [super init]) {
    _rootDirURL = [NSURL fileURLWithPath:path];
    _channelConfig = [[BDLyxnChannelConfig alloc] initWithDictionary:infoDict
                                                             groupID:groupID
                                                             rootDir:_rootDirURL];
    _groupID = groupID;
    _version = _channelConfig.version;
  }
  return self;
}

- (NSData *)lynxDataWithCardID:(NSString *)cardID {
  if (self.isSingleFile && [self.singleFilePath isFileURL]) {
    return [NSData dataWithContentsOfURL:self.singleFilePath];
  }
  if (cardID && self.channelConfig.iOSConfig.templateList.count) {
    BDLynxTemplateConfig *templateConfig =
        [self.channelConfig.iOSConfig templateConfigForCardID:cardID];

    if (!templateConfig) {
      BDLERROR([NSString stringWithFormat:@"cardID error,cardID:%@", cardID]);
      return nil;
    }
    NSURL *realURL = [self.rootDirURL URLByAppendingPathComponent:templateConfig.cardPath];

    if ([[NSFileManager defaultManager] fileExistsAtPath:realURL.path]) {
      return [NSData dataWithContentsOfURL:realURL];
    } else {
      BDLERROR([NSString stringWithFormat:@"wrong url, filePath:%@", realURL]);
    }
  }

  BDLERROR(
      [NSString stringWithFormat:@"not found path, bundle:%@,rootDir:%@", cardID, self.rootDirURL]);
  return nil;
}

- (NSDictionary *)lynxExtraDataWithCardID:(NSString *)cardID {
  if (cardID && self.channelConfig.iOSConfig.templateList.count) {
    BDLynxTemplateConfig *templateConfig =
        [self.channelConfig.iOSConfig templateConfigForCardID:cardID];
    ;
    return templateConfig.extra;
  }
  return nil;
}

- (BOOL)updateDataWithRootDir:(NSURL *)fileURL {
  if (!(fileURL != nil && [fileURL isFileURL])) {
    BDLERROR(@"invalid root path");
    return NO;
  }

  NSURL *infoFileURL = [fileURL URLByAppendingPathComponent:@"config.json"];
  if (![[NSFileManager defaultManager] fileExistsAtPath:infoFileURL.path]) {
    BDLERROR(@"not found config file");
    return NO;
  }

  NSData *data = [NSData dataWithContentsOfURL:infoFileURL];
  NSAssert(data != nil, @"invalid file data");

  NSError *error;
  NSDictionary *infoDict;
  if (data != nil) {
    infoDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (![infoDict isKindOfClass:[NSDictionary class]]) {
      BDLERROR(@"invalid config file");
      return NO;
    }
  }

  [self.channelConfig updateWithDictionary:infoDict];
  self.channelConfig.rootDirURL = fileURL;
  _rootDirURL = fileURL;
  _isSingleFile = NO;
  _version = self.channelConfig.version;
  return YES;
}

- (BOOL)updateDataWithSingleBundleFile:(NSURL *)fileUrl {
  if ([[NSFileManager defaultManager] fileExistsAtPath:fileUrl.path]) {
    _singleFilePath = fileUrl;
    _isSingleFile = YES;
    _rootDirURL = nil;
    return YES;
  }
  return NO;
}

- (BDLynxTemplateConfig *)lynxCardDataWithCardID:(NSString *)cardID {
  BDLynxTemplateConfig *templateConfig;
  if (cardID.length) {
    templateConfig = [self.channelConfig.iOSConfig templateConfigForCardID:cardID];
  } else if (self.channelConfig.iOSConfig.templateList.count) {
    templateConfig = self.channelConfig.iOSConfig.templateList[0];
  }
  return templateConfig;
}
@end
