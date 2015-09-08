//
//  AttractionManager.h
//  i84-TaichungV2
//
//  Created by ＴＭＳ 景翊科技 on 2014/4/3.
//  Copyright (c) 2014年 ＴＭＳ 景翊科技. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef enum
{
    AttractionSuccess = 1
    ,AttractionFail = -1
    ,AttractionHased = 2
} AttractionResult;

@interface AttractionManager : NSObject
{
    
}

+ (NSString *) GetVerStr;
- (void) CheckOrCopyDb;

+ (NSMutableArray *) ReadHopLandmark;
+ (NSMutableArray *) SearchLandMark:(NSString *)KeyWord;
+ (NSMutableArray *) ReadStoreLandmark;
+ (AttractionResult) AddStoreLandmarkByName:(NSString *)LandMarkName Address:(NSString *)Address Lon:(float)lon Lat:(float)lat;

@end
