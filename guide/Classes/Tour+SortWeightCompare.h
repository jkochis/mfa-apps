//
//  Tour+SortWeightCompare.h
//  MFA Guide
//
//  Created by Robert Brecher on 7/28/11.
//  Copyright 2011 Genuine Interactive. All rights reserved.
//

#import "Tour.h"

@interface Tour (SortWeightCompare)

- (NSComparisonResult)sortWeightCompare:(Tour *)otherTour;

@end
