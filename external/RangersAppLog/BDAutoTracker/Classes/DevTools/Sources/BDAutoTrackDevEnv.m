//
//  BDAutoTrackDevEnv.m
//  RangersAppLog-RangersAppLogDevTools
//
//  Created by bytedance on 6/28/22.
//

#import "BDAutoTrackDevEnv.h"
#import "BDAutoTrackForm.h"
#import "BDAutoTrackInspector.h"
#import "BDAutoTrack+Private.h"
#import "BDAutoTrackSummary.h"
#import "BDAutoTrack+DevTools.h"

#import "BDAutoTrackLocalConfigService.h"
#import "BDAutoTrackABConfig.h"
#import "BDAutoTrackUtility.h"

@interface BDAutoTrackDevEnv () {
    
    BDAutoTrackForm *form;
    
}

@end

@implementation BDAutoTrackDevEnv

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    // Do any additional setup after loading the view.
    form = [BDAutoTrackForm new];
    [form embedIn:self];
    
    form.groups = @[
        [BDAutoTrackFormGroup groupWithTitle:@"SDK Info" elements:@[
            [BDAutoTrackFormElement elementUsingBlock:nil stateUpdate:nil defaultTitle:@"version" defualtValue:[BDAutoTrack SDKVersion]],
            [BDAutoTrackFormElement elementUsingBlock:nil stateUpdate:^(BDAutoTrackFormElement * ele) {
                ele.val = self.inspector.currentTracker.started ? @"Running" : @"Suspend";
            } defaultTitle:@"status" defualtValue:@"Suspend"],
            [BDAutoTrackFormElement elementUsingBlock:^(BDAutoTrackFormElement * ele) {
                
                BDAutoTrackSummary *summary = [BDAutoTrackSummary new];
                summary.groups = @[[BDAutoTrackFormGroup groupWithTitle:@"Identifier" elements:[BDAutoTrackFormElement transform:[self.inspector.currentTracker devtools_identifier]]]];
                [self.navigationController pushViewController:summary animated:YES];
                
            } stateUpdate:nil defaultTitle:@"Identifier" defualtValue:nil]
        ]],
        [BDAutoTrackFormGroup groupWithTitle:@"User Define" elements:@[
            [BDAutoTrackFormElement elementUsingBlock:^(BDAutoTrackFormElement * ele) {
                
                BDAutoTrackSummary *summary = [BDAutoTrackSummary new];
                summary.groups = @[[BDAutoTrackFormGroup groupWithTitle:@"CONFIG" elements:[BDAutoTrackFormElement transform:[self.inspector.currentTracker devtools_configToDictionary]]]];
                [self.navigationController pushViewController:summary animated:YES];
                
            } stateUpdate:nil defaultTitle:@"Config" defualtValue:nil],
            [BDAutoTrackFormElement elementUsingBlock:^(BDAutoTrackFormElement * ele) {
                
            BDAutoTrackSummary *summary = [BDAutoTrackSummary new];
            summary.groups = @[[BDAutoTrackFormGroup groupWithTitle:@"Custom Header" elements:[BDAutoTrackFormElement transform:[self.inspector.currentTracker devtools_customHeaderToDictionary]]]];
            summary.title = @"CUSTOM HEADER";
            [self.navigationController pushViewController:summary animated:YES];
                
            } stateUpdate:nil defaultTitle:@"Custom Header" defualtValue:nil],
            [BDAutoTrackFormElement elementUsingBlock:^(BDAutoTrackFormElement * ele) {
                
                BDAutoTrackSummary *summary = [BDAutoTrackSummary new];
            summary.groups = @[[BDAutoTrackFormGroup groupWithTitle:@"Remote Settings" elements:[BDAutoTrackFormElement transform:[self.inspector.currentTracker devtools_logsettings]]]];
                [self.navigationController pushViewController:summary animated:YES];
                
            } stateUpdate:nil defaultTitle:@"Remote Settings" defualtValue:nil]
        ]],
        [BDAutoTrackFormGroup groupWithTitle:@"OTHERS" elements:@[
            [BDAutoTrackFormElement elementUsingBlock:^(BDAutoTrackFormElement * ele) {
                
                BDAutoTrackSummary *summary = [BDAutoTrackSummary new];
                summary.title = @"Tester";
                NSDictionary *allIDs = [self.inspector.currentTracker devtools_identifier];
                NSDictionary *testerIDs = @{
                    @"DeviceID": allIDs[@"DeviceID"],
                    @"UserUniqueID": allIDs[@"UserUnqiueID"],
                    @"SSID":allIDs[@"SSID"]
                };
            
                NSDictionary *rawDict = [self.inspector.currentTracker allABTestConfigs2];
                
                BDAutoTrackABConfig *ab = self.inspector.currentTracker.abTester;
                BDAutoTrackLocalConfigService *settings = self.inspector.currentTracker.localConfig;
            
                BDAutoTrackFormGroup *testerIDGroup = [BDAutoTrackFormGroup groupWithTitle:@"User Identifier" elements:[BDAutoTrackFormElement transform:testerIDs]];
                BDAutoTrackFormGroup *ExposedGroup = [BDAutoTrackFormGroup groupWithTitle:@"Exposed Vids" elements:[BDAutoTrackFormElement transform:ab.testerABVersions]];
                BDAutoTrackFormGroup *ExternalGroup = [BDAutoTrackFormGroup groupWithTitle:@"External Vids" elements:[BDAutoTrackFormElement transform:ab.externalVersions]];
                BDAutoTrackFormGroup *AlinkGroup = [BDAutoTrackFormGroup groupWithTitle:@"ALink Vids" elements:[BDAutoTrackFormElement transform:ab.alinkABVersions]];
            
                BDAutoTrackFormGroup *AllGroup = [BDAutoTrackFormGroup groupWithTitle:@"All Tester Data" elements:@[
                    [BDAutoTrackFormElement elementUsingBlock:^(BDAutoTrackFormElement * ele) {
                    
                        BDAutoTrackSummary *sub = [BDAutoTrackSummary new];
                        NSMutableArray *groups = [NSMutableArray array];
                        
                        [rawDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, NSDictionary*  _Nonnull obj, BOOL * _Nonnull stop) {
                            [groups addObject:[BDAutoTrackFormGroup groupWithTitle:key elements:[BDAutoTrackFormElement transform:obj]]];
                        }];
                        sub.groups = groups;
                        
                        [self.navigationController pushViewController:sub animated:YES];
 
                    } stateUpdate:nil defaultTitle:@"All Tester Data" defualtValue:@""]]];
            
            
                summary.groups = @[testerIDGroup,ExposedGroup,ExternalGroup,AlinkGroup,AllGroup];
                [self.navigationController pushViewController:summary animated:YES];
                
            } stateUpdate:nil defaultTitle:@"Tester" defualtValue:nil],
        ]],
    ];
    
}

- (NSString *)dump
{
    BDAutoTrack *track = self.inspector.currentTracker;
    NSString *envPath =  [bd_trackerLibraryPathForAppID(track.appID) stringByAppendingPathComponent:@"env.txt"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:envPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:envPath error:nil];
    }
    [[NSFileManager defaultManager] createFileAtPath:envPath contents:nil attributes:nil];
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:envPath];
    
    [fileHandle seekToEndOfFile];
    [fileHandle writeData:[[NSString stringWithFormat:@"SDK_VERSION: %@ \r\n", [BDAutoTrack SDKVersion]] dataUsingEncoding:NSUTF8StringEncoding]];
    [fileHandle seekToEndOfFile];
    [fileHandle writeData:[[NSString stringWithFormat:@"Running: %d \r\n", track.started] dataUsingEncoding:NSUTF8StringEncoding]];
    [fileHandle seekToEndOfFile];
    [fileHandle writeData:[@"Identifier:\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [fileHandle seekToEndOfFile];
    [fileHandle writeData:[[NSString stringWithFormat:@"%@ \r\n",[track devtools_identifier]] dataUsingEncoding:NSUTF8StringEncoding]];
    [fileHandle seekToEndOfFile];
    [fileHandle writeData:[@"Config:\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [fileHandle seekToEndOfFile];
    [fileHandle writeData:[[NSString stringWithFormat:@"%@ \r\n",[track devtools_configToDictionary]] dataUsingEncoding:NSUTF8StringEncoding]];
    [fileHandle seekToEndOfFile];
    [fileHandle writeData:[@"Custom Header:\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [fileHandle seekToEndOfFile];
    [fileHandle writeData:[[NSString stringWithFormat:@"%@ \r\n",[track devtools_customHeaderToDictionary]] dataUsingEncoding:NSUTF8StringEncoding]];
    [fileHandle seekToEndOfFile];
    [fileHandle writeData:[@"Log Setting:\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [fileHandle seekToEndOfFile];
    [fileHandle writeData:[[NSString stringWithFormat:@"%@ \r\n",[track devtools_logsettings]] dataUsingEncoding:NSUTF8StringEncoding]];
    
    BDAutoTrackABConfig *ab = track.abTester;
    
    [fileHandle seekToEndOfFile];
    [fileHandle writeData:[@"Tester Exposed Vids:\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [fileHandle seekToEndOfFile];
    [fileHandle writeData:[[NSString stringWithFormat:@"%@ \r\n",[ab testerABVersions]] dataUsingEncoding:NSUTF8StringEncoding]];
    [fileHandle seekToEndOfFile];
    [fileHandle writeData:[[NSString stringWithFormat:@"external: %@ \r\n",[ab externalVersions]] dataUsingEncoding:NSUTF8StringEncoding]];
    [fileHandle seekToEndOfFile];
    [fileHandle writeData:[[NSString stringWithFormat:@"alink: %@ \r\n",[ab alinkABVersions]] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [fileHandle seekToEndOfFile];
    [fileHandle writeData:[@"Tester All Vids:\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [fileHandle seekToEndOfFile];
    [fileHandle writeData:[[NSString stringWithFormat:@"%@ \r\n",[track allABTestConfigs2]] dataUsingEncoding:NSUTF8StringEncoding]];
    
    
    [fileHandle closeFile];
    return envPath;
    
}



@end
