//
//  busDynamicCell.h
//  i84-TaichungV2
//
//  Created by TMS_APPLE on 2014/3/12.
//  Copyright (c) 2014年 ＴＭＳ 景翊科技. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface busDynamicCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UIImageView *imageTimeBackground;
@property (strong, nonatomic) IBOutlet UILabel *labelTime;
@property (strong, nonatomic) IBOutlet UILabel *labelSequence;
@property (strong, nonatomic) IBOutlet UILabel *labelStopName;
@property (strong, nonatomic) IBOutlet UIImageView *imageBusType;
@property (strong, nonatomic) IBOutlet UILabel *labelBusPlate;
@property (strong, nonatomic) IBOutlet UIImageView *imageBusPlateBackground;

@end
