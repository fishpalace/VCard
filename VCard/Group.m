//
//  Group.m
//  VCard
//
//  Created by 海山 叶 on 12-7-15.
//  Copyright (c) 2012年 Mondev. All rights reserved.
//

#import "Group.h"


@implementation Group

@dynamic groupID;
@dynamic index;
@dynamic name;
@dynamic picURL;
@dynamic type;
@dynamic groupUserID;
@dynamic count;

+ (Group *)groupWithID:(NSString *)groupID inManagedObjectContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    [request setEntity:[NSEntityDescription entityForName:@"Group" inManagedObjectContext:context]];
    [request setPredicate:[NSPredicate predicateWithFormat:@"groupID == %@", groupID]];
    
    Group *res = [[context executeFetchRequest:request error:NULL] lastObject];
    
    return res;
}

+ (Group *)groupWithName:(NSString *)name inManagedObjectContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    [request setEntity:[NSEntityDescription entityForName:@"Group" inManagedObjectContext:context]];
    [request setPredicate:[NSPredicate predicateWithFormat:@"name == %@ && type == %@", name, [NSNumber numberWithInt:2]]];
    
    Group *res = [[context executeFetchRequest:request error:NULL] lastObject];
    
    return res;
}

+ (Group *)insertGroupInfo:(NSDictionary *)dict inManagedObjectContext:(NSManagedObjectContext *)context
{
    NSString *groupID = [dict objectForKey:@"idstr"];
    
    if (!groupID || [groupID isEqualToString:@""]) {
        return nil;
    }
    
    Group *result = [Group groupWithID:groupID inManagedObjectContext:context];
    if (!result) {
        result = [NSEntityDescription insertNewObjectForEntityForName:@"Group" inManagedObjectContext:context];
    }
    
    result.groupID = groupID;
    NSString *url = [dict objectForKey:@"profile_image_url"];
    result.picURL = [url stringByReplacingOccurrencesOfString:@"/50/" withString:@"/180/"];
    result.name = [dict objectForKey:@"name"];
    result.type = [NSNumber numberWithInt:kGroupTypeGroup];
    result.count = [NSNumber numberWithInt:[[dict objectForKey:@"member_count"] intValue]];
    
    return result;
}

+ (Group *)insertTopicInfo:(NSDictionary *)dict inManagedObjectContext:(NSManagedObjectContext *)context
{
    NSString *groupID = [dict objectForKey:@"trend_id"];
    
    if (!groupID || [groupID isEqualToString:@""]) {
        return nil;
    }
    
    Group *result = [Group groupWithID:groupID inManagedObjectContext:context];
    if (!result) {
        result = [NSEntityDescription insertNewObjectForEntityForName:@"Group" inManagedObjectContext:context];
    }
    result.groupID = groupID;
    result.name = [dict objectForKey:@"hotword"];
    result.type = [NSNumber numberWithInt:kGroupTypeTopic];
    
    return result;
}

+ (Group *)insertTopicWithName:(NSString *)name andID:(NSString *)trendID inManangedObjectContext:(NSManagedObjectContext *)context
{
    if (!trendID || [trendID isEqualToString:@""]) {
        return nil;
    }
    
    Group *result = [Group groupWithID:trendID inManagedObjectContext:context];
    if (!result) {
        result = [NSEntityDescription insertNewObjectForEntityForName:@"Group" inManagedObjectContext:context];
    }
    result.groupID = trendID;
    result.name = name;
    result.type = [NSNumber numberWithInt:kGroupTypeTopic];
    
    return result;
}

+ (void)deleteGroupWithGroupID:(NSString *)groupID inManagedObjectContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    [request setEntity:[NSEntityDescription entityForName:@"Group" inManagedObjectContext:context]];
    [request setPredicate:[NSPredicate predicateWithFormat:@"groupID == %@", groupID]];
    
    [context deleteObject:[[context executeFetchRequest:request error:NULL] lastObject]];
}

@end
