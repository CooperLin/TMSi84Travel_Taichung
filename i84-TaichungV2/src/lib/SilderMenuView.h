//
//  SilderMenuView.h
//  i84-TaichungV2
//
//  Created by ＴＭＳ 景翊科技 on 2014/3/3.
//  Copyright (c) 2014年 ＴＭＳ 景翊科技. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SilderMenuDelegate <NSObject>

- (void) ItemSelectedEvent:(NSString *) SelectedItem;
- (void) SilderMenuHiddenedEvent;
- (void) SilderMenuShowedEvent;

@end

@interface SilderMenuView : UITableView<UITableViewDataSource,UITableViewDelegate>
{
    NSMutableArray * Items;
    id<SilderMenuDelegate> delegate;
}
@property id<SilderMenuDelegate> SilderDelegate;
@property UIView *viewCover;

- (void) insertItem:(NSDictionary *) insertItem;
- (void) removeItem:(NSDictionary *) removeItem;
- (void) setItemsByPlistName:(NSString *)PlistName;
- (void) SilderShow;
- (void) SilderHidden;

- (void) setSilderDelegate:(id<SilderMenuDelegate>) SilderDelegate;


@end
