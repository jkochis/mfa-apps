//
//  BevelView.m
//  MFA Guide
//
//  Created by Robert Brecher on 10/5/10.
//  Copyright 2010 Genuine Interactive. All rights reserved.
//

#import "BevelView.h"


@implementation BevelView

@synthesize fill, bevel, flipped;

- (id)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder])) {
		[self setFill:[self backgroundColor]];
		[self setBackgroundColor:[UIColor clearColor]];
		const CGFloat * components = CGColorGetComponents([fill CGColor]);
		[self setBevel:[UIColor colorWithRed:MIN(components[0] + 0.45f, 1.0f) green:MIN(components[1] + 0.45f, 1.0f) blue:MIN(components[2] + 0.45f, 1.0f) alpha:components[3]]];
	}
	return self;
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self setFill:[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.6f]];
		[self setBevel:[UIColor colorWithRed:0.65f green:0.65f blue:0.65f alpha:0.6f]];
		[self setOpaque:NO];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
	CGContextRef c = UIGraphicsGetCurrentContext();
    if (c != nil) {
		
		// store positions
        int leftX = rect.origin.x;
		int rightX = rect.origin.x + rect.size.width;
		int topY = rect.origin.y;
		int bottomY = rect.origin.y + rect.size.height;
		
		if (!flipped) {
		
			// left edge
			CGContextSetFillColorWithColor(c, [fill CGColor]);
			CGContextBeginPath(c);
			CGContextMoveToPoint(c, leftX, topY);
			CGContextAddLineToPoint(c, leftX + 1, topY);
			CGContextAddLineToPoint(c, leftX + 1, bottomY);
			CGContextAddLineToPoint(c, leftX, bottomY);
			CGContextAddLineToPoint(c, leftX, topY);
			CGContextClosePath(c);
			CGContextFillPath(c);
			
			// left inner edge
			CGContextSetFillColorWithColor(c, [bevel CGColor]);
			CGContextBeginPath(c);
			CGContextMoveToPoint(c, leftX + 1, topY + 1);
			CGContextAddLineToPoint(c, leftX + 2, topY + 1);
			CGContextAddLineToPoint(c, leftX + 2, bottomY);
			CGContextAddLineToPoint(c, leftX + 1, bottomY);
			CGContextAddLineToPoint(c, leftX + 1, topY + 1);
			CGContextClosePath(c);
			CGContextFillPath(c);
			
			// top edge
			CGContextSetFillColorWithColor(c, [fill CGColor]);
			CGContextBeginPath(c);
			CGContextMoveToPoint(c, leftX, topY);
			CGContextAddLineToPoint(c, rightX, topY);
			CGContextAddLineToPoint(c, rightX, topY + 1);
			CGContextAddLineToPoint(c, leftX, topY + 1);
			CGContextAddLineToPoint(c, leftX, topY);
			CGContextClosePath(c);
			CGContextFillPath(c);
			
			// top inner edge
			CGContextSetFillColorWithColor(c, [bevel CGColor]);
			CGContextBeginPath(c);
			CGContextMoveToPoint(c, leftX + 2, topY + 1);
			CGContextAddLineToPoint(c, rightX, topY + 1);
			CGContextAddLineToPoint(c, rightX, topY + 2);
			CGContextAddLineToPoint(c, leftX + 2, topY + 2);
			CGContextAddLineToPoint(c, leftX + 2, topY + 1);
			CGContextClosePath(c);
			CGContextFillPath(c);
			
			// fill
			CGMutablePathRef pathRef = CGPathCreateMutable();
			CGPathMoveToPoint(pathRef, NULL, leftX + 2, topY + 2);
			CGPathAddLineToPoint(pathRef, NULL, rightX, topY + 2);
			CGPathAddLineToPoint(pathRef, NULL, rightX, bottomY);
			CGPathAddLineToPoint(pathRef, NULL, leftX + 2, bottomY);
			CGPathAddLineToPoint(pathRef, NULL, leftX + 2, topY + 2);
			CGPathCloseSubpath(pathRef);
			CGContextAddPath(c, pathRef);
			CGContextClip(c);
			CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
			const CGFloat * fillComponents = CGColorGetComponents([fill CGColor]);
			CGFloat locations[2] = {0.0f, 1.0f};
			CGFloat components[8] = {MIN(fillComponents[0] + 0.2f, 1.0f), MIN(fillComponents[1] + 0.2f, 1.0f), MIN(fillComponents[2] + 0.2f, 1.0f), fillComponents[3],
									 fillComponents[0], fillComponents[1], fillComponents[2], fillComponents[3]};
			CGGradientRef gradientRef = CGGradientCreateWithColorComponents(colorSpaceRef, components, locations, 2);
			CGPoint startPoint, endPoint;
			startPoint.x = leftX;
			startPoint.y = topY;
			endPoint.x = leftX;
			endPoint.y = bottomY;
			CGContextDrawLinearGradient(c, gradientRef, startPoint, endPoint, 0);
			
			// cleanup
			CGPathRelease(pathRef);
			CGColorSpaceRelease(colorSpaceRef);
			CGGradientRelease(gradientRef);
		}
		else {
			
			// left edge
			CGContextSetFillColorWithColor(c, [fill CGColor]);
			CGContextBeginPath(c);
			CGContextMoveToPoint(c, leftX, topY);
			CGContextAddLineToPoint(c, leftX + 1, topY);
			CGContextAddLineToPoint(c, leftX + 1, bottomY);
			CGContextAddLineToPoint(c, leftX, bottomY);
			CGContextAddLineToPoint(c, leftX, topY);
			CGContextClosePath(c);
			CGContextFillPath(c);
			
			// left inner edge
			CGContextSetFillColorWithColor(c, [bevel CGColor]);
			CGContextBeginPath(c);
			CGContextMoveToPoint(c, leftX + 1, topY);
			CGContextAddLineToPoint(c, leftX + 2, topY);
			CGContextAddLineToPoint(c, leftX + 2, bottomY - 1);
			CGContextAddLineToPoint(c, leftX + 1, bottomY - 1);
			CGContextAddLineToPoint(c, leftX + 1, topY);
			CGContextClosePath(c);
			CGContextFillPath(c);
			
			// bottom edge
			CGContextSetFillColorWithColor(c, [fill CGColor]);
			CGContextBeginPath(c);
			CGContextMoveToPoint(c, leftX, bottomY);
			CGContextAddLineToPoint(c, rightX, bottomY);
			CGContextAddLineToPoint(c, rightX, bottomY - 1);
			CGContextAddLineToPoint(c, leftX, bottomY - 1);
			CGContextAddLineToPoint(c, leftX, bottomY);
			CGContextClosePath(c);
			CGContextFillPath(c);
			
			// bottom inner edge
			CGContextSetFillColorWithColor(c, [bevel CGColor]);
			CGContextBeginPath(c);
			CGContextMoveToPoint(c, leftX + 2, bottomY - 1);
			CGContextAddLineToPoint(c, rightX, bottomY - 1);
			CGContextAddLineToPoint(c, rightX, bottomY - 2);
			CGContextAddLineToPoint(c, leftX + 2, bottomY - 2);
			CGContextAddLineToPoint(c, leftX + 2, bottomY - 1);
			CGContextClosePath(c);
			CGContextFillPath(c);
			
			// fill
			CGMutablePathRef pathRef = CGPathCreateMutable();
			CGPathMoveToPoint(pathRef, NULL, leftX + 2, topY);
			CGPathAddLineToPoint(pathRef, NULL, rightX, topY);
			CGPathAddLineToPoint(pathRef, NULL, rightX, bottomY - 2);
			CGPathAddLineToPoint(pathRef, NULL, leftX + 2, bottomY - 2);
			CGPathAddLineToPoint(pathRef, NULL, leftX + 2, topY);
			CGPathCloseSubpath(pathRef);
			CGContextAddPath(c, pathRef);
			CGContextClip(c);
			CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
			const CGFloat * fillComponents = CGColorGetComponents([fill CGColor]);
			CGFloat locations[2] = {0.0f, 1.0f};
			CGFloat components[8] = {MIN(fillComponents[0] + 0.2f, 1.0f), MIN(fillComponents[1] + 0.2f, 1.0f), MIN(fillComponents[2] + 0.2f, 1.0f), fillComponents[3],
				fillComponents[0], fillComponents[1], fillComponents[2], fillComponents[3]};
			CGGradientRef gradientRef = CGGradientCreateWithColorComponents(colorSpaceRef, components, locations, 2);
			CGPoint startPoint, endPoint;
			startPoint.x = leftX;
			startPoint.y = topY;
			endPoint.x = leftX;
			endPoint.y = bottomY;
			CGContextDrawLinearGradient(c, gradientRef, startPoint, endPoint, 0);
			
			// cleanup
			CGPathRelease(pathRef);
			CGColorSpaceRelease(colorSpaceRef);
			CGGradientRelease(gradientRef);
		}
    }
}

- (void)dealloc
{
	[fill release];
	[bevel release];
    [super dealloc];
}


@end
