//
//  SettingTableViewCell.h
//  WeTongji
//
//  Created by 紫川 王 on 12-4-24.
//  Copyright (c) 2012年 Tongji Apple Club. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingTableViewCell : UITableViewCell

@property (nonatomic, strong) UISwitch *itemSwitch;
@property (nonatomic, strong) UIButton *itemWatchButton;

- (void)setSwitch;
- (void)setDisclosureIndicator;
- (void)setWatchButton;

@end
