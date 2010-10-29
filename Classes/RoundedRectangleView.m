//
//  RoundedRectangleView.m
//  MFA Guide
//
//  Created by Robert Brecher on 10/5/10.
//  Copyright 2010 Genuine Interactive. All rights reserved.
//

#import "RoundedRectangleView.h"


@implementation RoundedRectangleView

@synthesize radius, fill;

- (id)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder])) {
		[self setRadius:5];
		[self setFill:[self backgroundColor]];
		[self setBackgroundColor:[UIColor clearColor]];
	}
	return self;
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
		[self setRadius:5];
		[self setFill:[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.8f]];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
	CGContextRef c = UIGraphicsGetCurrentContext();
    if (c != nil) {
        int leftX = rect.origin.x;
		int leftXCenter = rect.origin.x + radius;
		int rightX = rect.origin.x + rect.size.width;
		int rightXCenter = rect.origin.x + rect.size.width - radius;
		int topY = rect.origin.y;
		int topYCenter = rect.origin.y + radius;
		int bottomY = rect.origin.y + rect.size.height;
		int bottomYCenter = rect.origin.y + rect.size.height - radius;
		CGContextSetFillColorWithColor(c, [fill CGColor]);
        CGContextBeginPath(c);  
		CGContextMoveToPoint(c, leftX, topYCenter);  
		CGContextAddArcToPoint(c, leftX, topY, leftXCenter, topY, radius);  
		CGContextAddLineToPoint(c, rightXCenter, topY);  
		CGContextAddArcToPoint(c, rightX, topY, rightX, topYCenter, radius);  
		CGContextAddLineToPoint(c, rightX, bottomYCenter);  
		CGContextAddArcToPoint(c, rightX, bottomY, rightXCenter, bottomY, radius);  
		CGContextAddLineToPoint(c, leftXCenter, bottomY);  
		CGContextAddArcToPoint(c, leftX, bottomY, leftX, bottomYCenter, radius);  
		CGContextAddLineToPoint(c, leftX, topYCenter);  
		CGContextClosePath(c);
        CGContextFillPath(c);
    }
}

- (void)dealloc {
    [super dealloc];
}


@end
