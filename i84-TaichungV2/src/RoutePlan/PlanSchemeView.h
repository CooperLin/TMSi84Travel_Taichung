//
//  PlanSchemeView.h
//  i84-TaichungV2
//
//  Created by ＴＭＳ 景翊科技 on 2014/3/10.
//  Copyright (c) 2014年 ＴＭＳ 景翊科技. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DataTypes.h"

@class PlanScheme;
@interface PlanSchemeView : UIView<UITableViewDataSource,UITableViewDelegate>
{
    PlanScheme * Source;
}

- (void) SetSchemeSource:(PlanScheme *) SourceValue;
- (CGFloat) CalculateSumHeight;

@end
