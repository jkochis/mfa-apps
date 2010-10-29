//
//  ToursXMLParser.m
//  Test
//
//  Created by Robert Brecher on 9/16/10.
//  Copyright 2010 Genuine Interactive. All rights reserved.
//

#import "ToursXMLParser.h"

#import "BaseStop.h"
#import "ToursXMLTour.h"
#import "StopFactory.h"
#import "TourMLUtils.h"

@implementation ToursXMLParser

+ (NSArray *)parseToursXML:(NSData *)xmlData
{
	// convert xml to NSArray of <Tour> nodes, represented by the ToursXMLTour object
	xmlTextReaderPtr reader = xmlReaderForMemory([xmlData bytes], [xmlData length], nil, nil, (XML_PARSE_NOBLANKS | XML_PARSE_NOCDATA | XML_PARSE_NOERROR | XML_PARSE_NOWARNING));
	if (!reader) {
		NSLog(@"Failed to load reader.");
		return nil;
	}
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
	NSString *currentTag = nil;
	NSString *currentValue = nil;
	ToursXMLTour *currentTour = nil;
	NSMutableArray *tours = [NSMutableArray	array];
	char* temp;
	while (xmlTextReaderRead(reader)) {
		switch (xmlTextReaderNodeType(reader)) {
			case XML_READER_TYPE_ELEMENT: {
				temp = (char*)xmlTextReaderConstName(reader);
				currentTag = [NSString stringWithCString:temp encoding:NSUTF8StringEncoding];
				if ([currentTag isEqualToString:@"Tour"]) {
					currentTour = [[[ToursXMLTour alloc] init] autorelease];
					[tours addObject:currentTour];
				}
				break;
			}
			case XML_READER_TYPE_TEXT: {
				temp = (char*)xmlTextReaderConstValue(reader);
				currentValue = [NSString stringWithCString:temp encoding:NSUTF8StringEncoding];
				if ([currentTag isEqualToString:@"Id"]) {
					[currentTour setId:[NSNumber numberWithInt:[currentValue intValue]]];
				}
				else if ([currentTag isEqualToString:@"Title"]) {
					[currentTour setTitle:currentValue];
				}
				else if ([currentTag isEqualToString:@"BundleName"]) {
					[currentTour setBundleName:currentValue];
				}
				else if ([currentTag isEqualToString:@"BundleTourML"]) {
					[currentTour setBundleTourML:currentValue];
				}
				else if ([currentTag isEqualToString:@"Language"]) {
					[currentTour setLanguage:currentValue];
				}
				else if ([currentTag isEqualToString:@"UpdateDate"]) {
					[currentTour setUpdatedDate:[dateFormatter dateFromString:currentValue]];
				}
				currentTag = nil;
				currentValue = nil;
				break;
			}
			default: {
				break;
			}
		}
	}
	[dateFormatter release];
	return tours;
}

@end
