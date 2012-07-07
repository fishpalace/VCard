//
//  Group.h
//
//
//  Created by 海山 叶 on 12-7-5.
//  Copyright (c) 2012年 Mondev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#define kGroupTypeFavourite 0
#define kGroupTypeGroup     1
#define kGroupTypeTopic     2

@interface Group : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * picURL;
@property (nonatomic, retain) NSString * groupID;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) NSNumber * index;

+ (Group *)insertGroupInfo:(NSDictionary *)dict inManagedObjectContext:(NSManagedObjectContext *)context;
+ (Group *)insertTopicInfo:(NSDictionary *)dict inManagedObjectContext:(NSManagedObjectContext *)context;
+ (Group *)insertTopicWithName:(NSString *)name andID:(NSString *)trendID inManangedObjectContext:(NSManagedObjectContext *)context;
+ (Group *)groupWithName:(NSString *)name inManagedObjectContext:(NSManagedObjectContext *)context;
+ (void)deleteGroupWithGroupID:(NSString *)groupID inManagedObjectContext:(NSManagedObjectContext *)context;

@end