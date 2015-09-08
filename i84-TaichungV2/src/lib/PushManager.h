//
//  PushManager.h
//  TTravelPad
//
//  Created by ＴＭＳ 景翊科技 on 13/8/2.
//  Copyright (c) 2013年 ycgisMini2. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PushManager : NSObject
{
    
}


- (id) initWithToken:(NSString *)Token;

+ (NSString *) GetToken;

@end
