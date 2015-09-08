//
//  MarqueeView.m
//  TTravelPad
//
//  Created by ＴＭＳ 景翊科技 on 2013/12/20.
//  Copyright (c) 2013年 ycgisMini2. All rights reserved.
//

#import "MarqueeView.h"

#define MarqueeDefaultFont [UIFont systemFontOfSize:20.0f]
@implementation MarqueeContent
@synthesize color,Content;

- (id) init
{
    self = [super init];
    if(self)
    {
//        font = [UIFont systemFontOfSize:17.0f];
        color = [UIColor blackColor];
    }
    return self;
}
@end
@interface MarqueeView ()
{
    NSMutableArray * UnuseLabels;
    NSMutableArray * UsedLabels;

    int MarqueeIndex;
    
    NSThread * UpdataViewT;
}

@end

@implementation MarqueeView
@synthesize delegate,Dir,EvenPxAtSec,MarqueeSpacing,Contents;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[UIColor clearColor]];
        UnuseLabels = [[NSMutableArray alloc] init];
        UsedLabels = [[NSMutableArray alloc] init];
        Contents = [[NSMutableArray alloc] init];
        MarqueeIndex = -1;
        EvenPxAtSec = 25;
        MarqueeSpacing = 50;
    }
    return self;
}

- (void) StartMarquee
{
    if(UpdataViewT != nil)
    {
        [UpdataViewT cancel];
    }
    UpdataViewT = [[NSThread alloc] initWithTarget:self selector:@selector(UpdataViewWork) object:nil];
    [UpdataViewT start];
}
- (void) StopMarquee
{
    if(UpdataViewT)
    {
        [UpdataViewT cancel];
    }
}
- (void) UpdataViewWork
{
    while (![[NSThread currentThread] isCancelled])
    {
        //回收現有跑出畫面外的Label
        if([UsedLabels count] > 0)
        {
            for(long i=[UsedLabels count]-1;i>=0;i--)
            {
                UILabel * oneLbl = [UsedLabels objectAtIndex:i];
                CGRect frame = oneLbl.frame;
                //向左移方向跑馬燈
                if(frame.origin.x + frame.size.width <= 0)
                {
                    [UsedLabels removeObject:oneLbl];
                    [UnuseLabels addObject:oneLbl];
                }
            }
            if([UsedLabels count] == 0 && delegate != nil)
            {
                [delegate MarqueeScrollFinish];
            }
        }
        bool NeedNewMarquee = NO;
        //檢查最後一個Label是否超出螢幕
        if([UsedLabels count] > 0)
        {
            UILabel * oneLbl = [UsedLabels lastObject];
            CGRect frame = oneLbl.frame;
            //向左移方向跑馬燈
            if(frame.origin.x + frame.size.width + MarqueeSpacing - EvenPxAtSec < self.frame.size.width)
            {
                NeedNewMarquee = YES;
            }
        }
        if(MarqueeIndex == -1 && [Contents count] > 0)
        {
            NeedNewMarquee = YES;
        }
        if(NeedNewMarquee)
        {
            [self performSelectorOnMainThread:@selector(GenerateNewMarquee:) withObject:[NSNumber numberWithBool:NeedNewMarquee] waitUntilDone:YES];
        }

        
        //計算現有的Label位移
        [self performSelectorOnMainThread:@selector(UpdataUsedLabel) withObject:nil waitUntilDone:YES];
        
        [NSThread sleepForTimeInterval:1.0f];
    }
}
//計算現有的Label位移
- (void)UpdataUsedLabel
{
    if([UsedLabels count] > 0)
    {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:1.0f];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationCurve:UIViewAnimationCurveLinear|UIViewAnimationOptionAllowUserInteraction];
        
//        [UIView animateWithDuration:1.0f delay:0.0f options:UIViewAnimationCurveLinear | UIViewAnimationOptionAllowUserInteraction animations:^{
            for(UILabel * oneLbl in UsedLabels)
            {
                CGRect frame = oneLbl.frame;
                frame.origin.x = frame.origin.x - EvenPxAtSec;
                [oneLbl setFrame:frame];
            }

        
        
//        } completion:nil];
        

        [UIView commitAnimations];
    }
}
- (void) GenerateNewMarquee :(NSNumber *)NeedNewMarqueeValue
{
    BOOL NeedNewMarquee = [NeedNewMarqueeValue boolValue];
    while (NeedNewMarquee)
    {
        UILabel * newLbl;
//        NSLog(@"GenerateNewMarquee Index:%d UnuseLabels Count:%d",MarqueeIndex,[UnuseLabels count]);
        if([UnuseLabels count]>0)
        {
            newLbl =[UnuseLabels objectAtIndex:0];
            [UnuseLabels removeObjectAtIndex:0];
        }
        else
        {
            newLbl = [[UILabel alloc] init];
            [newLbl setLineBreakMode:NSLineBreakByClipping];
            [newLbl setBackgroundColor:[UIColor clearColor]];
            [newLbl setFont:MarqueeDefaultFont];
            [newLbl setUserInteractionEnabled:YES];
            [newLbl setTextAlignment:NSTextAlignmentCenter];
            UITapGestureRecognizer * recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(TapMarqueeContentEvent:)];
            recognizer.numberOfTapsRequired = 1;
            recognizer.numberOfTouchesRequired = 1;
            [newLbl addGestureRecognizer:recognizer];
            recognizer = nil;
        }
        
        MarqueeIndex = MarqueeIndex + 1;
        if(MarqueeIndex >= [Contents count])
        {
            MarqueeIndex = 0;
        }
        MarqueeContent * oneContent = [Contents objectAtIndex:MarqueeIndex];
        [newLbl setFont:MarqueeDefaultFont];
//        [newLbl setFont:oneContent.font];
        [newLbl setTextColor:oneContent.color];
        [newLbl setText:oneContent.Content];
        [newLbl setTag:MarqueeIndex];
        CGSize maxSize = self.frame.size;
        maxSize.width = maxSize.width * 3;
        CGSize experctedSize = [oneContent.Content sizeWithFont:newLbl.font constrainedToSize:maxSize lineBreakMode:newLbl.lineBreakMode];
        CGRect frame = newLbl.frame;
        frame.size.width = experctedSize.width;
        frame.size.height = self.frame.size.height;
        //向左移方向跑馬燈
        frame.origin.x = self.frame.size.width;
        if([UsedLabels count] > 0)
        {
            UILabel * LastLbl = [UsedLabels lastObject];
            CGRect LastFrame = LastLbl.frame;
            frame.origin.x = LastFrame.origin.x + LastFrame.size.width + MarqueeSpacing;
            
        }
        if(frame.origin.x + frame.size.width + MarqueeSpacing - EvenPxAtSec < self.frame.size.width )
        {
            NeedNewMarquee = YES;
        }
        else
        {
            NeedNewMarquee = NO;
        }
        [newLbl setFrame:frame];
        
        [UsedLabels addObject:newLbl];
        [self addSubview:newLbl];
    }
}

-(void) TapMarqueeContentEvent:(UITapGestureRecognizer *)sender
{
    UILabel * TapLbl = (UILabel *)sender.view;
    long TapMarqueeIndex = TapLbl.tag;
    MarqueeContent * TapContent = [Contents objectAtIndex:TapMarqueeIndex];
    if(delegate!=nil)
    {
        [delegate MarqueeClick:TapContent];
    }
//    NSLog(@"Tap :%@",TapContent.Content);
}


@end
