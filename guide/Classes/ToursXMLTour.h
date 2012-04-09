//
//  ToursXMLTour.h
//  MFA Guide
//
//  Created by Robert Brecher on 10/8/10.
//  Copyright 2010 Genuine Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ToursXMLTour : NSObject {
	NSNumber *id;
	NSString *title;
	NSString *bundleName;
	NSString *bundleTourML;
	NSString *language;
	NSDate *updatedDate;
	NSNumber *sortWeight;
}

@property (nonatomic, retain) NSNumber *id;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *bundleName;
@property (nonatomic, retain) NSString *bundleTourML;
@property (nonatomic, retain) NSString *language;
@property (nonatomic, retain) NSDate *updatedDate;
@property (nonatomic, retain) NSNumber *sortWeight;

@end
