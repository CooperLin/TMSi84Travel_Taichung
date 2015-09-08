//
//  NSNull+JSON.m
//  i84-TaichungV2
//
//  Created by TMS_APPLE on 2014/7/31.
//  Copyright (c) 2014年 ＴＭＳ 景翊科技. All rights reserved.
//

#import "NSNull+JSON.h"

@implementation NSNull (JSON)

- (NSUInteger)length { return 0; }

- (NSInteger)integerValue { return 0; };

- (float)floatValue { return 0; };

- (NSString *)description { return @"0(NSNull)"; }

- (NSArray *)componentsSeparatedByString:(NSString *)separator { return @[]; }

- (id)objectForKey:(id)key { return nil; }

- (BOOL)boolValue { return NO; }

-(BOOL) isEqualToString:(NSString *) compare {
    
    if ([compare isKindOfClass:[NSNull class]] || !compare) {
        NSLog(@"NSNull isKindOfClass called!");
        return YES;
    }
    
    return NO;
}
@end