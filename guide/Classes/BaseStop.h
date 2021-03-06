#import <Foundation/Foundation.h>

#import "TourMLUtils.h"

@interface BaseStop : NSObject {
	
	xmlNodePtr stopNode;
}

@property xmlNodePtr stopNode;

- (id)initWithStopNode:(xmlNodePtr)stop;

// Get the internal stop id
- (NSString *)getStopId;

// Get the internal stop code
- (NSString *)getStopCode;

// Return the stop title
- (NSString *)getTitle;

// Return the stop description or null if not provided
- (NSString *)getDescription;

// Return the path to an icon to use for a stop
- (NSString *)getIconPath;

// Return the stop update date
- (NSDate *)getUpdateDate;

// Return an array of all the files this stop uses
- (NSArray *)getAllFiles;

// Check if this stop provides a view controller
- (BOOL)providesViewController;

// Get a UIViewController for the stop
- (UIViewController *)newViewController;

// Let the stop run itself
- (BOOL)loadStopView;

@end
