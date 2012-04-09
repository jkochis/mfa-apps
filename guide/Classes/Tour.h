//
//  Tour.h
//  MFA Guide
//
//  Created by Robert Brecher on 7/21/11.
//  Copyright (c) 2011 Genuine Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Tour : NSManagedObject {
@private
}
@property (nonatomic, retain) NSString * language;
@property (nonatomic, retain) NSNumber * id;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSDate * updatedDate;
@property (nonatomic, retain) NSNumber * errors;
@property (nonatomic, retain) NSString * bundleName;
@property (nonatomic, retain) NSNumber * sortWeight;

@end
