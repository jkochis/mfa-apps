//
//  Tour+SortWeightCompare.m
//  MFA Guide
//
//  Created by Robert Brecher on 7/28/11.
//  Copyright 2011 Genuine Interactive. All rights reserved.
//

#import "Tour+SortWeightCompare.h"

@implementation Tour (SortWeightCompare)

- (NSComparisonResult)sortWeightCompare:(Tour *)otherTour
{
	// if both sort weights are nil, sort by title
	if ([self sortWeight] == nil &&
		[otherTour sortWeight] == nil) {
		return [[self title] compare:[otherTour title]];
	}
	
	// if either is nil, sort the nil value down
	if ([self sortWeight] == nil) {
		return NSOrderedDescending;
	}
	if ([otherTour sortWeight] == nil) {
		return NSOrderedAscending;
	}
	
	// if both sort weights are set and differ, sort accordingly
	if ([self sortWeight] < [otherTour sortWeight]) {
		return NSOrderedAscending;
	}
	if ([self sortWeight] > [otherTour sortWeight]) {
		return NSOrderedDescending;
	}
	
	// default to title
	return [[self title] compare:[otherTour title]];
}

@end
