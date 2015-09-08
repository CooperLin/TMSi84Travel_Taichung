//
//  MarqueeView.h
//  TTravelPad
//
//  Created by ＴＭＳ 景翊科技 on 2013/12/20.
//  Copyright (c) 2013年 ycgisMini2. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MarqueeContent : NSObject
{
//    UIFont * font;
    UIColor * color;
    NSString * Content;
}
//@property (nonatomic,retain) UIFont * font;
@property (nonatomic,retain) UIColor * color;
@property (nonatomic,copy) NSString * Content;
@end
@protocol MarqueeDelegate <NSObject>

- (void) MarqueeClick:(MarqueeContent *) MarqueeContentSender;
- (void) MarqueeScrollFinish;

@end
typedef enum 
{
	Marquee_Right,
	Marquee_Left
}MarqueeDirection;

@interface MarqueeView : UIView
{
    id<MarqueeDelegate> delegate;
    MarqueeDirection Dir;
    
    int EvenPxAtSec;//每秒位移Px
    int MarqueeSpacing;//兩則跑馬燈間距
    
    NSMutableArray * Contents;//跑馬燈訊息
}

@property (nonatomic,retain) id<MarqueeDelegate> delegate;
@property MarqueeDirection Dir;
@property int EvenPxAtSec;
@property int MarqueeSpacing;
@property (nonatomic,retain) NSMutableArray * Contents;

- (void) StartMarquee;
- (void) StopMarquee;

@end
