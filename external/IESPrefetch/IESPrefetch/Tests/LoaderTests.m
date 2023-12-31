//
//  LoaderTests.m
//  IESPrefetch-Unit-Tests
//
//  Created by yuanyiyang on 2019/12/6.
//

#import <Specta/Specta.h>
#import <Expecta/Expecta.h>
#import <OCMock/OCMock.h>
#import <IESPrefetch/IESPrefetchLoader.h>
#import <IESPrefetch/IESPrefetchLoaderPrivateProtocol.h>
#import <IESPrefetch/IESPrefetchManager.h>
#import <IESPrefetch/IESPrefetchFlatSchema.h>
#import "MemoryTestCacheStorage.h"

FOUNDATION_EXPORT NSDictionary *jsonDictFromResource(NSString *resourceName, NSString *resourceType);
FOUNDATION_EXPORT NSString *pathForResource(NSString *resourceName, NSString *resourceType);


SpecBegin(YogaLoader)
describe(@"loadConfigAndPrefetch", ^{
         it(@"prefetchOccasion", ^{
    NSDictionary *dict = jsonDictFromResource(@"correct_project_config", @"json");
    id mockCapability = OCMProtocolMock(@protocol(IESPrefetchCapability));
    IESPrefetchLoader *loader = [[IESPrefetchLoader alloc] initWithCapability:mockCapability business:@"Test"];
    id mockLoader = OCMPartialMock(loader);
    OCMExpect([mockLoader prefetchAPI:[OCMArg checkWithBlock:^BOOL(IESPrefetchAPIModel * obj) {
        if ([obj isKindOfClass:[IESPrefetchAPIModel class]] == NO) {
            return NO;
        }
        if ([obj.request.url isEqualToString:@"https://httpbin.org/get"] == NO) {
            return NO;
        }
        if ([obj.request.method isEqualToString:@"GET"] == NO) {
            return NO;
        }
        if (obj.request.data.count != 0) {
            return NO;
        }
        if ([(NSDictionary *)obj.request.params count] != 0) {
            return NO;
        }
        return YES;
    }]]);
    [mockLoader loadConfigurationDict:dict withEvent:nil];
    
    [mockLoader prefetchForOccasion:@"launch_app" withVariable:nil];
    waitUntil(^(DoneCallback done) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            OCMVerifyAll(mockLoader);
            [mockLoader stopMocking];
            done();
        });
    });
});
it(@"prefetchSchemaAndMatchQuery", ^{
    NSDictionary *dict = jsonDictFromResource(@"correct_project_config", @"json");
    id mockCapability = OCMProtocolMock(@protocol(IESPrefetchCapability));
    IESPrefetchManager *manager = [IESPrefetchManager new];
    id<IESPrefetchLoaderPrivateProtocol> loader = (id<IESPrefetchLoaderPrivateProtocol>)[manager registerCapability:mockCapability forBusiness:@"Test"];
    id mockLoader = OCMPartialMock(loader);
    OCMExpect([mockLoader prefetchAPI:[OCMArg checkWithBlock:^BOOL(IESPrefetchAPIModel * obj) {
        if ([obj isKindOfClass:[IESPrefetchAPIModel class]] == NO) {
            return NO;
        }
        if ([obj.request.url isEqualToString:@"https://httpbin.org/get"] == NO) {
            return NO;
        }
        if ([obj.request.method isEqualToString:@"GET"] == NO) {
            return NO;
        }
        if (obj.request.data.count != 0) {
            return NO;
        }
        if ([(NSDictionary *)obj.request.params count] == 0) {
            return NO;
        }
        if ([obj.request.params[@"appkey"] isEqualToString:@"1234"] == NO) {
            return NO;
        }
        return YES;
    }]]);
    [loader loadConfigurationDict:dict withEvent:nil];
    
    NSURL *url = [NSURL URLWithString:@"https://snssdk.com/falcon/live_inapp/page/feedback/index.html"];
    [mockLoader prefetchForSchema:url.absoluteString withVariable:@{@"feedback_appkey":@"1234"}];
    waitUntil(^(DoneCallback done) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            OCMVerifyAll(mockLoader);
            [mockLoader stopMocking];
            done();
        });
    });
});
it(@"prefetchSchemaWithoutAPIQuery", ^{
    NSDictionary *dict = jsonDictFromResource(@"correct_project_config", @"json");
    id mockCapability = OCMProtocolMock(@protocol(IESPrefetchCapability));
    IESPrefetchManager *manager = [IESPrefetchManager new];
    id<IESPrefetchLoaderPrivateProtocol> loader = (id<IESPrefetchLoaderPrivateProtocol>)[manager registerCapability:mockCapability forBusiness:@"Test"];
    id mockLoader = OCMPartialMock(loader);
    OCMExpect([mockLoader prefetchAPI:[OCMArg checkWithBlock:^BOOL(IESPrefetchAPIModel * obj) {
        if ([obj isKindOfClass:[IESPrefetchAPIModel class]] == NO) {
            return NO;
        }
        if ([obj.request.url isEqualToString:@"https://httpbin.org/get"] == NO) {
            return NO;
        }
        if ([obj.request.method isEqualToString:@"GET"] == NO) {
            return NO;
        }
        if (obj.request.data.count != 0) {
            return NO;
        }
        if ([(NSDictionary *)obj.request.params count] != 0) {
            return NO;
        }
        return YES;
    }]]);
    [mockLoader loadConfigurationDict:dict withEvent:nil];
    
    NSURL *url = [NSURL URLWithString:@"https://snssdk.com/falcon/live_inapp/page/feedback/index.html"];
    [mockLoader prefetchForSchema:url.absoluteString withVariable:nil];
    waitUntil(^(DoneCallback done) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            OCMVerifyAll(mockLoader);
            [mockLoader stopMocking];
            done();
        });
    });
});
         it(@"prefetchSchemaWithoutMatch", ^{
    NSDictionary *dict = jsonDictFromResource(@"correct_project_config", @"json");
    id mockCapability = OCMProtocolMock(@protocol(IESPrefetchCapability));
    IESPrefetchManager *manager = [IESPrefetchManager new];
    id<IESPrefetchLoaderPrivateProtocol> loader = (id<IESPrefetchLoaderPrivateProtocol>)[manager registerCapability:mockCapability forBusiness:@"Test"];
    id mockLoader = OCMPartialMock(loader);
    OCMReject([mockLoader prefetchAPI:[OCMArg any]]);
    [mockLoader loadConfigurationDict:dict withEvent:nil];
    
    NSURL *url = [NSURL URLWithString:@"https://snssdk.com/falcon/live_inapp/page/guest_shop/index.html"];
    [mockLoader prefetchForSchema:url.absoluteString withVariable:nil];
    waitUntil(^(DoneCallback done) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            OCMVerifyAll(mockLoader);
            [mockLoader stopMocking];
            done();
        });
    });
});
         it(@"prefetchSchemaWithHash", ^{
    NSDictionary *dict = jsonDictFromResource(@"correct_project_config", @"json");
    id mockCapability = OCMProtocolMock(@protocol(IESPrefetchCapability));
    IESPrefetchManager *manager = [IESPrefetchManager new];
    id<IESPrefetchLoaderPrivateProtocol> loader = (id<IESPrefetchLoaderPrivateProtocol>)[manager registerCapability:mockCapability forBusiness:@"Test"];
    id mockLoader = OCMPartialMock(loader);
    OCMExpect([mockLoader prefetchAPI:[OCMArg checkWithBlock:^BOOL(IESPrefetchAPIModel * obj) {
        if ([obj isKindOfClass:[IESPrefetchAPIModel class]] == NO) {
            return NO;
        }
        if ([obj.request.url isEqualToString:@"https://httpbin.org/get"] == NO) {
            return NO;
        }
        if ([obj.request.method isEqualToString:@"GET"] == NO) {
            return NO;
        }
        if (obj.request.data.count != 0) {
            return NO;
        }
        if ([(NSDictionary *)obj.request.params count] != 0) {
            return NO;
        }
        return YES;
    }]]);
    [mockLoader loadConfigurationDict:dict withEvent:nil];
    
    NSURL *url = [NSURL URLWithString:@"https://snssdk.com/falcon/live_inapp/page/push_hot/index.html#/home"];
    IESPrefetchFlatSchema *schema = [IESPrefetchFlatSchema schemaWithURL:url];
    [mockLoader prefetchForSchema:schema occasion:nil withVariables:nil event:nil];
    OCMVerifyAll(mockLoader);
    [mockLoader stopMocking];
});
         it(@"prefetchSchemaWithRestful", ^{
    NSDictionary *dict = jsonDictFromResource(@"correct_project_config", @"json");
    id mockCapability = OCMProtocolMock(@protocol(IESPrefetchCapability));
    IESPrefetchManager *manager = [IESPrefetchManager new];
    id<IESPrefetchLoaderPrivateProtocol> loader = (id<IESPrefetchLoaderPrivateProtocol>)[manager registerCapability:mockCapability forBusiness:@"Test"];
    id mockLoader = OCMPartialMock(loader);
    OCMExpect([mockLoader prefetchAPI:[OCMArg checkWithBlock:^BOOL(IESPrefetchAPIModel * obj) {
        if ([obj isKindOfClass:[IESPrefetchAPIModel class]] == NO) {
            return NO;
        }
        if ([obj.request.url isEqualToString:@"https://httpbin.org/get"] == NO) {
            return NO;
        }
        if ([obj.request.method isEqualToString:@"GET"] == NO) {
            return NO;
        }
        if (obj.request.data.count != 0) {
            return NO;
        }
        if ([(NSDictionary *)obj.request.params count] == 0) {
            return NO;
        }
        if ([obj.request.params[@"item_id"] isEqualToString:@"1234"] == NO) {
            return NO;
        }
        return YES;
    }]]);
    [mockLoader loadConfigurationDict:dict withEvent:nil];
    
    NSURL *url = [NSURL URLWithString:@"https://snssdk.com/share/item/1234"];
    [mockLoader prefetchForSchema:url.absoluteString withVariable:nil];
    waitUntil(^(DoneCallback done) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            OCMVerifyAll(mockLoader);
            [mockLoader stopMocking];
            done();
        });
    });
});
         });
SpecEnd

SpecBegin(YogaPrefetchLoader)
describe(@"prefetch", ^{
         it(@"withSchema", ^{
    NSString *configPath = pathForResource(@"correct_project_config", @"json");
    NSString *config = [[NSString alloc] initWithContentsOfFile:configPath encoding:NSUTF8StringEncoding error:nil];
    id mockCapability = OCMProtocolMock(@protocol(IESPrefetchCapability));
    OCMExpect([mockCapability networkForRequest:[OCMArg any] completion:[OCMArg any]]);
    IESPrefetchManager *manager = [IESPrefetchManager new];
    id<IESPrefetchLoaderProtocol> loader = [manager registerCapability:mockCapability forBusiness:@"Tests"];
    [loader loadConfigurationJSON:config];
    waitUntil(^(DoneCallback done) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [loader prefetchForSchema:@"https://snssdk.com/share/item/1234" withVariable:nil];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                OCMVerifyAll(mockCapability);
                [mockCapability stopMocking];
                [manager removeLoaderForBusiness:@"Tests"];
                done();
            });
        });
    });
});
         it(@"disable", ^{
    NSString *configPath = pathForResource(@"correct_project_config", @"json");
    NSString *config = [[NSString alloc] initWithContentsOfFile:configPath encoding:NSUTF8StringEncoding error:nil];
    id mockCapability = OCMProtocolMock(@protocol(IESPrefetchCapability));
    OCMReject([mockCapability networkForRequest:[OCMArg any] completion:[OCMArg any]]);
    IESPrefetchManager *manager = [IESPrefetchManager new];
    id<IESPrefetchLoaderProtocol> loader = [manager registerCapability:mockCapability forBusiness:@"Tests"];
    [loader setEnabled:NO];
    [loader loadConfigurationJSON:config];
    waitUntil(^(DoneCallback done) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [loader prefetchForSchema:@"https://snssdk.com/share/item/1234" withVariable:nil];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                OCMVerifyAll(mockCapability);
                [mockCapability stopMocking];
                [manager removeLoaderForBusiness:@"Tests"];
                done();
            });
        });
    });
});
         });
describe(@"config", ^{
         it(@"loadAllConfig", ^{
    NSString *configPath = pathForResource(@"correct_project_config", @"json");
    NSString *config = [[NSString alloc] initWithContentsOfFile:configPath encoding:NSUTF8StringEncoding error:nil];
    NSMutableDictionary *dict = [[NSJSONSerialization JSONObjectWithData:[config dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil] mutableCopy];
    dict[@"project"] = @"project1";
    NSString *config1 = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dict options:0 error:nil] encoding:NSUTF8StringEncoding];
    dict[@"project"] = @"project2";
    NSString *config2 = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dict options:0 error:nil] encoding:NSUTF8StringEncoding];
    id mockCapability = OCMProtocolMock(@protocol(IESPrefetchCapability));
    IESPrefetchManager *manager = [IESPrefetchManager new];
    id<IESPrefetchLoaderPrivateProtocol> loader = (id<IESPrefetchLoaderPrivateProtocol>)[manager registerCapability:mockCapability forBusiness:@"Tests"];
    waitUntilTimeout(10, ^(DoneCallback done) {
        [loader loadConfigurationJSON:config];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSArray<NSString *> *projects = [loader allProjects];
            expect([projects containsObject:@"live_inapp"]).to.beTruthy();
            id<IESPrefetchConfigTemplate> template = [loader templateForProject:@"live_inapp"];
            expect(template).notTo.beNil();
            [loader loadAllConfigurations:@[config1, config2]];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                NSArray<NSString *> *projects = [loader allProjects];
                expect(projects.count).equal(2);
                expect([projects containsObject:@"project1"]).to.beTruthy();
                expect([projects containsObject:@"project2"]).to.beTruthy();
                expect([projects containsObject:@"live_inapp"]).to.beFalsy();
                done();
            });
        });
    });
});
         it(@"removeConfig", ^{
    NSString *configPath = pathForResource(@"correct_project_config", @"json");
    NSString *config = [[NSString alloc] initWithContentsOfFile:configPath encoding:NSUTF8StringEncoding error:nil];
    id mockCapability = OCMProtocolMock(@protocol(IESPrefetchCapability));
    IESPrefetchManager *manager = [IESPrefetchManager new];
    id<IESPrefetchLoaderPrivateProtocol> loader = (id<IESPrefetchLoaderPrivateProtocol>)[manager registerCapability:mockCapability forBusiness:@"Tests"];
    waitUntilTimeout(10, ^(DoneCallback done) {
        [loader loadConfigurationJSON:config];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSArray<NSString *> *projects = [loader allProjects];
            expect([projects containsObject:@"live_inapp"]).to.beTruthy();
            id<IESPrefetchConfigTemplate> template = [loader templateForProject:@"live_inapp"];
            expect(template).notTo.beNil();
            [loader removeConfiguration:@"live_inapp"];
            projects = [loader allProjects];
            expect(projects.count).equal(0);
            done();
        });
    });
});
         });

describe(@"fetchData", ^{
         it(@"fetchWithinCache", ^{
    NSString *configPath = pathForResource(@"correct_project_config", @"json");
    NSString *config = [[NSString alloc] initWithContentsOfFile:configPath encoding:NSUTF8StringEncoding error:nil];
    MemoryCacheTestStorage *cacheStorage = [MemoryCacheTestStorage new];
    id mockCapability = OCMProtocolMock(@protocol(IESPrefetchCapability));
    OCMStub([mockCapability networkForRequest:[OCMArg any] completion:([OCMArg invokeBlockWithArgs:@{@"key":@"value"}, [NSNull null], nil])]);
    OCMStub([mockCapability customCacheStorage]).andReturn(cacheStorage);
    IESPrefetchManager *manager = [IESPrefetchManager new];
    id<IESPrefetchLoaderPrivateProtocol> loader = (id<IESPrefetchLoaderPrivateProtocol>)[manager registerCapability:mockCapability forBusiness:@"Tests"];
    [loader loadConfigurationJSON:config];
    waitUntil(^(DoneCallback done) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [loader prefetchForOccasion:@"launch_app" withVariable:nil];
            IESPrefetchJSNetworkRequestModel *requestModel = [IESPrefetchJSNetworkRequestModel new];
            requestModel.url = @"https://httpbin.org/get";
            requestModel.method = @"GET";
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [loader requestDataWithModel:requestModel completion:^(id  _Nullable data, IESPrefetchCache cached, NSError * _Nullable error) {
                    expect(cached).equal(IESPrefetchCacheHit);
                    expect(data).equal(@{@"key": @"value"});
                    done();
                }];
            });
        });
    });
});
         it(@"fetchWithoutCache", ^{
    NSString *configPath = pathForResource(@"correct_project_config", @"json");
    NSString *config = [[NSString alloc] initWithContentsOfFile:configPath encoding:NSUTF8StringEncoding error:nil];
    MemoryCacheTestStorage *cacheStorage = [MemoryCacheTestStorage new];
    id mockCapability = OCMProtocolMock(@protocol(IESPrefetchCapability));
    OCMStub([mockCapability networkForRequest:[OCMArg any] completion:([OCMArg invokeBlockWithArgs:@{@"key":@"value"}, [NSNull null], nil])]);
    OCMStub([mockCapability customCacheStorage]).andReturn(cacheStorage);
    IESPrefetchManager *manager = [IESPrefetchManager new];
    id<IESPrefetchLoaderPrivateProtocol> loader = (id<IESPrefetchLoaderPrivateProtocol>)[manager registerCapability:mockCapability forBusiness:@"Tests"];
    [loader loadConfigurationJSON:config];
    waitUntil(^(DoneCallback done) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            IESPrefetchJSNetworkRequestModel *requestModel = [IESPrefetchJSNetworkRequestModel new];
            requestModel.url = @"https://httpbin.org/get";
            requestModel.method = @"GET";
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [loader requestDataWithModel:requestModel completion:^(id  _Nullable data, IESPrefetchCache cached, NSError * _Nullable error) {
                    expect(cached).equal(IESPrefetchCacheNone);
                    expect(data).equal(@{@"key": @"value"});
                    done();
                }];
            });
        });
    });
});
         it(@"fetchWhenDisabled", ^{
    NSString *configPath = pathForResource(@"correct_project_config", @"json");
    NSString *config = [[NSString alloc] initWithContentsOfFile:configPath encoding:NSUTF8StringEncoding error:nil];
    MemoryCacheTestStorage *cacheStorage = [MemoryCacheTestStorage new];
    id mockCapability = OCMProtocolMock(@protocol(IESPrefetchCapability));
    OCMStub([mockCapability networkForRequest:[OCMArg any] completion:([OCMArg invokeBlockWithArgs:@{@"key":@"value"}, [NSNull null], nil])]);
    OCMStub([mockCapability customCacheStorage]).andReturn(cacheStorage);
    IESPrefetchManager *manager = [IESPrefetchManager new];
    id<IESPrefetchLoaderPrivateProtocol> loader = (id<IESPrefetchLoaderPrivateProtocol>)[manager registerCapability:mockCapability forBusiness:@"Tests"];
    [loader loadConfigurationJSON:config];
    waitUntil(^(DoneCallback done) {
        [loader setEnabled:NO];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [loader prefetchForOccasion:@"launch_app" withVariable:nil];
            IESPrefetchJSNetworkRequestModel *requestModel = [IESPrefetchJSNetworkRequestModel new];
            requestModel.url = @"https://httpbin.org/get";
            requestModel.method = @"GET";
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [loader requestDataWithModel:requestModel completion:^(id  _Nullable data, IESPrefetchCache cached, NSError * _Nullable error) {
                    expect(cached).equal(IESPrefetchCacheDisabled);
                    expect(data).equal(@{@"key": @"value"});
                    done();
                }];
            });
        });
    });
});
         });

describe(@"eventDelegate", ^{
         it(@"eventWithoutError", ^{
    NSString *configPath = pathForResource(@"correct_project_config", @"json");
    NSString *config = [[NSString alloc] initWithContentsOfFile:configPath encoding:NSUTF8StringEncoding error:nil];
    id mockCapability = OCMProtocolMock(@protocol(IESPrefetchCapability));
    OCMStub([mockCapability networkForRequest:[OCMArg any] completion:([OCMArg invokeBlockWithArgs:@{}, [NSNull null], nil])]);
    IESPrefetchManager *manager = [IESPrefetchManager new];
    id<IESPrefetchLoaderPrivateProtocol> loader = (id<IESPrefetchLoaderPrivateProtocol>)[manager registerCapability:mockCapability forBusiness:@"Tests"];
    id mockEventDelegate = OCMProtocolMock(@protocol(IESPrefetchLoaderEventDelegate));
    OCMExpect([mockEventDelegate loader:loader didFinishLoadConfig:@"live_inapp" withError:nil]);
    OCMExpect([mockEventDelegate loader:loader didFinishPrefetchOccasion:@"launch_app" withError:nil]);
    OCMExpect([mockEventDelegate loader:loader didFinishPrefetchSchema:@"https://snssdk.com/share/item/1234" withError:nil]);
    OCMExpect([mockEventDelegate loader:loader didFinishFetchData:@"https://httpbin.org/get" withStatus:IESPrefetchCacheNone error:nil]);
    OCMExpect([mockEventDelegate loader:loader didFinishPrefetchApi:@"https://httpbin.org/get" withCacheStatus:IESPrefetchCacheNone]);
    [loader addEventDelegate:mockEventDelegate];
    [loader loadConfigurationJSON:config];
    waitUntil(^(DoneCallback done) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [loader prefetchForOccasion:@"launch_app" withVariable:nil];
            [loader prefetchForSchema:@"https://snssdk.com/share/item/1234" withVariable:nil];
            IESPrefetchJSNetworkRequestModel *requestModel = [IESPrefetchJSNetworkRequestModel new];
            requestModel.url = @"https://httpbin.org/get";
            requestModel.method = @"GET";
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [loader requestDataWithModel:requestModel completion:^(id  _Nullable data, IESPrefetchCache cached, NSError * _Nullable error) {
                    OCMVerifyAll(mockEventDelegate);
                    done();
                }];
            });
        });
    });
});
         it(@"configEventWithError", ^{
    NSString *configPath = pathForResource(@"correct_api_config", @"json");
    NSString *config = [[NSString alloc] initWithContentsOfFile:configPath encoding:NSUTF8StringEncoding error:nil];
    id mockCapability = OCMProtocolMock(@protocol(IESPrefetchCapability));
    OCMStub([mockCapability networkForRequest:[OCMArg any] completion:([OCMArg invokeBlockWithArgs:@{}, [NSNull null], nil])]);
    IESPrefetchManager *manager = [IESPrefetchManager new];
    id<IESPrefetchLoaderPrivateProtocol> loader = (id<IESPrefetchLoaderPrivateProtocol>)[manager registerCapability:mockCapability forBusiness:@"Tests"];
    id mockEventDelegate = OCMProtocolMock(@protocol(IESPrefetchLoaderEventDelegate));
    OCMExpect([mockEventDelegate loader:loader didFinishLoadConfig:nil withError:[OCMArg isKindOfClass:[NSError class]]]);
    [loader addEventDelegate:mockEventDelegate];
    [loader loadConfigurationJSON:config];
    waitUntil(^(DoneCallback done) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [loader prefetchForOccasion:@"launch_app" withVariable:nil];
            [loader prefetchForSchema:@"https://snssdk.com/share/item/1234" withVariable:nil];
            IESPrefetchJSNetworkRequestModel *requestModel = [IESPrefetchJSNetworkRequestModel new];
            requestModel.url = @"https://httpbin.org/get";
            requestModel.method = @"GET";
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [loader requestDataWithModel:requestModel completion:^(id  _Nullable data, IESPrefetchCache cached, NSError * _Nullable error) {
                    OCMVerifyAll(mockEventDelegate);
                    done();
                }];
            });
        });
    });
});
         describe(@"concurrent", ^{
    it(@"prefetch", ^{
        NSString *configPath = pathForResource(@"correct_project_config", @"json");
        NSString *config = [[NSString alloc] initWithContentsOfFile:configPath encoding:NSUTF8StringEncoding error:nil];
        MemoryCacheTestStorage *cacheStorage = [MemoryCacheTestStorage new];
        id mockCapability = OCMProtocolMock(@protocol(IESPrefetchCapability));
        OCMStub([mockCapability networkForRequest:[OCMArg any] completion:([OCMArg invokeBlockWithArgs:@{@"key":@"value"}, [NSNull null], nil])]);
        OCMStub([mockCapability customCacheStorage]).andReturn(cacheStorage);
        IESPrefetchManager *manager = [IESPrefetchManager new];
        id<IESPrefetchLoaderPrivateProtocol> loader = (id<IESPrefetchLoaderPrivateProtocol>)[manager registerCapability:mockCapability forBusiness:@"Tests"];
        [loader loadConfigurationJSON:config];
        waitUntilTimeout(15, ^(DoneCallback done) {
            dispatch_group_t group = dispatch_group_create();
            for (NSInteger i = 0; i < 1000; i++) {
                dispatch_group_enter(group);
                dispatch_async(dispatch_get_global_queue(0, 0), ^{
                    [loader prefetchForOccasion:@"launch_app" withVariable:nil];
                    [loader prefetchForSchema:@"https://snssdk.com/share/item/1234" withVariable:nil];
                    IESPrefetchJSNetworkRequestModel *requestModel = [IESPrefetchJSNetworkRequestModel new];
                    requestModel.url = @"https://httpbin.org/get";
                    requestModel.method = @"GET";
                    [loader requestDataWithModel:requestModel completion:^(id  _Nullable data, IESPrefetchCache cached, NSError * _Nullable error) {
                        dispatch_group_leave(group);
                        expect(data).equal(@{@"key":@"value"});
                    }];
                });
            }
            dispatch_group_wait(group, 150);
            done();
        });
    });
});
         });
SpecEnd
