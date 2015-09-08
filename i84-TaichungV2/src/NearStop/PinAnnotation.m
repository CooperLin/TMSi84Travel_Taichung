//
//  PinAnnotation.m
//  i84-TaichungV2
//
//  Created by TMS_APPLE on 2014/4/16.
//  Copyright (c) 2014年 ＴＭＳ 景翊科技. All rights reserved.
//

#import "PinAnnotation.h"

@implementation PinAnnotation
@synthesize coordinate, title, subtitle;

- (id)initWithCoordinate:(CLLocationCoordinate2D)coords {
    self = [super init];
    if (self != nil) coordinate = coords;
    
    return self;
}

@end
