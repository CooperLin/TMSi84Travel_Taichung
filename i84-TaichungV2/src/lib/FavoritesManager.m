//
//  FavoritesManager.m
//  i84-TaichungV2
//
//  Created by ＴＭＳ 景翊科技 on 2014/2/26.
//  Copyright (c) 2014年 ＴＭＳ 景翊科技. All rights reserved.
//

#import "FavoritesManager.h"
#import "sqlite3.h"
#import "DataTypes.h"
#import "ShareTools.h"
#import <SystemConfiguration/SCNetworkReachability.h>
#include <netinet/in.h>
#import <CFNetwork/CFNetwork.h>
#import "ASIHTTPRequest.h"
#import "PushManager.h"
#import "AppDelegate.h"

@interface FavoritesManager ()
{
    NSMutableArray * ExportToNewPushUrls;
}

@end


@implementation FavoritesManager

@synthesize delegate,intQueryFail;
#define FavoriteDb [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"Favorites.sqlite"]
#define PushDb [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"Pushs.sqlite"]
#define OldDb [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"Taichung_iPhone.sqlite"]

#define CreateFavoriteTableSql @"CREATE TABLE IF NOT EXISTS Favorites(RouteId TEXT ,RouteName TEXT,StopID TEXT,StopName TEXT,GoBack Integer,Seq Integer,RouteKind Integer,Lon Real,Lat Real);"

#define CreatePushTableSql @"CREATE TABLE IF NOT EXISTS Pushes(RouteId TEXT ,RouteName TEXT,StopID TEXT,StopName TEXT,GoBack Integer,Enable Integer,StartTime TEXT,EndTime TEXT,ArrivalTime Integer,WeekSun Integer,WeekMon Integer,WeekTue Integer,WeekWed Integer,WeekThu Integer,WeekFri Integer,WeekSat Integer,Seq Integer,RouteKind Integer);"

#define InsertFavoriteSql @"insert into Favorites(RouteId,RouteName,StopID,StopName,GoBack,RouteKind,seq,Lon,Lat) Values('%@','%@','%@','%@',%d,%d,(select max(rowid) from Favorites),%f,%f);"
#define InsertPushSql @"insert into Pushes(RouteId,RouteName,StopID,StopName,GoBack,Enable,StartTime,EndTime,ArrivalTime,WeekSun,WeekMon,WeekTue,WeekWed,WeekThu,WeekFri,WeekSat,RouteKind,Seq) Values('%@','%@','%@','%@',%d,%d,'%@','%@',%d,%d,%d,%d,%d,%d,%d,%d,%d,(select max(rowid) from Pushes));"
#define UpdatePushSql @"Update Pushes set Enable = %d,StartTime = '%@',EndTime = '%@',ArrivalTime = %d,WeekSun = %d,WeekMon = %d,WeekTue = %d,WeekWed = %d,WeekThu = %d,WeekFri = %d,WeekSat = %d Where RouteId = '%@' and RouteName = '%@' and StopID = '%@' and StopName = '%@' and GoBack = %d and RouteKind = %d;"
#define FavoriteIsExistsSql @"Select 1 from Favorites Where RouteId = '%@' and RouteName = '%@' and StopId = '%@' and StopName = '%@' and GoBack = %d;"

#define PushIsExistsSql  @"Select 1 from Pushes Where RouteId = '%@' and RouteName = '%@' and StopId = '%@' and StopName = '%@' and GoBack = %d and StartTime = '%@' and EndTime = '%@' and WeekSun = %d and WeekMon = %d and WeekTue = %d and WeekWed = %d and WeekThu = %d and WeekFri = %d and WeekSat = %d and RouteKind = %d"

#define DelFavoriteSql @"Delete from Favorites Where RouteId = '%@' and RouteName = '%@' and StopID = '%@' and StopName = '%@' and GoBack = %d and RouteKind = %d;"

#define DelPushSql @"Delete from Pushes Where RouteId = '%@' and RouteName = '%@' and StopID = '%@' and StopName = '%@' and GoBack = %d and StartTime = '%@' and EndTime = '%@' and WeekSun = %d and WeekMon = %d and WeekTue = %d and WeekWed = %d and WeekThu = %d and WeekFri = %d and WeekSat = %d and RouteKind = %d;"

//多加where Lon>0 and lat>0放棄舊資料 舊版資料第一次更新(v2.0)已被改變, 無法分辨新舊資料的去返程(新的是1,2舊的是0,1), 僅能用座標空值判斷是舊資料 14.08.06
#define SelectFavoritesSql @"Select RouteId,RouteName,StopID,StopName,GoBack,RouteKind,Lon,Lat From Favorites where Lon>0 and lat>0 Order by Seq;"
#define SelectPushSql @"Select RouteId,RouteName,StopID,StopName,GoBack,Enable,StartTime,EndTime,ArrivalTime,WeekSun,WeekMon,WeekTue,WeekWed,WeekThu,WeekFri,WeekSat,RouteKind From Pushes Order by RouteName,StopName"

#define UpdateFavSql @"Update Favorites Set Seq = %d,RouteId = '%@',StopID = '%@',Lon=%f,Lat=%f Where RouteName = '%@' and StopName = '%@' and GoBack = %d and RouteKind = %d;"
#define OldPushUrl @"http://citybus.taichung.gov.tw/BusTCAPI/getorderStop.aspx?Did=%@&phone=iphone&City=Taichung"

#define APISelect NSLocalizedStringFromTable(@"APISelectForF",appDelegate.LocalizedTable,nil)

+ (void) CreateTable
{
    sqlite3 *db=nil;
    
    if(sqlite3_open_v2([FavoriteDb UTF8String], &db, SQLITE_OPEN_READWRITE|SQLITE_OPEN_CREATE, NULL) == SQLITE_OK)
    {
        //NSLog(@"建立或打開資料庫");
        char *errorMsg;
        if (sqlite3_exec(db, [CreateFavoriteTableSql UTF8String], NULL,NULL,&errorMsg) == SQLITE_OK)
        {
            //            NSLog(@"寫入Log Info");

        }else {
            NSLog(@"err: %s",errorMsg);
            sqlite3_free(errorMsg);
        }
    }
    if(db) {
        sqlite3_close(db);
        db = nil;
    }

    if(sqlite3_open_v2([PushDb UTF8String], &db, SQLITE_OPEN_READWRITE|SQLITE_OPEN_CREATE, NULL) == SQLITE_OK)
    {
        //NSLog(@"建立或打開資料庫");
        char *errorMsg;
        if (sqlite3_exec(db, [CreatePushTableSql UTF8String], NULL,NULL,&errorMsg) == SQLITE_OK)
        {
            //            NSLog(@"寫入Log Info");
            
        }else {
            NSLog(@"err: %s",errorMsg);
            sqlite3_free(errorMsg);
        }
    }
    if(db) {
        sqlite3_close(db);
        db = nil;
    }
}
- (void) ImportOldPush
{
    NSUserDefaults  * userDefault = [NSUserDefaults standardUserDefaults];
    NSString * ImportOldFav = [userDefault objectForKey:@"ImportOldFav"];
    if(ImportOldFav == nil || [ImportOldFav compare:@"false"] == 0 )
    {
        if([ShareTools connectedToNetwork])
        {
            NSString * OldPushUrlStr = [NSString stringWithFormat:OldPushUrl,[PushManager GetToken]];
            ASIHTTPRequest * OldImportRequest = [[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:OldPushUrlStr]];
            [OldImportRequest setDelegate:self];
            [OldImportRequest setDidFinishSelector:@selector(OldImportRequestFinish:)];
            [OldImportRequest setTimeOutSeconds:30.0];
            [OldImportRequest startAsynchronous];
        }
    }
    
}
#pragma mark - Query API
- (void) SendSynchronousRequest
{
    BOOL NeedUpdate = NO;
    NSDate * now = [[NSDate alloc] init];
    NSDateFormatter * Formatter = [[NSDateFormatter alloc] init];
    [Formatter setDateFormat:@"MMddHHmm"];
    NSString * nowDateStr = [[Formatter stringFromDate:now] substringToIndex:7];
    NSUserDefaults  * userDefault = [NSUserDefaults standardUserDefaults];
    if([userDefault objectForKey:@"LastUpdatePushList"] == nil
       || [(NSString *)[userDefault objectForKey:@"LastUpdatePushList"] compare:nowDateStr] != 0)
    {
        NeedUpdate = YES;
    }
    if(!NeedUpdate)
    {
        //不需更新
        return;
    }
    
    
    if ( ![ShareTools connectedToNetwork] )
    {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"請確定網路狀態" message:@"請先開啟網路同步到站提醒列表" delegate:nil cancelButtonTitle:@"確定" otherButtonTitles:nil, nil];
        [alert show];
		return;
	}
    
    NSString * UrlStr = [NSString stringWithFormat:APISelect,APIServer,[PushManager GetToken]];
    ASIHTTPRequest * Request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:UrlStr]];
    [Request setDelegate:self];
    [Request setDidFinishSelector:@selector(SynchronousRequestFinish:)];
    [Request setDidFailSelector:@selector(SynchronousRequestFail:)];
    [Request setTimeOutSeconds:30.0];
    [Request startAsynchronous];
#ifdef LogOut
    NSLog(@"RequestStr:%@",UrlStr);
#endif
    
}
- (void) OldImportRequestFinish:(ASIHTTPRequest *)request
{
    NSString * Response = [request responseString];
    if([Response hasPrefix:@"Err"])
    {
        return;
    }
    NSMutableString * FavSqlSb = [[NSMutableString alloc] init]
        ,* PushSqlSb = [[NSMutableString alloc] init];
    
    ExportToNewPushUrls = [[NSMutableArray alloc] init];
    
    NSArray * Rows = [Response componentsSeparatedByString:@"&_"];
    for(int i=1;i<[Rows count]-1;i++)
    {
        NSArray * Values = [[Rows objectAtIndex:i] componentsSeparatedByString:@",_"];
        NSString * RouteName = [Values objectAtIndex:0];
        NSString * StopName = [Values objectAtIndex:1];
        NSString * GoBack = [Values objectAtIndex:2];
        NSString * StartHour = [Values objectAtIndex:3];
        NSString * EndHour = [Values objectAtIndex:4];
        NSString * ArrivalTime = [Values objectAtIndex:5];
        NSString * Enable = [Values objectAtIndex:6];
        
        [FavSqlSb appendFormat:InsertFavoriteSql,@"",RouteName,@"",StopName,[GoBack intValue]+1,0,0.0f,0.0f];
        [FavSqlSb appendString:@"\n"];
        [PushSqlSb appendFormat:InsertPushSql,@"",RouteName,@"",StopName,[GoBack intValue]+1,[Enable intValue],[NSString stringWithFormat:@"%@:00",StartHour],[NSString stringWithFormat:@"%@:00",EndHour],[ArrivalTime intValue],1,1,1,1,1,1,1,0];
        [PushSqlSb appendString:@"\n"];
        
//        NSMutableDictionary * ExportUrlInfo = [[NSMutableDictionary alloc] init];
//        NSString * Url =[NSString stringWithFormat:ExportNewPushUrl
//                         ,[PushManager GetToken]
//                         ,
//                         
//                         ];
//        [ExportUrlInfo setObject:Url forKey:@"Url"];
        
    }
    sqlite3 *db=nil;
    if(sqlite3_open_v2([FavoriteDb UTF8String], &db, SQLITE_OPEN_READWRITE, NULL) == SQLITE_OK)
    {
        char *errorMsg;
        if (sqlite3_exec(db, [FavSqlSb UTF8String], NULL,NULL,&errorMsg) != SQLITE_OK)
        {
            NSLog(@"Sql Error:%s",errorMsg);
            NSLog(@"Sql:%@",FavSqlSb);
        }
        else
        {}
    }
    if(db) {
        sqlite3_close(db);
        db = nil;
    }
    if(sqlite3_open_v2([PushDb UTF8String], &db, SQLITE_OPEN_READWRITE, NULL) == SQLITE_OK)
    {
        char *errorMsg;
        if (sqlite3_exec(db, [PushSqlSb UTF8String], NULL,NULL,&errorMsg) != SQLITE_OK)
        {
            NSLog(@"Sql Error:%s",errorMsg);
            NSLog(@"Sql:%@",PushSqlSb);
        }
        else
        {}
    }
    if(db) {
        sqlite3_close(db);
        db = nil;
    }
    NSUserDefaults  * userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setObject:@"true" forKey:@"ImportOldFav"];
    [userDefault synchronize];

    
}
- (void) SynchronousRequestFinish:(ASIHTTPRequest *) Request
{
    NSString * Response = [Request responseString];
#ifdef LogOut
    NSLog(@"Response:%@",Response);
#endif
    if([Response hasPrefix:@"err"])
    {
        
        
    }
    else
    {
        NSMutableString * SqlSb = [[NSMutableString alloc] init];
        [SqlSb appendString:@"Delete From Pushes;\n"];
        NSArray * Rows = [Response componentsSeparatedByString:@"&_"];
        for(int i=1;i<[Rows count]-1;i++)
        {
            NSArray * Values = [[Rows objectAtIndex:i] componentsSeparatedByString:@",_"];
            NSString * RouteId = [Values objectAtIndex:0]
            , * RouteName = [Values objectAtIndex:1]
            , * StopId = [Values objectAtIndex:2]
            , * StopName = [Values objectAtIndex:3]
            , * GoBackStr = [Values objectAtIndex:4]
            , * StartTime = [Values objectAtIndex:5]
            , * EndTime = [Values objectAtIndex:6]
            , * ArrivalStr = [Values objectAtIndex:7]
            , * EnableStr = [Values objectAtIndex:8]
            , * RouteKindStr = [Values objectAtIndex:10]
            , * WeekStr = [Values objectAtIndex:11];
            
            int GoBack = [GoBackStr intValue]
            ,Enable = [EnableStr intValue]
            ,Arrival = [ArrivalStr intValue]
            ,RouteKind = [RouteKindStr intValue]
            ,WeekSun = 0,WeekMon = 0,WeekTue = 0,WeekWed = 0,WeekThu = 0,WeekFri = 0,WeekSat = 0;
            NSRange range = [WeekStr rangeOfString:@"0"];
            if(range.location != NSNotFound){WeekSun = 1;}
            range = [WeekStr rangeOfString:@"1"];
            if(range.location != NSNotFound){WeekMon = 1;}
            range = [WeekStr rangeOfString:@"2"];
            if(range.location != NSNotFound){WeekTue = 1;}
            range = [WeekStr rangeOfString:@"3"];
            if(range.location != NSNotFound){WeekWed = 1;}
            range = [WeekStr rangeOfString:@"4"];
            if(range.location != NSNotFound){WeekThu = 1;}
            range = [WeekStr rangeOfString:@"5"];
            if(range.location != NSNotFound){WeekFri = 1;}
            range = [WeekStr rangeOfString:@"6"];
            if(range.location != NSNotFound){WeekSat = 1;}
            
            
            
            NSString * SqlStr = [NSString stringWithFormat:InsertPushSql
                                 ,RouteId
                                 ,RouteName
                                 ,StopId
                                 ,StopName
                                 ,GoBack
                                 ,Enable
                                 ,StartTime
                                 ,EndTime
                                 ,Arrival
                                 ,WeekSun,WeekMon,WeekTue,WeekWed,WeekThu,WeekFri,WeekSat,RouteKind];
            [SqlSb appendString:SqlStr];
            [SqlSb appendString:@"\n"];
            
        }
        
        sqlite3 *db=nil;
        if(sqlite3_open_v2([PushDb UTF8String], &db, SQLITE_OPEN_READWRITE, NULL) == SQLITE_OK)
        {
            
            
            char *errorMsg;
            if (sqlite3_exec(db, [SqlSb UTF8String], NULL,NULL,&errorMsg) != SQLITE_OK)
            {
                NSLog(@"Sql Error:%s",errorMsg);
                NSLog(@"Sql:%@",SqlSb);
                
            }
            else
            {
                
            }
            
        }
        if(db) {
            sqlite3_close(db);
            db = nil;
        }
        
        
    }
    if(delegate != nil)
    {
        [delegate PushSynchronousFinish];
    }
}
- (void) SynchronousRequestFail:(ASIHTTPRequest *) Request
{
    intQueryFail = intQueryFail + 1;
    if(intQueryFail < 5)
    {
        [self SendSynchronousRequest];
        return;
    }
    else
    {
        if([[NSThread currentThread] isMainThread])
        {
            UIAlertView * Alert = [[UIAlertView alloc] initWithTitle:nil message:@"同步失敗，請稍後再試!" delegate:nil cancelButtonTitle:@"確定" otherButtonTitles:nil, nil];
            [Alert show];
        }
        else
        {
            [self performSelectorOnMainThread:@selector(SynchronousRequestFail:) withObject:Request waitUntilDone:YES];
            return;
        }
    }
}

//+ (void) ImportOldSqlite
//{
//    if([[NSFileManager defaultManager] fileExistsAtPath:OldDb])
//    {
//        NSMutableString * SqlSb = [[NSMutableString alloc] init];
//        sqlite3 *db=nil;
//        sqlite3_stmt *statement=nil;
//        if(sqlite3_open_v2([FavoriteDb UTF8String], &db, SQLITE_OPEN_READWRITE, NULL) == SQLITE_OK)
//        {
//            if (sqlite3_prepare_v2(db, [SelectOldDbSql UTF8String], -1, &statement, nil) == SQLITE_OK)
//            {
//                if (sqlite3_step(statement) == SQLITE_ROW)
//                {
//                    NSString * RouteName = nil,* StopName = nil;
//                    if(sqlite3_column_type(statement, 0) == SQLITE3_TEXT)
//                    {
//                        RouteName = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(statement, 0)];
//                    }
//                    if(sqlite3_column_type(statement, 1) == SQLITE3_TEXT)
//                    {
//                        StopName = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(statement, 1)];
//                    }
//                    if(RouteName != nil && StopName != nil)
//                    {
//                        [SqlSb appendFormat:InsertFavoriteSql,@"",RouteName,@"",StopName,1,1];
//                        [SqlSb appendString:@"\n"];
//                        [SqlSb appendFormat:InsertFavoriteSql,@"",RouteName,@"",StopName,2,1];
//                        [SqlSb appendString:@"\n"];
//                        
//                    }
//
//                }
//                
//            }
//            if(statement)
//            {
//                sqlite3_finalize(statement);
//                statement = nil;
//            }
//        }
//        if(db) {
//            sqlite3_close(db);
//            db = nil;
//        }
//        
//        
//        if(sqlite3_open_v2([FavoriteDb UTF8String], &db, SQLITE_OPEN_READWRITE, NULL) == SQLITE_OK)
//        {
//            char *errorMsg;
//            if (sqlite3_exec(db, [SqlSb UTF8String], NULL,NULL,&errorMsg) != SQLITE_OK)
//            {
//                NSLog(@"Sql Error:%s",errorMsg);
//                NSLog(@"Sql:%@",SqlSb);
//            }
//            else
//            {}
//        }
//        if(db) {
//            sqlite3_close(db);
//            db = nil;
//        }
//    }
//    
//}

+ (FavoriteResult) AddToFavoritesByRouteId:(NSString *)RouteId RouteName:(NSString *) RouteName StopId:(NSString *)StopId StopName:(NSString *)StopName GoBack:(int)GoBack RouteKind:(int)RouteKind Lon:(float)Lon Lat:(float)Lat
{
    FavoriteResult result = fail;
    
    NSString * IsExistsSql = [NSString stringWithFormat:FavoriteIsExistsSql
                              ,RouteId == nil ? @"":RouteId
                              ,RouteName == nil ? @"":RouteName
                              ,StopId == nil ? @"":StopId
                              ,StopName == nil ? @"":StopName
                              ,GoBack];
    
    NSString * SqlStr = [NSString stringWithFormat:InsertFavoriteSql
                         ,RouteId == nil ? @"":RouteId
                         ,RouteName == nil ? @"":RouteName
                         ,StopId == nil ? @"":StopId
                         ,StopName == nil ? @"":StopName
                         ,GoBack
                         ,RouteKind
                         ,Lon > 0 ? Lon:0.0f
                         ,Lat > 0 ? Lat:0.0f];
#ifdef LogOut
    NSLog(@"Insert Favotites Sql:%@",SqlStr);
#endif
    sqlite3 *db=nil;
    sqlite3_stmt *statement=nil;
    if(sqlite3_open_v2([FavoriteDb UTF8String], &db, SQLITE_OPEN_READWRITE, NULL) == SQLITE_OK)
    {
        if (sqlite3_prepare_v2(db, [IsExistsSql UTF8String], -1, &statement, nil) == SQLITE_OK)
        {
            if (sqlite3_step(statement) == SQLITE_ROW)
            {
                int count = sqlite3_column_int(statement, 0);
                if(count > 0)
                {
                    result = hased;
                }
            }
            
        }
        if(statement)
        {
            sqlite3_finalize(statement);
            statement = nil;
        }
        
        if(result != hased)
        {
            char *errorMsg;
            if (sqlite3_exec(db, [SqlStr UTF8String], NULL,NULL,&errorMsg) != SQLITE_OK)
            {
                NSLog(@"Sql Error:%s",errorMsg);
                NSLog(@"Sql:%@",SqlStr);
                
            }
            else
            {
                result = success;
            }
        }
    }
    if(db) {
        sqlite3_close(db);
        db = nil;
    }
    
    
    return result;
}

+ (FavoriteResult) DeleteFavoritesByRouteId:(NSString *)RouteId RouteName:(NSString *) RouteName StopId:(NSString *)StopId StopName:(NSString *)StopName GoBack:(int)GoBack RouteKind:(int)RouteKind
{
    
    FavoriteResult result = fail;
    NSString * SqlStr = [NSString stringWithFormat:DelFavoriteSql
                         ,RouteId == nil ? @"":RouteId
                         ,RouteName == nil ? @"":RouteName
                         ,StopId == nil ? @"":StopId
                         ,StopName == nil ? @"":StopName
                         ,GoBack
                         ,RouteKind];
#ifdef LogOut
    NSLog(@"Delete Favotites Sql:%@",SqlStr);
#endif
    sqlite3 *db=nil;
    if(sqlite3_open_v2([FavoriteDb UTF8String], &db, SQLITE_OPEN_READWRITE, NULL) == SQLITE_OK)
    {
        char *errorMsg;
        if (sqlite3_exec(db, [SqlStr UTF8String], NULL,NULL,&errorMsg) != SQLITE_OK)
        {
            NSLog(@"Sql Error:%s",errorMsg);
            NSLog(@"Sql:%@",SqlStr);
            
        }
        else
        {
            result = success;
        }
    }
    if(db) {
        sqlite3_close(db);
        db = nil;
    }
    return result;
}

+ (FavoriteResult) AddToPushsByRouteId:(NSString *)RouteId RouteName:(NSString *) RouteName StopId:(NSString *)StopId StopName:(NSString *)StopName GoBack:(int)GoBack RouteKind:(int)RouteKind
{
    FavoriteResult result = fail;
    NSString * IsExistsSql = [NSString stringWithFormat:PushIsExistsSql
                              ,RouteId == nil ? @"":RouteId
                              ,RouteName == nil ? @"":RouteName
                              ,StopId == nil ? @"":StopId
                              ,StopName == nil ? @"":StopName
                              ,GoBack
                              ,@"07:00"
                              ,@"08:00"
                              ,0,0,0,0,0,0,0,RouteKind];
    
    NSString * SqlStr = [NSString stringWithFormat:InsertPushSql
                         ,RouteId == nil ? @"":RouteId
                         ,RouteName == nil ? @"":RouteName
                         ,StopId == nil ? @"":StopId
                         ,StopName == nil ? @"":StopName
                         ,GoBack
                         ,0
                         ,@"07:00"
                         ,@"08:00"
                         ,10
                         ,0,0,0,0,0,0,0,RouteKind];
#ifdef LogOut
    NSLog(@"Insert Push Sql:%@",SqlStr);
#endif
    sqlite3 *db=nil;
    sqlite3_stmt *statement=nil;
    if(sqlite3_open_v2([PushDb UTF8String], &db, SQLITE_OPEN_READWRITE, NULL) == SQLITE_OK)
    {
        if (sqlite3_prepare_v2(db, [IsExistsSql UTF8String], -1, &statement, nil) == SQLITE_OK)
        {
            if (sqlite3_step(statement) == SQLITE_ROW)
            {
                int count = sqlite3_column_int(statement, 0);
                if(count > 0)
                {
                    result = hased;
                }
            }
            
        }
        if(statement)
        {
            sqlite3_finalize(statement);
            statement = nil;
        }
        
        if(result != hased)
        {
            char *errorMsg;
            if (sqlite3_exec(db, [SqlStr UTF8String], NULL,NULL,&errorMsg) != SQLITE_OK)
            {
                NSLog(@"Sql Error:%s",errorMsg);
                NSLog(@"Sql:%@",SqlStr);
                
            }
            else
            {
                result = success;
            }
        }
    }
    if(db) {
        sqlite3_close(db);
        db = nil;
    }
    
    
    return result;
}

+ (FavoriteResult) DeletePushsByRouteId:(NSString *)RouteId RouteName:(NSString *) RouteName StopId:(NSString *)StopId StopName:(NSString *)StopName GoBack:(int)GoBack StartTime:(NSString *)StartTime  EndTime:(NSString *)EndTime WeekSun:(int)WeekSun WeekMon:(int)WeekMon WeekTue:(int)WeekTue WeekWed:(int)WeekWed WeekThu:(int)WeekThu WeekFri:(int)WeekFri WeekSat:(int)WeekSat RouteKind:(int)RouteKind
{

    FavoriteResult result = fail;
    NSString * SqlStr = [NSString stringWithFormat:DelPushSql
                         ,RouteId == nil ? @"":RouteId
                         ,RouteName == nil ? @"":RouteName
                         ,StopId == nil ? @"":StopId
                         ,StopName == nil ? @"":StopName
                         ,GoBack
                         ,StartTime
                         ,EndTime
                         ,WeekSun
                         ,WeekMon
                         ,WeekTue
                         ,WeekWed
                         ,WeekThu
                         ,WeekFri
                         ,WeekSat
                         ,RouteKind];
#ifdef LogOut
    NSLog(@"Delete Push Sql:%@",SqlStr);
#endif
    sqlite3 *db=nil;
    if(sqlite3_open_v2([PushDb UTF8String], &db, SQLITE_OPEN_READWRITE, NULL) == SQLITE_OK)
    {
        char *errorMsg;
        if (sqlite3_exec(db, [SqlStr UTF8String], NULL,NULL,&errorMsg) != SQLITE_OK)
        {
            NSLog(@"Sql Error:%s",errorMsg);
            NSLog(@"Sql:%@",SqlStr);
            
        }
        else
        {
            result = success;
        }
    }
    if(db) {
        sqlite3_close(db);
        db = nil;
    }
    return result;
}
+ (FavoriteResult) UpdatePushByRouteId:(NSString *)RouteId RouteName:(NSString *) RouteName StopId:(NSString *)StopId StopName:(NSString *)StopName GoBack:(int)GoBack Enable:(int)Enable StartTime:(NSString *)StartTime  EndTime:(NSString *)EndTime ArrivalTime:(int)ArrivalTime WeekSun:(int)WeekSun WeekMon:(int)WeekMon WeekTue:(int)WeekTue WeekWed:(int)WeekWed WeekThu:(int)WeekThu WeekFri:(int)WeekFri WeekSat:(int)WeekSat RouteKind:(int)RouteKind
{
    FavoriteResult result = fail;
    NSString * SqlStr = [NSString stringWithFormat:UpdatePushSql
                         ,Enable
                         ,StartTime
                         ,EndTime
                         ,ArrivalTime
                         ,WeekSun
                         ,WeekMon
                         ,WeekTue
                         ,WeekWed
                         ,WeekThu
                         ,WeekFri
                         ,WeekSat
                         ,RouteId == nil ? @"":RouteId
                         ,RouteName == nil ? @"":RouteName
                         ,StopId == nil ? @"":StopId
                         ,StopName == nil ? @"":StopName
                         ,GoBack
                         ,RouteKind];
#ifdef LogOut
    NSLog(@"Update Push Sql:%@",SqlStr);
#endif
    sqlite3 *db=nil;
    if(sqlite3_open_v2([PushDb UTF8String], &db, SQLITE_OPEN_READWRITE, NULL) == SQLITE_OK)
    {
        char *errorMsg;
        if (sqlite3_exec(db, [SqlStr UTF8String], NULL,NULL,&errorMsg) != SQLITE_OK)
        {
            NSLog(@"Sql Error:%s",errorMsg);
            NSLog(@"Sql:%@",SqlStr);
            
        }
        else
        {
            result = success;
        }
    }
    if(db) {
        sqlite3_close(db);
        db = nil;
    }
    return result;
}
+ (FavoriteResult) UpdateFavoritesByRouteId:(NSString *)RouteId RouteName:(NSString *) RouteName StopId:(NSString *)StopId StopName:(NSString *)StopName GoBack:(int)GoBack RouteKind:(int)RouteKind Seq:(int)Seq Lon:(float)Lon Lat:(float)Lat
{
    FavoriteResult result = fail;
    NSString * SqlStr = [NSString stringWithFormat:UpdateFavSql
                         ,Seq
                         ,RouteId == nil ? @"":RouteId
                         ,StopId == nil ? @"":StopId
                         ,Lon > 0 ? Lon : 0.0f
                         ,Lat > 0 ? Lat : 0.0f
                         ,RouteName == nil ? @"":RouteName
                         ,StopName == nil ? @"":StopName
                         ,GoBack

                         ,RouteKind];
#ifdef LogOut
    NSLog(@"Update Fav Sql:%@",SqlStr);
#endif
    sqlite3 *db=nil;
    if(sqlite3_open_v2([FavoriteDb UTF8String], &db, SQLITE_OPEN_READWRITE, NULL) == SQLITE_OK)
    {
        char *errorMsg;
        if (sqlite3_exec(db, [SqlStr UTF8String], NULL,NULL,&errorMsg) != SQLITE_OK)
        {
            NSLog(@"Sql Error:%s",errorMsg);
            NSLog(@"Sql:%@",SqlStr);
            
        }
        else
        {
            result = success;
        }
    }
    if(db) {
        sqlite3_close(db);
        db = nil;
    }
    return result;
}
+ (NSMutableArray *)GetFavorites
{
    NSMutableArray * Favorites = [[NSMutableArray alloc] init];
    sqlite3_stmt *statement=nil;
    sqlite3* database=nil;
    if (sqlite3_open([FavoriteDb UTF8String], &database) != SQLITE_OK) {
		sqlite3_close(database);
		NSAssert(0, @"Failed to open database");
	}
    if (sqlite3_prepare_v2(database, [SelectFavoritesSql UTF8String], -1, &statement, nil) == SQLITE_OK)
    {
        while (sqlite3_step(statement) == SQLITE_ROW)
        {
            FavoritData * favdata = [[FavoritData alloc] init];
            if(sqlite3_column_type(statement, 0) == SQLITE3_TEXT)
            {
                [favdata setRouteId: [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(statement, 0)]];
            }
            if(sqlite3_column_type(statement, 1) == SQLITE3_TEXT)
            {
                [favdata setRouteName:[[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(statement, 1)]];
            }
            if(sqlite3_column_type(statement, 2) == SQLITE3_TEXT)
            {
                [favdata setStopId: [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(statement, 2)]];
            }
            if(sqlite3_column_type(statement, 3) == SQLITE3_TEXT)
            {
                [favdata setStopName: [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(statement, 3)]];
            }
            
            [favdata setGoBack: sqlite3_column_int(statement, 4)];
            [favdata setRouteKind: sqlite3_column_int(statement, 5)];
            if(sqlite3_column_type(statement, 6) == SQLITE_FLOAT)
            {
                [favdata setLon:sqlite3_column_double(statement, 6)];
            }
            if(sqlite3_column_type(statement, 7) == SQLITE_FLOAT)
            {
                [favdata setLat:sqlite3_column_double(statement, 7)];
            }
            
            [Favorites addObject:favdata];
        }
        
    }
    if(statement)
    {
        sqlite3_finalize(statement);
        statement = nil;
    }
    
    if(database)
    {
        sqlite3_close(database);
        database = nil;
    }
    
    
    
    return Favorites;
}

+ (NSMutableArray *)GetPushes
{
    NSMutableArray * Pushes = [[NSMutableArray alloc] init];
    sqlite3_stmt *statement=nil;
    sqlite3* database=nil;
    if (sqlite3_open([PushDb UTF8String], &database) != SQLITE_OK) {
		sqlite3_close(database);
		NSAssert(0, @"Failed to open database");
	}
    if (sqlite3_prepare_v2(database, [SelectPushSql UTF8String], -1, &statement, nil) == SQLITE_OK)
    {
        while (sqlite3_step(statement) == SQLITE_ROW)
        {
            PushData * pushdata = [[PushData alloc] init];
            if(sqlite3_column_type(statement, 0) == SQLITE3_TEXT)
            {
                [pushdata setRouteId: [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(statement, 0)]];
            }
            if(sqlite3_column_type(statement, 1) == SQLITE3_TEXT)
            {
                [pushdata setRouteName:[[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(statement, 1)]];
            }
            if(sqlite3_column_type(statement, 2) == SQLITE3_TEXT)
            {
                [pushdata setStopId: [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(statement, 2)]];
            }
            if(sqlite3_column_type(statement, 3) == SQLITE3_TEXT)
            {
                [pushdata setStopName: [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(statement, 3)]];
            }
            [pushdata setGoBack: sqlite3_column_int(statement, 4)];
            [pushdata setEnable: sqlite3_column_int(statement, 5)];
            if(sqlite3_column_type(statement, 6) == SQLITE3_TEXT)
            {
                [pushdata setStartTime: [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(statement, 6)]];
            }
            if(sqlite3_column_type(statement, 7) == SQLITE3_TEXT)
            {
                [pushdata setEndtime: [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(statement, 7)]];
            }
            [pushdata setArrival: sqlite3_column_int(statement, 8)];
            [pushdata setWeekSun: sqlite3_column_int(statement, 9)];
            [pushdata setWeekMon: sqlite3_column_int(statement, 10)];
            [pushdata setWeekTue: sqlite3_column_int(statement, 11)];
            [pushdata setWeekWed: sqlite3_column_int(statement, 12)];
            [pushdata setWeekThu: sqlite3_column_int(statement, 13)];
            [pushdata setWeekFri: sqlite3_column_int(statement, 14)];
            [pushdata setWeekSat: sqlite3_column_int(statement, 15)];
            [pushdata setRouteKind: sqlite3_column_int(statement, 16)];
            [Pushes addObject:pushdata];
        }
        
    }
    if(statement)
    {
        sqlite3_finalize(statement);
        statement = nil;
    }
    
    if(database)
    {
        sqlite3_close(database);
        database = nil;
    }
    
    
    
    return Pushes;
}
- (void) UpdateFavoritesByArray:(NSArray *)Favorites
{
    
}
@end
