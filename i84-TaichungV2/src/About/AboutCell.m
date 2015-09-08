//
//  AboutCell.m
//  LongWay
//
//  Created by ＴＭＳ 景翊科技 on 13/3/14.
//  Copyright (c) 2013年 ＴＭＳ 景翊科技. All rights reserved.
//

#import "AboutCell.h"

@implementation AboutCell
@synthesize Iv;
@synthesize TitleLbl;
@synthesize BgV;

@synthesize TopLine;
@synthesize BottomLine;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
