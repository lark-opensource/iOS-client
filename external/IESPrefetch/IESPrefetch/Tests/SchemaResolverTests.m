//
//  SchemaResolverTests.m
//  IESPrefetch-Unit-Tests
//
//  Created by yuanyiyang on 2019/12/1.
//

#import <Specta/Specta.h>
#import <Expecta/Expecta.h>
#import <OCMock/OCMock.h>
#import <IESPrefetch/IESPrefetchFlatSchema.h>
#import <IESPrefetch/IESWebViewSchemaResolver.h>
#import <IESPrefetch/IESSimpleSchemaResolver.h>
#import <IESPrefetch/IESFallbackSchemaResolver.h>
#import <IESPrefetch/IESPrefetchLoader.h>
#import <IESPrefetch/IESPrefetchManager.h>

@interface IESTestPrefetchSchemaResolver : NSObject<IESPrefetchSchemaResolver>

@end

@implementation IESTestPrefetchSchemaResolver

- (BOOL)shouldInterceptHierachicalSchema:(NSString *)urlString
{
    return YES;
}

- (NSURL *)resolveFlatSchema:(NSString *)urlString
{
    return [NSURL URLWithString:@"https://www.baidu.com"];
}

@end

@interface IESPrefetchLoader (SchemaTest)

- (IESPrefetchFlatSchema *)resolveSchema:(NSString *)urlString;

@end

SpecBegin(IESPrefetchFlatSchemaTest)

describe(@"initWithUrl", ^{
    it(@"queryAfterHash", ^{
        NSString *urlString = @"https://hotsoon.snssdk.com/falcon/live_inapp/page/push_hot/index.html#/?enter_from=publish_finish&item_id=6724185674863496455";
        NSURL *url = [NSURL URLWithString:urlString];
        IESPrefetchFlatSchema *schema = [[IESPrefetchFlatSchema alloc] initWithURL:url];
        expect(schema.fragment).equal(@"/");
        expect(schema.queryItems[@"enter_from"]).equal(@"publish_finish");
        expect(schema.path).equal(@"/falcon/live_inapp/page/push_hot/index.html");
    });
    it(@"nohashAndNoQuery", ^{
        NSString *urlString = @"https://hotsoon.snssdk.com/falcon/live_inapp/page/push_hot/index.html";
        NSURL *url = [NSURL URLWithString:urlString];
        IESPrefetchFlatSchema *schema = [[IESPrefetchFlatSchema alloc] initWithURL:url];
        expect(schema.fragment).beNil();
        expect(schema.queryItems.count).equal(0);
        expect(schema.path).equal(@"/falcon/live_inapp/page/push_hot/index.html");
    });
    it(@"hashAndNoQuery", ^{
        NSString *urlString = @"https://hotsoon.snssdk.com/falcon/live_inapp/page/push_hot/index.html#/path/to/push";
        NSURL *url = [NSURL URLWithString:urlString];
        IESPrefetchFlatSchema *schema = [[IESPrefetchFlatSchema alloc] initWithURL:url];
        expect(schema.fragment).equal(@"/path/to/push");
        expect(schema.queryItems.count).equal(0);
        expect(schema.path).equal(@"/falcon/live_inapp/page/push_hot/index.html");
    });
    it(@"nohashButQuery", ^{
        NSString *urlString = @"https://hotsoon.snssdk.com/falcon/live_inapp/page/push_hot/index.html?enter_from=publish_finish&item_id=6724185674863496455";
        NSURL *url = [NSURL URLWithString:urlString];
        IESPrefetchFlatSchema *schema = [[IESPrefetchFlatSchema alloc] initWithURL:url];
        expect(schema.fragment).beNil();
        expect(schema.queryItems[@"enter_from"]).equal(@"publish_finish");
        expect(schema.path).equal(@"/falcon/live_inapp/page/push_hot/index.html");
    });
    it(@"hashBehindQuery", ^{
        NSString *urlString = @"https://hotsoon.snssdk.com/falcon/live_inapp/page/push_hot/index.html?enter_from=publish_finish&item_id=6724185674863496455#/path/to/push";
        NSURL *url = [NSURL URLWithString:urlString];
        IESPrefetchFlatSchema *schema = [[IESPrefetchFlatSchema alloc] initWithURL:url];
        expect(schema.fragment).equal(@"/path/to/push");
        expect(schema.queryItems[@"enter_from"]).equal(@"publish_finish");
        expect(schema.path).equal(@"/falcon/live_inapp/page/push_hot/index.html");
    });
    it(@"hashQueryAndQuery", ^{
        NSString *urlString = @"https://hotsoon.snssdk.com/falcon/live_inapp/page/push_hot/index.html?hide_more=true#/path/to/push?enter_from=publish_finish&item_id=6724185674863496455";
        NSURL *url = [NSURL URLWithString:urlString];
        IESPrefetchFlatSchema *schema = [[IESPrefetchFlatSchema alloc] initWithURL:url];
        expect(schema.fragment).equal(@"/path/to/push");
        expect(schema.queryItems[@"enter_from"]).equal(@"publish_finish");
        expect(schema.queryItems[@"hide_more"]).equal(@"true");
        expect(schema.path).equal(@"/falcon/live_inapp/page/push_hot/index.html");
    });
});

describe(@"urlString", ^{
         it(@"equalOriginalURL", ^{
    NSString *urlString = @"https://hotsoon.snssdk.com/falcon/live_inapp/page/push_hot/index.html?hide_more=true#/path/to/push?enter_from=publish_finish&item_id=6724185674863496455";
    NSURL *url = [NSURL URLWithString:urlString];
    IESPrefetchFlatSchema *schema = [[IESPrefetchFlatSchema alloc] initWithURL:url];
    expect(schema.urlString).equal(urlString);
});
         });

SpecEnd

SpecBegin(SchemaResolverTests)

describe(@"IESSimpleSchemaResolver", ^{
    it(@"correctSchema", ^{
        NSString *urlString = @"sslocal://webview?hide_nav_bar=1&disable_bounces=1&url=https%3A%2F%2Fhotsoon.snssdk.com%2Ffalcon%2Flive_inapp%2Fpage%2Fpush_hot%2Findex.html%23%2F%3Fenter_from%3Dpublish_finish%26item_id%3D6724185674863496455";
        IESSimpleSchemaResolver *resolver = [[IESSimpleSchemaResolver alloc] initWithHost:@"webview" keyQuery:@"url"];
        BOOL shouldIntercept = [resolver shouldInterceptHierachicalSchema:urlString];
        expect(shouldIntercept).beTruthy();
        NSURL *url = [resolver resolveFlatSchema:urlString];
        expect(url).notTo.beNil();
        NSString *decodedUrl = @"https://hotsoon.snssdk.com/falcon/live_inapp/page/push_hot/index.html#/?enter_from=publish_finish&item_id=6724185674863496455";
        expect(url.absoluteString).equal(decodedUrl);
    });
    it(@"wrongSchema", ^{
        NSString *urlString = @"sslocal://webview_cast?hide_nav_bar=1&disable_bounces=1&url=https%3A%2F%2Fhotsoon.snssdk.com%2Ffalcon%2Flive_inapp%2Fpage%2Fpush_hot%2Findex.html%23%2F%3Fenter_from%3Dpublish_finish%26item_id%3D6724185674863496455";
        IESSimpleSchemaResolver *resolver = [[IESSimpleSchemaResolver alloc] initWithHost:@"webview" keyQuery:@"url"];
        BOOL shouldIntercept = [resolver shouldInterceptHierachicalSchema:urlString];
        expect(shouldIntercept).beFalsy();
    });
    it(@"wrongKey", ^{
        NSString *urlString = @"sslocal://webview?hide_nav_bar=1&disable_bounces=1&http=https%3A%2F%2Fhotsoon.snssdk.com%2Ffalcon%2Flive_inapp%2Fpage%2Fpush_hot%2Findex.html%23%2F%3Fenter_from%3Dpublish_finish%26item_id%3D6724185674863496455";
        IESSimpleSchemaResolver *resolver = [[IESSimpleSchemaResolver alloc] initWithHost:@"webview" keyQuery:@"url"];
        BOOL shouldIntercept = [resolver shouldInterceptHierachicalSchema:urlString];
        expect(shouldIntercept).beTruthy();
        NSURL *url = [resolver resolveFlatSchema:urlString];
        expect(url.absoluteString).equal(urlString);
    });
});

describe(@"IESWebViewSchemaResolver", ^{
    it(@"correctSchema", ^{
        NSString *urlString = @"sslocal://webview?hide_nav_bar=1&disable_bounces=1&url=https%3A%2F%2Fhotsoon.snssdk.com%2Ffalcon%2Flive_inapp%2Fpage%2Fpush_hot%2Findex.html%23%2F%3Fenter_from%3Dpublish_finish%26item_id%3D6724185674863496455";
        IESWebViewSchemaResolver *resolver = [IESWebViewSchemaResolver new];
        BOOL shouldIntercept = [resolver shouldInterceptHierachicalSchema:urlString];
        expect(shouldIntercept).beTruthy();
        NSURL *url = [resolver resolveFlatSchema:urlString];
        expect(url).notTo.beNil();
        NSString *decodedUrl = @"https://hotsoon.snssdk.com/falcon/live_inapp/page/push_hot/index.html#/?enter_from=publish_finish&item_id=6724185674863496455";
        expect(url.absoluteString).equal(decodedUrl);
    });
});

describe(@"IESFallbackSchemaResolver", ^{
         it(@"correctSchema", ^{
   NSString *urlString = @"https://hotsoon.snssdk.com/falcon/live_inapp/page/push_hot/index.html#/?enter_from=publish_finish&item_id=6724185674863496455";
    IESFallbackSchemaResolver *resolver = [IESFallbackSchemaResolver new];
    BOOL shouldIntercept = [resolver shouldInterceptHierachicalSchema:urlString];
    expect(shouldIntercept).beTruthy();
    NSURL *url = [resolver resolveFlatSchema:urlString];
    expect(url).notTo.beNil();
    expect(url.absoluteString).equal(urlString);
});
         });

describe(@"IESPrefetchManager", ^{
         it(@"defaultSchemaOrder", ^{
    id mockCapability = OCMProtocolMock(@protocol(IESPrefetchCapability));
    IESPrefetchManager *manager = [IESPrefetchManager new];
    IESPrefetchLoader *loader = (IESPrefetchLoader *)[manager registerCapability:mockCapability forBusiness:@"Tests"];
    NSString *urlString = @"https://hotsoon.snssdk.com/falcon/live_inapp/page/push_hot/index.html#/?enter_from=publish_finish&item_id=6724185674863496455";
    IESPrefetchFlatSchema *schema = [loader resolveSchema:urlString];
    expect(schema).notTo.beNil();
    expect(schema.urlString).equal(urlString);
    NSString *webSchemaString = @"sslocal://webview?hide_nav_bar=1&disable_bounces=1&url=https%3A%2F%2Fhotsoon.snssdk.com%2Ffalcon%2Flive_inapp%2Fpage%2Fpush_hot%2Findex.html%23%2F%3Fenter_from%3Dpublish_finish%26item_id%3D6724185674863496455";
    schema = [loader resolveSchema:webSchemaString];
    expect(schema.urlString).equal(@"https://hotsoon.snssdk.com/falcon/live_inapp/page/push_hot/index.html#/?enter_from=publish_finish&item_id=6724185674863496455");
    [mockCapability stopMocking];
    [manager removeLoaderForBusiness:@"Tests"];
});
         it(@"loaderAddCustomSchema", ^{
    id mockCapability = OCMProtocolMock(@protocol(IESPrefetchCapability));
    IESPrefetchManager *manager = [IESPrefetchManager new];
    IESPrefetchLoader *loader = (IESPrefetchLoader *)[manager registerCapability:mockCapability forBusiness:@"CustomSchemaTests"];
    [loader registerSchemaResolver:[IESTestPrefetchSchemaResolver new]];
    NSString *urlString = @"https://hotsoon.snssdk.com/falcon/live_inapp/page/push_hot/index.html#/?enter_from=publish_finish&item_id=6724185674863496455";
    IESPrefetchFlatSchema *schema = [loader resolveSchema:urlString];
    expect(schema.urlString).equal(@"https://www.baidu.com");
    [mockCapability stopMocking];
    [manager removeLoaderForBusiness:@"CustomSchemaTests"];
});
          it(@"managerAddCustomSchema", ^{
     id mockCapability = OCMProtocolMock(@protocol(IESPrefetchCapability));
     IESPrefetchManager *manager = [IESPrefetchManager new];
     IESPrefetchLoader *loader = (IESPrefetchLoader *)[manager registerCapability:mockCapability forBusiness:@"CustomSchemaTests"];
     [manager registerSchemaResolver:[IESTestPrefetchSchemaResolver new]];
     NSString *urlString = @"https://hotsoon.snssdk.com/falcon/live_inapp/page/push_hot/index.html#/?enter_from=publish_finish&item_id=6724185674863496455";
     IESPrefetchFlatSchema *schema = [loader resolveSchema:urlString];
     expect(schema.urlString).equal(@"https://www.baidu.com");
     [mockCapability stopMocking];
     [manager removeLoaderForBusiness:@"CustomSchemaTests"];
 });
         });

SpecEnd
