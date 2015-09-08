//
//  AboutCell.h
//  LongWay
//
//  Created by ＴＭＳ 景翊科技 on 13/3/14.
//  Copyright (c) 2013年 ＴＭＳ 景翊科技. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AboutCell : UITableViewCell
{
    IBOutlet UIImageView * Iv;
    IBOutlet UILabel * TitleLbl;
    IBOutlet UIView * BgV;
    
    IBOutlet UIView * TopLine;
    IBOutlet UIView * BottomLine;
}
@property (nonatomic,retain) IBOutlet UIImageView * Iv;
@property (nonatomic,retain) IBOutlet UILabel * TitleLbl;
@property (nonatomic,retain) IBOutlet UIView * BgV;

@property (nonatomic,retain) IBOutlet UIView * TopLine;
@property (nonatomic,retain) IBOutlet UIView * BottomLine;

@end
