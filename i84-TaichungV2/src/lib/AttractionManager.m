//
//  AttractionManager.m
//  i84-TaichungV2
//
//  Created by ＴＭＳ 景翊科技 on 2014/4/3.
//  Copyright (c) 2014年 ＴＭＳ 景翊科技. All rights reserved.
//

#import "AttractionManager.h"
#import "sqlite3.h"
#import "DataTypes.h"
#import "ShareTools.h"
#import <SystemConfiguration/SCNetworkReachability.h>
#include <netinet/in.h>
#import <CFNetwork/CFNetwork.h>
#import "ASIHTTPRequest.h"
#import "PushManager.h"
#import "AppDelegate.h"

@interface AttractionManager ()
{
    NSString * NewVar;
    NSString * NewVarDownloadUrl;
}
@end

@implementation AttractionManager

#define TopAttractionCheckAPI @"/iTravel/ItravelAPI/ExpoAPI/GetSQLiteVer.aspx?Type=Topattraction&Ver=%@"

#define AttractionDb [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"TopAttraction.sqlite"]
#define TempAttractionDb [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"TempTopAttraction.sqlite"]
#define StoreDb [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"StoreLandmarkDb.sqlite"]

#define SelectHotLandmarkSql @"Select top_Name,Address,lon,lat from Topattraction where not (top_Name = '')  and not (Address = '') and lon > 0.0 and lat > 0.0 and not (top_id = '') order by top_id desc;"
#define SelectLandmarkByKeyWordSql @"Select top_Name,Address,lon,lat from Topattraction where not (top_Name = '')  and not (Address = '') and lon > 0.0 and lat > 0.0 and top_Name like '%@' union Select top_Name,Address,lon,lat from Topattraction where not (top_Name = '')  and not (Address = '') and lon > 0.0 and lat > 0.0 and address like '%@';"
#define SelectStoreSql @"Select Name,Address,Lon,Lat from StoreLandmark;"
#define CreateStoreTableSql @"CREATE TABLE IF NOT EXISTS StoreLandmark(Name TEXT ,Address TEXT,Lon float,Lat float);"
#define StoreIsExistsSql @"Select 1 from StoreLandmark Where Name = '%@';"
#define InsertStoreSql @"insert into StoreLandmark(Name,Address,Lon,Lat) Values('%@','%@',%f,%f);Update StoreLandmark set Address = '%@',Lon=%f,Lat=%f where Name = '%@';"

+ (NSString *) GetVerStr
{
    NSUserDefaults  * userDefault = [NSUserDefaults standardUserDefaults];
    if([userDefault objectForKey:@"AttractionVersion"])
    {
        return [userDefault objectForKey:@"AttractionVersion"];
    }
    return @"";
}
- (void) CheckOrCopyDb
{
    NSFileManager * fm = [NSFileManager defaultManager];
    if(![fm fileExistsAtPath:AttractionDb])
    {
        NSString * defaultDb = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"TopAttraction.sqlite"];
        [fm copyItemAtPath:defaultDb toPath:AttractionDb error:nil];
    }
    [self SendCheckDBRequest];
}
+ (NSMutableArray *) ReadHopLandmark
{
    NSMutableArray * LandMarks = [[NSMutableArray alloc] init];
    sqlite3_stmt *statement=nil;
    sqlite3* database=nil;
    if (sqlite3_open([AttractionDb UTF8String], &database) != SQLITE_OK) {
		sqlite3_close(database);
		NSAssert(0, @"Failed to open database");
	}
    if (sqlite3_prepare_v2(database, [SelectHotLandmarkSql UTF8String], -1, &statement, nil) == SQLITE_OK)
    {
        while (sqlite3_step(statement) == SQLITE_ROW)
        {
            LandMark * lm = [[LandMark alloc] init];
            if(sqlite3_column_type(statement, 0) == SQLITE3_TEXT)
            {
                [lm setName: [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(statement, 0)]];
            }
            if(sqlite3_column_type(statement, 1) == SQLITE3_TEXT)
            {
                [lm setAddress:[[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(statement, 1)]];
            }
            if(sqlite3_column_type(statement, 2) == SQLITE3_TEXT)
            {
                [lm setLon: [[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 2)] floatValue] ];
            }
            if(sqlite3_column_type(statement, 3) == SQLITE3_TEXT)
            {
                [lm setLat: [[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 3)] floatValue] ];
            }
            [LandMarks addObject:lm];
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
    
    
    
    return LandMarks;
}
+ (NSMutableArray *) SearchLandMark:(NSString *)KeyWord
{
    NSMutableArray * LandMarks = [[NSMutableArray alloc] init];
    
    NSMutableString * KeyWordSb = [[NSMutableString alloc] init];
    [KeyWordSb appendString:@"%"];
    [KeyWordSb appendString:KeyWord];
    [KeyWordSb appendString:@"%"];
    
    NSString * SelectSql = [NSString stringWithFormat:SelectLandmarkByKeyWordSql,KeyWordSb,KeyWordSb ];
    
    
    sqlite3_stmt *statement=nil;
    sqlite3* database=nil;
    if (sqlite3_open([AttractionDb UTF8String], &database) != SQLITE_OK) {
		sqlite3_close(database);
		NSAssert(0, @"Failed to open database");
	}
    if (sqlite3_prepare_v2(database, [SelectSql UTF8String], -1, &statement, nil) == SQLITE_OK)
    {
        while (sqlite3_step(statement) == SQLITE_ROW)
        {
            LandMark * lm = [[LandMark alloc] init];
            if(sqlite3_column_type(statement, 0) == SQLITE3_TEXT)
            {
                [lm setName: [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(statement, 0)]];
            }
            if(sqlite3_column_type(statement, 1) == SQLITE3_TEXT)
            {
                [lm setAddress:[[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(statement, 1)]];
            }
            if(sqlite3_column_type(statement, 2) == SQLITE3_TEXT)
            {
                [lm setLon: [[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 2)] floatValue] ];
            }
            if(sqlite3_column_type(statement, 3) == SQLITE3_TEXT)
            {
                [lm setLat: [[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 3)] floatValue] ];
            }
            [LandMarks addObject:lm];
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
    
    
    
    return LandMarks;
}
+ (NSMutableArray *) ReadStoreLandmark
{
    NSMutableArray * LandMarks = [[NSMutableArray alloc] init];
    NSFileManager * fm = [NSFileManager defaultManager];
    if(![fm fileExistsAtPath:StoreDb])
    {
        return LandMarks;
    }
    sqlite3_stmt *statement=nil;
    sqlite3* database=nil;
    if (sqlite3_open([StoreDb UTF8String], &database) != SQLITE_OK) {
		sqlite3_close(database);
		NSAssert(0, @"Failed to open database");
	}
    if (sqlite3_prepare_v2(database, [SelectStoreSql UTF8String], -1, &statement, nil) == SQLITE_OK)
    {
        while (sqlite3_step(statement) == SQLITE_ROW)
        {
            LandMark * lm = [[LandMark alloc] init];
            if(sqlite3_column_type(statement, 0) == SQLITE3_TEXT)
            {
                [lm setName: [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(statement, 0)]];
            }
            if(sqlite3_column_type(statement, 1) == SQLITE3_TEXT)
            {
                [lm setAddress:[[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(statement, 1)]];
            }
            [lm setLon: sqlite3_column_double(statement, 2) ];
            [lm setLat: sqlite3_column_double(statement, 3) ];
            [LandMarks addObject:lm];
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
    
    
    return LandMarks;
}
+ (AttractionResult) AddStoreLandmarkByName:(NSString *)LandMarkName Address:(NSString *)Address Lon:(float)lon Lat:(float)lat
{
    AttractionResult result = AttractionFail;
    NSFileManager * fm = [NSFileManager defaultManager];
    if(![fm fileExistsAtPath:StoreDb])
    {
        sqlite3 *db=nil;
        
        if(sqlite3_open_v2([StoreDb UTF8String], &db, SQLITE_OPEN_READWRITE|SQLITE_OPEN_CREATE, NULL) == SQLITE_OK)
        {
            //NSLog(@"建立或打開資料庫");
            char *errorMsg;
            if (sqlite3_exec(db, [CreateStoreTableSql UTF8String], NULL,NULL,&errorMsg) == SQLITE_OK)
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
    NSString * IsExistsSql = [NSString stringWithFormat:StoreIsExistsSql,LandMarkName];
    NSString * SqlStr = [NSString stringWithFormat:InsertStoreSql,LandMarkName,Address,lon,lat,Address,lon,lat,LandMarkName];
    
    sqlite3 *db=nil;
    sqlite3_stmt *statement=nil;
    if(sqlite3_open_v2([StoreDb UTF8String], &db, SQLITE_OPEN_READWRITE, NULL) == SQLITE_OK)
    {
        if (sqlite3_prepare_v2(db, [IsExistsSql UTF8String], -1, &statement, nil) == SQLITE_OK)
        {
            if (sqlite3_step(statement) == SQLITE_ROW)
            {
                int count = sqlite3_column_int(statement, 0);
                if(count > 0)
                {
                    result = AttractionHased;
                }
            }
            
        }
        if(statement)
        {
            sqlite3_finalize(statement);
            statement = nil;
        }
        
        if(result != AttractionHased)
        {
            char *errorMsg;
            if (sqlite3_exec(db, [SqlStr UTF8String], NULL,NULL,&errorMsg) != SQLITE_OK)
            {
                NSLog(@"Sql Error:%s",errorMsg);
                NSLog(@"Sql:%@",SqlStr);
            }
            else
            {
                result = AttractionSuccess;
            }
        }
    }
    if(db) {
        sqlite3_close(db);
        db = nil;
    }
    
    
    return result;
}
#pragma mark ASIHTTP
- (void) SendCheckDBRequest
{
    if(![ShareTools connectedToNetwork])
    {
        if([[NSThread currentThread] isMainThread])
        {
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:nil message:@"請先開啟網路或網路狀態不穩" delegate:nil cancelButtonTitle:@"確定" otherButtonTitles:nil, nil];
            [alert show];
        }
    }

    
    
    NSString * urlstr = [NSString stringWithFormat:@"%@%@",APIServer,TopAttractionCheckAPI];
    urlstr = [NSString stringWithFormat:urlstr,[AttractionManager GetVerStr]];
    
    NSURL * url = [NSURL URLWithString:[urlstr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSLog(@"Search Address Url:%@",url);
    
    ASIHTTPRequest * SearchRequest = [ASIHTTPRequest requestWithURL:url];
    [SearchRequest setDelegate:self];
    [SearchRequest setDidFinishSelector:@selector(CheckDBRequestFinish:)];
    [SearchRequest startAsynchronous];
}
- (void) SendDownloadNewDBRequest
{
    if(![ShareTools connectedToNetwork])
    {
        return;
    }

    ASIHTTPRequest * DownloadDbRequest = [[ASIHTTPRequest alloc] initWithURL:[[NSURL alloc] initWithString:NewVarDownloadUrl]];
    [DownloadDbRequest setDelegate:self];
    [DownloadDbRequest setDownloadDestinationPath:TempAttractionDb];
    [DownloadDbRequest setDidFinishSelector:@selector(DownloadNewDBRequestFinish:)];
    [DownloadDbRequest startAsynchronous];
}
- (void) CheckDBRequestFinish:(ASIHTTPRequest *)Request
{
    NSString * Response = [Request responseString];
    if(![Response hasPrefix:@"Err"])
    {
        NSArray * Values = [Response componentsSeparatedByString:@",_"];
        if([(NSString *)[Values objectAtIndex:0] compare:@"1"] == 0)
        {
            //需要更新
            NewVar = [Values objectAtIndex:1];
            NewVarDownloadUrl = [Values objectAtIndex:2];
            [self SendDownloadNewDBRequest];
        }
    }
}
- (void) DownloadNewDBRequestFinish:(ASIHTTPRequest *)Request
{
    sqlite3_stmt *stm=nil;
    sqlite3 *db=nil;
    if (sqlite3_open([TempAttractionDb UTF8String], &db) != SQLITE_OK) {
        sqlite3_close(db);
        NSAssert(0, @"Open Database Failed");
    }
    BOOL DbIsOk = NO;
    
    if (sqlite3_prepare_v2(db, [@"Select Count(*) From Topattraction;" UTF8String], -1, &stm, nil) == SQLITE_OK)
    {
        while (sqlite3_step(stm) == SQLITE_ROW)
        {
            int count = sqlite3_column_int(stm, 0);
            if(count > 0)DbIsOk = YES;
            else DbIsOk = NO;
        }
    }
    if(stm)
    {
        sqlite3_finalize(stm);
        stm = nil;
    }
    if(db)
    {
        sqlite3_close(db);
    }
    if(DbIsOk)
    {
        NSError *error;
        
        if([[NSFileManager defaultManager] fileExistsAtPath:AttractionDb])
            [[NSFileManager defaultManager] removeItemAtPath:AttractionDb error:&error];
        
        [[NSFileManager defaultManager] copyItemAtPath:TempAttractionDb toPath:AttractionDb error:&error];
        NSUserDefaults  * userDefault = [NSUserDefaults standardUserDefaults];
        [userDefault setObject:NewVar forKey:@"AttractionVersion"];
        [userDefault synchronize];
        NSLog(@"Attraction Updata Finish.New Version:%@",NewVar);
        
    }
    else
    {
        
    }
    if(stm)
    {
        sqlite3_finalize(stm);
        stm = nil;
    }
    if(db)
    {
        sqlite3_close(db);
    }
}


@end
