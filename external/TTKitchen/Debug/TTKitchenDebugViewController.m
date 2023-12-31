//
//  TTKitchenDebugViewController.m
//  TTKitchen-Browser-Core-Debug-KeyReporter-SettingsSyncer
//
//  Created by liujinxing on 2020/9/22.
//

#import "TTKitchenDebugViewController.h"
#import "TTKitchenInternal.h"
#import "TTKitchenSyncer+SessionDiff.h"
#import <Heimdallr/HMDInjectedInfo.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>

static NSString * const kTTSettingsMMKVCacheEnabled = @"tt_settings_config.mmkv_cache_enabled";
static NSString * const kTTKitchenHasMigrated = @"kTTKitchenHasMigrated";

@interface TTKitchenAllKVDataViewController : UIViewController

@property(nonatomic, strong) STDebugTextView *textView;

@end

@implementation TTKitchenAllKVDataViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.textView = [[STDebugTextView alloc] initWithFrame:self.view.bounds];
    self.textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.textView appendText:[[TTKitchen allKitchenRawDictionary] btd_jsonStringEncoded]];
    [self.view addSubview:self.textView];
}

@end


@interface TTKitchenSettingsDiffsViewController : UIViewController

@property(nonatomic, strong) STDebugTextView *textView;

@end

@implementation TTKitchenSettingsDiffsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.textView = [[STDebugTextView alloc] initWithFrame:self.view.bounds];
    self.textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    NSString *diffSettings = [[HMDInjectedInfo defaultInfo].customContext objectForKey:@"diff_settings"];
    [self.textView appendText:diffSettings];

    NSString *diffSettingsTimeStamp = [[HMDInjectedInfo defaultInfo].customContext objectForKey:@"diff_settings_timestamp"];
    [self.textView appendText:[NSString stringWithFormat:@"\n timestamps: \n%@",diffSettingsTimeStamp]];
    [self.view addSubview:self.textView];
}

@end



@implementation TTKitchenDebugViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSMutableArray *dataSource = [NSMutableArray array];
    
    NSMutableArray *migrationDebugItemArray = [NSMutableArray array];
    STTableViewCellItem *checkMigrateResult = [[STTableViewCellItem alloc] initWithTitle:@"迁移结果" target:self action:@selector(showMigrationResult)];
    [migrationDebugItemArray addObject:checkMigrateResult];
    STTableViewCellItem *checkUpdateResult = [[STTableViewCellItem alloc] initWithTitle:@"增量更新结果" target:self action:@selector(showUpdateResult)];
    [migrationDebugItemArray addObject:checkUpdateResult];
    
    STTableViewCellItem *mmkvUsed = [[STTableViewCellItem alloc] initWithTitle:@"MMKV or not" target:self action:nil];
    mmkvUsed.switchStyle = YES;
    mmkvUsed.checked = [TTKitchenManager.diskCache isKindOfClass:NSClassFromString(@"TTKitchenMMKVDiskCache")];
    [migrationDebugItemArray addObject:mmkvUsed];
    
    STTableViewCellItem *mmkvEnabled = [[STTableViewCellItem alloc] initWithTitle:@"MMKV 迁移开关" target:self action:nil];
    mmkvEnabled.switchStyle = YES;
    mmkvEnabled.checked = [[NSUserDefaults standardUserDefaults] boolForKey:kTTSettingsMMKVCacheEnabled];
    [migrationDebugItemArray addObject:mmkvEnabled];
    
    STTableViewCellItem *hasMigrated = [[STTableViewCellItem alloc] initWithTitle:@"MMKV 迁移完成" target:self action:nil];
    hasMigrated.switchStyle = YES;
    hasMigrated.checked = [[NSUserDefaults standardUserDefaults] boolForKey:kTTKitchenHasMigrated];
    [migrationDebugItemArray addObject:hasMigrated];
    
    STTableViewSectionItem *migrationDebugSection = [[STTableViewSectionItem alloc] initWithSectionTitle:@"TTKitchen 迁移状态" items:migrationDebugItemArray];
    [dataSource addObject:migrationDebugSection];
    
    
    NSMutableArray *diffDebugItemArray = [NSMutableArray array];
    STTableViewCellItem *allKVData = [[STTableViewCellItem alloc] initWithTitle:@"所有KV数据" target:self action:@selector(showAllKVData)];
    [diffDebugItemArray addObject:allKVData];
    
    STTableViewCellItem *settingsDiffs = [[STTableViewCellItem alloc] initWithTitle:@"Settings diffs" target:self action:@selector(showSettingsDiffs)];
    [diffDebugItemArray addObject:settingsDiffs];
    
    STTableViewSectionItem *diffDebugSection = [[STTableViewSectionItem alloc] initWithSectionTitle:@"TTKitchen 数据" items:diffDebugItemArray];
    [dataSource addObject:diffDebugSection];

    
    self.dataSource = dataSource;
}

- (void)showMigrationResult {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"迁移结果" message:TTKitchen.migrateDebugMessage ?: @"No Message" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:true completion:nil];
}

- (void)showUpdateResult {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"增量更新结果" message:TTKitchen.updateDebugMessage ?: @"No Message" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:true completion:nil];
}

- (void)showAllKVData {
    TTKitchenAllKVDataViewController *allKVDataVC = TTKitchenAllKVDataViewController.new;
    [self.navigationController pushViewController:allKVDataVC animated:YES];
}

- (void)showSettingsDiffs {
    TTKitchenSettingsDiffsViewController * settingsDiffsVC = TTKitchenSettingsDiffsViewController.new;
    [self.navigationController pushViewController:settingsDiffsVC animated:YES];
}

@end
