//
//  TripCell.h
//  i84-TaichungV2
//
//  Created by ＴＭＳ 景翊科技 on 2014/3/11.
//  Copyright (c) 2014年 ＴＭＳ 景翊科技. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TripCell : UITableViewCell
{
    IBOutlet UIImageView * KindIv;
    IBOutlet UIImageView * PointIv;
    IBOutlet UIImageView * LineIv;
    IBOutlet UILabel * StopLbl;
    IBOutlet UILabel * DescLbl;
}
@property (nonatomic,retain)    IBOutlet UIImageView * KindIv;
@property (nonatomic,retain)    IBOutlet UIImageView * PointIv;
@property (nonatomic,retain)    IBOutlet UIImageView * LineIv;
@property (nonatomic,retain)    IBOutlet UILabel * StopLbl;
@property (nonatomic,retain)    IBOutlet UILabel * DescLbl;

@end
