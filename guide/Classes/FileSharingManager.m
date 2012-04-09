//
//  FileSharingManager.m
//  MFA Guide
//
//  Created by Robert Brecher on 11/1/10.
//  Copyright 2010 Genuine Interactive. All rights reserved.
//

#import "FileSharingManager.h"

#import "CoreDataManager.h"
#import "Tour.h"
#import "TourController.h"

@implementation FileSharingManager

+ (void)checkBundles
{
	NSArray *documentsPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [documentsPaths objectAtIndex:0];
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	NSArray *contents = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:nil];
	if (contents) {
		for (int i = 0; i < [contents count]; i++)
		{
			NSString *filename = [contents objectAtIndex:i];
			if ([[filename pathExtension] isEqualToString:@"bundle"]) {
				Tour *tour = [CoreDataManager getTourByBundleName:[filename stringByDeletingPathExtension]];
				if (tour) {
					NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:[documentsDirectory stringByAppendingPathComponent:filename] error:nil];
					if ([[fileAttributes fileModificationDate] timeIntervalSinceDate:[tour updatedDate]] >= 0) {
						[CoreDataManager updateTourUpdatedDate:[NSDate date] byId:[tour id]];
					}
				}
				else {
					NSBundle *tourBundle = [NSBundle bundleWithPath:[documentsDirectory stringByAppendingPathComponent:filename]];
					NSString *tourDataPath = [tourBundle pathForResource:TOUR_FILENAME ofType:@"xml"];
					if (!tourDataPath) {
						NSLog(@"%@: Could not find %@.xml", filename, TOUR_FILENAME);
						continue;
					}
					NSNumber *tourId;
					NSString *title;
					NSString *language;
					xmlDocPtr tourDoc = xmlParseFile([tourDataPath UTF8String]);
					xmlNodePtr idNode = [TourMLUtils getIdInDocument:tourDoc];
					if (idNode) {
						char* idChars = (char*)xmlNodeGetContent(idNode);
						tourId = [NSNumber numberWithInt:[[NSString stringWithUTF8String:idChars] intValue]];
						free(idChars);
					}
					else {
						continue;
					}
					xmlNodePtr titleNode = [TourMLUtils getTitleInDocument:tourDoc];
					if (titleNode) {
						char* titleChars = (char*)xmlNodeGetContent(titleNode);
						title = [NSString stringWithUTF8String:titleChars];
						free(titleChars);
					}
					else {
						continue;
					}
					xmlNodePtr languageNode = [TourMLUtils getLanguageInDocument:tourDoc];
					if (languageNode) {
						char* languageChars = (char*)xmlNodeGetContent(languageNode);
						language = [NSString stringWithUTF8String:languageChars];
						free(languageChars);
					}
					else {
						language = @"en";
					}
					xmlFreeDoc(tourDoc);
					[CoreDataManager addOrUpdateTourWithId:tourId 
													 title:title 
												bundleName:[filename stringByDeletingPathExtension] 
												  language:language 
											   updatedDate:[NSDate date] 
												sortWeight:nil
													errors:NO];
				}
			}
		}
	}
	[fileManager release];
}

@end
