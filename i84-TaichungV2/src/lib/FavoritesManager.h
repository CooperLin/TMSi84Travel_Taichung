//
//  FavoritesManager.h
//  i84-TaichungV2
//
//  Created by ＴＭＳ 景翊科技 on 2014/2/26.
//  Copyright (c) 2014年 ＴＭＳ 景翊科技. All rights reserved.
//

#import <Foundation/Foundation.h>



typedef enum
{
    success
    ,fail
    ,hased
} FavoriteResult;

@protocol PushSynchronousDelegate <NSObject>

- (void) PushSynchronousFinish;

@end

@interface FavoritesManager : NSObject
{
    id<PushSynchronousDelegate> delegate;
    int intQueryFail;
}
@property int intQueryFail;
@property id<PushSynchronousDelegate> delegate;

+ (void) CreateTable;
//+ (void) ImportOldSqlite;
- (void) ImportOldPush;
- (void) SendSynchronousRequest;

+ (FavoriteResult) AddToFavoritesByRouteId:(NSString *)RouteId RouteName:(NSString *) RouteName StopId:(NSString *)StopId StopName:(NSString *)StopName GoBack:(int)GoBack RouteKind:(int)RouteKind Lon:(float)Lon Lat:(float)Lat;
+ (FavoriteResult) DeleteFavoritesByRouteId:(NSString *)RouteId RouteName:(NSString *) RouteName StopId:(NSString *)StopId StopName:(NSString *)StopName GoBack:(int)GoBack RouteKind:(int)RouteKind;
+ (FavoriteResult) AddToPushsByRouteId:(NSString *)RouteId RouteName:(NSString *) RouteName StopId:(NSString *)StopId StopName:(NSString *)StopName GoBack:(int)GoBack RouteKind:(int)RouteKind;
+ (FavoriteResult) DeletePushsByRouteId:(NSString *)RouteId RouteName:(NSString *) RouteName StopId:(NSString *)StopId StopName:(NSString *)StopName GoBack:(int)GoBack StartTime:(NSString *)StartTime  EndTime:(NSString *)EndTime WeekSun:(int)WeekSun WeekMon:(int)WeekMon WeekTue:(int)WeekTue WeekWed:(int)WeekWed WeekThu:(int)WeekThu WeekFri:(int)WeekFri WeekSat:(int)WeekSat RouteKind:(int)RouteKind;
+ (FavoriteResult) UpdatePushByRouteId:(NSString *)RouteId RouteName:(NSString *) RouteName StopId:(NSString *)StopId StopName:(NSString *)StopName GoBack:(int)GoBack Enable:(int)Enable StartTime:(NSString *)StartTime  EndTime:(NSString *)EndTime ArrivalTime:(int)ArrivalTime WeekSun:(int)WeekSun WeekMon:(int)WeekMon WeekTue:(int)WeekTue WeekWed:(int)WeekWed WeekThu:(int)WeekThu WeekFri:(int)WeekFri WeekSat:(int)WeekSat RouteKind:(int)RouteKind;

+ (FavoriteResult) UpdateFavoritesByRouteId:(NSString *)RouteId RouteName:(NSString *) RouteName StopId:(NSString *)StopId StopName:(NSString *)StopName GoBack:(int)GoBack RouteKind:(int)RouteKind Seq:(int)Seq Lon:(float)Lon Lat:(float)Lat;

+ (NSMutableArray *)GetFavorites;

+ (NSMutableArray *)GetPushes;

- (void) UpdateFavoritesByArray:(NSArray *)Favorites;


@end
