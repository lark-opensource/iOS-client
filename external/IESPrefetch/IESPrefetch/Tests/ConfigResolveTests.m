//
//  ConfigResolveTests.m
//  IESPrefetch-Unit-Tests
//
//  Created by yuanyiyang on 2019/12/2.
//

#import <Specta/Specta.h>
#import <Expecta/Expecta.h>
#import <IESPrefetch/IESPrefetchAPIConfigResolver.h>
#import <IESPrefetch/IESPrefetchAPITemplate.h>
#import <IESPrefetch/IESPrefetchRuleConfigResolver.h>
#import <IESPrefetch/IESPrefetchRuleTemplate.h>
#import <IESPrefetch/IESPrefetchOccasionTemplate.h>
#import <IESPrefetch/IESPrefetchOccasionConfigResolver.h>

FOUNDATION_EXPORT NSString *pathForResource(NSString *resourceName, NSString *resourceType);
FOUNDATION_EXPORT NSDictionary *jsonDictFromResource(NSString *resourceName, NSString *resourceType);

SpecBegin(APIConfigResolver)
describe(@"resolveAPI", ^{
    it(@"correctConfig", ^{
        NSDictionary *dict = jsonDictFromResource(@"correct_api_config", @"json");
        IESPrefetchAPIConfigResolver *resolver = [IESPrefetchAPIConfigResolver new];
        IESPrefetchAPITemplate *template = [resolver resolveConfig:dict];
        expect(template).notTo.beNil();
        expect([template apiNodeForName:@"api_name1"]).notTo.beNil();
        expect([template apiNodeForName:@"api_name2"]).beNil();
        expect([template apiNodeForName:@"api_name3"]).beNil();

        IESPrefetchAPINode *node = [template apiNodeForName:@"api_name1"];
        expect(node.url).equal(@"http://example.com/api1");
        expect(node.method).equal(@"POST");
        expect(node.expire).equal(6000);
        expect([node.headers objectForKey:@"Content-Type"]).equal(@"application/json");

        IESPrefetchAPIParamsNode *paramNode = [node.params objectForKey:@"param1"];
        expect(paramNode).notTo.beNil();
        expect(paramNode.paramName).equal(@"param1");
        expect(paramNode.type).equal(IESPrefetchAPIParamStatic);
        expect(paramNode.valueFrom).equal(@"live");
    
    IESPrefetchAPIParamsNode *paramNode2 = [node.params objectForKey:@"param2"];
    expect(paramNode2.valueFrom).equal(@"");
    
    IESPrefetchAPIParamsNode *paramNode3 = [node.params objectForKey:@"param3"];
    expect(paramNode3).beNil();

        IESPrefetchAPIParamsNode *dataNode = [node.data objectForKey:@"item_id"];
        expect(dataNode).notTo.beNil();
        expect(dataNode.paramName).equal(@"item_id");
        expect(dataNode.type).equal(IESPrefetchAPIParamQuery);
        expect(dataNode.valueFrom).equal(@"item_id");
    });
    it(@"wrongConfig", ^{
        NSDictionary *dict = @{@"prefetch_apis": @{}};
        IESPrefetchAPIConfigResolver *resolver = [IESPrefetchAPIConfigResolver new];
        IESPrefetchAPITemplate *template = [resolver resolveConfig:dict];
        expect(template).beNil();
    });
});
SpecEnd

SpecBegin(RuleConfigResolver)
describe(@"resolveRule", ^{
         it(@"correctConfig", ^{
    NSDictionary *dict = jsonDictFromResource(@"correct_rule_config", @"json");
    IESPrefetchRuleConfigResolver *resolver = [IESPrefetchRuleConfigResolver new];
    IESPrefetchRuleTemplate *template = [resolver resolveConfig:dict];
    expect(template).notTo.beNil();
    NSUInteger count = [template countOfRuleNodes];
    expect(count).equal(4);
    
    IESPrefetchRuleNode *node1 = [template ruleNodeForName:@"rule_name"];
    expect(node1).to.beNil();
    
    IESPrefetchRuleNode *node2 = [template ruleNodeForName:@"/tt482a3e97d7008189/pages/author_guide/health"];
    expect(node2).notTo.beNil();
    expect(node2.itemNodes.count).equal(1);
    IESPrefetchRuleItemNode *node2Item = node2.itemNodes.firstObject;
    expect(node2Item.apis.count).equal(1);
    expect(node2Item.fragment).equal(@"^#/home\\?");
    expect(node2Item.queryNodes.count).equal(1);
    IESPrefetchRuleQueryNode *node2ItemQuery = node2Item.queryNodes.firstObject;
    expect(node2ItemQuery.key).equal(@"item_id");
    expect(node2ItemQuery.valueRegex).equal(@"^128");
    
    IESPrefetchRuleNode *node3 = [template ruleNodeForName:@"/tt482a3e97d7008189/pages/push_hot/home"];
    expect(node3).notTo.beNil();
    expect(node3.itemNodes.count).equal(2);
    IESPrefetchRuleItemNode *node3Item = node3.itemNodes.firstObject;
    expect(node3Item.apis.count).equal(1);
    expect(node3Item.queryNodes.count).equal(1);
    expect(node3Item.fragment).beNil();
    IESPrefetchRuleQueryNode *node3ItemQuery = node3Item.queryNodes.firstObject;
    expect(node3ItemQuery.key).equal(@"item_id");
    expect(node3ItemQuery.valueRegex).beNil();
    
    IESPrefetchRuleRegexNode *node4 = [template regexRuleNodeForName:@"/share/item/:item_id"];
    expect(node4).notTo.beNil();
    expect(node4.pathComponents.count).equal(4);
    expect(node4.pathComponents.firstObject).equal(@"");
    expect(node4.pathComponents.lastObject).equal(@":item_id");
});
         it(@"wrongConfig", ^{
    NSDictionary *dict = @{@"rules": @{}};
    IESPrefetchRuleConfigResolver *resolver = [IESPrefetchRuleConfigResolver new];
    IESPrefetchRuleTemplate *template = [resolver resolveConfig:dict];
    expect(template).beNil();
});
         });
SpecEnd

SpecBegin(OccasionConfigResolver)
describe(@"resolveOccasion", ^{
         it(@"correctConfig", ^{
    NSDictionary *dict = jsonDictFromResource(@"correct_occasion_config", @"json");
    IESPrefetchOccasionConfigResolver *resolver = [IESPrefetchOccasionConfigResolver new];
    IESPrefetchOccasionTemplate *template = [resolver resolveConfig:dict];
    expect(template).notTo.beNil();
    NSUInteger count = [template countOfNodes];
    expect(count).equal(1);
    IESPrefetchOccasionNode *node = [template nodeForName:@"hts_mycells_show"];
    expect(node).notTo.beNil();
    expect(node.name).equal(@"hts_mycells_show");
    expect(node.rules.count).equal(1);
    expect(node.rules.firstObject).equal(@"rule_name");
});
         it(@"wrongConfig", ^{
    NSDictionary *dict = @{@"rules": @{}};
    IESPrefetchOccasionConfigResolver *resolver = [IESPrefetchOccasionConfigResolver new];
    IESPrefetchOccasionTemplate *template = [resolver resolveConfig:dict];
    expect(template).beNil();
});
         });
SpecEnd
