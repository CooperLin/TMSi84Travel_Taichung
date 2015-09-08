//
//  DataTypes.h
//  i84-TaichungV2
//
//  Created by ＴＭＳ 景翊科技 on 2014/2/27.
//  Copyright (c) 2014年 ＴＭＳ 景翊科技. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

@interface DataTypes : NSObject

@end
@interface FavoritData : NSObject
{
    NSString * RouteId;
    NSString * RouteName;
    NSString * StopId;
    NSString * StopName;
    int GoBack;
    int Arrival;
    NSString * Arrival2;
    int RouteKind;
    NSString * Destination;
    NSString * Departure;
    float Lon;
    float Lat;
}
@property (nonatomic,retain)    NSString * RouteId;
@property (nonatomic,retain)    NSString * RouteName;
@property (nonatomic,retain)    NSString * StopId;
@property (nonatomic,retain)    NSString * StopName;
@property int GoBack;
@property int Arrival;
@property (nonatomic,retain)    NSString * Arrival2;
@property int RouteKind;
@property (nonatomic,retain)    NSString * Destination;
@property (nonatomic,retain)    NSString * Departure;
@property float Lon;
@property float Lat;

@end

@interface PushData : NSObject
{
    NSString * RouteId;
    NSString * RouteName;
    NSString * StopId;
    NSString * StopName;
    int GoBack;
    int Enable;
    NSString * StartTime;
    NSString * Endtime;
    int Arrival;
    int WeekSun;
    int WeekMon;
    int WeekTue;
    int WeekWed;
    int WeekThu;
    int WeekFri;
    int WeekSat;
    int RouteKind;
    NSString * Destination;
}
@property (nonatomic,retain)    NSString * RouteId;
@property (nonatomic,retain)    NSString * RouteName;
@property (nonatomic,retain)    NSString * StopId;
@property (nonatomic,retain)    NSString * StopName;
@property int GoBack;
@property int Enable;
@property (nonatomic,retain)    NSString * StartTime;
@property (nonatomic,retain)    NSString * Endtime;
@property int Arrival;
@property int WeekSun;
@property int WeekMon;
@property int WeekTue;
@property int WeekWed;
@property int WeekThu;
@property int WeekFri;
@property int WeekSat;
@property int RouteKind;
@property (nonatomic,retain)    NSString * Destination;
@end
typedef enum
{
    FootDirect = 0//步行直達
    ,OneStepBus = 1//公車直達
    ,TwoStepBus = 2//公車轉乘
    ,OneStepTrain = 3//火車直達
    ,TrainToBus = 4//火車轉公車
    ,BusToTrain = 5//公車轉火車

} SchemeKind;
typedef enum
{
    EPoint = -1 //終點
    ,Foot = 0 //步行
    ,ByBus = 1 //搭乘公車
    ,ByTrain = 2//搭乘火車
    
} TripKind;


@interface PlanScheme :NSObject
{
    SchemeKind SchemeKind;
    int Arrival;
    NSString * Arrival2;
    NSMutableArray * Trips;
    int SumTravelMins;
}
@property SchemeKind SchemeKind;
@property int Arrival;
@property (nonatomic,retain) NSString * Arrival2;
@property (nonatomic,retain) NSMutableArray * Trips;
@property int SumTravelMins;

@end
@interface Trip : NSObject
{
    TripKind TripKind;
    NSString * FromStop;
    NSString * FromStopId;
    int FromStopGoBack;
    NSString * ToStop;
    float FromLon;
    float FromLat;
    float ToLon;
    float ToLat;
    NSString * Desc;
    int travelMin;
    int ticket;
    int RouteKind;
    NSString * RouteName;
    NSString * RouteId;
    NSString * Destination;
    
    /*
    int FootDistance;
    int RouteKind;
    int TravelStopCount;
    NSString * ArrivalStopId;
    NSString * ArrivalStopName;
    float ArrivalLon,ArrivalLat;
    NSString * RouteId;
    NSString * RouteName;
    int GoBack;
    NSString * StopId;
    NSString * StopName;
    float Lon,Lat;
    */
}
@property     TripKind TripKind;
@property (nonatomic,retain) NSString * FromStop;
@property (nonatomic,retain) NSString * FromStopId;
@property int FromStopGoBack;
@property (nonatomic,retain) NSString * ToStop;
@property     float FromLon;
@property     float FromLat;
@property     float ToLon;
@property     float ToLat;
@property (nonatomic,retain) NSString * Desc;
@property     int travelMin;
@property     int ticket;
@property     int RouteKind;
@property (nonatomic,retain) NSString * RouteName;
@property (nonatomic,retain) NSString * RouteId;
@property (nonatomic,retain) NSString * Destination;

/*
@property     int FootDistance;
@property     int RouteKind;
@property     int TravelStopCount;
@property (nonatomic,retain)        NSString * ArrivalStopId;
@property (nonatomic,retain)        NSString * ArrivalStopName;
@property float ArrivalLon;
@property float ArrivalLat;
@property (nonatomic,retain)    NSString * RouteId;
@property (nonatomic,retain)    NSString * RouteName;
@property int GoBack;
@property (nonatomic,retain)    NSString * StopId;
@property (nonatomic,retain)    NSString * StopName;
@property float Lon;
@property float Lat;
*/
@end
@interface LandMark : NSObject <MKAnnotation,NSCopying>
{
    NSString * Id;
    NSString * Name;
    NSString * Address;
    
    float Lon,Lat;
    NSString *subtitle;
	NSString *title;
    CLLocationCoordinate2D coordinate;
}
@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic,copy) NSString *subtitle;
@property (nonatomic,copy) NSString *title;
@property (nonatomic,retain) NSString * Id;
@property (nonatomic,retain) NSString * Name;
@property (nonatomic,retain) NSString * Address;
@property float Lon;
@property float Lat;

@end
