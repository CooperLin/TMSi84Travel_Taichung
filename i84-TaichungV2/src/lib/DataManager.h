//
//  DataManager.h
//  i84-TaichungV2
//
//  Created by TMS_APPLE on 2014/4/22.
//  Copyright (c) 2014年 ＴＭＳ 景翊科技. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "sqlite3.h"
//#import "DataTypes.h"
//#import "ShareTools.h"
//#import <SystemConfiguration/SCNetworkReachability.h>
//#include <netinet/in.h>
//#import <CFNetwork/CFNetwork.h>
//#import "ASIHTTPRequest.h"
//#import "PushManager.h"
typedef enum _DataManagerResult
{
    DataManagerResultNull = 0
    ,DataManagerResultSuccess = 1
    ,DataManagerResultFail = 2
    ,DataManagerResultExist = 3
} DataManagerResult;


@interface DataManager : NSObject
+ (void) createTableByDictionary:(NSDictionary*)dictionarySource withName:(NSString*)tableName toDataBase:(NSString*)dataBaseName;
+ (NSMutableArray *)getDataFromTable:(NSString*)tableName fromDataBase:(NSString*)dataBaseName;
+(DataManagerResult)updateDictinaryData:(NSDictionary*)dictionaryData toTable:(NSString*)tableName inDataBase:(NSString*)dataBaseName;
+(DataManagerResult)checkTable:(NSString*)tableName fromDataBase:(NSString*)dataBaseName;

@end
