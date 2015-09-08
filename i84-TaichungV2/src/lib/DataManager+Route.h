//
//  DataManager+Route.h
//  i84-TaichungV2
//
//  Created by TMS_APPLE on 2014/4/28.
//  Copyright (c) 2014年 ＴＭＳ 景翊科技. All rights reserved.
//

#import "DataManager.h"

@interface DataManager (Route)
typedef enum _RouteDataType
{
    RouteDataTypeCityRoutes = 1,
    RouteDataTypeHighwayRoutes = 2,
    RouteDataTypeCityProviders = 3,
    RouteDataTypeHighwayProviders = 4
	
} RouteDataType;
//get Route Data
+(NSMutableArray*)getDataByType:(RouteDataType)routeDataType;

+(BOOL)checkUpdatedTodayByType:(RouteDataType)routeDataType;

//arrayData structure
//[{id:key,id2:key2,...},{},...]
+(DataManagerResult)updateTableFromArray:(NSArray*)arrayData byType:(RouteDataType)routeDataType;


typedef enum _RouteDataColumnType
{
    RouteDataColumnTypeRouteID = 1,
    RouteDataColumnTypeRouteName = 2,
	
} RouteDataColumnType;
//for nearStopViewController
+(NSArray*)selectRouteDataKeyWord:(NSString*)stringKeyWord byColumnTitle:(RouteDataColumnType)routeDataColumnType fromTableType:(RouteDataType)routeDataType;

@end
