//
//  stopMapViewController.h
//  i84-TaichungV2
//
//  Created by TMS_APPLE on 2014/4/16.
//  Copyright (c) 2014年 ＴＭＳ 景翊科技. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "PinAnnotation.h"
@interface stopMapViewController : UIViewController<MKMapViewDelegate>
@property (strong,nonatomic)id idSelectedStop;
@property (strong, nonatomic) IBOutlet MKMapView *mapView;

@end
