//
//  DataManager+Route.m
//  i84-TaichungV2
//
//  Created by TMS_APPLE on 2014/4/28.
//  Copyright (c) 2014年 ＴＭＳ 景翊科技. All rights reserved.
//

#import "DataManager+Route.h"
#define KeyDataBaseRoutes @"Routes"
#define KeyHighwayRoutes @"HighwayRoutes"
#define KeyHighwayProviders @"HighwayProviders"
#define KeyCityRoutes @"CityRoutes"
#define KeyCityProviders @"CityProviders"

//departureZh,destinationZh,type,ddesc,ProviderId,gxcode,nameZh(route),ID(route)
#define ColumnRouteID @"ID"
#define ColumnRouteName @"nameZh"

#define SqlDocumentsPath [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]
#define sqlRouteData @"SELECT * FROM %@ WHERE %@='%@'"

@implementation DataManager (Route)
+(NSMutableArray *)getDataByType:(RouteDataType)routeDataType
{
    NSString * stringKey = [DataManager keyByType:routeDataType];
    if ([DataManager checkUpdatedTodayByType:routeDataType])
    {
        return [DataManager getDataFromTable:stringKey fromDataBase:KeyDataBaseRoutes];
    }
    return nil;
}
+(BOOL)checkUpdatedTodayByType:(RouteDataType)routeDataType
{
    BOOL boolCheckResult = NO;
    if ([DataManager checkTableExistByType:routeDataType])
    {
        NSString * stringKey = [DataManager keyByType:routeDataType];
        NSDateFormatter * dateFormatter = [NSDateFormatter new];
        [dateFormatter setDateFormat:@"YYYYMMdd"];
        NSString * stringDate = [dateFormatter stringFromDate:[NSDate date]];
        boolCheckResult = [[[NSUserDefaults standardUserDefaults]objectForKey:stringKey]isEqualToString:stringDate];
    }
    return boolCheckResult;
}
+(DataManagerResult)updateTableFromArray:(NSArray*)arrayData byType:(RouteDataType)routeDataType
{
    NSString * stringKey = [DataManager keyByType:routeDataType];
    //將資料存入sqlite

    
    if ([DataManager checkUpdatedTodayByType:routeDataType])
    {
        return DataManagerResultExist;
    }
    [DataManager createTableByDictionary:[arrayData objectAtIndex:0] withName:stringKey toDataBase:KeyDataBaseRoutes];

    for (id idDictionary in arrayData)
    {
        if([DataManager updateDictinaryData:(NSDictionary*)idDictionary toTable:stringKey inDataBase:KeyDataBaseRoutes] == DataManagerResultFail)
        {
            return DataManagerResultFail;
        }
    }
    NSDateFormatter * dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"YYYYMMdd"];
    NSString * stringDate = [dateFormatter stringFromDate:[NSDate date]];
    [[NSUserDefaults standardUserDefaults]setObject:stringDate forKey:stringKey];
    [[NSUserDefaults standardUserDefaults]synchronize];
    
    return DataManagerResultSuccess;
}
+(NSString*)keyByType:(RouteDataType)routeDataType
{
    NSString * stringKey;
    
    switch (routeDataType)
    {
        case RouteDataTypeCityRoutes:
        {
            stringKey = KeyCityRoutes;
        }
            break;
        case RouteDataTypeCityProviders:
        {
            stringKey = KeyCityProviders;
        }
            break;
        case RouteDataTypeHighwayRoutes:
        {
            stringKey = KeyHighwayRoutes;
        }
            break;
        case RouteDataTypeHighwayProviders:
        {
            stringKey = KeyHighwayProviders;
        }
            break;
            
        default:
            break;
    }
    return stringKey;
}

+(NSArray*)selectRouteDataKeyWord:(NSString*)stringKeyWord byColumnTitle:(RouteDataColumnType)routeDataColumnType fromTableType:(RouteDataType)routeDataType
{
    NSString * stringTable;
    switch (routeDataType)
    {
        case RouteDataTypeHighwayRoutes:
            stringTable = KeyHighwayRoutes;
            break;
        case RouteDataTypeCityRoutes:
            stringTable = KeyCityRoutes;
            break;
            
        default:
            break;
    }
    
    NSString * stringColumn;
    switch (routeDataColumnType)
    {
        case RouteDataColumnTypeRouteID:
            stringColumn = ColumnRouteID;
            break;
        case RouteDataColumnTypeRouteName:
            stringColumn = ColumnRouteName;
            break;
            
        default:
            break;
    }
    NSMutableArray * arrayData = [[NSMutableArray alloc] init];
    sqlite3_stmt *statement = nil;
    sqlite3* database = nil;
    if (sqlite3_open([[SqlDocumentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Routes.sqlite"]] UTF8String], &database) != SQLITE_OK)
    {
		sqlite3_close(database);
		NSAssert(0, @"Failed to open database");
	}
    if (sqlite3_prepare_v2(database, [[NSString stringWithFormat:sqlRouteData,stringTable,stringColumn,stringKeyWord] UTF8String], -1, &statement, nil) == SQLITE_OK)
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
    
    if (arrayData.count>0)
    {
        return arrayData;
    }
    return nil;

}
+(BOOL)checkTableExistByType:(RouteDataType)routeDataType
{
    return [DataManager checkTable:[DataManager keyByType:routeDataType] fromDataBase:KeyDataBaseRoutes];
}
@end
