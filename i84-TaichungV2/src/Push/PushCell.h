//
//  PushCell.h
//  i84-TaichungV2
//
//  Created by ＴＭＳ 景翊科技 on 2014/3/4.
//  Copyright (c) 2014年 ＴＭＳ 景翊科技. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PushCell : UITableViewCell
{
    IBOutlet UILabel * RouteLbl;
    IBOutlet UILabel * StopLbl;
    IBOutlet UILabel * TripLbl;
    IBOutlet UILabel * TimeLbl;
    IBOutlet UILabel * WeekLbl;
    
    IBOutlet UIImageView * SwitchIv;
}

@property (nonatomic,retain)     IBOutlet UILabel * RouteLbl;
@property (nonatomic,retain)     IBOutlet UILabel * StopLbl;
@property (nonatomic,retain)     IBOutlet UILabel * TripLbl;
@property (nonatomic,retain)     IBOutlet UILabel * TimeLbl;
@property (nonatomic,retain)     IBOutlet UILabel * WeekLbl;

@property (nonatomic,retain)     IBOutlet UIImageView * SwitchIv;

@end
