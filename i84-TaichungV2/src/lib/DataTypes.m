//
//  DataTypes.m
//  i84-TaichungV2
//
//  Created by ＴＭＳ 景翊科技 on 2014/2/27.
//  Copyright (c) 2014年 ＴＭＳ 景翊科技. All rights reserved.
//

#import "DataTypes.h"

@implementation DataTypes

@end

@implementation FavoritData
@synthesize RouteId,RouteName,StopId,StopName,GoBack,Arrival,Arrival2,RouteKind,Destination,Lon,Lat;

-(id) init
{
    self = [super init];
    if(self)
    {
        Arrival = -5;//讀取中
        
    }
    return self;
    
}


@end

@implementation PushData
@synthesize RouteId,RouteName,StopId,StopName,GoBack,Enable,StartTime,Endtime,Arrival,WeekSun,WeekMon,WeekTue,WeekWed,WeekThu,WeekFri,WeekSat,RouteKind,Destination;


@end
@implementation PlanScheme
@synthesize SchemeKind,Arrival,Arrival2,Trips,SumTravelMins;

- (id) init
{
    self = [super init];
    if(self)
    {
        Arrival = -5;
        SumTravelMins = -1;
        Trips = [[NSMutableArray alloc] init];
    }
    
    return self;
}

@end

@implementation Trip
@synthesize TripKind;
@synthesize FromStop,FromLon,FromLat,FromStopId,FromStopGoBack,ToStop,ToLon,ToLat,Desc,travelMin,ticket,RouteKind,RouteName,Destination,RouteId;
//,FootDistance,RouteKind,TravelStopCount,ArrivalStopId,ArrivalStopName,RouteId,RouteName,GoBack,StopId,StopName,Lon,Lat,ArrivalLon,ArrivalLat;


@end

@implementation LandMark
@synthesize Id,Name,Lon,Lat,Address,title,subtitle,coordinate;
- (id) copyWithZone:(NSZone *)zone
{
    LandMark * copyobj = [[[self class] alloc] init];
    if(copyobj)
    {
        if(self.title)
        {
            [copyobj setTitle:[self.title copy]];
        }
        if(self.subtitle)
        {
            [copyobj setSubtitle:[self.subtitle copy]];
        }
        if(self.Id)
        {
            [copyobj setId:[self.Id copy]];
        }
        if(self.Name)
        {
            [copyobj setName:[self.Name copy]];
        }
        copyobj.Lon = self.Lon;
        copyobj.Lat = self.Lat;
        copyobj.coordinate = CLLocationCoordinate2DMake(self.Lat, self.Lon);
        
    }
    return copyobj;
}

@end
