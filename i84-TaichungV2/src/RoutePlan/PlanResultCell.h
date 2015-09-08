//
//  PlanResultCell.h
//  i84-TaichungV2
//
//  Created by ＴＭＳ 景翊科技 on 2014/3/11.
//  Copyright (c) 2014年 ＴＭＳ 景翊科技. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PlanResultCell : UITableViewCell
{
    IBOutlet UILabel * SchemeLbl;
    IBOutlet UILabel * SumTravelTimeLbl;
    IBOutlet UILabel * RouteLbl;
    IBOutlet UILabel * DescLbl;
    IBOutlet UILabel * ArrivalLbl;
    
    IBOutlet UIImageView * TitleBgIv;
}
@property (nonatomic,retain)    IBOutlet UILabel * SchemeLbl;
@property (nonatomic,retain)    IBOutlet UILabel * SumTravelTimeLbl;
@property (nonatomic,retain)    IBOutlet UILabel * RouteLbl;
@property (nonatomic,retain)    IBOutlet UILabel * DescLbl;
@property (nonatomic,retain)    IBOutlet UILabel * ArrivalLbl;
@property (nonatomic,retain)    IBOutlet UIImageView * TitleBgIv;

@end
