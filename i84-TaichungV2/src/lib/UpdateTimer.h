//
//  UpdateTimer.h
//  takeBus_Taipei
//
//  Created by TMS_APPLE on 2014/5/5.
//  Copyright (c) 2014年 TMS. All rights reserved.
//
//  follow UpdateTimerDelegate in ViewController to recieve updateTimerTick every second
//  and recieve -updateTimerAlarm every setting alarm time

#import <Foundation/Foundation.h>
@protocol UpdateTimerDelegate <NSObject>
@required

@optional
-(void)updateTimerTick:(NSUInteger)updateTime;
-(void)updateTimerAlarm;
@end
@interface UpdateTimer : NSObject
@property (strong, nonatomic)NSThread * threadUpdate;
@property (strong, nonatomic)id<UpdateTimerDelegate> delegate;
@property (assign, nonatomic)NSUInteger alarmTime;
@property (assign, nonatomic)BOOL tickOn;
//Alarm by delegate method -updateTimerAlarm on setting alarm time
-(id)initWithAlarmTime:(NSUInteger)time;

-(void)timerTickStart;
-(void)timerTickStop;
//set update time 0
-(void)resetUpdateTime;

@end
