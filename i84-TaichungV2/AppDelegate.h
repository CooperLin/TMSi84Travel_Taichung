//
//  AppDelegate.h
//  i84-TaichungV2
//
//  Created by ＴＭＳ 景翊科技 on 2014/2/26.
//  Copyright (c) 2014年 ＴＭＳ 景翊科技. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RequestManager.h"
#import "DataManager+Route.h"
#import "UpdateTimer.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate,RequestManagerDelegate>

#define IS_WIDESCREEN (fabs((double)[[UIScreen mainScreen] bounds].size.height - (double)568) < DBL_EPSILON)
#define IS_IPHONE ([[[UIDevice currentDevice] model] isEqualToString:@"iPhone"]||[[[UIDevice currentDevice] model] isEqualToString:@"iPhone Simulator"])
#define IS_IPOD ([[[UIDevice currentDevice] model] isEqualToString:@"iPod touch"])
#define IS_IPHONE_5 (IS_IPHONE && IS_WIDESCREEN)
#define SystemVersion [[[UIDevice currentDevice] systemVersion] floatValue]
#define stringApiLanguage NSLocalizedString(@"Lang=eng",@"Lang=eng")
#define LogOut
#define UpdateTime 30

#define TaipeiCityHall CLLocationCoordinate2DMake(25.037559,121.563796)

#define pathDocuments [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]
#define APIServer @"http://citybus.taichung.gov.tw"

#define appDelegate ((AppDelegate*)[[UIApplication sharedApplication]delegate])

#define kDefaultUS @"LocalizedString_US"
#define kDefaultTW @"LocalizedString_TW"
#define kUserDefaultKey @"UserLocalized"

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

//紀錄使用者點選哪個語系
@property (nonatomic, strong) NSString *LocalizedTable;

//for返回 所以不共用同個變數
@property (strong,nonatomic) id selectedRoute;
@property (strong,nonatomic) id selectedStop;
@property (nonatomic,retain) RequestManager * requestManager;
@property (strong, nonatomic) UpdateTimer *updateTimer;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;


- (void) SwitchViewer:(int)Viewer;
@end
