//
//  RequestManager.h
//  TakeAirplane
//
//  Created by TMS_APPLE on 2014/5/30.
//  Copyright (c) 2014年 Joe. All rights reserved.
//

#define useXML
#import "NSNull+JSON.h"
#import <Foundation/Foundation.h>
#import "ASINetworkQueue.h"
#import "ASIHTTPRequest.h"
#import "ShareTools.h"
#ifdef useXML
#import "GDataXMLNode.h"
#endif
@protocol RequestManagerDelegate<NSObject>
@optional
-(void)requestManagerStartActivityIndicator;
-(void)requestManagerStopActivityIndicator;
-(void)requestManager:(id)requestManager fileDownloadedPath:(NSString*)path withKey:(NSString*)key;
-(void)requestManager:(id)requestManager returnXmlDoc:(GDataXMLDocument*)gdataXmlDoc withKey:(NSString*)key;
-(void)requestManager:(id)requestManager returnJSONSerialization:(NSJSONSerialization*)jsonSerialization withKey:(NSString*)key;
-(void)requestManager:(id)requestManager returnString:(NSString*)stringResponse withKey:(NSString*)key;
-(void)requestManager:(id)requestManager returnNoDataWithKey:(NSString*)key;
-(void)requestManager:(id)requestManager returnInputErrorWithKey:(NSString*)key;


@required
@end

typedef enum _RequestDataType
{
    RequestDataTypeXML = 1,
    RequestDataTypeJson = 2,
    RequestDataTypeString = 3,
}
RequestDataType;

@interface RequestManager : NSObject
@property (strong, nonatomic) id<RequestManagerDelegate>delegate;
-(instancetype)initWithMaxRequestsQuantity:(NSUInteger)quantity;
-(instancetype)initWithRequestTimeout:(NSUInteger)timeout;

- (void) addRequestWithKey:(NSString*)key andUrl:(NSString*)url byType:(RequestDataType)type;
- (void) addFileRequestWithKey:(NSString*)key andUrl:(NSString*)url savedFileName:(NSString*)fileName;

@end
