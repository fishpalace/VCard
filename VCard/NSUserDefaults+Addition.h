//
//  NSUserDefaults+Addition.h
//  VCard
//
//  Created by 王 紫川 on 12-7-11.
//  Copyright (c) 2012年 Mondev. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    SettingOptionFontSizeTypeSmall,
    SettingOptionFontSizeTypeNormal,
    SettingOptionFontSizeTypeBig,
} SettingOptionFontSizeType;

typedef enum {
    SettingOptionFontSizeSmall = 14,
    SettingOptionFontSizeNormal = 17,
    SettingOptionFontSizeBig = 20,
} SettingOptionFontSize;

typedef enum {
    SettingOptionFontNotificationTypeComment,
    SettingOptionFontNotificationTypeFollower,
    SettingOptionFontNotificationTypeMention,
    SettingOptionFontNotificationTypeMessage,
} SettingOptionFontNotificationType;

@class UserAccountInfo;
@class SettingOptionInfo;

@interface NSUserDefaults (Addition)

+ (void)insertUserAccountInfoWithUserID:(NSString *)userID
                                account:(NSString *)account
                               password:(NSString *)password;

+ (UserAccountInfo *)getUserAccountInfoWithUserID:(NSString *)userID;
+ (void)setUserAccountInfoWithUserID:(NSString *)userID
                          groupIndex:(NSInteger)index
                          groupTitle:(NSString *)title
                   groupDatasourceID:(NSString *)dataSourceID
                           groupType:(int)groupType;

+ (void)setCurrentUserID:(NSString *)userID;
+ (NSString *)getCurrentUserID;

+ (NSArray *)getLoginUserArray;
+ (void)setLoginUserArray:(NSArray *)array;

+ (BOOL)isAutoTrafficSavingEnabled;
+ (BOOL)isAutoLocateEnabled;
+ (BOOL)isSoundEffectEnabled;
+ (BOOL)isPictureEnabled;
+ (BOOL)isRetinaDisplayEnabled;
+ (BOOL)isDateDisplayEnabled;
+ (BOOL)isSourceDisplayEnabled;

+ (void)setPictureEnabled:(BOOL)enabled;
+ (void)setAutoTrafficSavingEnabled:(BOOL)enabled;

+ (void)updateCurrentFontSize;
+ (void)setCurrentFontSize:(CGFloat)fontSize;
+ (CGFloat)currentFontSize;
+ (CGFloat)currentLeading;
+ (SettingOptionFontSizeType)currentFontSizeType;
//返回一个数组，数组中的元素按 SettingOptionFontNotificationType 排列，类型均为包含一个BOOL类型数据的NSNumber。
+ (NSArray *)getCurrentNotificationStatus;

+ (SettingOptionInfo *)getInfoForOptionKey:(NSString *)optionKey;
+ (void)setSettingOptionInfo:(SettingOptionInfo *)info;

+ (void)setCurrentUserFavouriteIDs:(NSArray *)array;
+ (NSArray *)getCurrentUserFavouriteIDs;
+ (void)addFavouriteID:(NSString *)statusID;
+ (void)removeFavouriteID:(NSString *)statusID;

+ (BOOL)hasShownGuideBook;
+ (void)setShownGuideBook:(BOOL)hasShown;
+ (BOOL)hasShownShelfTips;
+ (void)setShownShelfTips:(BOOL)hasShown;
+ (BOOL)hasShownStackTips;
+ (void)setShownStackTips:(BOOL)hasShown;
+ (BOOL)hasShown3GWarning;
+ (void)setShown3GWarning:(BOOL)hasShown;
+ (BOOL)hasFetchedMessages;
+ (void)setFetchedMessages:(BOOL)hasShown;
+ (BOOL)hasShownMessageList;
+ (void)setShownMessageList:(BOOL)hasShown;

+ (BOOL)shouldPostRecommendVCardWeibo;
+ (void)setShouldPostRecommendVCardWeibo:(BOOL)shouldPost;

+ (BOOL)isReloaingCardCell;
+ (void)setReloadingCardCellStatus:(BOOL)reloading;

@end

@interface UserAccountInfo : NSObject

@property (nonatomic, strong) NSString *userID;
@property (nonatomic, strong) NSString *account;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSString *groupTitle;
@property (nonatomic, strong) NSString *groupIndexString;
@property (nonatomic, strong) NSString *groupDataSourceID;
@property (nonatomic, strong) NSString *groupType;

- (id)initWithInfoDict:(NSDictionary *)dict;
- (NSDictionary *)infoDictionary;
- (NSInteger)groupIndex;

@end

@interface SettingOptionInfo : NSObject

@property (nonatomic, strong) NSArray *optionsArray;
@property (nonatomic, strong) NSArray *optionChosenStatusArray;
@property (nonatomic, strong) NSString *optionKey;
@property (nonatomic, strong) NSString *optionName;
@property (nonatomic, assign) BOOL allowMultiOptions;

- (id)initWithOptionKey:(NSString *)optionKey;

@end
