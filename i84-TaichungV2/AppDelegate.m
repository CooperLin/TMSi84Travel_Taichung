//
//  AppDelegate.m
//  i84-TaichungV2
//
//  Created by ＴＭＳ 景翊科技 on 2014/2/26.
//  Copyright (c) 2014年 ＴＭＳ 景翊科技. All rights reserved.
//

#import "AppDelegate.h"
#import "PushManager.h"
#import "FavoritesManager.h"
#import "AttractionManager.h"

#import "MainViewController.h"
#import "FavoritesViewer.h"
#import "PushViewer.h"
#import "AboutViewer.h"
#import "RoutePlanViewer.h"
#import "SearchBusViewController.h"
#import "busDynamicViewController.h"
#import "stopNearLinesViewController.h"
#import "nearStopViewController.h"
#import "QuestionReportViewer.h"
#import "TakeTimeViewController.h"
#import "LanguageViewer.h"
#import "ASINetworkQueue.h"
#import "ASIHTTPRequest.h"

//市區客運
//#define APICityRoutesPath @"/xmlb/StaticData/GetRoute.xml"
#define APICityRoutesPath NSLocalizedStringFromTable(@"CityRoutesPath",appDelegate.LocalizedTable,nil)
#define APICityProvidersPath NSLocalizedStringFromTable(@"CityProvidersPath",appDelegate.LocalizedTable,nil)

//國道客運
#define APIHighwayRoutesPath NSLocalizedStringFromTable(@"HighwayRoutesPath",appDelegate.LocalizedTable,nil)
#define APIHighwayProvidersPath NSLocalizedStringFromTable(@"HighwayProvidersPath",appDelegate.LocalizedTable,nil)

@interface AppDelegate ()
{
    PushManager * PushManagerObj;
    FavoritesManager * fm;
    AttractionManager * AttManagerObj;
}

@end


@implementation AppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
//@synthesize threadUpdate;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    
//    NSString *userDefaultLocalized = [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultKey];
//    if(userDefaultLocalized){
//        self.LocalizedTable = userDefaultLocalized;
//    }else{
//        NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
//        if([@"en" isEqualToString:language]){
            self.LocalizedTable = kDefaultUS;
//        }else{
//            self.LocalizedTable = kDefaultTW;
//        }
//    }
    
    [self SwitchViewer:0];
    [FavoritesManager CreateTable];

    fm = [[FavoritesManager alloc] init];
    [fm ImportOldPush];
    fm.intQueryFail = 0;
    [fm SendSynchronousRequest];
    
    
    AttManagerObj = [[AttractionManager alloc] init];
    [AttManagerObj CheckOrCopyDb];
    
    //Notification
    
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    
    [self addRequests];
    
    // Reset the badge
    
    [application setApplicationIconBadgeNumber:0];
    
//    //更新用
//    if (!threadUpdate)
//    {
//        threadUpdate = [[NSThread alloc] initWithTarget:self selector:@selector(actTimerTick) object:nil];
//    }
//    [threadUpdate start];
    self.updateTimer = [[UpdateTimer alloc]init];

    return YES;
}
-(void)addRequests
{
    if (!self.requestManager)
    {
        self.requestManager = [[RequestManager alloc]init];
    }
    self.requestManager.delegate = self;
    
    if (![DataManager checkUpdatedTodayByType:RouteDataTypeCityRoutes])
    {
        [self.requestManager addRequestWithKey:@"CityRoutes" andUrl:[NSString stringWithFormat:@"%@%@",APIServer,APICityRoutesPath] byType:RequestDataTypeXML];
    }
    if (![DataManager checkUpdatedTodayByType:RouteDataTypeHighwayRoutes])
    {
        [self.requestManager addRequestWithKey:@"HighwayRoutes" andUrl:[NSString stringWithFormat:@"%@%@",APIServer,APIHighwayRoutesPath] byType:RequestDataTypeXML];
    }
    if (![DataManager checkUpdatedTodayByType:RouteDataTypeCityProviders])
    {
        [self.requestManager addRequestWithKey:@"CityProviders" andUrl:[NSString stringWithFormat:@"%@%@",APIServer,APICityProvidersPath] byType:RequestDataTypeXML];
    }
    if (![DataManager checkUpdatedTodayByType:RouteDataTypeHighwayProviders])
    {
        [self.requestManager addRequestWithKey:@"HighwayProviders" andUrl:[NSString stringWithFormat:@"%@%@",APIServer,APIHighwayProvidersPath] byType:RequestDataTypeXML];
    }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [fm SendSynchronousRequest];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}
#pragma mark notification
- (void) application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSString* newToken = [deviceToken description];
	newToken = [newToken stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
	newToken = [newToken stringByReplacingOccurrencesOfString:@" " withString:@""];
    
 	NSLog(@"Notification Token is: %@", newToken);
    if(PushManagerObj == nil)
    {
        PushManagerObj = [[PushManager alloc] initWithToken:newToken];
    }
}
- (void) application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    NSLog(@"Received notification: %@", userInfo);
}
- (void) application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"Failed to get token, error: %@",error);
    if(PushManagerObj == nil && [PushManager GetToken] != nil)
    {
        PushManagerObj = [[PushManager alloc] initWithToken:[PushManager GetToken]];
    }
}
#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil)
    {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"i84_TaichungV2" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil)
    {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"i84_TaichungV2.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
    {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}
- (void) SwitchViewer:(int)intViewer
{
    UIViewController * viewer;
    switch (intViewer)
    {
        case 0://主畫面
            viewer = [[MainViewController alloc] initWithNibName:@"MainView" bundle:nil];
            break;
        case 1://搜尋路線
            viewer = [[SearchBusViewController alloc] initWithNibName:@"SearchBusViewController" bundle:nil];
            break;
        case 2://即時到站
            viewer = [[busDynamicViewController alloc] initWithNibName:@"busDynamicViewController" bundle:nil];
            break;
        case 3://經過路線
            viewer = [[stopNearLinesViewController alloc] initWithNibName:@"stopNearLinesViewController" bundle:nil];
            break;
        case 4://附近站牌
            viewer = [[nearStopViewController alloc] initWithNibName:@"nearStopViewController" bundle:nil];
            break;
            
        case 5://旅行時間
            viewer = [[TakeTimeViewController alloc]initWithNibName:@"TakeTimeViewController" bundle:nil];
            break;
            
        case 6://路線規劃
            viewer = [[RoutePlanViewer alloc] initWithNibName:@"RoutePlanView" bundle:nil];
            break;
            
        case 7://我的最愛
            viewer = [[FavoritesViewer alloc] initWithNibName:@"FavoritesView" bundle:nil];
            break;
            
        case 8://到站提醒
            viewer = [[PushViewer alloc] initWithNibName:@"PushView" bundle:nil];
            break;
            
        case 9://問題回報
            viewer = [[QuestionReportViewer alloc] initWithNibName:@"QuestionReportViewer" bundle:nil];
            break;
        case 10://關於
            viewer = [[AboutViewer alloc] initWithNibName:@"AboutView" bundle:nil];
            break;
        case 11://語系切換
            viewer = [[LanguageViewer alloc] initWithNibName:@"LanguageView" bundle:nil];
            break;
    }
    if (viewer)
    {
        self.window.rootViewController = viewer;
    }
    [self.window makeKeyAndVisible];
}
-(void)actParseXmlDoc:(GDataXMLDocument*)XmlDoc byType:(RouteDataType)requestType
{
    NSMutableArray *arrayDataCollected = [NSMutableArray new];
    NSString * stringNodeName;
//    NSString * stringKey = nil;
    
    switch (requestType)
    {
        case RouteDataTypeCityRoutes:
        {
//            arrayDataCollected = arrayRoutesCity;
            stringNodeName = @"Route";
        }
            break;
        case RouteDataTypeHighwayRoutes:
        {
//            arrayDataCollected = arrayRoutesHighway;
            stringNodeName = @"Route";
        }
            break;
        case RouteDataTypeCityProviders:
        {
//            arrayDataCollected = arrayProvidersCity;
            stringNodeName = @"Provider";
        }
            break;
        case RouteDataTypeHighwayProviders:
        {
//            arrayDataCollected = arrayProvidersHighway;
            stringNodeName = @"Provider";
        }
            break;
        default:
            break;
    }
    
//    if (!arrayDataCollected.count)
//    {
//        [arrayDataCollected removeAllObjects];
//    }
    NSArray * arrayElementTmp = [XmlDoc.rootElement elementsForName:@"BusInfo"];
    
    NSArray * arrayElementOnes = [[arrayElementTmp objectAtIndex:0] elementsForName:stringNodeName];
    for(GDataXMLElement * elementOne in arrayElementOnes)
    {
        NSArray * arrayElementAttributes = [elementOne attributes];
        NSMutableDictionary * dictionaryDataCache = [NSMutableDictionary new];
        for (GDataXMLNode * node in arrayElementAttributes)
        {
            [dictionaryDataCache setObject:[[elementOne attributeForName:[node name]]stringValue] forKey:[node name]];
        }
        switch (requestType)
        {
            case RouteDataTypeHighwayProviders:
            {
                [dictionaryDataCache setObject:[[[dictionaryDataCache objectForKey:@"nameZh"] componentsSeparatedByString:@"-"]objectAtIndex:0] forKey:@"nameZh"];
                if ([[dictionaryDataCache objectForKey:@"ID"]integerValue]<100)
                {
                    [arrayDataCollected addObject:dictionaryDataCache];
                }
            }
                break;
            case RouteDataTypeCityProviders:
            {
                if ([[dictionaryDataCache objectForKey:@"ID"]integerValue]<100)
                {
                    [arrayDataCollected addObject:dictionaryDataCache];
                }
            }
                break;
            case RouteDataTypeCityRoutes:
            {
                [dictionaryDataCache setObject:@"city" forKey:@"type"];
                [arrayDataCollected addObject:dictionaryDataCache];
            }
                break;
            case RouteDataTypeHighwayRoutes:
            {
                [dictionaryDataCache setObject:@"highway" forKey:@"type"];
                [arrayDataCollected addObject:dictionaryDataCache];
            }
                break;
            default:
                
                break;
        }
    }
#ifdef LogOut
    //        NSLog(@"%@:\n%@",stringNodeName,arrayTarget);
#endif
    [DataManager updateTableFromArray:arrayDataCollected byType:requestType];
    
//    if (queueASIRequests.operationCount==0)
//    {
//        [self actBuildList];
//    }
}
#pragma mark - RequestManager Delegate
-(void)requestManager:(id)requestManager returnXmlDoc:(GDataXMLDocument *)gdataXmlDoc withKey:(NSString *)key
{
    RouteDataType dataType = 0;
    if ([key isEqualToString:@"CityRoutes"])
    {
        dataType = RouteDataTypeCityRoutes;
    }
    else
        if ([key isEqualToString:@"HighwayRoutes"])
        {
            dataType = RouteDataTypeHighwayRoutes;
        }
        else
            if ([key isEqualToString:@"CityProviders"])
            {
                dataType = RouteDataTypeCityProviders;
            }
            else
                if ([key isEqualToString:@"HighwayProviders"])
                {
                    dataType = RouteDataTypeHighwayProviders;
                }
    [self actParseXmlDoc:gdataXmlDoc byType:dataType];
    
}

@end
