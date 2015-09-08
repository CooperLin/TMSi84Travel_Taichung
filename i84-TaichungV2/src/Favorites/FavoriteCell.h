//
//  FavoriteCell.h
//  i84-TaichungV2
//
//  Created by ＴＭＳ 景翊科技 on 2014/3/4.
//  Copyright (c) 2014年 ＴＭＳ 景翊科技. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FavoriteCell : UITableViewCell
{
    IBOutlet UIImageView * IconIv;
    IBOutlet UILabel * RouteLbl;
    IBOutlet UILabel * StopLbl;
    IBOutlet UILabel * GotoLbl;
    IBOutlet UILabel * ArrivalLbl;
}
@property (nonatomic,retain)     IBOutlet UIImageView * IconIv;
@property (nonatomic,retain)     IBOutlet UILabel * RouteLbl;
@property (nonatomic,retain)     IBOutlet UILabel * StopLbl;
@property (nonatomic,retain)     IBOutlet UILabel * GotoLbl;
@property (nonatomic,retain)     IBOutlet UILabel * ArrivalLbl;

@end
