//
//  UpdateTimer.m
//  takeBus_Taipei
//
//  Created by TMS_APPLE on 2014/5/5.
//  Copyright (c) 2014年 TMS. All rights reserved.
//

#import "UpdateTimer.h"

@implementation UpdateTimer
{
    NSUInteger uintegerTimer;
}
@synthesize alarmTime,tickOn,delegate;
-(id)init
{
    self = [super init];
    
    if (self)
    {
        self.threadUpdate = [[NSThread alloc] initWithTarget:self selector:@selector(timerTickerMake) object:nil];
        [self.threadUpdate start];
        [self timerTickStart];
    }
    return self;
}
-(id)initWithAlarmTime:(NSUInteger)time
{
    self = [self init];
    if (self)
    {
        [self setAlarmTime:time];
    }
    return self;
}
-(void)timerTickerMake
{
    while (![[NSThread currentThread] isCancelled])
    {
        if (tickOn && self.delegate)
        {
            [self timerTickCheck];
            [self timerAlarmCheck];
        }
        uintegerTimer ++;
        [NSThread sleepForTimeInterval:1];
    }
}
-(void)timerAlarmCheck
{
    if (![NSThread isMainThread])
    {
        [self performSelectorOnMainThread:@selector(timerAlarmCheck) withObject:nil waitUntilDone:NO];
        return;
    }
    if (uintegerTimer >= self.alarmTime)
    {
        if (self.delegate)
        {
            if ([self.delegate respondsToSelector:@selector(updateTimerAlarm)])
            {
                [self.delegate updateTimerAlarm];
            }
        }
        [self resetUpdateTime];
    }
}
-(void)timerTickCheck
{
    if (![NSThread isMainThread])
    {
        [self performSelectorOnMainThread:@selector(timerTickCheck) withObject:nil waitUntilDone:NO];
        return;
    }
    if (self.delegate)
    {
        if ([self.delegate respondsToSelector:@selector(updateTimerTick:)])
        {
            [self.delegate updateTimerTick:uintegerTimer];
        }
    }
}
-(void)timerTickStart
{
    self.tickOn = YES;
    [self resetUpdateTime];
}
-(void)timerTickStop
{
    self.tickOn = NO;
}
-(void)resetUpdateTime
{
    uintegerTimer = 0;
}
@end
