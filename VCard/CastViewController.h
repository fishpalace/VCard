//
//  CastViewController.h
//  VCard
//
//  Created by 海山 叶 on 12-4-18.
//  Copyright (c) 2012年 Mondev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreDataTableViewController.h"
#import "PullToRefreshView.h"
#import "WaterflowView.h"

@interface CastViewController : CoreDataTableViewController <WaterflowViewDelegate, WaterflowViewDatasource, PullToRefreshViewDelegate, UIScrollViewDelegate> {
    
    WaterflowView *_waterflowView;
    PullToRefreshView *_pullView;
    
}

@property(nonatomic, strong) IBOutlet WaterflowView *waterflowView;

@end
