//
//  Tour.h
//  MFA Guide
//
//  Created by Robert Brecher on 10/14/10.
//  Copyright 2010 Genuine Interactive. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface Tour :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * language;
@property (nonatomic, retain) NSNumber * id;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSDate * updatedDate;
@property (nonatomic, retain) NSNumber * errors;
@property (nonatomic, retain) NSString * bundleName;

@end



