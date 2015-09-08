//
//  TakeTimeTableViewCell.h
//  i84-TaichungV2
//
//  Created by TMS_APPLE on 2014/6/30.
//  Copyright (c) 2014年 ＴＭＳ 景翊科技. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TakeTimeTableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UILabel *labelName;
@property (strong, nonatomic) IBOutlet UILabel *labelPath;
@property (strong, nonatomic) IBOutlet UILabel *labelStopsCount;
@property (strong, nonatomic) IBOutlet UILabel *labelTime;
@property (strong, nonatomic) IBOutlet UILabel *stopLabel;

@end
