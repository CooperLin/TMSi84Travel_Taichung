//
//  DataManager.m
//  i84-TaichungV2
//
//  Created by TMS_APPLE on 2014/4/22.
//  Copyright (c) 2014年 ＴＭＳ 景翊科技. All rights reserved.
//

#import "DataManager.h"
#define SqlDocumentsPath [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]
#define SqlCreateTable @"CREATE TABLE IF NOT EXISTS %@(%@);"
#define SqlDropTable @"DROP TABLE IF EXISTS %@;"

//Select RouteId,RouteName,StopID,StopName,GoBack,RouteKind From Favorites Order by Seq;
#define SqlSelect @"SELECT * FROM %@;"
#define SqlUpdate @"INSERT OR REPLACE INTO %@ (%@) VALUES (%@);"
#define SqlCheckTable @"SELECT 1 FROM sqlite_master WHERE type='table' AND name='%@';"

@implementation DataManager
//Table ex:
//Favorites(RouteId TEXT ,RouteName TEXT,StopID TEXT,StopName TEXT,GoBack Integer,Seq Integer,RouteKind Integer)
+ (void) createTableByDictionary:(NSDictionary*)dictionarySource withName:(NSString*)stringTableName toDataBase:(NSString*)stringDataBaseName
{
    //括弧()內的sql
    NSMutableString * stringTableColumn = [NSMutableString new];
    
    NSArray * arrayKeys = [dictionarySource allKeys];
    for (NSString * stringKey in arrayKeys)
    {
        //非第一欄加","
        if (stringKey != [arrayKeys objectAtIndex:0])
        {
            [stringTableColumn appendString:@","];
        }
        //判斷資料種類
        NSString * stringDataType;
        id idData = [dictionarySource objectForKey:stringKey];
        if ([idData isKindOfClass:[NSString class]])
        {
            stringDataType = @"TEXT";
        }
        else
            if ([idData isKindOfClass:[NSNumber class]])
            {
                NSString * stringDataToStringValue = [(NSNumber*)idData stringValue];
                NSRange range = [stringDataToStringValue rangeOfString:@"."];
                if (range.length>0)
                {
                    stringDataType = @"FLOAT";
                }
                else
                {
                    stringDataType = @"INTERGER";
                }
            }
        [stringTableColumn appendString:[NSString stringWithFormat:@"%@ %@",stringKey,stringDataType]];
    }
    NSString * stringSqlDropTable = [NSString stringWithFormat:SqlDropTable,stringTableName];

    NSString * stringSqlCreateTable = [NSString stringWithFormat:SqlCreateTable,stringTableName,stringTableColumn];
    
    NSString * stringSql = [NSString stringWithFormat:@"%@%@",stringSqlDropTable,stringSqlCreateTable];
    
    
    sqlite3 *database = nil;
    
    if(sqlite3_open_v2([[SqlDocumentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite",stringDataBaseName]] UTF8String], &database, SQLITE_OPEN_READWRITE|SQLITE_OPEN_CREATE, NULL) == SQLITE_OK)
    {
        //NSLog(@"建立或打開資料庫");
        char *errorMsg;
        if (sqlite3_exec(database, [stringSql UTF8String], NULL,NULL,&errorMsg) == SQLITE_OK)
        {
            //            NSLog(@"寫入Log Info");
            
        }
        else
        {
            sqlite3_free(errorMsg);
            NSAssert(0,@"err: %s",errorMsg);
        }
    }
    else
    {
        NSAssert(0,@"Database Open or Create Error");
    }
    if(database) {
        sqlite3_close(database);
        database = nil;
    }
}
//
//Select RouteId,RouteName,StopID,StopName,GoBack,RouteKind From Favorites Order by Seq;2
+ (NSMutableArray *)getDataFromTable:(NSString*)stringTableName fromDataBase:(NSString*)stringDataBaseName
{
    NSMutableArray * arrayData = [[NSMutableArray alloc] init];
    sqlite3_stmt *statement=nil;
    sqlite3* database=nil;
    if (sqlite3_open([[SqlDocumentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite",stringDataBaseName]] UTF8String], &database) != SQLITE_OK)
    {
		sqlite3_close(database);
		NSAssert(0, @"Failed to open database");
	}
    if (sqlite3_prepare_v2(database, [[NSString stringWithFormat:SqlSelect,stringTableName] UTF8String], -1, &statement, nil) == SQLITE_OK)
    {
        while (sqlite3_step(statement) == SQLITE_ROW)
        {
            NSMutableDictionary * dictionary = [NSMutableDictionary new];
            int intColumnCount = sqlite3_column_count(statement);
            
            for (int i = 0; i<intColumnCount; i++)
            {
                id idObject = nil;
                NSString * stringColumnTitle = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_name(statement, i)];
                switch (sqlite3_column_type(statement, i))
                {
                    case SQLITE3_TEXT:
                    {
                        idObject = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(statement, i)];

                    }
                        break;
                    case SQLITE_INTEGER:
                    {
                        idObject = [[NSNumber alloc] initWithInt:sqlite3_column_int(statement, i)];
                        
                    }
                        break;
                    case SQLITE_FLOAT:
                    {
                        idObject = [[NSNumber alloc] initWithDouble:sqlite3_column_double(statement, i)];
                        
                    }
                        break;
                        
                    default:
                        break;
                }
                [dictionary setObject:idObject forKey:stringColumnTitle];
            }
            [arrayData addObject:dictionary];
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
    
    return arrayData;
}
+(DataManagerResult)updateDictinaryData:(NSDictionary*)dictionaryData toTable:(NSString*)stringTableName inDataBase:(NSString*)stringDataBaseName
{
    DataManagerResult result = DataManagerResultFail;
    
    NSMutableString * stringTableColumnData = [NSMutableString new];
    NSMutableString * stringTableColumnTitle = [NSMutableString new];

    NSArray * arrayKeys = [dictionaryData allKeys];
    
    for (NSString * stringKey in arrayKeys)
    {
        if (stringKey != [arrayKeys objectAtIndex:0])
        {
            [stringTableColumnTitle appendString:@","];
            [stringTableColumnData appendString:@","];
        }
        [stringTableColumnTitle appendString:stringKey];
        id idData = [dictionaryData objectForKey:stringKey] ;
        if ([idData isKindOfClass:[NSString class]])
        {
            idData = [NSString stringWithFormat:@"'%@'",(NSString*)idData];
        }
        
        [stringTableColumnData appendString:idData];

    }
    
    NSString * stringSql = [NSString stringWithFormat:SqlUpdate,stringTableName,stringTableColumnTitle,stringTableColumnData];
    
    
    sqlite3 *database = nil;

    if(sqlite3_open_v2([[SqlDocumentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite",stringDataBaseName]] UTF8String], &database, SQLITE_OPEN_READWRITE, NULL) == SQLITE_OK)
    {
        
        char *errorMsg;
        if (sqlite3_exec(database, [stringSql UTF8String], NULL,NULL,&errorMsg) != SQLITE_OK)
        {
            NSLog(@"Sql Error:%s",errorMsg);
        }
        else
        {
            result = DataManagerResultSuccess;
        }
    }
    if(database) {
        sqlite3_close(database);
        database = nil;
    }
    return result;
}
+(DataManagerResult)checkTable:(NSString*)stringTableName fromDataBase:(NSString*)stringDataBaseName
{
    DataManagerResult result = DataManagerResultNull;
    sqlite3_stmt * statement = nil;
    sqlite3 * database = nil;
    if (sqlite3_open([[SqlDocumentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite",stringDataBaseName]] UTF8String], &database) == SQLITE_OK)
    {
	
        if (sqlite3_prepare_v2(database, [[NSString stringWithFormat:SqlCheckTable,stringTableName] UTF8String], -1, &statement, nil) == SQLITE_OK)
        {
            if (sqlite3_column_count(statement)>0)
            {
                result = DataManagerResultExist;
            }
            
            if(statement)
            {  
                sqlite3_finalize(statement);
                statement = nil;
            }
        }
    }
    
    
    if(database)
    {
        sqlite3_close(database);
        database = nil;
    }
    
    return result;
}
@end
