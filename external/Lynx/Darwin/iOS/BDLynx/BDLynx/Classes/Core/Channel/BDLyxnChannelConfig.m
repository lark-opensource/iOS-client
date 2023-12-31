//
//  BDLyxnChannelConfig.m
//  BDLynx
//
//  Created by  wanghanfeng on 2020/2/6.
//

#import "BDLyxnChannelConfig.h"
#import "NSDictionary+BDLynxAdditions.h"

@implementation BDLynxChannelRegisterConfig

@end

@implementation BDLynxBaseConfig

- (instancetype)initWithDictionary:(NSDictionary *)dictionary groupID:(NSString *)groupID {
  self = [super init];
  if (self) {
    _groupID = groupID;
    [self updateWithDictionary:dictionary];
  }

  return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
                           groupID:(NSString *)groupID
                           rootDir:(NSURL *)rootDirURL {
  self = [super init];
  if (self) {
    _groupID = groupID;
    _rootDirURL = rootDirURL;
    [self updateWithDictionary:dictionary];
  }

  return self;
}

- (void)updateWithDictionary:(NSDictionary *)dictionary {
}

@end

@implementation BDLynxTemplateConfig

/*
"card_id": "124",
"card_template_path": "hot_board/hot_board.js",
"card_version": "756",
"desc": "xxx",
"ext": {
    "blist": [],
    "wlist": [],
    ......
}
*/

- (void)updateWithDictionary:(NSDictionary *)dictionary {
  _cardID = [dictionary bdlynx_stringValueForKey:@"card_id"];
  _cardPath = [dictionary bdlynx_stringValueForKey:@"card_template_path"];
  _cardVersion = [dictionary bdlynx_stringValueForKey:@"card_version"];
  _desc = [dictionary bdlynx_stringValueForKey:@"desc"];
  _extra = [dictionary bdlynx_dictionaryValueForKey:@"ext"];
  _hasExtResource = [dictionary bdlynx_boolValueForKey:@"fetch_res"];
  _extURLPrefix = [dictionary bdlynx_arrayValueForKey:@"res_http_prefix"];
}

- (NSURL *)realURLForPath:(NSString *)path {
  return [self.rootDirURL URLByAppendingPathComponent:path];
}

- (NSData *)dataForPath:(NSString *)path {
  NSURL *url = [self realURLForPath:path];
  return [NSData dataWithContentsOfURL:url];
}

@end

@interface BDLynxChannelIOSConfig ()

@property(nonatomic, strong) NSDictionary<NSString *, BDLynxTemplateConfig *> *templateConfigMapper;

@end

@implementation BDLynxChannelIOSConfig

- (void)updateWithDictionary:(NSDictionary *)dictionary {
  NSArray *listDict = [dictionary bdlynx_arrayValueForKey:@"card_list"];
  NSMutableArray *templateList = [NSMutableArray arrayWithCapacity:listDict.count];
  NSMutableDictionary *templateConfigMapper =
      [NSMutableDictionary dictionaryWithCapacity:listDict.count];
  [listDict enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
    if ([obj isKindOfClass:[NSDictionary class]]) {
      BDLynxTemplateConfig *templateConfig =
          [[BDLynxTemplateConfig alloc] initWithDictionary:obj
                                                   groupID:self.groupID
                                                   rootDir:self.rootDirURL];
      [templateList addObject:templateConfig];

      [templateConfigMapper setValue:templateConfig forKey:templateConfig.cardID];
    }
  }];
  _templateList = templateList;
  _templateConfigMapper = templateConfigMapper;
}

- (BDLynxTemplateConfig *)templateConfigForCardID:(NSString *)cardID {
  if (!cardID) {
    return nil;
  }

  return [self.templateConfigMapper valueForKey:cardID];
}

@end

@implementation BDLyxnChannelConfig

- (void)updateWithDictionary:(NSDictionary *)dictionary {
  NSString *version = [dictionary bdlynx_stringValueForKey:@"version"];
  NSParameterAssert(version);
  version = version ?: @"0";

  if (_version.length > 0 && [version compare:_version
                                      options:NSNumericSearch] != NSOrderedDescending) {
    return;
  }

  _version = version;
  _iOSConfig = [[BDLynxChannelIOSConfig alloc]
      initWithDictionary:[dictionary bdlynx_dictionaryValueForKey:@"ios"]
                 groupID:self.groupID
                 rootDir:self.rootDirURL];
}

@end
