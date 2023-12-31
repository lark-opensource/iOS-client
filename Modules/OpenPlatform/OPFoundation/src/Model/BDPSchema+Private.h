//
//  BDPSchema+Private.h
//  Timor
//
//  Created by liubo on 2019/4/11.
//

#import "BDPSchema.h"

#pragma mark - BDPSchema Private

@interface BDPSchema ()

- (instancetype)initWithURL:(NSURL *)url appType:(OPAppType)appType;

#pragma mark - Error

@property (nonatomic, copy) NSError *error;

#pragma mark - Origin

@property (nonatomic, copy) NSString *schemaVersion;
@property (nonatomic, copy) NSURL *originURL;
@property (nonatomic, copy) NSDictionary *originQueryParams;

#pragma mark - Basic

@property (nonatomic, copy) NSString *protocol;
@property (nonatomic, copy) NSString *host;
@property (nonatomic, copy) NSString *fullHost;

#pragma mark - App

@property (nonatomic, copy) NSString *appID;
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *instanceID;

#pragma mark - Version

@property (nonatomic, assign, copy) OPAppVersionType versionType;
@property (nonatomic, copy) NSString *token;

#pragma mark - Meta

@property (nonatomic, copy) NSDictionary *meta;

#pragma mark - Debug Info

@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSDictionary *urlDictionary;
@property (nonatomic, copy) NSString *ideDisableDomainCheck;

#pragma mark - Common Params For Event Track

@property (nonatomic, copy) NSString *ttid;
@property (nonatomic, copy) NSString *launchFrom;
@property (nonatomic, copy) NSString *originEntrance;

#pragma mark - Scene

@property (nonatomic, copy) NSString *scene;
@property (nonatomic, copy) NSString *subScene;

#pragma mark - Start Page

@property (nonatomic, copy) NSString *startPage;
@property (nonatomic, copy) NSString *startPagePath;
@property (nonatomic, copy) NSString *startPageQuery;
@property (nonatomic, copy) NSDictionary *startPageQueryDictionary;

#pragma mark - Query

@property (nonatomic, copy) NSString *query;
@property (nonatomic, copy) NSDictionary *queryDictionary;

#pragma mark - Extra

@property (nonatomic, copy) NSString *extra;
@property (nonatomic, copy) NSDictionary *extraDictionary;

#pragma mark - BDP Log

@property (nonatomic, copy) NSString *bdpLog;
@property (nonatomic, copy) NSDictionary *bdpLogDictionary;

#pragma mark - Business Params

@property (nonatomic, copy) NSDictionary *refererInfoDictionary;

@property (nonatomic, copy) NSString *shareTicket;

#pragma mark - GD Ext

@property (nonatomic, copy) NSString *gdExt;
@property (nonatomic, copy) NSDictionary *gdExtDictionary;

#pragma mark - VDOM

@property (nonatomic, copy) NSString *snapshotUrl;

@end
