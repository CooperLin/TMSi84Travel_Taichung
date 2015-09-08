//
//  PlanSchemeView.m
//  i84-TaichungV2
//
//  Created by ＴＭＳ 景翊科技 on 2014/3/10.
//  Copyright (c) 2014年 ＴＭＳ 景翊科技. All rights reserved.
//

#import "PlanSchemeView.h"
#import "DataTypes.h"
#import "TripCell.h"

@interface PlanSchemeView()
{
    UIView * BordersV;
    UITableView * TripTv;
}
@end

@implementation PlanSchemeView

- (id) init
{
    self = [super initWithFrame:CGRectMake(0, 0, 320, 44)];
    if (self) {
        [self setBackgroundColor:[UIColor clearColor]];
        BordersV = [[UIView alloc] initWithFrame:CGRectMake(2, 2, 316, 40)];
        [BordersV setBackgroundColor:[UIColor grayColor]];
        TripTv = [[UITableView alloc] initWithFrame:CGRectMake(5, 4, 310, 36)];
        [TripTv setBackgroundColor:[UIColor whiteColor]];
        [TripTv setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        [TripTv setDataSource:self];
        [TripTv setDelegate:self];
        [TripTv setScrollEnabled:NO];
        
        [self addSubview:BordersV];
        [self addSubview:TripTv];
        
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void) setFrame:(CGRect)frame
{
    [super setFrame:frame];
    CGRect Borderframe = BordersV.frame;
    Borderframe.size.width = frame.size.width - 4;
    Borderframe.size.height = frame.size.height - 4;
    [BordersV setFrame:Borderframe];
    CGRect Tvframe = TripTv.frame;
    Tvframe.size.width = frame.size.width - 10;
    Tvframe.size.height = frame.size.height - 8;
    [TripTv setFrame:Tvframe];
}


- (void) SetSchemeSource:(PlanScheme *) SourceValue
{
    Source = SourceValue;
    [TripTv reloadData];
}
- (CGFloat) CalculateSumHeight
{
    CGFloat SumHeight = 8.0f;
    for(int i=0;i<[Source.Trips count];i++)
    {
        SumHeight += [self tableView:TripTv heightForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
    }
    return SumHeight;
}
#pragma mark TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Trip * oneTrip = [Source.Trips objectAtIndex:[indexPath row]];
    if(oneTrip.TripKind != EPoint)
    {
        return 88.0f;
    }
    else
    {
        return 21.0f;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(Source == nil)
    {
        return 0;
    }
    else
    {
        return [Source.Trips count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TripCell * cell = (TripCell *)[tableView dequeueReusableCellWithIdentifier:@"TripCell"];
    if(cell == nil)
    {
        NSArray *nib=[[NSBundle mainBundle]loadNibNamed:@"TripCell" owner:self options:nil];
        cell = (TripCell *)[nib objectAtIndex:0];
    }
//    Trip * lastTrip = ([indexPath row] > 0) ? [Source.Trips objectAtIndex:[indexPath row]-1]:nil;
//    Trip * oneTrip = [Source.Trips objectAtIndex:[indexPath row]];
//    Trip * nextTrip = ([indexPath row] < [Source.Trips count]-1) ? [Source.Trips objectAtIndex:[indexPath row]+1]:nil;
//
//    [cell.StopLbl setText:oneTrip.StopName];
//    NSMutableString * DescSb = [[NSMutableString alloc] init];
//   
//    if(oneTrip.TripKind == Foot)
//    {
//        [cell.KindIv setHidden:NO];
//        [cell.LineIv setHidden:NO];
//        [cell.DescLbl setHidden:NO];
//        [cell.KindIv setImage:[UIImage imageNamed:@"routeplan_tripfoot.png"]];
//        [DescSb appendString:@"從"];
//        if(lastTrip == nil )
//        {
//            [DescSb appendFormat:@" 起點 %@ ",oneTrip.StopName];
//        }
//        else
//        {
//            if(lastTrip.TripKind == ByBus)
//            {
//                [DescSb appendFormat:@"公車站 [%@] ",oneTrip.StopName];
//            }
//            else
//            {
//                [DescSb appendFormat:@"火車站 [%@] ",oneTrip.StopName];
//            }
//        }
//        [DescSb appendFormat:@"步行%d公尺，到達",oneTrip.FootDistance];
//        if(nextTrip != nil )
//        {
//            if(nextTrip.TripKind == ByBus)
//            {
//                [DescSb appendFormat:@"公車站 [%@] ",nextTrip.StopName];
//            }
//            else if(nextTrip.TripKind == ByTrain)
//            {
//                [DescSb appendFormat:@"火車站 [%@] ",nextTrip.StopName];
//            }
//            else if(nextTrip.TripKind == EPoint)
//            {
//                [DescSb appendFormat:@"終點 %@",nextTrip.StopName];
//            }
//        }
//
//    }
//    else if(oneTrip.TripKind == ByBus)
//    {
//        [cell.KindIv setHidden:NO];
//        [cell.LineIv setHidden:NO];
//        [cell.DescLbl setHidden:NO];
//        [cell.KindIv setImage:[UIImage imageNamed:@"routeplan_tripbus.png"]];
//        [DescSb appendFormat:@"從公車站 [%@] 搭乘",oneTrip.StopName];
//        if(oneTrip.RouteKind == 1)
//        {
//            [DescSb appendString:@"公車"];
//        }
//        else
//        {
//            [DescSb appendString:@"客運"];
//        }
//        [DescSb appendFormat:@" [%@] ，經過%d站後，於公車站 [%@] 下車。",oneTrip.RouteName,oneTrip.TravelStopCount,oneTrip.ArrivalStopName];
//        
//    }
//    else if(oneTrip.TripKind == ByTrain)
//    {
//        [cell.KindIv setHidden:NO];
//        [cell.LineIv setHidden:NO];
//        [cell.DescLbl setHidden:NO];
//        [cell.KindIv setImage:[UIImage imageNamed:@"routeplan_tripbus.png"]];
//        [DescSb appendFormat:@"從火車站 [%@] 搭乘 [%@] ，經過%d站後，於火車站 [%@] 下車。",oneTrip.StopName,oneTrip.RouteName,oneTrip.TravelStopCount,oneTrip.ArrivalStopName];
//    }
//    else
//    {
//        [cell.PointIv setImage:[UIImage imageNamed:@"routeplan_point2.png"]];
//        [cell.LineIv setHidden:YES];
//        [cell.KindIv setHidden:YES];
//        [cell.DescLbl setHidden:YES];
//        return cell;
//    }
//    [cell.DescLbl setText:DescSb];
    Trip * oneTrip = [Source.Trips objectAtIndex:[indexPath row]];
    [cell.StopLbl setText:oneTrip.FromStop];
    if(oneTrip.TripKind == Foot)
    {
        [cell.KindIv setHidden:NO];
        [cell.LineIv setHidden:NO];
        [cell.DescLbl setHidden:NO];
        [cell.KindIv setImage:[UIImage imageNamed:@"routeplan_tripfoot.png"]];
        [cell.DescLbl setText:oneTrip.Desc];
    }
    else if(oneTrip.TripKind == ByBus)
    {
        [cell.KindIv setHidden:NO];
        [cell.LineIv setHidden:NO];
        [cell.DescLbl setHidden:NO];
        [cell.KindIv setImage:[UIImage imageNamed:@"routeplan_tripbus.png"]];
        [cell.DescLbl setText:oneTrip.Desc];
    }
    else if(oneTrip.TripKind == ByTrain)
    {
        [cell.KindIv setHidden:NO];
        [cell.LineIv setHidden:NO];
        [cell.DescLbl setHidden:NO];
        [cell.KindIv setImage:[UIImage imageNamed:@"routeplan_tripbus.png"]];
        [cell.DescLbl setText:oneTrip.Desc];
    }
    else
    {
        [cell.PointIv setImage:[UIImage imageNamed:@"routeplan_point2.png"]];
        [cell.LineIv setHidden:YES];
        [cell.KindIv setHidden:YES];
        [cell.DescLbl setHidden:YES];
        return cell;
    }
    
    
    if([indexPath row] == 0)
    {
        [cell.PointIv setImage:[UIImage imageNamed:@"routeplan_point1.png"]];
    }
    else
    {
        [cell.PointIv setImage:[UIImage imageNamed:@"routeplan_point3.png"]];
    }
    
    
    
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

}

@end
